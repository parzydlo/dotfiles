require("mason").setup()

-- mason-lspconfig v2's automatic_enable calls vim.lsp.enable() for every
-- INSTALLED mason package, not just the ones in ensure_installed. That is how
-- ruff started attaching without ever appearing in this config. Enable servers
-- explicitly instead, the way the pre-migration config's server loop did.
--
-- Per-server configuration stays modular: lsp/<server>.lua at the config root,
-- merged over nvim-lspconfig's defaults for that server.
require("mason-lspconfig").setup({
	automatic_enable = false,
	ensure_installed = {
		"lua_ls",
		"bashls",
		"dockerls",
		"jsonls",
		"yamlls",
	},
})

-- basedpyright and ruff are uv tools (~/.local/bin), not mason packages.
-- mason's pypi installer resolves "python"/"python3" off PATH and parses
-- `--version`; here exepath("python") hits pyenv-win's EXTENSION-LESS shim,
-- which Windows cannot execute (shell_error -1, empty output), so no candidate
-- ever matches and mason reports "Unable to find python3 installation in PATH".
-- Putting a real python.exe first on PATH would fix it, but uv already manages
-- both servers without one. Reinstall either with
--   uv tool install basedpyright
--   uv tool install ruff
vim.lsp.enable({
	"basedpyright",
	"ruff",
	"lua_ls",
	"bashls",
	"dockerls",
	"jsonls",
	"yamlls",
})

-- border for all floating windows (hover, signature help, diagnostics, ...)
vim.o.winborder = "single"

-- Only the first line of a diagnostic is the message proper; ruff appends a
-- "help: ..." tail and basedpyright wraps long type errors. Rendered inline in
-- full, either one runs off the right edge of the window.
local function inline_message(diagnostic)
	local msg = vim.trim(vim.split(diagnostic.message, "\n", { plain = true })[1])
	local budget = math.max(24, math.floor(vim.api.nvim_win_get_width(0) / 3))
	if vim.fn.strchars(msg) > budget then
		msg = vim.fn.strcharpart(msg, 0, budget - 1) .. "…"
	end
	return msg
end

vim.diagnostic.config({
	virtual_text = {
		spacing = 2,
		prefix = "▎",
		format = inline_message,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "⨯",
			[vim.diagnostic.severity.WARN] = "!",
			[vim.diagnostic.severity.HINT] = "·",
			[vim.diagnostic.severity.INFO] = "ℹ",
		},
	},
	-- re-rendering on every keystroke is what makes highlighting churn while
	-- typing; the sign column and underline still update on InsertLeave
	update_in_insert = false,
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

-- The virtual_text handler renders EVERY diagnostic on a line, concatenated.
-- Show only the most severe one inline -- severity_sort above means the list
-- arrives worst-first, so the first per line is the one to keep. The rest stay
-- reachable through <leader>e, ]d and <leader>q.
local virtual_text = vim.diagnostic.handlers.virtual_text
vim.diagnostic.handlers.virtual_text = {
	show = function(ns, bufnr, diagnostics, opts)
		local seen, worst_per_line = {}, {}
		for _, d in ipairs(diagnostics) do
			if not seen[d.lnum] then
				seen[d.lnum] = true
				worst_per_line[#worst_per_line + 1] = d
			end
		end
		virtual_text.show(ns, bufnr, worst_per_line, opts)
	end,
	hide = virtual_text.hide,
}

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

		-- If highlighting still breaks mid-token while typing, basedpyright's
		-- semantic tokens are the cause (they land on a stale document version
		-- and fight treesitter). Uncomment to fall back to treesitter alone:
		-- local client = vim.lsp.get_client_by_id(ev.data.client_id)
		-- if client and client.name == "basedpyright" then
		--     vim.lsp.semantic_tokens.enable(false, { client_id = client.id, bufnr = ev.buf })
		-- end
	end,
})

-- basedpyright provides no formatter, so this used to be a no-op in Python.
-- ruff formats (capability registered dynamically) and sorts imports through a
-- code action rather than through the formatter, hence the two steps.
vim.api.nvim_create_user_command("Format", function()
	vim.lsp.buf.format({
		async = false,
		timeout_ms = 3000,
		filter = function(client)
			return client.name ~= "basedpyright"
		end,
	})
	if #vim.lsp.get_clients({ bufnr = 0, name = "ruff" }) > 0 then
		vim.lsp.buf.code_action({
			context = { only = { "source.organizeImports.ruff" }, diagnostics = {} },
			apply = true,
		})
	end
end, {})
