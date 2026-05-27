<?php

declare(strict_types=1);

namespace Ghboard;

use PhpTui\Tui\Extension\Core\Widget\ParagraphWidget;
use PhpTui\Tui\Extension\Core\Widget\TableWidget;
use PhpTui\Tui\Extension\Core\Widget\Table\TableCell;
use PhpTui\Tui\Extension\Core\Widget\Table\TableRow;
use PhpTui\Tui\Extension\Core\Widget\Table\TableState;
use PhpTui\Tui\Model\Color\AnsiColor;
use PhpTui\Tui\Model\Layout\Constraint;
use PhpTui\Tui\Model\Style;
use PhpTui\Tui\Model\Text\Line;
use PhpTui\Tui\Model\Text\Span;
use PhpTui\Tui\Model\Text\Text;

final class Dashboard
{
    public function buildHeader(int $repoCount, int $secondsSinceRefresh, bool $refreshing): ParagraphWidget
    {
        $leftSpan = Span::styled(
            'ghboard  ·  ' . $repoCount . ' repos',
            Style::default()->fg(AnsiColor::White),
        );

        if ($refreshing) {
            $statusSpan = Span::styled('refreshing...', Style::default()->fg(AnsiColor::Yellow));
        } else {
            $statusSpan = Span::styled(
                'last refresh: ' . $secondsSinceRefresh . 's ago',
                Style::default()->fg(AnsiColor::DarkGray),
            );
        }

        $keymapSpan = Span::styled(
            '  ·  [r] refresh  [i] ignore  [enter] open  [q] quit',
            Style::default()->fg(AnsiColor::DarkGray),
        );

        $line = Line::fromSpans([$leftSpan, Span::fromString('  '), $statusSpan, $keymapSpan]);

        return ParagraphWidget::fromText(Text::fromLine($line));
    }

    /**
     * @param RepoData[] $repos
     */
    public function buildTable(array $repos, TableState $state): TableWidget
    {
        $headerRow = TableRow::fromCells(
            TableCell::fromLine(Line::fromSpan(Span::styled('REPO', Style::default()->fg(AnsiColor::DarkGray)))),
            TableCell::fromLine(Line::fromSpan(Span::styled('WORKFLOWS', Style::default()->fg(AnsiColor::DarkGray)))),
            TableCell::fromLine(Line::fromSpan(Span::styled('DEPENDABOT', Style::default()->fg(AnsiColor::DarkGray)))),
            TableCell::fromLine(Line::fromSpan(Span::styled('PRS', Style::default()->fg(AnsiColor::DarkGray)))),
            TableCell::fromLine(Line::fromSpan(Span::styled('ISSUES', Style::default()->fg(AnsiColor::DarkGray)))),
        );

        $rows = array_map(fn (RepoData $repo): TableRow => $this->buildRow($repo), $repos);

        return TableWidget::default()
            ->widths(
                Constraint::percentage(20),
                Constraint::percentage(34),
                Constraint::percentage(24),
                Constraint::percentage(11),
                Constraint::percentage(11),
            )
            ->header($headerRow)
            ->rows(...$rows)
            ->state($state);
    }

    public function buildFooter(int $selectedIndex, int $total, int $secondsUntilRefresh): ParagraphWidget
    {
        $text = sprintf(
            '↕ j/k to scroll  ·  %d/%d  ·  auto-refresh in %ds',
            $selectedIndex,
            $total,
            $secondsUntilRefresh,
        );

        $line = Line::fromSpan(Span::styled($text, Style::default()->fg(AnsiColor::DarkGray)));

        return ParagraphWidget::fromText(Text::fromLine($line));
    }

    private function buildRow(RepoData $repo): TableRow
    {
        $nameSpan = Span::styled($repo->name, Style::default()->fg(AnsiColor::White));

        if ($repo->loading) {
            return TableRow::fromCells(
                TableCell::fromLine(Line::fromSpan($nameSpan)),
                TableCell::fromLine(Line::fromSpan(
                    Span::styled('loading...', Style::default()->fg(AnsiColor::DarkGray))
                )),
                TableCell::fromString(''),
                TableCell::fromString(''),
                TableCell::fromString(''),
            );
        }

        if ($repo->error !== null) {
            return TableRow::fromCells(
                TableCell::fromLine(Line::fromSpan($nameSpan)),
                TableCell::fromLine(Line::fromSpan(
                    Span::styled('error fetching data', Style::default()->fg(AnsiColor::Red))
                )),
                TableCell::fromString(''),
                TableCell::fromString(''),
                TableCell::fromString(''),
            );
        }

        return TableRow::fromCells(
            TableCell::fromLine(Line::fromSpan($nameSpan)),
            TableCell::fromLine($this->buildWorkflowsLine($repo->workflows)),
            TableCell::fromLine($this->buildDependabotLine($repo->dependabot)),
            TableCell::fromLine($this->buildCountLine($repo->openPrs)),
            TableCell::fromLine($this->buildCountLine($repo->openIssues)),
        );
    }

    /**
     * @param WorkflowRun[] $workflows
     */
    private function buildWorkflowsLine(array $workflows): Line
    {
        if ($workflows === []) {
            return Line::fromSpan(Span::styled('—', Style::default()->fg(AnsiColor::DarkGray)));
        }

        $spans = [];

        foreach ($workflows as $index => $workflow) {
            if ($index > 0) {
                $spans[] = Span::fromString('  ');
            }

            $color = match (true) {
                $workflow->isRunning() => AnsiColor::Yellow,
                $workflow->isFailed()  => AnsiColor::Red,
                default                => AnsiColor::Green,
            };

            $label = $workflow->icon() . ' ' . $workflow->name;
            $spans[] = Span::styled($label, Style::default()->fg($color));
        }

        return Line::fromSpans($spans);
    }

    private function buildDependabotLine(DependabotSummary $dependabot): Line
    {
        if (!$dependabot->hasAlerts()) {
            return Line::fromSpan(Span::styled('—', Style::default()->fg(AnsiColor::DarkGray)));
        }

        $spans = [];
        $addSeparator = false;

        if ($dependabot->critical > 0) {
            $spans[] = Span::styled(
                '● ' . $dependabot->critical . ' crit',
                Style::default()->fg(AnsiColor::Red),
            );
            $addSeparator = true;
        }

        if ($dependabot->high > 0) {
            if ($addSeparator) {
                $spans[] = Span::fromString('  ');
            }
            $spans[] = Span::styled(
                '● ' . $dependabot->high . ' high',
                Style::default()->fg(AnsiColor::Yellow),
            );
            $addSeparator = true;
        }

        if ($dependabot->medium > 0) {
            if ($addSeparator) {
                $spans[] = Span::fromString('  ');
            }
            $spans[] = Span::styled(
                '● ' . $dependabot->medium . ' med',
                Style::default()->fg(AnsiColor::DarkGray),
            );
        }

        return Line::fromSpans($spans);
    }

    private function buildCountLine(int $count): Line
    {
        $color = $count > 0 ? AnsiColor::White : AnsiColor::DarkGray;

        return Line::fromSpan(Span::styled((string) $count, Style::default()->fg($color)));
    }
}
