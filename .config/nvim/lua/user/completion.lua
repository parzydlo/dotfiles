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
-- No "fuzzy": it is flat subsequence matching with no preference for prefix
-- hits, so in a Python buffer "str" matched SOCK_STREAM, SIGTRAP, STARTUPINFO
-- and 143 other stdlib symbols. Dropping it takes that list to 29, all of which
-- actually start with "str". nvim-cmp did allow fuzzy matching, but it set
-- disallow_partial_fuzzy_matching and sorted with compare.exact/compare.offset,
-- so prefix hits dominated; the builtin flag has no such gradation.
vim.opt.completeopt = { "menuone", "noselect", "popup" }

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

-- Gating the automatic trigger.
--
-- The builtin engine fires on any text change, whatever produced it, and the
-- menu it opens with an empty base is 203 items: every stdlib symbol
-- basedpyright knows, in alphabetical order. So indenting an empty line, or
-- just opening one with o, popped a full-screen menu. nvim-cmp never did that
-- (its keyword_pattern needs a word character) and 'autocomplete' has no
-- equivalent knob, so the rule is applied by hand here: the menu is allowed
-- only when the cursor sits right after a non-blank character.
--
-- Every hook below runs BEFORE the change it judges. That is deliberate --
-- clearing 'autocomplete' from TextChangedI is too late, the trigger has
-- already been scheduled by then, and it does not close a menu that is up.
local function gate_autocomplete(buf, on)
	-- Prompt buffers stay off unconditionally, see the InsertEnter rule below.
	if vim.bo[buf].buftype ~= "prompt" then
		vim.bo[buf].autocomplete = on
	end
end

local function blank_before_cursor()
	return vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1):match("^%s*$") ~= nil
end

-- Typed characters: whitespace never opens the menu, the next word character
-- turns it back on.
vim.api.nvim_create_autocmd("InsertCharPre", {
	group = vim.api.nvim_create_augroup("user_autocomplete_gate", { clear = true }),
	callback = function(ev)
		gate_autocomplete(ev.buf, vim.v.char:match("^%s$") == nil)
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
--
-- For ordinary buffers this is the entry point that covers o, O, cc and S: they
-- leave the cursor after nothing but indent.
vim.api.nvim_create_autocmd("InsertEnter", {
	group = vim.api.nvim_create_augroup("user_prompt_no_autocomplete", { clear = true }),
	callback = function(ev)
		if vim.bo[ev.buf].buftype == "prompt" then
			vim.bo[ev.buf].autocomplete = false
		else
			gate_autocomplete(ev.buf, not blank_before_cursor())
		end
	end,
})

local keymap = vim.keymap.set
local expr = { expr = true, silent = true }

-- Keys that edit without going through InsertCharPre. <CR>, <C-u> and <C-w>
-- always leave the cursor after a line start, indent or word boundary; <C-t>
-- and <C-d> only matter on a line that is still blank. <BS> has to look at
-- what the deletion will leave behind.
local function gate_and(keys)
	return function()
		gate_autocomplete(vim.api.nvim_get_current_buf(), false)
		return keys
	end
end

keymap("i", "<C-u>", gate_and("<C-u>"), expr)
keymap("i", "<C-w>", gate_and("<C-w>"), expr)

for _, key in ipairs({ "<C-t>", "<C-d>" }) do
	keymap("i", key, function()
		if blank_before_cursor() then
			gate_autocomplete(vim.api.nvim_get_current_buf(), false)
		end
		return key
	end, expr)
end

-- Clearing 'autocomplete' does not close a menu that is already up, so dismiss
-- it with <C-e> in the same keystroke when the deletion lands back on blanks.
keymap("i", "<BS>", function()
	local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1)
	local left = vim.fn.strcharpart(before, 0, math.max(0, vim.fn.strchars(before) - 1))
	local last = left:sub(-1)
	local blank = last == "" or last:match("^%s$") ~= nil
	gate_autocomplete(vim.api.nvim_get_current_buf(), not blank)
	if blank and vim.fn.pumvisible() == 1 then
		return "<C-e><BS>"
	end
	return "<BS>"
end, expr)

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
	-- a fresh line starts on indent, which must not open the menu
	gate_autocomplete(vim.api.nvim_get_current_buf(), false)
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
