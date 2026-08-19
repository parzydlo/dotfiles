#!/usr/bin/env python3
import json
import os
import subprocess
import sys


RESET = '\033[0m'
DIM = '\033[2m'
BAR_WIDTH = 10


def make_bar(pct, width=BAR_WIDTH):
    """Fully dimmed; fill level reads from the glyphs, not colour or weight."""
    on = max(0, min(width, round((pct / 100) * width)))
    return f"{DIM}{'█' * on}{'░' * (width - on)}{RESET}"


def main():
    # Git Bash doesn't inherit PYTHONIOENCODING, so stdout falls back to cp1252
    # and the bar's block chars raise UnicodeEncodeError. Force UTF-8.
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        sys.exit(0)

    cwd = data.get('workspace', {}).get('current_dir', '')
    model = data.get('model', {}).get('display_name', '')
    effort = data.get('effort', {}).get('level', '')
    style = (data.get('output_style', {}) or {}).get('name', '').lower()
    used = (data.get('context_window', {}) or {}).get('used_percentage')

    dir_name = os.path.basename(cwd) if cwd else ''

    branch = ''
    if cwd:
        try:
            result = subprocess.run(
                ['git', '--no-optional-locks', 'rev-parse', '--abbrev-ref', 'HEAD'],
                cwd=cwd, capture_output=True, text=True, timeout=2
            )
            if result.returncode == 0:
                branch = result.stdout.strip()
        except Exception:
            pass

    parts = [dir_name] if dir_name else []
    if branch:
        parts.append(branch)
    if model:
        label = ' · '.join(x for x in (model, effort, style) if x)
        parts.append(f'{DIM}{label}{RESET}')
    if used is not None:
        parts.append(f'{make_bar(used)} {DIM}{round(used)}%{RESET}')

    print('  '.join(parts), end='')


if __name__ == '__main__':
    main()
