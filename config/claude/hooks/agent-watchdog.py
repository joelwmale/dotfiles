#!/usr/bin/env python3
"""Stalled-subagent recovery: the hook side.

Claude Code has no hook that can interrupt a running subagent, no wall-clock
timeout for ordinary subagents, and (tested on 2.1.301) no hook that can wake an
idle parent: an `asyncRewake` hook on SubagentStart delivers to the subagent, and
on Pre/PostToolUse it runs synchronously and blocks the parent instead. The one
supported way for a process to wake the parent is the Monitor tool, so:

  enforced   pre-agent denies a re-run of an identical prompt that already timed
             out; bash-guard denies destructive git while a recovery is active;
             a Monitor running `watch` does wake the parent when it prints.
  advisory   post-agent only *asks* the parent to start that Monitor, and the
             budget and findings file only ask the subagent to behave. Cancelling
             stays with the parent, via TaskStop.

Subcommands (hook input is JSON on stdin):
  pre-agent    PreToolUse on Agent  - dedupe repeats, queue the prompt hash
  start        SubagentStart        - record the agent, inject budget + findings path
  stop         SubagentStop         - mark the agent finished
  post-agent   PostToolUse on Agent - hand the parent the Monitor command to run
  watch ID SID run under Monitor: prints a line at stall / partial / hard
  sleeper KIND async rewake inside the subagent; KIND is partial | hard
  bash-guard   PreToolUse on Bash   - protect uncommitted work during recovery
  end-recovery run by the parent once recovery is finished

Thresholds default to 10/15/20 minutes and can be shortened for testing with
~/.claude/state/agent-watchdog/override.json: {"stall": 10, "partial": 15, "hard": 20}.
"""

import fcntl
import glob
import hashlib
import json
import os
import re
import sys
import time

STATE = os.path.expanduser('~/.claude/state/agent-watchdog')
AGENTS = os.path.join(STATE, 'agents')
FINDINGS = os.path.join(STATE, 'findings')
QUEUE = os.path.join(STATE, 'pending.jsonl')
TIMED_OUT = os.path.join(STATE, 'timed-out.json')
RECOVERY = os.path.join(STATE, 'recovery-active')

DEFAULTS = {'stall': 600, 'partial': 900, 'hard': 1200}
REPEAT_BLOCK_SECONDS = 6 * 3600
RECOVERY_SECONDS = 3600
QUEUE_MAX_AGE = 120
SLEEP_CHUNK = 30

DESTRUCTIVE_GIT = re.compile(
    r'\bgit\s+(?:-C\s+\S+\s+)?('
    r'reset\s+--hard|clean\b|checkout\s+(?:--\s|-f\b|\.)|restore\b(?!.*--staged)|'
    r'stash\s+(?:drop|clear)|worktree\s+remove|branch\s+-D|push\s+.*--force|'
    r'switch\s+(?:-f|--discard-changes)'
    r')'
)


def thresholds():
    values = dict(DEFAULTS)
    try:
        with open(os.path.join(STATE, 'override.json')) as handle:
            values.update({k: float(v) for k, v in json.load(handle).items() if k in DEFAULTS})
    except (OSError, ValueError):
        pass
    return values


def ensure_dirs():
    for path in (STATE, AGENTS, FINDINGS):
        os.makedirs(path, exist_ok=True)


def read_input():
    try:
        return json.load(sys.stdin)
    except ValueError:
        return {}


def prompt_hash(subagent_type, prompt):
    normalised = ' '.join((prompt or '').lower().split())
    return hashlib.sha256(f'{subagent_type or "general-purpose"}\n{normalised}'.encode()).hexdigest()[:16]


def load_json(path, default):
    try:
        with open(path) as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return default


def locked_queue(mutate):
    """Run mutate(entries) -> entries under an exclusive lock on the queue."""
    ensure_dirs()
    with open(QUEUE, 'a+') as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        handle.seek(0)
        entries = [json.loads(line) for line in handle if line.strip()]
        result = mutate(entries)
        handle.seek(0)
        handle.truncate()
        for entry in entries:
            handle.write(json.dumps(entry) + '\n')
        return result


def emit(payload):
    print(json.dumps(payload))


def deny(event, reason):
    emit({'hookSpecificOutput': {
        'hookEventName': event,
        'permissionDecision': 'deny',
        'permissionDecisionReason': reason,
    }})


def pre_agent():
    data = read_input()
    tool_input = data.get('tool_input') or {}
    subagent_type = tool_input.get('subagent_type') or 'general-purpose'
    digest = prompt_hash(subagent_type, tool_input.get('prompt'))

    failed = load_json(TIMED_OUT, {}).get(digest)
    if failed and time.time() - failed['at'] < REPEAT_BLOCK_SECONDS:
        deny('PreToolUse', (
            f'An identical {subagent_type} task already timed out '
            f'({failed["reason"]}). Do not repeat it. Read the partial findings at '
            f'{failed["findings"]} first, then retry once with a strictly smaller scope '
            '(fewer files or one directory) or do the work directly. '
            'See ~/.claude/rules/agent_recovery.md.'
        ))
        return

    def push(entries):
        cutoff = time.time() - QUEUE_MAX_AGE
        entries[:] = [e for e in entries if e['at'] > cutoff]
        entries.append({'hash': digest, 'type': subagent_type, 'at': time.time()})

    locked_queue(push)


def start():
    ensure_dirs()
    data = read_input()
    agent_id = data.get('agent_id')
    if not agent_id:
        return
    agent_type = data.get('agent_type') or 'general-purpose'

    def pop(entries):
        for index, entry in enumerate(entries):
            if entry['type'] == agent_type:
                return entries.pop(index)['hash']
        return None

    digest = locked_queue(pop) or hashlib.sha256(agent_id.encode()).hexdigest()[:16]
    findings = os.path.join(FINDINGS, f'{digest}.md')
    limits = thresholds()
    with open(os.path.join(AGENTS, f'{agent_id}.json'), 'w') as handle:
        json.dump({'hash': digest, 'type': agent_type, 'session_id': data.get('session_id'),
                   'started': time.time(), 'findings': findings}, handle)

    minutes = round(limits['hard'] / 60, 1)
    emit({'hookSpecificOutput': {'hookEventName': 'SubagentStart', 'additionalContext': (
        f'TIME BUDGET: you will be cancelled after {minutes} minutes and a stall of '
        f'{round(limits["stall"] / 60, 1)} minutes with no activity is treated as failure. '
        f'Append each finding to {findings} as soon as you have it (create the file on your '
        'first finding) so work survives cancellation. Prefer a short, partial, concrete '
        'result over an exhaustive one. Stay inside the scope you were given.'
    )}})

    cutoff = time.time() - 86400
    for path in glob.glob(os.path.join(AGENTS, '*')) + glob.glob(os.path.join(FINDINGS, '*')):
        try:
            if os.path.getmtime(path) < cutoff:
                os.remove(path)
        except OSError:
            pass


def stop():
    ensure_dirs()
    agent_id = read_input().get('agent_id')
    if agent_id:
        open(os.path.join(AGENTS, f'{agent_id}.done'), 'w').close()


def transcript_mtime(session_id, agent_id):
    pattern = os.path.expanduser(f'~/.claude/projects/*/{session_id}/subagents/agent-{agent_id}.jsonl')
    for path in glob.glob(pattern):
        return os.path.getmtime(path)
    return None


def wake_message(kind, meta, limits):
    findings = meta.get('findings', '(unknown)')
    label = f'{meta.get("type", "agent")} {meta.get("agent_id", "")}'.strip()
    mins = {k: round(v / 60, 1) for k, v in limits.items()}
    if kind == 'stall':
        return (
            f'WATCHDOG: subagent {label} has shown no activity for {mins["stall"]} min. Do not keep '
            f'waiting. Read its partial findings at {findings} now. At {mins["hard"]} min you cancel it.'
        )
    if kind == 'partial':
        return (
            f'WATCHDOG: subagent {label} has run {mins["partial"]} min. Read its partial findings at '
            f'{findings}. Ask it via SendMessage to wrap up if you can; hard limit is {mins["hard"]} min.'
        )
    return (
        f'WATCHDOG: subagent {label} hit the {mins["hard"]} min limit. Call TaskStop on it now, then follow '
        f'~/.claude/rules/agent_recovery.md: read partial findings at {findings}, retry ONCE with a strictly '
        'smaller scope, and if that also fails do the work yourself. Do not reset, clean, restore or stash-drop.'
    )


def agent_message_for_subagent(kind, meta, limits):
    findings = meta.get('findings', '(unknown)')
    if kind == 'partial':
        return (
            f'WATCHDOG: you have used {round(limits["partial"] / 60, 1)} min of {round(limits["hard"] / 60, 1)}. '
            f'Stop starting new work. Make sure everything you know is appended to {findings}, then finish '
            'with a short report of what you found and what you did not get to.'
        )
    return (
        f'WATCHDOG: time limit reached. Reply NOW with whatever you have (also in {findings}). '
        'Do not make further tool calls.'
    )


def load_meta(agent_id):
    meta = load_json(os.path.join(AGENTS, f'{agent_id}.json'), {})
    meta['agent_id'] = agent_id
    return meta


def sleeper(kind):
    """Runs inside the subagent: its stderr reaches the subagent, not the parent."""
    data = read_input()
    agent_id = data.get('agent_id')
    if not agent_id:
        return
    limits = thresholds()
    started = time.time()
    done = os.path.join(AGENTS, f'{agent_id}.done')
    while time.time() - started < limits[kind]:
        if os.path.exists(done):
            return
        time.sleep(max(1, min(limits[kind] - (time.time() - started), SLEEP_CHUNK)))
    if os.path.exists(done):
        return
    meta = load_meta(agent_id)
    if kind == 'hard':
        record_timeout(meta, f'no result after {round(limits["hard"] / 60, 1)} min')
    print(agent_message_for_subagent(kind, meta, limits), file=sys.stderr)
    sys.exit(2)


def watch(agent_id, session_id):
    """Runs under the Monitor tool; each stdout line wakes the parent."""
    limits = thresholds()
    started = time.time()
    done = os.path.join(AGENTS, f'{agent_id}.done')
    sent = set()
    while time.time() - started < limits['hard'] + 120:
        if os.path.exists(done):
            return
        elapsed = time.time() - started
        last = transcript_mtime(session_id, agent_id) or started
        idle = time.time() - last
        due = [k for k, hit in (('stall', idle >= limits['stall']), ('partial', elapsed >= limits['partial']),
                                ('hard', elapsed >= limits['hard'])) if hit and k not in sent]
        for kind in due:
            meta = load_meta(agent_id)
            if kind == 'hard':
                record_timeout(meta, f'no result after {round(limits["hard"] / 60, 1)} min')
            print(wake_message(kind, meta, limits), flush=True)
            sent.add(kind)
        if 'hard' in sent:
            return
        waits = [limits['stall'] - idle, limits['partial'] - elapsed, limits['hard'] - elapsed]
        time.sleep(max(1, min([w for w in waits if w > 0] + [SLEEP_CHUNK])))


def post_agent():
    data = read_input()
    response = data.get('tool_response') or {}
    agent_id = response.get('agentId') if isinstance(response, dict) else None
    if not agent_id or not response.get('isAsync'):
        return
    limits = thresholds()
    command = (f'python3 ~/.claude/hooks/agent-watchdog.py watch {agent_id} {data.get("session_id", "")}')
    emit({'hookSpecificOutput': {'hookEventName': 'PostToolUse', 'additionalContext': (
        f'WATCHDOG: background agent {agent_id} can stall without anyone noticing. Start the Monitor tool now '
        f'with this command (persistent: false, timeout_ms {int((limits["hard"] + 180) * 1000)}) and carry on: '
        f'{command} . It prints only if the agent goes quiet for {round(limits["stall"] / 60, 1)} min, '
        f'runs {round(limits["partial"] / 60, 1)} min, or reaches {round(limits["hard"] / 60, 1)} min, and then '
        'you act per ~/.claude/rules/agent_recovery.md. Hooks cannot cancel the agent; only TaskStop can.'
    )}})


def record_timeout(meta, reason):
    ensure_dirs()
    registry = load_json(TIMED_OUT, {})
    if meta.get('hash'):
        registry[meta['hash']] = {'at': time.time(), 'reason': reason, 'findings': meta['findings']}
    with open(TIMED_OUT, 'w') as handle:
        json.dump(registry, handle)
    with open(RECOVERY, 'w') as handle:
        json.dump({'at': time.time(), 'session_id': meta.get('session_id')}, handle)


def bash_guard():
    marker = load_json(RECOVERY, None)
    if not marker or time.time() - marker['at'] > RECOVERY_SECONDS:
        return
    command = (read_input().get('tool_input') or {}).get('command') or ''
    if DESTRUCTIVE_GIT.search(command):
        deny('PreToolUse', (
            'Blocked: a subagent timed out and recovery is active, so commands that can discard '
            'uncommitted work are disabled. Commit or `git stash push` instead. '
            'When recovery is finished run: python3 ~/.claude/hooks/agent-watchdog.py end-recovery'
        ))


def end_recovery():
    try:
        os.remove(RECOVERY)
    except OSError:
        pass


COMMANDS = {
    'pre-agent': pre_agent, 'start': start, 'stop': stop,
    'bash-guard': bash_guard, 'end-recovery': end_recovery, 'post-agent': post_agent,
}

if __name__ == '__main__':
    command = sys.argv[1] if len(sys.argv) > 1 else ''
    if command == 'sleeper' and len(sys.argv) > 2 and sys.argv[2] in ('partial', 'hard'):
        sleeper(sys.argv[2])
    elif command == 'watch' and len(sys.argv) > 2:
        watch(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else '')
    elif command in COMMANDS:
        COMMANDS[command]()
    sys.exit(0)
