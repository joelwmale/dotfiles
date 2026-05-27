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

    /** @return WorkflowRun[] */
    public function getWorkflowRuns(string $owner, string $repo): array
    {
        $slug = escapeshellarg("{$owner}/{$repo}");
        $output = ($this->executor)(
            "gh run list --repo {$slug} --limit 30 --json name,status,conclusion 2>/dev/null"
        );

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

    public function getDependabotSummary(string $owner, string $repo): DependabotSummary
    {
        $urlPath = escapeshellarg("repos/{$owner}/{$repo}/dependabot/alerts?state=open&per_page=100");
        $output = ($this->executor)("gh api {$urlPath} 2>/dev/null");

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

    public function getOpenPrCount(string $owner, string $repo): int
    {
        $slug = escapeshellarg("{$owner}/{$repo}");
        $output = ($this->executor)(
            "gh pr list --repo {$slug} --state open --json number 2>/dev/null"
        );

        $data = json_decode($output, associative: true);
        return is_array($data) ? count($data) : 0;
    }

    public function getOpenIssueCount(string $owner, string $repo): int
    {
        $slug = escapeshellarg("{$owner}/{$repo}");
        $output = ($this->executor)(
            "gh issue list --repo {$slug} --state open --json number 2>/dev/null"
        );

        $data = json_decode($output, associative: true);
        return is_array($data) ? count($data) : 0;
    }
}
