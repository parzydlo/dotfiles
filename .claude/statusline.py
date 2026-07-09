#!/usr/bin/env python3
import json
import os
import subprocess
import sys


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    cwd = data.get('workspace', {}).get('current_dir', '')
    model = data.get('model', {}).get('display_name', '')
    used = data.get('context_window', {}).get('used_percentage')

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

    parts = [dir_name]
    if branch:
        parts.append(branch)
    if model:
        parts.append(model)
    if used is not None:
        parts.append(f'ctx:{round(used)}%')

    print('  '.join(parts), end='')


if __name__ == '__main__':
    main()
