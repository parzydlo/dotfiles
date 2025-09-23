-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Mouse scroll
local scroll_factor = "2"
keymap('n', '<ScrollWheelUp>', scroll_factor .. '<C-y>', opts)
keymap('n', '<ScrollWheelDown>', scroll_factor .. '<C-e>', opts)
keymap('i', '<ScrollWheelUp>', scroll_factor .. '<C-y>', opts)
keymap('i', '<ScrollWheelDown>', scroll_factor .. '<C-e>', opts)
keymap('v', '<ScrollWheelUp>', scroll_factor .. '<C-y>', opts)
keymap('v', '<ScrollWheelDown>', scroll_factor .. '<C-e>', opts)

-- NORMAL --
-- Reload init.vim
keymap("n", "<leader>s", ":source ~/.config/nvim/init.vim<CR>", opts)

-- NERDTree actions
--keymap("n", "<leader>", ":NERDTreeFocus<CR>", opts)
keymap("n", "<C-n>", ":NERDTree<CR>", opts)
keymap("n", "<C-t>", ":NERDTreeToggle<CR>", opts)
keymap("n", "<C-f>", ":NERDTreeFind<CR>", opts)

-- Toggle search highlighting
keymap("n", "<leader>h", ":set hlsearch!<CR>", opts)

-- Turn off highlighting and clear displayed messagge
keymap("n", "<Enter>", ":nohlsearch<Bar>:echo<CR>", opts)

-- Cycle through buffers
keymap("n", "<tab>", ":if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bnext<CR>", opts)
keymap("n", "<s-tab>", ":if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bprevious<CR>", opts)

-- Close all buffers but the currently focused one
keymap("n", "<leader>bf", ":%bd\\|e#\\|bd#<CR>", opts)

-- Vertical Scrolling --
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)

-- Move text up and down
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)

-- Add all missing imports (if Pyright supports it)
vim.keymap.set("n", "<leader>im", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = { "source.addMissingImports", "quickfix" },
    },
  })
end, { desc = "LSP(pyright): Add all missing imports" })

-- Auto-import symbol under cursor using completion hack
vim.keymap.set("n", "<leader>ii", function()
  local symbol = vim.fn.expand("<cword>")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Start insert mode at the cursor position
  vim.api.nvim_feedkeys("a", "n", false)
  vim.defer_fn(function()
    -- Trigger completion
    vim.fn.complete(col + 1, { symbol })
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-y>", true, false, true),
      "n",
      false
    )
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
      "n",
      false
    )
  end, 50)
end, { desc = "LSP(pyright): Auto-import symbol under cursor" })

-- VISUAL --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "p", '"_dP', opts)


-- VISUAL BLOCK --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)
