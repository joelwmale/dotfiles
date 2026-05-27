<?php

declare(strict_types=1);

namespace Ghboard;

final class RepoData
{
    public function __construct(
        public readonly string $name,
        public readonly string $owner,
        public readonly string $path,
        /** @var WorkflowRun[] */
        public readonly array $workflows = [],
        public readonly DependabotSummary $dependabot = new DependabotSummary(0, 0, 0),
        public readonly int $openPrs = 0,
        public readonly int $openIssues = 0,
        public readonly bool $loading = true,
        public readonly ?string $error = null,
    ) {}

    public function withData(
        array $workflows,
        DependabotSummary $dependabot,
        int $openPrs,
        int $openIssues,
    ): self {
        return new self(
            name: $this->name,
            owner: $this->owner,
            path: $this->path,
            workflows: $workflows,
            dependabot: $dependabot,
            openPrs: $openPrs,
            openIssues: $openIssues,
            loading: false,
            error: null,
        );
    }

    public function withError(string $error): self
    {
        return new self(
            name: $this->name,
            owner: $this->owner,
            path: $this->path,
            workflows: $this->workflows,
            dependabot: $this->dependabot,
            openPrs: $this->openPrs,
            openIssues: $this->openIssues,
            loading: false,
            error: $error,
        );
    }
}
