<?php

declare(strict_types=1);

use Ghboard\WorkflowRun;

it('reports passed when status is completed and conclusion is success', function (): void {
    $run = new WorkflowRun(name: 'CI', status: 'completed', conclusion: 'success');
    expect($run->isPassed())->toBeTrue()
        ->and($run->isRunning())->toBeFalse()
        ->and($run->isFailed())->toBeFalse();
});

it('reports running when status is in_progress', function (): void {
    $run = new WorkflowRun(name: 'Tests', status: 'in_progress', conclusion: null);
    expect($run->isRunning())->toBeTrue()
        ->and($run->isPassed())->toBeFalse()
        ->and($run->isFailed())->toBeFalse();
});

it('reports failed when conclusion is failure', function (): void {
    $run = new WorkflowRun(name: 'Deploy', status: 'completed', conclusion: 'failure');
    expect($run->isFailed())->toBeTrue()
        ->and($run->isPassed())->toBeFalse();
});

it('returns correct icon for each state', function (): void {
    expect((new WorkflowRun('CI', 'completed', 'success'))->icon())->toBe('✓')
        ->and((new WorkflowRun('Tests', 'in_progress', null))->icon())->toBe('⟳')
        ->and((new WorkflowRun('Deploy', 'completed', 'failure'))->icon())->toBe('✗');
});
