local M = {}

M.setup = function()
	local config = {
		-- disable virtual text
		virtual_text = true,
		-- show signs - updated api use
		signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = "⨯",
                [vim.diagnostic.severity.WARN]  = "!",
                [vim.diagnostic.severity.HINT]  = "·",
                [vim.diagnostic.severity.INFO]  = "ℹ",
            },
        },
		update_in_insert = true,
		underline = true,
		severity_sort = true,
		float = {
			focusable = false,
			style = "minimal",
			border = "single",
			source = "always",
			header = "",
			prefix = "",
		},
	}

	vim.diagnostic.config(config)

	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		border = "single",
		width = 60,
	})

	vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
		border = "single",
		width = 60,
	})
end

local function lsp_highlight_document(client)
    if client.server_capabilities.documentHighlightProvider then
        local group = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
        --vim.api.nvim_create_autocmd("CursorHold", {
            --group = group,
            --buffer = 0,
            --callback = vim.lsp.buf.document_highlight,
        --})
        vim.api.nvim_create_autocmd({"CursorMoved", "InsertEnter"}, {
            group = group,
            buffer = 0,
            callback = vim.lsp.buf.clear_references,
        })
    end
end

local function lsp_keymaps(bufnr)
	local opts = { noremap = true, silent = true }
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    --vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover(); vim.lsp.buf.document_highlight()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
     vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
	vim.cmd([[ command! Format execute 'lua vim.lsp.buf.format{async=true}' ]])
end

M.on_attach = function(client, bufnr)
	-- vim.notify(client.name .. " starting...")
	-- TODO: refactor this into a method that checks if string in list
	if client.name == "tsserver" then
		client.server_capabilities.documentFormattingProvider = false
	end
	lsp_keymaps(bufnr)
    lsp_highlight_document(client)
end

local capabilities = vim.tbl_deep_extend(
	"force",
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)

M.capabilities = capabilities

return M
