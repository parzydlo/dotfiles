local cmp = require('cmp')
local ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")
cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
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
        ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'ultisnips' }, -- For ultisnips users.
        { name = 'nvim_lsp_signature_help' },
    }, {
            { name = 'path' },
            { name = 'buffer', keyword_length = 2,
                option = {
                    -- include all buffers
                    get_bufnrs = function()
                        return vim.api.nvim_list_bufs()
                    end
                    -- include all buffers, avoid indexing big files
                    -- get_bufnrs = function()
                    -- local buf = vim.api.nvim_get_current_buf()
                    -- local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
                    -- if byte_size > 1024 * 1024 then -- 1 Megabyte max
                    -- return {}
                    -- end
                    -- return { buf }
                    -- end
                }},  -- end of buffer
        }),
    completion = {
        keyword_length = 2,
        completeopt = "menu,noselect"
    },
})
-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' },
    },
})
-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
            { name = 'cmdline' },
        }),
})
