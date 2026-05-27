<?php

declare(strict_types=1);

namespace Ghboard;

final class RepoDiscovery
{
    public function __construct(
        private readonly string $cwd,
        private readonly string $baseDir = '',
    ) {}

    public function isSingleRepoMode(): bool
    {
        return is_dir($this->cwd . '/.git');
    }

    /** @return RepoData[] */
    public function discover(array $ignored): array
    {
        if ($this->isSingleRepoMode()) {
            $repo = $this->parseRepo($this->cwd);
            return $repo !== null ? [$repo] : [];
        }

        $scanDir = $this->baseDir ?: $this->cwd;
        $repos = [];

        if (!is_dir($scanDir)) {
            return [];
        }

        foreach (scandir($scanDir) as $entry) {
            if ($entry === '.' || $entry === '..') {
                continue;
            }

            $path = $scanDir . '/' . $entry;

            if (!is_dir($path) || !is_dir($path . '/.git')) {
                continue;
            }

            if (in_array($entry, $ignored, strict: true)) {
                continue;
            }

            $repo = $this->parseRepo($path);
            if ($repo !== null) {
                $repos[] = $repo;
            }
        }

        usort($repos, fn(RepoData $a, RepoData $b) => strcmp($a->name, $b->name));

        return $repos;
    }

    private function parseRepo(string $path): ?RepoData
    {
        $configFile = $path . '/.git/config';

        if (!file_exists($configFile)) {
            return null;
        }

        $content = file_get_contents($configFile);
        if ($content === false) {
            return null;
        }
        $url = $this->extractRemoteUrl($content);

        if ($url === null) {
            return null;
        }

        [$owner, $name] = $this->parseGithubUrl($url);

        if ($owner === null || $name === null) {
            return null;
        }

        return new RepoData(name: $name, owner: $owner, path: $path);
    }

    private function extractRemoteUrl(string $gitConfig): ?string
    {
        if (preg_match('/\[remote "origin"\][^\[]*url\s*=\s*(.+)/s', $gitConfig, $matches)) {
            return trim(explode("\n", $matches[1])[0]);
        }
        return null;
    }

    /** @return array{string|null, string|null} */
    private function parseGithubUrl(string $url): array
    {
        // SSH: git@github.com:owner/repo.git
        // HTTPS: https://github.com/owner/repo.git
        if (preg_match('/github\.com[:\\/]([^\/]+)\/([^\/\s]+?)(?:\.git)?$/', $url, $m)) {
            return [$m[1], $m[2]];
        }
        return [null, null];
    }
}
