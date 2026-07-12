require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				-- actions.which_key shows the mappings for your picker
				["<C-h>"] = "which_key",
			},
		},
	},
	pickers = {
		find_files = {
			theme = "dropdown",
		},
	},
})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "LSP references" })
