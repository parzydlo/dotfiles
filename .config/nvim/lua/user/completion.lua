-- Native LSP completion (replaces nvim-cmp + UltiSnips)
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_completion", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
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
