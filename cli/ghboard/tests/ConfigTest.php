<?php

declare(strict_types=1);

use Ghboard\Config;

beforeEach(function (): void {
    $this->tmpPath = sys_get_temp_dir() . '/ghboard-test-' . uniqid() . '.json';
});

afterEach(function (): void {
    if (file_exists($this->tmpPath)) {
        unlink($this->tmpPath);
    }
});

it('creates config file with defaults when file does not exist', function (): void {
    $config = Config::load($this->tmpPath);

    expect($config->ignored)->toBe([])
        ->and($config->refreshInterval)->toBe(60)
        ->and($config->baseDir)->toBe(getenv('HOME') . '/Code');

    expect(file_exists($this->tmpPath))->toBeTrue();
});

it('loads values from existing config file', function (): void {
    file_put_contents($this->tmpPath, json_encode([
        'ignored' => ['noise-repo'],
        'refresh_interval' => 120,
        'base_dir' => '/Users/joel/Projects',
    ]));

    $config = Config::load($this->tmpPath);

    expect($config->ignored)->toBe(['noise-repo'])
        ->and($config->refreshInterval)->toBe(120)
        ->and($config->baseDir)->toBe('/Users/joel/Projects');
});

it('adds a repo to ignored and persists to disk', function (): void {
    $config = Config::load($this->tmpPath);
    $config->ignore('noise-repo');

    $reloaded = Config::load($this->tmpPath);
    expect($reloaded->ignored)->toContain('noise-repo');
});

it('does not duplicate repos in ignored list', function (): void {
    $config = Config::load($this->tmpPath);
    $config->ignore('repo-a');
    $config->ignore('repo-a');

    $reloaded = Config::load($this->tmpPath);
    expect($reloaded->ignored)->toBe(['repo-a']);
});
