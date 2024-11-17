local lspkind = require('lspkind')
local cmp = require('cmp')
local ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")
cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
    },
    mapping = {
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                ultisnips_mappings.expand_or_jump_forwards(fallback)
            end
        end),
        ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                ultisnips_mappings.expand_or_jump_backwards(fallback)
            end
        end,
        ["<C-j>"] = cmp.mapping(function(fallback)
            ultisnips_mappings.expand_or_jump_forwards(fallback)
        end),
        ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-g>'] = cmp.mapping({i = cmp.mapping.abort(), c = cmp.mapping.close()}),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
    },
    sources = cmp.config.sources({
        { name = 'copilot' },         -- Add copilot as the first source
        { name = 'nvim_lsp' },
        { name = 'ultisnips' },       -- For ultisnips users.
        { name = 'nvim_lsp_signature_help' },
    }, {
        { name = 'path' },
        { name = 'buffer', keyword_length = 2,
            option = {
                get_bufnrs = function()
                    return vim.api.nvim_list_bufs()
                end
            }},
    }),
    completion = {
        keyword_length = 2,
        completeopt = "menu,noselect"
    },
    formatting = {
        format = lspkind.cmp_format({
            mode = "symbol",
            max_width = 50,
            symbol_map = { Copilot = "" },
            ellipsis_char = '...', -- when popup is wider than maxwidth
        })
    }
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
