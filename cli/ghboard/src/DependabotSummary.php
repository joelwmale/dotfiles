<?php

declare(strict_types=1);

namespace Ghboard;

final class DependabotSummary
{
    public function __construct(
        public readonly int $critical,
        public readonly int $high,
        public readonly int $medium,
    ) {}

    public static function empty(): self
    {
        return new self(0, 0, 0);
    }

    public function hasAlerts(): bool
    {
        return $this->critical > 0 || $this->high > 0 || $this->medium > 0;
    }
}
