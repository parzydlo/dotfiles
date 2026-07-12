-- G E N E R A L
pcall(vim.cmd.language, "en_GB") -- locale name differs per OS; skip quietly if unavailable

local opt = vim.opt

opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.numberwidth = 5
opt.cursorline = true
opt.scrolloff = 3
opt.showmode = false
opt.laststatus = 3 -- single global statusline (lualine globalstatus)
opt.showtabline = 2

-- clipboard
opt.clipboard:append("unnamedplus")

-- Indentation
opt.wrap = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Providers: nothing needs the python host any more (molten was cut).
-- If a remote plugin ever needs it again, create the venv with uv:
--   uv venv ~/.venvs/neovim && uv pip install --python ~/.venvs/neovim pynvim
--   vim.g.python3_host_prog = vim.fs.normalize("~/.venvs/neovim/Scripts/python.exe")
--   (on mac/linux: ~/.venvs/neovim/bin/python)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
