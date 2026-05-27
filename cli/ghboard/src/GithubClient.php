<?php

declare(strict_types=1);

namespace Ghboard;

final class GithubClient
{
    /** @var callable(string): string */
    private $executor;

    public function __construct(?callable $executor = null)
    {
        $this->executor = $executor ?? static function (string $command): string {
            $output = shell_exec($command);
            return $output !== null ? trim($output) : '[]';
        };
    }

    // -------------------------------------------------------------------------
    // Parallel fetch API (used by App for concurrent repo loading)
    // -------------------------------------------------------------------------

    /**
     * Start all 4 gh processes for a repo concurrently via proc_open.
     * Returns process handles and stdout pipes to be collected later.
     *
     * @return array{procs: resource[], pipes: resource[]}
     */
    public function startFetch(string $owner, string $repo): array
    {
        $slug    = escapeshellarg("{$owner}/{$repo}");
        $urlPath = escapeshellarg("repos/{$owner}/{$repo}/dependabot/alerts?state=open&per_page=100");

        $commands = [
            "gh run list --repo {$slug} --limit 30 --json name,status,conclusion 2>/dev/null",
            "gh api {$urlPath} 2>/dev/null",
            "gh pr list --repo {$slug} --state open --json number 2>/dev/null",
            "gh issue list --repo {$slug} --state open --json number 2>/dev/null",
        ];

        $procs = [];
        $pipes = [];

        foreach ($commands as $i => $cmd) {
            $descriptors = [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['file', '/dev/null', 'a'],
            ];
            $cmdPipes = [];
            $proc = proc_open($cmd, $descriptors, $cmdPipes);

            if (!is_resource($proc)) {
                continue;
            }

            fclose($cmdPipes[0]);
            stream_set_blocking($cmdPipes[1], false);
            $procs[$i] = $proc;
            $pipes[$i] = $cmdPipes[1];
        }

        return ['procs' => $procs, 'pipes' => $pipes];
    }

    /**
     * Wait for all processes started by startFetch() to complete and parse results.
     *
     * @param array{procs: resource[], pipes: resource[]} $fetchState
     * @return array{0: WorkflowRun[], 1: DependabotSummary, 2: int, 3: int}
     */
    public function collectFetch(array $fetchState): array
    {
        $outputs  = array_fill(0, 4, '');
        $pipes    = $fetchState['pipes'];
        $procs    = $fetchState['procs'];
        $open     = $pipes;

        while (!empty($open)) {
            $read   = array_values($open);
            $write  = null;
            $except = null;

            if (false === stream_select($read, $write, $except, 5)) {
                break;
            }

            foreach ($open as $i => $pipe) {
                if (!in_array($pipe, $read, strict: true)) {
                    continue;
                }
                $chunk = fread($pipe, 65536);
                if ($chunk === false || $chunk === '') {
                    if (feof($pipe)) {
                        fclose($pipe);
                        unset($open[$i]);
                    }
                } else {
                    $outputs[$i] .= $chunk;
                }
            }
        }

        foreach ($procs as $proc) {
            if (is_resource($proc)) {
                proc_close($proc);
            }
        }

        return [
            $this->parseWorkflowRuns($outputs[0]),
            $this->parseDependabotSummary($outputs[1]),
            $this->parsePrCount($outputs[2]),
            $this->parseIssueCount($outputs[3]),
        ];
    }

    // -------------------------------------------------------------------------
    // Individual methods (kept for unit tests via injectable executor)
    // -------------------------------------------------------------------------

    /** @return WorkflowRun[] */
    public function getWorkflowRuns(string $owner, string $repo): array
    {
        $slug   = escapeshellarg("{$owner}/{$repo}");
        $output = ($this->executor)(
            "gh run list --repo {$slug} --limit 30 --json name,status,conclusion 2>/dev/null"
        );

        return $this->parseWorkflowRuns($output);
    }

    public function getDependabotSummary(string $owner, string $repo): DependabotSummary
    {
        $urlPath = escapeshellarg("repos/{$owner}/{$repo}/dependabot/alerts?state=open&per_page=100");
        $output  = ($this->executor)("gh api {$urlPath} 2>/dev/null");

        return $this->parseDependabotSummary($output);
    }

    public function getOpenPrCount(string $owner, string $repo): int
    {
        $slug   = escapeshellarg("{$owner}/{$repo}");
        $output = ($this->executor)(
            "gh pr list --repo {$slug} --state open --json number 2>/dev/null"
        );

        return $this->parsePrCount($output);
    }

    public function getOpenIssueCount(string $owner, string $repo): int
    {
        $slug   = escapeshellarg("{$owner}/{$repo}");
        $output = ($this->executor)(
            "gh issue list --repo {$slug} --state open --json number 2>/dev/null"
        );

        return $this->parseIssueCount($output);
    }

    // -------------------------------------------------------------------------
    // Parsers (shared between the executor-based and proc_open paths)
    // -------------------------------------------------------------------------

    /** @return WorkflowRun[] */
    private function parseWorkflowRuns(string $output): array
    {
        $data = json_decode($output, associative: true);

        if (!is_array($data)) {
            return [];
        }

        $seen = [];
        $runs = [];

        foreach ($data as $row) {
            $name = $row['name'] ?? '';
            if (isset($seen[$name])) {
                continue;
            }
            $seen[$name] = true;
            $runs[] = new WorkflowRun(
                name: $name,
                status: $row['status'] ?? '',
                conclusion: ($row['conclusion'] ?? null) ?: null,
            );
        }

        return $runs;
    }

    private function parseDependabotSummary(string $output): DependabotSummary
    {
        $data = json_decode($output, associative: true);

        if (!is_array($data)) {
            return DependabotSummary::empty();
        }

        $critical = $high = $medium = 0;

        foreach ($data as $alert) {
            match ($alert['security_vulnerability']['severity'] ?? '') {
                'critical' => $critical++,
                'high'     => $high++,
                'medium'   => $medium++,
                default    => null,
            };
        }

        return new DependabotSummary($critical, $high, $medium);
    }

    private function parsePrCount(string $output): int
    {
        $data = json_decode($output, associative: true);
        return is_array($data) ? count($data) : 0;
    }

    private function parseIssueCount(string $output): int
    {
        $data = json_decode($output, associative: true);
        return is_array($data) ? count($data) : 0;
    }
}
