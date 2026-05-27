<?php

declare(strict_types=1);

use Ghboard\GithubClient;
use Ghboard\WorkflowRun;

function makeClient(array $responses): GithubClient
{
    return new GithubClient(executor: function (string $cmd) use (&$responses): string {
        return array_shift($responses) ?? '[]';
    });
}

it('parses workflow runs and keeps only the latest run per workflow name', function (): void {
    $json = json_encode([
        ['name' => 'CI', 'status' => 'completed', 'conclusion' => 'success'],
        ['name' => 'CI', 'status' => 'completed', 'conclusion' => 'failure'],  // older, must be ignored
        ['name' => 'Tests', 'status' => 'in_progress', 'conclusion' => null],
        ['name' => 'Deploy', 'status' => 'completed', 'conclusion' => 'failure'],
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
