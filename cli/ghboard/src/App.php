<?php

declare(strict_types=1);

namespace Ghboard;

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
use PhpTui\Tui\Model\Layout\Constraint;

final class App
{
    /** @var RepoData[] */
    private array $repos = [];

    private int $selectedIndex = 0;

    private int $lastRefreshedAt = 0;

    private bool $refreshing = false;

    private bool $quit = false;

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
        $baseDir = str_replace('~', $home, $config->baseDir);

        $this->discovery = $discovery ?? new RepoDiscovery(
            cwd: getcwd() ?: $home,
            baseDir: $baseDir,
        );
    }

    public function run(): void
    {
        $terminal = Terminal::new();
        $backend = PhpTermBackend::new($terminal);
        $display = DisplayBuilder::default($backend)->build();

        $terminal->enableRawMode();

        register_shutdown_function(static function () use ($terminal): void {
            $terminal->disableRawMode();
        });

        // Initial data fetch before first render
        $this->repos = $this->discovery->discover($this->config->ignored);
        $this->fetchAll();

        while (!$this->quit) {
            // Auto-refresh check
            if (!$this->refreshing && time() - $this->lastRefreshedAt >= $this->config->refreshInterval) {
                $this->startRefresh();
            }

            // Handle input events (non-blocking)
            while (null !== $event = $terminal->events()->next()) {
                if ($event instanceof CharKeyEvent) {
                    $this->handleChar($event);
                } elseif ($event instanceof CodedKeyEvent) {
                    $this->handleCodedKey($event);
                }
            }

            // Render
            $this->render($display);

            // Tick at ~100ms
            usleep(100_000);
        }

        $terminal->disableRawMode();
    }

    private function render(mixed $display): void
    {
        $secondsSinceRefresh = time() - $this->lastRefreshedAt;
        $secondsUntilRefresh = max(0, $this->config->refreshInterval - $secondsSinceRefresh);

        $tableState = new TableState(
            offset: 0,
            selected: count($this->repos) > 0 ? $this->selectedIndex : null,
        );

        $header = $this->dashboard->buildHeader(
            repoCount: count($this->repos),
            secondsSinceRefresh: $secondsSinceRefresh,
            refreshing: $this->refreshing,
        );

        $table = $this->dashboard->buildTable($this->repos, $tableState);

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
        $freshRepos = $this->discovery->discover($this->config->ignored);

        // Retain existing data for repos already loaded, mark new ones as loading
        $existing = [];
        foreach ($this->repos as $repo) {
            $existing[$repo->owner . '/' . $repo->name] = $repo;
        }

        $merged = [];
        foreach ($freshRepos as $repo) {
            $key = $repo->owner . '/' . $repo->name;
            $merged[] = isset($existing[$key]) ? $existing[$key] : $repo;
        }

        $this->repos = $merged;
        $this->fetchAll();
    }

    private function fetchAll(): void
    {
        $this->refreshing = true;
        $fetched = [];

        foreach ($this->repos as $repo) {
            try {
                $fetched[] = $repo->withData(
                    workflows: $this->client->getWorkflowRuns($repo->owner, $repo->name),
                    dependabot: $this->client->getDependabotSummary($repo->owner, $repo->name),
                    openPrs: $this->client->getOpenPrCount($repo->owner, $repo->name),
                    openIssues: $this->client->getOpenIssueCount($repo->owner, $repo->name),
                );
            } catch (\Throwable $e) {
                $fetched[] = $repo->withError($e->getMessage());
            }
        }

        $this->repos = $fetched;
        $this->lastRefreshedAt = time();
        $this->refreshing = false;
    }
}
