<?php

declare(strict_types=1);

use Ghboard\GithubClient;

function makeClient(array $responses): GithubClient
{
    return new GithubClient(executor: function (string $cmd) use (&$responses): string {
        return array_shift($responses) ?? '[]';
    });
}

it('parses workflow runs and keeps only the latest run per workflow name', function (): void {
    $json = json_encode([
        ['workflowName' => 'CI',     'name' => 'CI',     'status' => 'completed',   'conclusion' => 'success', 'headBranch' => 'main'],
        ['workflowName' => 'CI',     'name' => 'CI',     'status' => 'completed',   'conclusion' => 'failure', 'headBranch' => 'main'],
        ['workflowName' => 'Tests',  'name' => 'Tests',  'status' => 'in_progress', 'conclusion' => null,      'headBranch' => 'main'],
        ['workflowName' => 'Deploy', 'name' => 'Deploy', 'status' => 'completed',   'conclusion' => 'failure', 'headBranch' => 'main'],
    ]);

    $runs = makeClient([$json])->getWorkflowRuns('owner', 'repo');

    expect($runs)->toHaveCount(3);
    $byName = [];
    foreach ($runs as $run) {
        $byName[$run->name] = $run;
    }
    expect($byName['CI']->isPassed())->toBeTrue();
    expect($byName['Tests']->isRunning())->toBeTrue();
    expect($byName['Deploy']->isFailed())->toBeTrue();
});

it('uses workflowName over run name to strip Dependabot PR title noise', function (): void {
    $json = json_encode([
        [
            'workflowName' => 'CI',
            'name'         => 'npm_and_yarn in /. - Update #1385939015',
            'status'       => 'completed',
            'conclusion'   => 'success',
            'headBranch'   => 'main',
        ],
        [
            'workflowName' => 'Tests',
            'name'         => 'github_actions in /. - Update #1385939029',
            'status'       => 'completed',
            'conclusion'   => 'failure',
            'headBranch'   => 'main',
        ],
    ]);

    $runs = makeClient([$json])->getWorkflowRuns('owner', 'repo');

    expect($runs)->toHaveCount(2);
    $names = array_map(fn ($r) => $r->name, $runs);
    expect($names)->toContain('CI')->toContain('Tests');
    expect($names)->not->toContain('npm_and_yarn in /. - Update #1385939015');
});

it('filters out workflow runs not on main or master branch', function (): void {
    $json = json_encode([
        ['workflowName' => 'CI',    'name' => 'CI',    'status' => 'completed', 'conclusion' => 'success', 'headBranch' => 'main'],
        ['workflowName' => 'Tests', 'name' => 'Tests', 'status' => 'completed', 'conclusion' => 'success', 'headBranch' => 'dependabot/npm_and_yarn/lodash-4.17.21'],
        ['workflowName' => 'Lint',  'name' => 'Lint',  'status' => 'completed', 'conclusion' => 'success', 'headBranch' => 'feature/my-branch'],
        ['workflowName' => 'Build', 'name' => 'Build', 'status' => 'completed', 'conclusion' => 'success', 'headBranch' => 'master'],
    ]);

    $runs = makeClient([$json])->getWorkflowRuns('owner', 'repo');

    expect($runs)->toHaveCount(2);
    $names = array_map(fn ($r) => $r->name, $runs);
    expect($names)->toContain('CI')->toContain('Build');
});

it('returns empty array when no workflow runs exist', function (): void {
    expect(makeClient(['[]'])->getWorkflowRuns('owner', 'repo'))->toBe([]);
});

it('parses dependabot alerts by severity', function (): void {
    $json = json_encode([
        ['security_vulnerability' => ['severity' => 'critical']],
        ['security_vulnerability' => ['severity' => 'critical']],
        ['security_vulnerability' => ['severity' => 'high']],
        ['security_vulnerability' => ['severity' => 'medium']],
        ['security_vulnerability' => ['severity' => 'low']],
    ]);

    $summary = makeClient([$json])->getDependabotSummary('owner', 'repo');

    expect($summary->critical)->toBe(2)
        ->and($summary->high)->toBe(1)
        ->and($summary->medium)->toBe(1);
});

it('returns empty summary when no dependabot alerts', function (): void {
    $summary = makeClient(['[]'])->getDependabotSummary('owner', 'repo');
    expect($summary->hasAlerts())->toBeFalse();
});

it('counts open PRs', function (): void {
    $json = json_encode([['number' => 1], ['number' => 2]]);
    expect(makeClient([$json])->getOpenPrCount('owner', 'repo'))->toBe(2);
});

it('counts open issues', function (): void {
    $json = json_encode([['number' => 1], ['number' => 2], ['number' => 3]]);
    expect(makeClient([$json])->getOpenIssueCount('owner', 'repo'))->toBe(3);
});
