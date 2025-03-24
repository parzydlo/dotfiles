local lspkind = require('lspkind')
local cmp_status_ok, cmp = pcall(require, "cmp")
local copilot_status_ok, copilot = pcall(require, "copilot.suggestion")

if not cmp_status_ok then
	return
end

local function check_backspace()
    local col = vim.fn.col(".") - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

local function should_undo_copilot()
    if not vim.b.copilot_last_inserted then
        vim.notify("Copilot undo check: No insertion flag set", vim.log.levels.INFO)
        return false
    end

    -- Get the current cursor position AFTER insertion
    local pos = vim.fn.getcurpos()
    local cur_line = pos[2]
    local cur_col = pos[3]

    -- Debugging output
    vim.notify(string.format("Checking should_undo_copilot()\n"
        .. "copilot_last_inserted: %s\n"
        .. "Current position: %d, %d\n"
        .. "Stored position: %s, %s\n",
        vim.inspect(vim.b.copilot_last_inserted), cur_line, cur_col,
        vim.inspect(vim.b.copilot_last_line), vim.inspect(vim.b.copilot_last_col)
    ), vim.log.levels.INFO)

    -- Check if the cursor is still at the end of the Copilot insertion
    local res = (vim.b.copilot_last_line == cur_line and vim.b.copilot_last_col == cur_col)

    vim.notify("Undo condition result: " .. tostring(res), vim.log.levels.INFO)

    return res
end

local function handle_tab(fallback)
    if cmp.visible() then
        cmp.select_next_item()
    elseif copilot_status_ok and copilot.is_visible() then
        copilot.accept()
        vim.b.copilot_last_inserted = true

        -- Register a one-time autocmd to capture the cursor position after Copilot modifies the buffer
        vim.api.nvim_create_autocmd("TextChangedI", {
            buffer = 0,
            once = true,  -- Run only once after the next change
            callback = function()
                local pos = vim.fn.getcurpos()  -- Get final cursor position after Copilot insertion
                vim.b.copilot_last_line = pos[2]  -- Line number
                vim.b.copilot_last_col = pos[3]   -- Column number
                vim.notify(string.format("Stored Copilot position AFTER buffer change: %d, %d", pos[2], pos[3]), vim.log.levels.INFO)
            end
        })
    elseif vim.fn["UltiSnips#CanExpandSnippet"]() == 1 then
        vim.fn["UltiSnips#ExpandSnippet"]()
    elseif vim.fn["UltiSnips#CanJumpForwards"]() == 1 then
        vim.fn["UltiSnips#JumpForwards"]()
    else
        fallback()
    end
end

local function handle_shift_tab(fallback)
    local has_ultisnips = vim.fn.exists("*UltiSnips#CanJumpBackwards") == 1

    if should_undo_copilot() then
        print("Undoing Copilot suggestion")  -- Debugging log
        vim.cmd("silent! undo")  -- Ensure undo executes without errors
        vim.b.copilot_last_inserted = nil  -- Reset flags
        vim.b.copilot_last_line = nil
        vim.b.copilot_last_col = nil
    elseif cmp.visible() then
        cmp.select_prev_item()
    elseif copilot_status_ok and copilot.is_visible() then
        copilot.dismiss()
    elseif has_ultisnips and vim.fn["UltiSnips#CanJumpBackwards"]() == 1 then
        vim.fn["UltiSnips#JumpBackwards"]()
    else
        fallback()
    end
end


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
        ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
                cmp.confirm({ select = false })
            else
                fallback() -- Insert a newline if no completion is selected
            end
        end, { "i", "s" }),
		["<Tab>"] = cmp.mapping(handle_tab, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(handle_shift_tab, { "i", "s" }),
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
		--{ name = "cmdline" },
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

-- Automatically reset Copilot undo flag when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        vim.b.copilot_last_inserted = nil
        vim.b.copilot_last_line = nil
        vim.b.copilot_last_col = nil
    end,
})
