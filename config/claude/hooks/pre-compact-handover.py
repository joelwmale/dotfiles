#!/usr/bin/env python3
"""
Pre-compact hook: reads the conversation transcript and saves a structured
handover document to the project's .claude/ directory.

Receives JSON on stdin with: transcript_path, cwd, session_id, trigger, etc.
Outputs a brief reminder to stdout so Claude knows to read the handover file.
"""

import json
import sys
import os
from datetime import datetime
from pathlib import Path


def extract_messages(transcript_path: str) -> list[dict]:
    """Parse the JSONL transcript and extract user/assistant messages."""
    messages = []
    try:
        with open(transcript_path, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue

                entry_type = entry.get("type")
                if entry_type not in ("user", "assistant"):
                    continue

                msg = entry.get("message", {})
                role = msg.get("role", entry_type)
                content = msg.get("content", "")

                # Handle content that's a list of blocks
                if isinstance(content, list):
                    text_parts = []
                    tool_uses = []
                    tool_results = []
                    for block in content:
                        if isinstance(block, dict):
                            if block.get("type") == "text":
                                text_parts.append(block.get("text", ""))
                            elif block.get("type") == "tool_use":
                                tool_uses.append({
                                    "tool": block.get("name", ""),
                                    "input_preview": str(block.get("input", {}))[:200],
                                })
                            elif block.get("type") == "tool_result":
                                result_content = block.get("content", "")
                                if isinstance(result_content, list):
                                    result_content = " ".join(
                                        b.get("text", "")[:200]
                                        for b in result_content
                                        if isinstance(b, dict) and b.get("type") == "text"
                                    )
                                tool_results.append(str(result_content)[:300])
                        elif isinstance(block, str):
                            text_parts.append(block)
                    content = "\n".join(text_parts)
                    messages.append({
                        "role": role,
                        "text": content[:2000],
                        "tool_uses": tool_uses,
                        "tool_results": tool_results,
                    })
                elif isinstance(content, str) and content.strip():
                    messages.append({
                        "role": role,
                        "text": content[:2000],
                        "tool_uses": [],
                        "tool_results": [],
                    })
    except (FileNotFoundError, PermissionError):
        return []
    return messages


def build_handover(messages: list[dict], session_id: str, cwd: str) -> str:
    """Build a structured handover markdown document from messages."""
    lines = [
        f"# Session Handover",
        f"",
        f"**Session:** `{session_id}`",
        f"**Project:** `{cwd}`",
        f"**Saved:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"",
        f"---",
        f"",
    ]

    # Extract user requests
    user_messages = [m for m in messages if m["role"] == "user" and m["text"].strip()]
    assistant_messages = [m for m in messages if m["role"] == "assistant"]

    # Summarize user requests
    lines.append("## User Requests")
    lines.append("")
    for i, msg in enumerate(user_messages, 1):
        text = msg["text"].strip()
        # Truncate long messages but keep enough context
        if len(text) > 500:
            text = text[:500] + "..."
        lines.append(f"{i}. {text}")
        lines.append("")

    # Summarize key actions (tool uses)
    all_tool_uses = []
    for msg in assistant_messages:
        all_tool_uses.extend(msg.get("tool_uses", []))

    if all_tool_uses:
        lines.append("## Key Actions Taken")
        lines.append("")

        # Group by tool
        tool_groups: dict[str, list[str]] = {}
        for tu in all_tool_uses:
            tool = tu["tool"]
            if tool not in tool_groups:
                tool_groups[tool] = []
            tool_groups[tool].append(tu["input_preview"])

        for tool, uses in tool_groups.items():
            lines.append(f"### {tool} ({len(uses)} calls)")
            # Show a few representative examples
            for use in uses[:5]:
                lines.append(f"- `{use[:150]}`")
            if len(uses) > 5:
                lines.append(f"- ... and {len(uses) - 5} more")
            lines.append("")

    # Extract assistant responses (the actual text, not tool calls)
    lines.append("## Assistant Responses (Summary)")
    lines.append("")
    for msg in assistant_messages:
        text = msg["text"].strip()
        if text and len(text) > 20:
            # Take first 300 chars of each response
            preview = text[:300]
            if len(text) > 300:
                preview += "..."
            lines.append(f"- {preview}")
            lines.append("")

    # Look for error patterns
    error_keywords = ["error", "failed", "failure", "exception", "fatal", "FAILED"]
    errors_found = []
    for msg in assistant_messages:
        for tr in msg.get("tool_results", []):
            if any(kw.lower() in tr.lower() for kw in error_keywords):
                errors_found.append(tr[:300])

    if errors_found:
        lines.append("## Errors Encountered")
        lines.append("")
        for err in errors_found[:10]:
            lines.append(f"- {err}")
        lines.append("")

    return "\n".join(lines)


def main():
    # Read hook input from stdin
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    transcript_path = hook_input.get("transcript_path", "")
    cwd = hook_input.get("cwd", os.getcwd())
    session_id = hook_input.get("session_id", "unknown")

    if not transcript_path or not os.path.exists(transcript_path):
        sys.exit(0)

    # Parse transcript
    messages = extract_messages(transcript_path)
    if not messages:
        sys.exit(0)

    # Build handover document
    handover = build_handover(messages, session_id, cwd)

    # Save to project's .claude directory
    handover_dir = Path(cwd) / ".claude"
    handover_dir.mkdir(parents=True, exist_ok=True)

    handover_file = handover_dir / "handover.md"
    handover_file.write_text(handover)

    # Output a brief message to stdout - this gets injected as context
    print(f"[Handover saved to .claude/handover.md — read it if context was lost during compaction]")


if __name__ == "__main__":
    main()
