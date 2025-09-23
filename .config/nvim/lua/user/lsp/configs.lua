require("mason").setup()

local lspconfig = require("lspconfig")
-- Don't require mason-lspconfig at all

local handlers = require("user.lsp.handlers")

local servers = {
    "pyright",
    "lua_ls",
    "dockerls",
    "bashls",
    "jsonls",
    "yamlls",
}

for _, server in pairs(servers) do
    local opts = {
        on_attach = handlers.on_attach,
        capabilities = handlers.capabilities,
    }
    local has_custom_opts, server_custom_opts = pcall(require, "user.lsp.settings." .. server)
    if has_custom_opts then
        opts = vim.tbl_deep_extend("force", opts, server_custom_opts)
    end
    lspconfig[server].setup(opts)
end

handlers.setup()
