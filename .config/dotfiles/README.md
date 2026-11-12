# Dotfiles (Windows)

A bare repo at `~\.dotfiles` with `$HOME` as its work tree.

## Setup

In Windows PowerShell:

```powershell
winget install --id Git.Git --exact
# open a new shell
git clone --bare https://github.com/parzydlo/dotfiles.git $HOME\.dotfiles
git --git-dir=$HOME\.dotfiles --work-tree=$HOME checkout windows
powershell -ExecutionPolicy Bypass -File $HOME\.config\dotfiles\bootstrap.ps1
```

If checkout stops on an existing file, move that file aside and run checkout again.
Pass `-BuildTools` to the script to install a C++ compiler as well.

`bootstrap.ps1` installs the tools, links config folders into place and asks
for your git name and email, which it writes to `~\.gitconfig.local`. To
change what it installs or links, edit the lists at the top of the script.

## Use

`config` in the PowerShell profile is git for this repo: `config status`,
`config add <file>`, `config commit`. Untracked files are hidden, so use
`config status -uall -- <path>` to check for new files before committing.
