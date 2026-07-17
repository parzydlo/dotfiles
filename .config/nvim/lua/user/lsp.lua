require("mason").setup()

-- mason-lspconfig v2: installs the servers and (automatic_enable, the default)
-- calls vim.lsp.enable() for each. Per-server configuration is modular: it
-- lives in lsp/<server>.lua at the config root, merged over nvim-lspconfig's
-- defaults for that server.
require("mason-lspconfig").setup({
	ensure_installed = {
		"basedpyright",
		"lua_ls",
		"bashls",
		"dockerls",
		"jsonls",
		"yamlls",
	},
})

-- border for all floating windows (hover, signature help, diagnostics, ...)
vim.o.winborder = "single"

vim.diagnostic.config({
	virtual_text = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "⨯",
			[vim.diagnostic.severity.WARN] = "!",
			[vim.diagnostic.severity.HINT] = "·",
			[vim.diagnostic.severity.INFO] = "ℹ",
		},
	},
	update_in_insert = true,
	underline = true,
	severity_sort = true,
	float = {
		focusable = false,
		style = "minimal",
		source = true,
		header = "",
		prefix = "",
	},
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
	callback = function(ev)
		local opts = { buffer = ev.buf, silent = true }
		local map = vim.keymap.set
		map("n", "gD", vim.lsp.buf.declaration, opts)
		map("n", "gd", vim.lsp.buf.definition, opts)
		map("n", "K", function()
			vim.lsp.buf.hover({ max_width = 60 })
		end, opts)
		map("n", "gi", vim.lsp.buf.implementation, opts)
		-- references: builtin grr (quickfix) or <leader>fr (telescope);
		-- no gr map so builtin grn/gra aren't delayed by ambiguity
		map("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		map("n", "<leader>rn", vim.lsp.buf.rename, opts)
		map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		map("n", "<leader>e", vim.diagnostic.open_float, opts)
		map("n", "[d", function()
			vim.diagnostic.jump({ count = -1 })
		end, opts)
		map("n", "]d", function()
			vim.diagnostic.jump({ count = 1 })
		end, opts)
		map("n", "<leader>q", vim.diagnostic.setloclist, opts)
	end,
})

vim.api.nvim_create_user_command("Format", function()
	vim.lsp.buf.format({ async = true })
end, {})
