require("poimandres").setup({
	bold_vert_split = true, -- use bold vertical separators
	disable_background = true, -- disable background color
})
vim.cmd.colorscheme("poimandres")

vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#2F3341" })
