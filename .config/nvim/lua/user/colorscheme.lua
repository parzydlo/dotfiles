local p = require("poimandres.palette")

require("poimandres").setup({
	bold_vert_split = true, -- use bold vertical separators
	disable_background = true, -- disable background color
})

-- Overrides run on every ColorScheme event rather than once at startup: a bare
-- :colorscheme call (or sourcing $MYVIMRC) reloads the theme and wipes anything
-- set outside this autocmd. Registered before the colorscheme so it also fires
-- on the initial load.
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("user_colorscheme", { clear = true }),
	pattern = "poimandres",
	callback = function()
		local hl = function(group, opts)
			vim.api.nvim_set_hl(0, group, opts)
		end

		hl("WinSeparator", { fg = "#2F3341" })

		-- poimandres leaves the fuzzy-match groups undefined, so they resolve to
		-- a bare { bold = true } with no fg and the matched characters inside a
		-- candidate look like the token broke in half. Give them the teal accent.
		hl("PmenuMatch", { fg = p.teal1, bold = true })
		hl("PmenuMatchSel", { fg = p.teal1, bold = true })
		hl("ComplMatchIns", { fg = p.blueGray3 })

		-- poimandres predates the treesitter capture renames, so it defines
		-- @property but not @variable.member, which is the name the python
		-- parser actually emits. Attribute access therefore rendered in the
		-- plain text colour until basedpyright's semantic tokens arrived
		-- (@lsp.type.property links to @property, priority 125 over
		-- treesitter's 100) and then flipped to blue. Same colour from both
		-- sources, no flip. @method/@function.method has the same gap; left
		-- alone because it would recolour every method call.
		hl("@variable.member", { link = "@property" })

		-- poimandres sets these to bg = blue2 (#ADD7FF) with no fg: a bright
		-- light-blue block under near-white text. Nothing calls
		-- document_highlight today, so this is pre-emptive.
		hl("LspReferenceText", { bg = p.background1 })
		hl("LspReferenceRead", { bg = p.background1 })
		hl("LspReferenceWrite", { bg = p.background1 })
	end,
})

vim.cmd.colorscheme("poimandres")
