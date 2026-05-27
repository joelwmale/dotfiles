<?php

declare(strict_types=1);

use Ghboard\RepoDiscovery;

function makeFakeRepo(string $baseDir, string $name, string $remoteUrl): void
{
    mkdir("$baseDir/$name/.git", recursive: true);
    file_put_contents(
        "$baseDir/$name/.git/config",
        "[remote \"origin\"]\n\turl = $remoteUrl\n"
    );
}

function removeFakeRepo(string $baseDir, string $name): void
{
    unlink("$baseDir/$name/.git/config");
    rmdir("$baseDir/$name/.git");
    rmdir("$baseDir/$name");
}

it('detects single-repo mode when cwd contains a .git directory', function (): void {
    $dir = sys_get_temp_dir() . '/ghboard-' . uniqid();
    mkdir($dir . '/.git', recursive: true);
    file_put_contents("$dir/.git/config", "[remote \"origin\"]\n\turl = git@github.com:joelwmale/test-repo.git\n");

    $discovery = new RepoDiscovery(cwd: $dir, baseDir: $dir);
    expect($discovery->isSingleRepoMode())->toBeTrue();

    $repos = $discovery->discover(ignored: []);
    expect($repos)->toHaveCount(1)
        ->and($repos[0]->name)->toBe('test-repo')
        ->and($repos[0]->owner)->toBe('joelwmale');

    unlink("$dir/.git/config");
    rmdir("$dir/.git");
    rmdir($dir);
});

it('detects multi-repo mode when cwd has no .git directory', function (): void {
    $baseDir = sys_get_temp_dir() . '/ghboard-' . uniqid();
    mkdir($baseDir);
    makeFakeRepo($baseDir, 'repo-a', 'git@github.com:owner/repo-a.git');
    makeFakeRepo($baseDir, 'repo-b', 'git@github.com:owner/repo-b.git');
    mkdir("$baseDir/not-a-repo");

    $discovery = new RepoDiscovery(cwd: $baseDir, baseDir: $baseDir);
    expect($discovery->isSingleRepoMode())->toBeFalse();

    $repos = $discovery->discover(ignored: []);
    $names = array_map(fn($r) => $r->name, $repos);
    expect($names)->toContain('repo-a')->toContain('repo-b');
    expect(count($repos))->toBe(2);

    removeFakeRepo($baseDir, 'repo-a');
    removeFakeRepo($baseDir, 'repo-b');
    rmdir("$baseDir/not-a-repo");
    rmdir($baseDir);
});

it('excludes ignored repos', function (): void {
    $baseDir = sys_get_temp_dir() . '/ghboard-' . uniqid();
    mkdir($baseDir);
    makeFakeRepo($baseDir, 'keep', 'git@github.com:owner/keep.git');
    makeFakeRepo($baseDir, 'noise', 'git@github.com:owner/noise.git');

    $discovery = new RepoDiscovery(cwd: $baseDir, baseDir: $baseDir);
    $repos = $discovery->discover(ignored: ['noise']);
    $names = array_map(fn($r) => $r->name, $repos);

    expect($names)->toContain('keep')->not->toContain('noise');

    removeFakeRepo($baseDir, 'keep');
    removeFakeRepo($baseDir, 'noise');
    rmdir($baseDir);
});

it('parses HTTPS remote URLs', function (): void {
    $dir = sys_get_temp_dir() . '/ghboard-' . uniqid();
    mkdir($dir . '/.git', recursive: true);
    file_put_contents("$dir/.git/config", "[remote \"origin\"]\n\turl = https://github.com/myorg/my-repo.git\n");

    $discovery = new RepoDiscovery(cwd: $dir, baseDir: $dir);
    $repos = $discovery->discover(ignored: []);

    expect($repos[0]->name)->toBe('my-repo')
        ->and($repos[0]->owner)->toBe('myorg');

    unlink("$dir/.git/config");
    rmdir("$dir/.git");
    rmdir($dir);
});
