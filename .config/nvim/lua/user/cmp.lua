local lspkind = require('lspkind')
local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
	return
end

-- Import UltiSnips mappings for better integration
local ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")

local check_backspace = function()
	local col = vim.fn.col(".") - 1
	return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

--   פּ ﯟ   some other good icons
local kind_icons = {
	Text = "",
	Method = "m",
	Function = "",
	Constructor = "",
	Field = "",
	Variable = "",
	Class = "",
	Interface = "",
	Module = "",
	Property = "",
	Unit = "",
	Value = "",
	Enum = "",
	Keyword = "",
	Snippet = "",
	Color = "",
	File = "",
	Reference = "",
	Folder = "",
	EnumMember = "",
	Constant = "",
	Struct = "",
	Event = "",
	Operator = "",
	TypeParameter = "",
	Copilot = "",
}
-- find more here: https://www.nerdfonts.com/cheat-sheet

cmp.setup({
	snippet = {
		expand = function(args)
			vim.fn["UltiSnips#Anon"](args.body) -- Use UltiSnips for snippet expansion
		end,
	},
	mapping = {
		["<C-k>"] = cmp.mapping.select_prev_item(),
		["<C-j>"] = cmp.mapping.select_next_item(),
		["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
		["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
		["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-y>"] = cmp.config.disable, -- Disable the default `<C-y>` mapping
		["<C-e>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept the selected item
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif require("copilot.suggestion").is_visible() then
				require("copilot.suggestion").accept()
			elseif ultisnips_mappings.expand_or_jumpable() then
				ultisnips_mappings.expand_or_jump()
			elseif check_backspace() then
				fallback()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif ultisnips_mappings.jumpable(-1) then
				ultisnips_mappings.jump_back()
			else
				fallback()
			end
		end, { "i", "s" }),
	},
    formatting = {
        fields = { "kind", "abbr", "menu" }, -- Specify the display order
        format = function(entry, vim_item)
            -- Use lspkind for kind icons
            vim_item = lspkind.cmp_format({
                mode = "symbol", -- Show only symbol annotations
                max_width = 50, -- Truncate popup width
                symbol_map = { Copilot = "" }, -- Custom Copilot symbol
                ellipsis_char = '...', -- Ellipsis for overflow
            })(entry, vim_item)

            -- Custom menu entries
            vim_item.menu = ({
                nvim_lsp = "[LSP]",
                ultisnips = "[UltiSnips]",
                buffer = "[Buffer]",
                path = "[Path]",
                copilot = "[Copilot]",
            })[entry.source.name] or ""

            return vim_item
        end,
    },
	sources = {
		{ name = "copilot" },
		{ name = "nvim_lsp" },
		{ name = "ultisnips" },
		{ name = "buffer" },
		{ name = "path" },
		{ name = "cmdline" },
	},
	confirm_opts = {
		behavior = cmp.ConfirmBehavior.Replace,
		select = false,
	},
    window = {
		documentation = {
			border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
		},
	},
    experimental = {
		ghost_text = false,
		native_menu = false,
	},
})

-- Use buffer and copilot source for `/`
cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' },
        { name = 'copilot' },
    },
})

-- Use cmdline, path, and copilot source for `:`
cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
        { name = 'path' },
        { name = 'copilot' },
    }, {
        { name = 'cmdline' },
    }),
})
