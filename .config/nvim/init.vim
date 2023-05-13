" G E N E R A L
let mapleader=" "
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

" WSL clipboard
set clipboard=unnamed
let g:clipboard = {
            \   'name': 'WslClipboard',
            \   'copy': {
            \      '+': 'clip.exe',
            \      '*': 'clip.exe',
            \    },
            \   'paste': {
            \      '+': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            \      '*': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            \   },
            \   'cache_enabled': 0,
            \ }


" Press Enter to turn off highlighting and clear any message already displayed.
:nnoremap <silent> <Enter> :nohlsearch<Bar>:echo<CR>

" Reload init.vim with <leader>+s
map <leader>s :source ~/.config/nvim/init.vim<CR>

nnoremap  <silent>   <tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bnext<CR>
nnoremap  <silent> <s-tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bprevious<CR>

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
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'jhlgns/naysayer88.vim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'shinchu/lightline-gruvbox.vim'
Plug 'edkolev/tmuxline.vim'
Plug 'scrooloose/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/goyo.vim'
Plug 'mhinz/vim-startify'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'neovim/nvim-lspconfig'
" telescope
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.1' }
" nvim-cmp {
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
" nvim-cmp }
" snippet engine
Plug 'SirVer/ultisnips'
" default snippets
Plug 'honza/vim-snippets', {'rtp': '.'}
Plug 'quangnguyen30192/cmp-nvim-ultisnips', {'rtp': '.'}
call plug#end()
call plug#helptags()
" auto install vim-plug and plugins:
if plug_install
    PlugInstall --sync
endif
unlet plug_install

" treesitter config
lua require('treesitter')

" lspconfig config
lua require('nvim-lspconfig')

" nvim-cmp configs
lua require('nvim-cmp')

" telescope
lua require('telescope-cfg')

let NERDTreeMapActivateNode='l'
let NEDRTreeMapDeactivateNode='h'
let g:NERDTreeDirArrowExpandable = ''
let g:NERDTreeDirArrowCollapsible = ''
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" lightline
function! LightlineFilename()
  let root = fnamemodify(get(b:, 'git_dir'), ':h')
  let path = expand('%:p')
  if path[:len(root)-1] ==# root
    return path[len(root)+1:]
  endif
  return expand('%')
endfunction

let g:lightline = {
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \ },
      \ 'colorscheme' : 'tokyonight',
      \ 'separator': { 'left': '', 'right': '' },
      \ 'subseparator': { 'left': '', 'right': '' }
      \ }

let g:lightline.tabline = {'left': [['buffers']], 'right': [['close']]}
let g:lightline.component_expand = {'buffers': 'lightline#bufferline#buffers'}
let g:lightline.component_type = {'buffers': 'tabsel'}

" Indentation
set nowrap
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
"
" Folding
set foldlevel=9
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()


colorscheme tokyonight-storm
"hi Normal ctermbg=none guibg=none

let g:python3_host_prog = '/home/parzydlo/.pyenv/versions/neovim3/bin/python3'
