-- ruff is attached as a formatter and import sorter only. Its lint diagnostics
-- duplicate basedpyright's (an unused import produced both Ruff F401 and
-- reportUnusedImport), and ruff's messages carry a "help: ..." tail that
-- overflows the line when rendered as virtual text.
--
-- Ruff reads its settings from init_options, NOT from settings -- see the
-- docstring in nvim-lspconfig's lsp/ruff.lua.
--
-- The binary comes from `uv tool install ruff` (~/.local/bin/ruff.exe), not from
-- mason: mason's pypi installer cannot find a usable python here (see the note
-- in lua/user/lsp.lua).
return {
	init_options = {
		settings = {
			lint = { enable = false },
		},
	},
}
