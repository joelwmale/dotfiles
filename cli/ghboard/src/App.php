<?php

declare(strict_types=1);

namespace Ghboard;

use PhpTui\Term\Actions;
use PhpTui\Term\Event\CharKeyEvent;
use PhpTui\Term\Event\CodedKeyEvent;
use PhpTui\Term\KeyCode;
use PhpTui\Term\KeyModifiers;
use PhpTui\Term\Terminal;
use PhpTui\Tui\Bridge\PhpTerm\PhpTermBackend;
use PhpTui\Tui\DisplayBuilder;
use PhpTui\Tui\Extension\Core\Widget\GridWidget;
use PhpTui\Tui\Extension\Core\Widget\Table\TableState;
use PhpTui\Tui\Model\Direction;
use PhpTui\Tui\Model\Display\Display;
use PhpTui\Tui\Model\Layout\Constraint;

final class App
{
    /** @var RepoData[] */
    private array $repos = [];

    private int $selectedIndex = 0;

    private int $lastRefreshedAt = 0;

    private bool $refreshing = false;

    private bool $quit = false;

    private ?Display $display = null;

    private readonly Dashboard $dashboard;

    private readonly GithubClient $client;

    private readonly RepoDiscovery $discovery;

    public function __construct(
        private readonly Config $config,
        ?GithubClient $client = null,
        ?RepoDiscovery $discovery = null,
    ) {
        $this->client = $client ?? new GithubClient();
        $this->dashboard = new Dashboard();

        $home = $_SERVER['HOME'] ?? getenv('HOME') ?: '';
        $baseDir = preg_replace('/^~/', $home, $config->baseDir);

        $this->discovery = $discovery ?? new RepoDiscovery(
            cwd: getcwd() ?: $home,
            baseDir: $baseDir,
        );
    }

    public function run(): void
    {
        $terminal = Terminal::new();
        $backend = PhpTermBackend::new($terminal);
        $this->display = DisplayBuilder::default($backend)->build();

        $terminal->enableRawMode();
        $terminal->execute(Actions::alternateScreenEnable(), Actions::cursorHide());

        register_shutdown_function(static function () use ($terminal): void {
            $terminal->execute(Actions::alternateScreenDisable(), Actions::cursorShow());
            $terminal->disableRawMode();
        });

        $this->repos = $this->discovery->discover($this->config->ignored);

        // Render loading state before the blocking initial fetch
        $this->refreshing = true;
        $this->render($this->display);
        $this->fetchAll();

        // Drain any events queued during the loading fetch so stray keypresses
        // don't immediately quit the app before the user sees the TUI
        while (null !== $terminal->events()->next()) {
        }

        while (!$this->quit) {
            // Process events first so keypresses are always responsive
            while (null !== $event = $terminal->events()->next()) {
                if ($event instanceof CharKeyEvent) {
                    $this->handleChar($event);
                } elseif ($event instanceof CodedKeyEvent) {
                    $this->handleCodedKey($event);
                }
            }

            if (!$this->refreshing && time() - $this->lastRefreshedAt >= $this->config->refreshInterval) {
                $this->startRefresh();
            }

            $this->render($this->display);

            usleep(100_000);
        }

        $terminal->execute(Actions::alternateScreenDisable(), Actions::cursorShow());
        $terminal->disableRawMode();
    }

    private function render(?Display $display): void
    {
        $secondsSinceRefresh = time() - $this->lastRefreshedAt;
        $secondsUntilRefresh = max(0, $this->config->refreshInterval - $secondsSinceRefresh);

        $displayList = $this->buildDisplayList();

        $displaySelectedIndex = null;
        if (count($this->repos) > 0) {
            foreach ($displayList as $displayIdx => $item) {
                if ($item['type'] === 'repo' && ($item['repoIndex'] ?? -1) === $this->selectedIndex) {
                    $displaySelectedIndex = $displayIdx;
                    break;
                }
            }
        }

        $tableState = new TableState(offset: 0, selected: $displaySelectedIndex);

        $header = $this->dashboard->buildHeader(
            repoCount: count($this->repos),
            secondsSinceRefresh: $secondsSinceRefresh,
            refreshing: $this->refreshing,
        );

        $table = $this->dashboard->buildTable($displayList, $tableState);

        $footer = $this->dashboard->buildFooter(
            selectedIndex: $this->selectedIndex + 1,
            total: count($this->repos),
            secondsUntilRefresh: $secondsUntilRefresh,
        );

        $grid = GridWidget::default()
            ->direction(Direction::Vertical)
            ->constraints(
                Constraint::length(1),
                Constraint::min(0),
                Constraint::length(1),
            )
            ->widgets($header, $table, $footer);

        $display->draw($grid);
    }

    /**
     * Build the flat display list that Dashboard renders.
     * When groups are configured, group header items are interleaved before
     * each group's repos. Repos not in any group appear last under "Other".
     * When no groups are configured, returns a simple indexed repo list.
     *
     * @return array<int, array{type: string, label?: string, repo?: RepoData, repoIndex?: int}>
     */
    private function buildDisplayList(): array
    {
        $groups = $this->config->groups;

        if (empty($groups)) {
            $list = [];
            foreach ($this->repos as $i => $repo) {
                $list[] = ['type' => 'repo', 'repo' => $repo, 'repoIndex' => $i];
            }
            return $list;
        }

        $byName = [];
        foreach ($this->repos as $i => $repo) {
            $byName[$repo->name] = ['repoIndex' => $i, 'repo' => $repo];
        }

        $list = [];
        $usedIndices = [];

        foreach ($groups as $groupName => $repoNames) {
            $groupItems = [];
            foreach ((array) $repoNames as $name) {
                if (isset($byName[$name])) {
                    $groupItems[] = $byName[$name];
                }
            }
            if (empty($groupItems)) {
                continue;
            }
            $list[] = ['type' => 'header', 'label' => $groupName];
            foreach ($groupItems as $item) {
                $list[] = ['type' => 'repo', 'repo' => $item['repo'], 'repoIndex' => $item['repoIndex']];
                $usedIndices[] = $item['repoIndex'];
            }
        }

        $ungrouped = [];
        foreach ($this->repos as $i => $repo) {
            if (!in_array($i, $usedIndices, strict: true)) {
                $ungrouped[] = ['type' => 'repo', 'repo' => $repo, 'repoIndex' => $i];
            }
        }
        if (!empty($ungrouped)) {
            $list[] = ['type' => 'header', 'label' => 'Other'];
            foreach ($ungrouped as $item) {
                $list[] = $item;
            }
        }

        return $list;
    }

    private function handleChar(CharKeyEvent $event): void
    {
        // Ctrl-C
        if ($event->char === 'c' && ($event->modifiers & KeyModifiers::CONTROL) !== 0) {
            $this->quit = true;
            return;
        }

        match ($event->char) {
            'q'  => $this->quit = true,
            'j'  => $this->moveDown(),
            'k'  => $this->moveUp(),
            'r'  => $this->startRefresh(),
            'i'  => $this->ignoreSelected(),
            "\r", "\n" => $this->openInBrowser(),
            default => null,
        };
    }

    private function handleCodedKey(CodedKeyEvent $event): void
    {
        if ($event->kind !== \PhpTui\Term\KeyEventKind::Press) {
            return;
        }

        // Ctrl-C via CodedKeyEvent (some terminals send this way)
        if ($event->code === KeyCode::Char && ($event->modifiers & KeyModifiers::CONTROL) !== 0) {
            $this->quit = true;
            return;
        }

        match ($event->code) {
            KeyCode::Down  => $this->moveDown(),
            KeyCode::Up    => $this->moveUp(),
            KeyCode::Enter => $this->openInBrowser(),
            default        => null,
        };
    }

    private function moveDown(): void
    {
        if (count($this->repos) === 0) {
            return;
        }

        $this->selectedIndex = min($this->selectedIndex + 1, count($this->repos) - 1);
    }

    private function moveUp(): void
    {
        $this->selectedIndex = max($this->selectedIndex - 1, 0);
    }

    private function ignoreSelected(): void
    {
        if (count($this->repos) === 0) {
            return;
        }

        $repo = $this->repos[$this->selectedIndex];
        $this->config->ignore($repo->name);

        array_splice($this->repos, $this->selectedIndex, 1);

        if (count($this->repos) > 0) {
            $this->selectedIndex = min($this->selectedIndex, count($this->repos) - 1);
        } else {
            $this->selectedIndex = 0;
        }

        // Reset the auto-refresh timer so ignoring multiple repos quickly
        // doesn't trigger a blocking API refresh between keypresses.
        $this->lastRefreshedAt = time();
    }

    private function openInBrowser(): void
    {
        if (count($this->repos) === 0) {
            return;
        }

        $repo = $this->repos[$this->selectedIndex];
        $slug = escapeshellarg($repo->owner . '/' . $repo->name);
        shell_exec("gh repo view {$slug} --web 2>/dev/null &");
    }

    private function startRefresh(): void
    {
        $this->refreshing = true;
        $this->render($this->display);
        $freshRepos = $this->discovery->discover($this->config->ignored);

        // Retain existing data for repos already loaded, mark new ones as loading
        $existing = [];
        foreach ($this->repos as $repo) {
            $existing[$repo->owner . '/' . $repo->name] = $repo;
        }

        $merged = [];
        foreach ($freshRepos as $repo) {
            $key = $repo->owner . '/' . $repo->name;
            $merged[] = $existing[$key] ?? $repo;
        }

        $this->repos = $merged;
        $this->fetchAll();
    }

    private function fetchAll(): void
    {
        // Batch to stay well under the macOS default FD limit (256).
        // Each repo opens 4 stdout pipes; 30 repos × 4 = 120 concurrent FDs.
        $fetched = [];

        foreach (array_chunk($this->repos, 30) as $batch) {
            $fetches = [];
            foreach ($batch as $repo) {
                $fetches[] = $this->client->startFetch($repo->owner, $repo->name);
            }

            foreach ($batch as $j => $repo) {
                try {
                    [$workflows, $dependabot, $openPrs, $openIssues] = $this->client->collectFetch($fetches[$j]);
                    $fetched[] = $repo->withData(
                        workflows: $workflows,
                        dependabot: $dependabot,
                        openPrs: $openPrs,
                        openIssues: $openIssues,
                    );
                } catch (\Throwable $e) {
                    $fetched[] = $repo->withError($e->getMessage());
                }
            }
        }

        $this->repos = $fetched;
        $this->lastRefreshedAt = time();
        $this->refreshing = false;
    }
}
