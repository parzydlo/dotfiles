-- nvim-treesitter `main` branch: no setup{}, parsers installed explicitly and
-- highlighting started per buffer. lua/vim/vimdoc/markdown/c/query parsers ship
-- with neovim itself. Installing extra parsers needs the tree-sitter CLI and a
-- C compiler on PATH.
local ts = require("nvim-treesitter")

if vim.fn.executable("tree-sitter") == 1 then
	ts.install({
		"python",
		"json",
		"yaml",
		"bash",
		"toml",
		"dockerfile",
	})
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
	callback = function(ev)
		-- no-op for filetypes without an installed parser
		pcall(vim.treesitter.start, ev.buf)
	end,
})

-- folds from treesitter, disabled by default (as before)
vim.opt.foldenable = false
vim.opt.foldlevel = 9
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- note: treesitter indent stays off — it used to mess up python indentation
