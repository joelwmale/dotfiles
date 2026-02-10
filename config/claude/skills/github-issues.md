Skill: github-issues

Purpose:
Fetch and format open GitHub issues for the current repo.

Command:
gh issue list --state open --limit 200 --json number,title,state,body --jq '.[] | "#\(.number) | \(.title) | \(.state) | \((.body // "" | gsub("[\r\n]+";" ") | .[0:200]))"'

Output requirements:
- One issue per line.
- Format exactly: "#<number> | <title> | <state> | <description>"
- Description is the first 200 chars of body with newlines collapsed. If empty, leave empty.
