local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Mouse scroll
local scroll_factor = "2"
for _, mode in ipairs({ "n", "i", "v" }) do
	keymap(mode, "<ScrollWheelUp>", scroll_factor .. "<C-y>", opts)
	keymap(mode, "<ScrollWheelDown>", scroll_factor .. "<C-e>", opts)
end

-- NORMAL --
-- Reload config
keymap("n", "<leader>s", "<cmd>source $MYVIMRC<CR>", opts)

-- Toggle search highlighting
keymap("n", "<leader>h", "<cmd>set hlsearch!<CR>", opts)

-- Turn off highlighting and clear displayed message
keymap("n", "<CR>", "<cmd>nohlsearch<Bar>echo<CR>", opts)

-- Cycle through buffers, writing the current one first if modified
local function write_if_modified()
	if vim.bo.modifiable and not vim.bo.readonly and vim.bo.modified then
		vim.cmd.write()
	end
end
keymap("n", "<Tab>", function()
	write_if_modified()
	vim.cmd.bnext()
end, opts)
keymap("n", "<S-Tab>", function()
	write_if_modified()
	vim.cmd.bprevious()
end, opts)

-- Close all buffers but the currently focused one
keymap("n", "<leader>bf", "<cmd>%bd<Bar>e#<Bar>bd#<CR>", opts)

-- Vertical scrolling recenters
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)

-- Move text up and down
keymap("n", "<A-j>", ":m .+1<CR>==", opts)
keymap("n", "<A-k>", ":m .-2<CR>==", opts)

-- Add all missing imports (basedpyright)
keymap("n", "<leader>im", function()
	vim.lsp.buf.code_action({
		apply = true,
		context = {
			only = { "source.addMissingImports", "quickfix" },
		},
	})
end, { desc = "LSP(pyright): Add all missing imports" })

-- Auto-import symbol under cursor using completion hack
keymap("n", "<leader>ii", function()
	local symbol = vim.fn.expand("<cword>")
	local _, col = unpack(vim.api.nvim_win_get_cursor(0))

	-- Start insert mode at the cursor position
	vim.api.nvim_feedkeys("a", "n", false)
	vim.defer_fn(function()
		-- Trigger completion
		vim.fn.complete(col + 1, { symbol })
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-y>", true, false, true), "n", false)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
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
