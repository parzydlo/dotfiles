#!/usr/bin/env python3
"""PreToolUse hook: inject project MEMORY.md on first tool call of this process context."""
import json
import os
import re
import sys
import tempfile
from pathlib import Path


def session_key():
    """Stable per-session id from the hook payload on stdin.

    PPID is NOT stable on Windows — a new shell is spawned per hook call, so a
    PPID-keyed flag never matches and leaks one temp file per tool call.
    """
    try:
        payload = json.loads(sys.stdin.read() or '{}')
        sid = payload.get('session_id')
        if sid:
            return re.sub(r'[^a-zA-Z0-9]', '', str(sid))[:40]
    except Exception:
        pass
    return f"ppid-{os.getppid()}"


def main():
    flag_path = Path(tempfile.gettempdir()) / f"claude-memory-loaded-{session_key()}"

    # Already loaded for this process — exit silently (no output = no context injection)
    if flag_path.exists():
        sys.exit(0)

    # Mark as loaded for this process
    flag_path.touch()

    project_dir = os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())

    # Map project dir to .claude/projects key.
    # Claude Code sanitises the CWD by replacing every non-alphanumeric character with '-'.
    # e.g. C:\Users\me\workspace\my_project -> C--Users-me-workspace-my-project
    mapped = re.sub(r'[^a-zA-Z0-9]', '-', project_dir)

    home = Path.home()
    memory_file = home / '.claude' / 'projects' / mapped / 'memory' / 'MEMORY.md'
    global_idx = home / '.claude' / 'memory' / 'memory.md'

    parts = []

    if memory_file.exists():
        lines = memory_file.read_text(encoding='utf-8').splitlines()[:200]
        parts.append(f"=== Project Memory: {project_dir} ===\n" + '\n'.join(lines))
    else:
        parts.append(f"(no project MEMORY.md at {memory_file})")

    if global_idx.exists():
        parts.append("=== Global Memory Index ===\n" + global_idx.read_text(encoding='utf-8'))

    context = '\n\n'.join(parts)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": context
        }
    }

    print(json.dumps(output))
    sys.exit(0)


if __name__ == "__main__":
    main()
