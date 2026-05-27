<?php

declare(strict_types=1);

namespace Ghboard;

final class Config
{
    private function __construct(
        public array $ignored,
        public int $refreshInterval,
        public string $baseDir,
        private readonly string $path,
    ) {}

    public static function load(?string $path = null): self
    {
        $path ??= self::defaultPath();

        if (!file_exists($path)) {
            $config = new self(
                ignored: [],
                refreshInterval: 60,
                baseDir: (getenv('HOME') ?: '') . '/Code',
                path: $path,
            );
            $config->persist();
            return $config;
        }

        $data = json_decode((string) file_get_contents($path), associative: true);
        $data = is_array($data) ? $data : [];

        return new self(
            ignored: $data['ignored'] ?? [],
            refreshInterval: $data['refresh_interval'] ?? 60,
            baseDir: $data['base_dir'] ?? (getenv('HOME') ?: '') . '/Code',
            path: $path,
        );
    }

    public function ignore(string $repoName): void
    {
        if (in_array($repoName, $this->ignored, strict: true)) {
            return;
        }

        $this->ignored[] = $repoName;
        $this->persist();
    }

    private function persist(): void
    {
        $tmp = $this->path . '.tmp';
        file_put_contents($tmp, json_encode([
            'ignored' => $this->ignored,
            'refresh_interval' => $this->refreshInterval,
            'base_dir' => $this->baseDir,
        ], JSON_PRETTY_PRINT));
        rename($tmp, $this->path);
    }

    private static function defaultPath(): string
    {
        return (getenv('HOME') ?: '') . '/.ghboard.json';
    }
}
