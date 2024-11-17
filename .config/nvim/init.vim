" G E N E R A L
language en_GB
set hlsearch
set nocompatible
set mouse=a
set number
set hidden
set history=100
set backspace=2
set nuw=5
set t_Co=256
set noshowmode
set laststatus=2
set showtabline=2
set relativenumber
set cursorline

" clipboard
set clipboard+=unnamedplus
" WSL-specific
"set clipboard=unnamed
"let g:clipboard = {
            "\   'name': 'WslClipboard',
            "\   'copy': {
            "\      '+': 'clip.exe',
            "\      '*': 'clip.exe',
            "\    },
            "\   'paste': {
            "\      '+': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            "\      '*': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            "\   },
            "\   'cache_enabled': 0,
            "\ }



" auto install vim-plug and plugins:
let plug_install = 0
let autoload_plug_path = stdpath('config') . '/autoload/plug.vim'
if !filereadable(autoload_plug_path)
    execute '!curl -fL --create-dirs -o ' . autoload_plug_path .
        \ ' https://raw.github.com/junegunn/vim-plug/master/plug.vim'
    execute 'source ' . fnameescape(autoload_plug_path)
    let plug_install = 1
endif
unlet autoload_plug_path
call plug#begin(stdpath('config') . '/plugged')
" plugins here ...
Plug 'nvim-lualine/lualine.nvim'
Plug 'rizzatti/dash.vim'
Plug 'olivercederborg/poimandres.nvim'
Plug 'edkolev/tmuxline.vim'
Plug 'scrooloose/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-obsession'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/goyo.vim'
Plug 'mhinz/vim-startify'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'ibhagwan/fzf-lua'
Plug 'folke/which-key.nvim'
" lspconfig
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'neovim/nvim-lspconfig'
" telescope
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }
" nvim-cmp {
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'onsails/lspkind.nvim'
" snippet engine
Plug 'SirVer/ultisnips'
" default snippets
Plug 'honza/vim-snippets', {'rtp': '.'}
Plug 'quangnguyen30192/cmp-nvim-ultisnips', {'rtp': '.'}
" copilot
Plug 'zbirenbaum/copilot.lua'
Plug 'zbirenbaum/copilot-cmp'
Plug 'CopilotC-Nvim/CopilotChat.nvim', { 'branch': 'canary' }
call plug#end()
call plug#helptags()
" auto install vim-plug and plugins:
if plug_install
    PlugInstall --sync
endif

unlet plug_install

"lua require('user.plugins')
lua require('user.keymaps')
lua require('user.lsp')
lua require('user.lualine')
lua require('user.copilot')
lua require('user.copilot-chat')
lua require('user.treesitter')
lua require('user.cmp')
lua require('user.telescope')

" startify
let g:startify_change_to_dir = 0

" nerdtree
let NERDTreeMapActivateNode='l'
let NEDRTreeMapDeactivateNode='h'
let g:NERDTreeDirArrowExpandable = ''
let g:NERDTreeDirArrowCollapsible = ''


" Indentation
set nowrap
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent


lua << EOF
  require('poimandres').setup {
    bold_vert_split = true, -- use bold vertical separators
  }
EOF
colorscheme poimandres
"hi Normal ctermbg=none guibg=none

let g:python3_host_prog = '$HOME/.pyenv/versions/neovim3/bin/python3'
