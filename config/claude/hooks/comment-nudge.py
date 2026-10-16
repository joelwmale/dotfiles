#!/usr/bin/env python3
"""PostToolUse on Edit/Write/MultiEdit: surface comments the edit just added.

comment-gate.py catches comments at `git commit`, which costs a strip-and-recommit
round per commit. This runs the same detector at the edit, when the agent still
has the line in hand. It never blocks; the commit gate stays as the backstop for
edits that bypass these tools (a heredoc through Bash).
"""

import importlib.util
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.realpath(__file__))
spec = importlib.util.spec_from_file_location('comment_gate', os.path.join(HERE, 'comment-gate.py'))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


def head_version(cwd, path):
    result = subprocess.run(
        ['git', 'show', f'HEAD:./{os.path.relpath(path, cwd)}'],
        cwd=cwd, capture_output=True, text=True, timeout=10,
    )
    return result.stdout if result.returncode == 0 else ''


def added_comments(old, new):
    before = {line.strip() for line in old.splitlines()}
    return [
        line.strip() for line in new.splitlines()
        if gate.COMMENT_START.match(line) and line.strip() not in before
    ]


def main():
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    tool_input = payload.get('tool_input') or {}
    path = tool_input.get('file_path') or ''
    if not path.endswith(gate.CHECKED_SUFFIXES):
        return

    cwd = payload.get('cwd') or os.getcwd()
    tool = payload.get('tool_name')
    if tool == 'Edit':
        found = added_comments(tool_input.get('old_string', ''), tool_input.get('new_string', ''))
    elif tool == 'MultiEdit':
        found = [c for e in tool_input.get('edits') or []
                 for c in added_comments(e.get('old_string', ''), e.get('new_string', ''))]
    elif tool == 'Write':
        found = added_comments(head_version(cwd, path), tool_input.get('content', ''))
    else:
        return
    if not found:
        return

    listing = '\n'.join(f'  {line}' for line in found)
    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext': (
            f'This edit added {len(found)} comment(s) to {os.path.basename(path)}:\n{listing}\n'
            'Delete each one unless it names a constraint the code cannot express. A comment that '
            'restates the line, narrates the change, or defends a decision belongs in the commit '
            'message instead. Keep a survivor to one line.'
        ),
    }}))


if __name__ == '__main__':
    main()
