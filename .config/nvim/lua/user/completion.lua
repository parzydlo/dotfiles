-- Neovim 0.12 ships a full autocompletion engine, so nvim-cmp is not needed:
--   'autocomplete'  opens the popup as you type, on every keypress
--   'complete'      lists the sources; "o" is the omnifunc, which vim.lsp
--                   points at v:lua.vim.lsp.omnifunc when a client attaches
--   'completeopt'   "fuzzy" gives subsequence matching, "popup" the doc window
-- Together those are nvim-cmp's nvim_lsp + buffer sources without the plugin.
--
-- Why this replaced vim.lsp.completion's autotrigger: that only fired on the
-- server's triggerCharacters ("." and "("), so mid-identifier there was no
-- popup and <Tab> fell through to inserting spaces. 'autocomplete' is what
-- makes <Tab> mean the same thing on every keystroke.
vim.o.autocomplete = true
vim.o.autocompletedelay = 50 -- raise this if it feels eager while typing fast
vim.o.complete = ".^5,w^5,b^5,u^5" -- fallback for buffers with no LSP client
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }

-- lspkind's default preset, copied byte for byte from lspkind.nvim rather than
-- retyped: these are Nerd Font private-use glyphs and do not survive being
-- read back out of tool output.
local kind_icons = {
	Text = "󰉿",
	Method = "󰆧",
	Function = "󰊕",
	Constructor = "",
	Field = "󰜢",
	Variable = "󰀫",
	Class = "󰠱",
	Interface = "",
	Module = "",
	Property = "󰜢",
	Unit = "󰑭",
	Value = "󰎠",
	Enum = "",
	Keyword = "󰌋",
	Snippet = "",
	Color = "󰏘",
	File = "󰈙",
	Reference = "󰈇",
	Folder = "󰉋",
	EnumMember = "",
	Constant = "󰏿",
	Struct = "󰙅",
	Event = "",
	Operator = "󰆕",
	TypeParameter = "",
}

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_completion", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			-- LSP only for this buffer. The buffer word sources return the same
			-- identifiers the server already knows, and nothing dedupes across
			-- sources the way nvim-cmp did, so every local symbol showed twice.
			-- Buffers with no server keep the global 'complete' set below.
			vim.bo[ev.buf].complete = "o"
			vim.lsp.completion.enable(true, client.id, ev.buf, {
				-- 'autocomplete' drives the trigger now. enable() is still
				-- required for the <C-y> side effects -- snippet expansion,
				-- auto-import additionalTextEdits, the resolve popup -- and
				-- those apply to omnifunc-driven items too.
				autotrigger = false,
				convert = function(item)
					local kind = item.kind and vim.lsp.protocol.CompletionItemKind[item.kind]
					return {
						kind = kind_icons[kind] or "",
						menu = "[LSP]",
					}
				end,
			})
		end
	end,
})

-- 'autocomplete' is global, so it also fires in prompt buffers -- typing a
-- telescope query popped up a keyword-completion menu over the picker. Prompt
-- buffers are for queries, not for editing text, so turn it off there. Keyed on
-- buftype rather than the TelescopePrompt filetype so any prompt-based UI is
-- covered. <Tab> keeps working: telescope binds it in the picker itself.
--
-- InsertEnter, not BufEnter: telescope sets buftype AFTER the buffer is entered,
-- so a BufEnter check still sees an empty buftype and does nothing.
vim.api.nvim_create_autocmd("InsertEnter", {
	group = vim.api.nvim_create_augroup("user_prompt_no_autocomplete", { clear = true }),
	callback = function(ev)
		if vim.bo[ev.buf].buftype == "prompt" then
			vim.bo[ev.buf].autocomplete = false
		end
	end,
})

local keymap = vim.keymap.set
local expr = { expr = true, silent = true }

-- Tab / S-Tab: cycle the popup menu, or jump between snippet stops (old cmp behaviour)
keymap("i", "<Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-n>"
	elseif vim.snippet.active({ direction = 1 }) then
		return "<Cmd>lua vim.snippet.jump(1)<CR>"
	end
	return "<Tab>"
end, expr)

keymap("i", "<S-Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-p>"
	elseif vim.snippet.active({ direction = -1 }) then
		return "<Cmd>lua vim.snippet.jump(-1)<CR>"
	end
	return "<S-Tab>"
end, expr)

-- C-j / C-k also cycle the menu
keymap("i", "<C-j>", function()
	return vim.fn.pumvisible() == 1 and "<C-n>" or "<C-j>"
end, expr)
keymap("i", "<C-k>", function()
	return vim.fn.pumvisible() == 1 and "<C-p>" or "<C-k>"
end, expr)

-- CR confirms only when an entry is actually selected
keymap("i", "<CR>", function()
	if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected >= 0 then
		return "<C-y>"
	end
	return "<CR>"
end, expr)

-- manually trigger LSP completion
keymap("i", "<C-Space>", function()
	vim.lsp.completion.get()
end, { silent = true })

-- Command-line autocompletion, replacing cmp-cmdline. Straight out of
-- :h cmdline-autocompletion -- 'wildoptions' already defaults to pum,tagfile.
vim.o.wildmode = "noselect:lastused,full"

vim.api.nvim_create_autocmd("CmdlineChanged", {
	group = vim.api.nvim_create_augroup("user_cmdline_completion", { clear = true }),
	pattern = { ":", "/", "?" },
	callback = function()
		vim.fn.wildtrigger()
	end,
})

-- keep <Up>/<Down> walking history rather than moving through the menu
keymap("c", "<Up>", function()
	return vim.fn.wildmenumode() == 1 and "<C-E><Up>" or "<Up>"
end, expr)
keymap("c", "<Down>", function()
	return vim.fn.wildmenumode() == 1 and "<C-E><Down>" or "<Down>"
end, expr)
