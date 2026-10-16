# Agent Recovery (Strict)

Applies whenever you delegate to a subagent, above all for reviews. A subagent
that stalls leaves you waiting indefinitely, so assume one will and plan for it.

---

## What is enforced and what is not

Nothing can interrupt a running subagent except you calling `TaskStop`. Hooks
cannot do it, and (tested on 2.1.301) no hook can wake an idle parent either:
async hooks on SubagentStart deliver to the subagent, and on Pre/PostToolUse
they run synchronously. The one supported wake-up channel is the `Monitor` tool.
Be exact about this when you report on a timeout.

| Mechanism | Status |
|---|---|
| `Monitor` running `agent-watchdog.py watch` wakes you at 10 min silent, 15 min, 20 min | enforced delivery, but you must start it |
| Starting that Monitor | advisory: a hook hands you the command, you run it |
| Cancelling the agent | only you, via `TaskStop` |
| An identical prompt that already timed out is refused | enforced (PreToolUse deny) |
| Destructive git is refused after a timeout | enforced (PreToolUse deny) |
| `maxTurns` on the agents in `agents/` | enforced, returns a partial result |
| `hooks/claude-timeout` around a subprocess | enforced, kills the process |
| Time budget, findings file, and the 15/20 min "wrap up" messages to the subagent | advisory, the agent may ignore them |

Anything not in the enforced rows is a request, not a guarantee.

---

## Before delegating

- **Several focused reviews, not one big one.** Split by directory, feature or
  risk area, a handful of files each, with the diff for that slice in the prompt.
  A prompt that says "review the branch" is the one that stalls.
- **State the scope in the prompt** as file paths, and say what to ignore.
- **Run reviews in the background** and carry on, rather than blocking on them.
  When the Agent call returns, a hook gives you a `Monitor` command for that
  agent. Start it immediately, as instructed, with the timeout it names.
- **Any review that shells out** (`claude -p`, codex, a test run) goes through
  `~/.claude/hooks/claude-timeout 1200 -- <command>`.

## When the Monitor wakes you

1. **10 min of silence**: read the findings file named in the message. Do not
   keep waiting on the agent.
2. **15 min**: read the findings file again. Try `SendMessage` asking it to wrap
   up; the docs do not promise a running agent receives it, so do not rely on it.
3. **20 min, or you have decided it is stuck**: `TaskStop` it. Then recover.

A Monitor expires after 30 minutes at most; if you delegate something that is
meant to run longer, re-arm it.

## Recovery

1. **Keep what exists.** Read the findings file and take completed findings as
   done. Commit or `git stash push` uncommitted work if you need a clean tree.
   Never run `git reset --hard`, `git clean`, `git checkout -- .`,
   `git restore` or `git stash drop` while recovering. The hook refuses them,
   and the reason it exists is that a half-finished agent may have edited files.
2. **Retry once, smaller.** Pick a strictly smaller slice than the one that
   failed - fewer files, one directory - and exclude what the findings file
   already covers. Do not resend the same prompt; the hook will refuse it.
3. **If the retry also times out, do the work yourself.** Read the code and
   review it directly. Do not dispatch a third agent.
4. **Report it.** Say which agent stalled, how long, what was recovered, and
   which part you did yourself.
5. When done, run `python3 ~/.claude/hooks/agent-watchdog.py end-recovery`.

## Do not

- Do not wait on a silent agent past the watchdog message.
- Do not repeat a failed delegation unchanged.
- Do not describe the watchdog as cancelling anything. You cancel; it only wakes you.
- Do not skip starting the Monitor because the agent "should be quick".
