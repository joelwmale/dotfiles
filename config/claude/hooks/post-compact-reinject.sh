#!/usr/bin/env bash
# SessionStart (compact) hook: re-injects the handover file content
# so Claude has context about what happened before compaction.

HANDOVER_FILE=".claude/handover.md"

if [ -f "$HANDOVER_FILE" ]; then
    echo ""
    echo "=== SESSION HANDOVER (from before compaction) ==="
    echo "The following is a summary of the conversation before context was compacted."
    echo "Use this to maintain continuity. The full handover is at: .claude/handover.md"
    echo "---"
    cat "$HANDOVER_FILE"
    echo "=== END HANDOVER ==="
fi
