local action_state = require("telescope.actions.state")

-- Shell-style completion for the prompt, which telescope has no builtin for:
-- actions.complete_tag (<C-l>) only offers kind prefilters like ":function:" in
-- the symbol, treesitter and diagnostic pickers.
--
-- Tab expands the prompt to the longest prefix every current match shares. Once
-- there is nothing further in common it cycles through the matches themselves;
-- S-Tab cycles backwards. Selection movement stays on telescope's own <C-n>/<C-p>
-- and <Down>/<Up>.
--
-- The candidate list is snapshotted on the first Tab because set_prompt re-runs
-- the filter: reading picker.manager again on the next press would cycle within
-- the one entry we had just written into the prompt.
local MAX_CANDIDATES = 500

local function snapshot(picker)
	local out = {}
	for entry in picker.manager:iter() do
		out[#out + 1] = entry.ordinal
		if #out >= MAX_CANDIDATES then
			break
		end
	end
	return out
end

local function common_prefix(candidates)
	local prefix = candidates[1] or ""
	for i = 2, #candidates do
		local candidate, n = candidates[i], 0
		while n < #prefix and n < #candidate and prefix:byte(n + 1) == candidate:byte(n + 1) do
			n = n + 1
		end
		prefix = prefix:sub(1, n)
		if prefix == "" then
			break
		end
	end
	return prefix
end

local function expand(step)
	return function(prompt_bufnr)
		local picker = action_state.get_current_picker(prompt_bufnr)
		if not picker then
			return
		end
		local prompt = picker:_get_prompt()

		-- a prompt we did not write ourselves means the user typed since the
		-- last press, so start a fresh expansion
		if picker._expand_prompt ~= prompt then
			picker._expand_candidates = snapshot(picker)
			picker._expand_index = nil
			local prefix = common_prefix(picker._expand_candidates)
			if #prefix > #prompt then
				picker._expand_prompt = prefix
				picker:set_prompt(prefix)
				return
			end
		end

		local candidates = picker._expand_candidates or {}
		if #candidates == 0 then
			return
		end
		local index = (picker._expand_index or (step > 0 and 0 or 1)) + step
		if index > #candidates then
			index = 1
		elseif index < 1 then
			index = #candidates
		end
		picker._expand_index = index
		picker._expand_prompt = candidates[index]
		picker:set_prompt(candidates[index])
	end
end

require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				-- actions.which_key shows the mappings for your picker
				["<C-h>"] = "which_key",
				["<Tab>"] = expand(1),
				["<S-Tab>"] = expand(-1),
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
