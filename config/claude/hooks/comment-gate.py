#!/usr/bin/env python3
"""PreToolUse gate on `git commit`: surface comments the staged diff adds.

The comment rules are judgement-based, so they do not bind the way Pint or a
failing test does - there is no moment that forces a look. This is that moment.

It gates the commit rather than the edit because edits arrive by several routes
(Edit, Write, a heredoc through Bash, sed) and `git diff --cached` sees all of
them. It never blocks twice for the same staged content: run the commit again
and it passes, so keeping a comment costs one look rather than an argument.
"""

import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

# Prose files comment differently and docs are meant to explain themselves.
CHECKED_SUFFIXES = ('.php', '.js', '.jsx', '.ts', '.tsx', '.vue', '.css', '.scss')

# `#` is left out: it is the ordinary comment in shell and YAML and rare in PHP,
# so matching it costs more noise than it catches. `/**` is left out because the
# house rule prefers a PHPDoc block on a class or method to inline comments.
COMMENT_START = re.compile(r'^\s*(//|\{\{--|<!--|/\*(?!\*))')

STATE_DIR = os.path.join(tempfile.gettempdir(), 'claude-comment-gate')


def allow():
    sys.exit(0)


def git(cwd, *args):
    result = subprocess.run(
        ['git', *args], cwd=cwd, capture_output=True, text=True, timeout=10
    )
    return result.stdout if result.returncode == 0 else ''


def comment_lines(cwd, stages_everything):
    """Return [(path, text)] for comment lines this commit would add.

    Diffs against HEAD rather than the index: the hook runs before the tool, so
    a `git add -A && git commit` has not staged anything yet and --cached would
    read empty. Untracked files are only read when the command stages them,
    since otherwise they are not part of the commit.
    """
    found = []
    path = None
    for line in git(cwd, 'diff', 'HEAD', '--unified=0', '--no-color').splitlines():
        if line.startswith('+++ b/'):
            path = line[6:]
            continue
        if not line.startswith('+') or line.startswith('+++'):
            continue
        if path and path.endswith(CHECKED_SUFFIXES) and COMMENT_START.match(line[1:]):
            found.append((path, line[1:].strip()))

    if stages_everything:
        untracked = git(cwd, 'ls-files', '--others', '--exclude-standard').split()
        for rel in untracked:
            if not rel.endswith(CHECKED_SUFFIXES):
                continue
            try:
                with open(os.path.join(cwd, rel), encoding='utf-8', errors='replace') as f:
                    for text in f:
                        if COMMENT_START.match(text):
                            found.append((rel, text.strip()))
            except OSError:
                continue

    return found


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        allow()

    if payload.get('tool_name') != 'Bash':
        allow()

    command = payload.get('tool_input', {}).get('command', '')
    # Only a real commit. `git commit --help` or a message merely mentioning the
    # words should not be gated.
    if not re.search(r'\bgit\s+(-\S+\s+|--\S+\s+)*commit\b', command):
        allow()
    if '--help' in command:
        allow()

    cwd = payload.get('cwd') or os.getcwd()

    try:
        comments = comment_lines(cwd, stages_everything=bool(re.search(r'\bgit\s+add\b', command)))
    except Exception:
        allow()

    if not comments:
        allow()

    # Second attempt at the same staged content goes through, so a comment that
    # earns its place is kept by simply re-running the commit.
    digest = hashlib.sha256(
        '\n'.join(f'{p}:{t}' for p, t in comments).encode()
    ).hexdigest()[:16]
    marker = os.path.join(STATE_DIR, digest)
    if os.path.exists(marker):
        allow()
    os.makedirs(STATE_DIR, exist_ok=True)
    open(marker, 'w').close()

    lines = [f'  {path}: {text}' for path, text in comments]
    plural = 'comment' if len(comments) == 1 else 'comments'

    print(
        f'This commit adds {len(comments)} {plural}:\n\n'
        + '\n'.join(lines)
        + '\n\nDelete each one. Is anything lost?\n\n'
          'Keep it only if it names a constraint the code cannot express and a\n'
          'reader would otherwise break. Delete it if it restates the line, '
          'narrates\nthe change, or defends a decision you weighed - that '
          'reasoning belongs in\nthis commit message, the PR, or the issue.\n\n'
          'Strip the ones that do not earn it, then commit again. Re-running '
          'the same\ncommit passes, so keeping one costs nothing but the look.',
        file=sys.stderr,
    )
    sys.exit(2)


if __name__ == '__main__':
    main()
