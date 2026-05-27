<?php

declare(strict_types=1);

namespace Ghboard;

final class WorkflowRun
{
    public function __construct(
        public readonly string $name,
        public readonly string $status,
        public readonly ?string $conclusion,
    ) {}

    public function isPassed(): bool
    {
        return $this->status === 'completed'
            && in_array($this->conclusion, ['success', 'skipped', 'neutral'], strict: true);
    }

    public function isRunning(): bool
    {
        return in_array($this->status, ['in_progress', 'queued', 'requested', 'waiting'], strict: true);
    }

    public function isFailed(): bool
    {
        return $this->status === 'completed' && !$this->isPassed();
    }

    public function icon(): string
    {
        return match (true) {
            $this->isRunning() => '⟳',
            $this->isFailed()  => '✗',
            default            => '✓',
        };
    }
}
