# Dotfiles, Windows branch

Bare repo at `~\.dotfiles`, work tree `$HOME`, branch `windows`. The mac config
is on `main`; the two branches share no history.

## New machine

Run these in Windows PowerShell (pwsh 7 is not installed yet).

1. Install git:

   ```powershell
   winget install --id Git.Git --exact
   ```

2. Open a new PowerShell window so `git` is on PATH.
3. Clone the bare repo:

   ```powershell
   git clone --bare https://github.com/parzydlo/dotfiles.git $HOME\.dotfiles
   ```

4. Check out the branch into your home folder:

   ```powershell
   git --git-dir=$HOME\.dotfiles --work-tree=$HOME checkout windows
   ```

   If checkout refuses because a file such as `.gitconfig` already exists, move
   that file aside and repeat this step.

5. Preview what the bootstrap script will change:

   ```powershell
   powershell -ExecutionPolicy Bypass -File $HOME\.config\dotfiles\bootstrap.ps1 -WhatIf
   ```

6. If you want telescope-fzf-native and compiled treesitter parsers, add
   `-BuildTools` to the next command (several GB download).
7. Run the bootstrap script:

   ```powershell
   powershell -ExecutionPolicy Bypass -File $HOME\.config\dotfiles\bootstrap.ps1
   ```

   It asks for your git name and email and writes them to `~\.gitconfig.local`,
   which is never committed.

8. If the summary lists warnings (for example Windows Terminal not started yet,
   or Developer Mode off), fix them and run step 7 again. Re-running is safe.
9. Open a new terminal, then start `nvim` once so vim.pack and mason install
   their plugins and servers.

## What the script does

| Step | Result |
|------|--------|
| repo settings | `status.showUntrackedFiles no`, `core.autocrlf false`, full fetch refspec |
| packages | winget: PowerShell 7, Neovim, oh-my-posh, uv, ripgrep, CMake, Node LTS, psmux; Claude Code native installer; `tree-sitter-cli` (npm); `basedpyright` and `ruff` (uv tools) |
| font | BlexMono Nerd Font Mono via `oh-my-posh font install IBMPlexMono` |
| links | `Documents\PowerShell` and `%LOCALAPPDATA%\nvim` junction to `~\.config\...`; Windows Terminal `settings.json` symlinks to `~\.config\windows-terminal\settings.json` |
| Claude venv | `~\.claude\venv` (Python 3.14), which `settings.json` calls for the statusline and the memory hook |
| psmux plugins | copies each `@plugin 'psmux-plugins/...'` named in `.psmux.conf` from github.com/psmux/psmux-plugins |
| git identity | `~\.gitconfig.local`, included from the tracked `.gitconfig` |

The script renames anything that blocks a link to `<name>.bak-<timestamp>`.
It never deletes.

## Not covered

- The Windows Terminal symlink needs Developer Mode or an elevated shell. If IT
  policy blocks both, copy the file by hand. Changes then stop syncing.
- winget's psmux is the upstream build. Local fixes to psmux and its plugins are
  not in this repo.
- The Windows PowerShell 5.1 profile (`Documents\WindowsPowerShell`) is not
  managed.

## Daily use

The `config` function in the pwsh profile wraps git for this repo:
`config status`, `config add <file>`, `config commit`. Untracked files are
hidden, so run `config status --untracked-files=all -- <path>` before
committing a change that adds a file. `~\.gitignore` allowlists `.claude\`:
add a `!` line there before tracking a new file under it.
