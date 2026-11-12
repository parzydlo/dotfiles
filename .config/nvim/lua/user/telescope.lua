local actions = require("telescope.actions")
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
-- Bound only in find_files and buffers, where an entry ordinal is a path worth
-- putting in the prompt. In live_grep the ordinals are matched LINES, so expanding
-- to one is meaningless; those pickers keep Tab on selection movement. Per-picker
-- mappings win over defaults: telescope turns them into an attach_mappings function
-- that runs first, and the defaults loop skips keys already applied.
--
-- The candidate list is snapshotted on the first Tab because set_prompt re-runs
-- the filter: reading picker.manager again on the next press would cycle within
-- the one entry we had just written into the prompt.
local MAX_CANDIDATES = 500

local function snapshot(picker)
	local out = {}
	for entry in picker.manager:iter() do
		-- the buffers picker ordinals are "2 : src\file.py"; drop the buffer
		-- number so the prompt gets the path alone. A Windows drive letter is not a
		-- digit, so "C:\..." is left intact. Separators go into the prompt as "/",
		-- which the slash-insensitive sorter below matches against "\".
		out[#out + 1] = (entry.ordinal:gsub("^%s*%d+%s*:%s*", ""):gsub("\\", "/"))
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

local expand_mappings = {
	i = {
		["<Tab>"] = expand(1),
		["<S-Tab>"] = expand(-1),
	},
}

require("telescope").setup({
	defaults = {
		-- telescope's default plus --path-separator, so grep results show "/" on
		-- Windows like the prompt does (a no-op elsewhere)
		vimgrep_arguments = {
			"rg", "--color=never", "--no-heading", "--with-filename",
			"--line-number", "--column", "--smart-case", "--path-separator", "/",
		},
		mappings = {
			i = {
				-- actions.which_key shows the mappings for your picker
				["<C-h>"] = "which_key",
				-- pickers without prompt expansion: Tab walks the results, rather
				-- than telescope's default toggle_selection
				["<Tab>"] = actions.move_selection_next,
				["<S-Tab>"] = actions.move_selection_previous,
			},
		},
	},
	pickers = {
		find_files = {
			theme = "dropdown",
			-- the command telescope picks when rg is installed, plus "/" separators
			find_command = { "rg", "--files", "--color", "never", "--path-separator", "/" },
			mappings = expand_mappings,
		},
		buffers = {
			mappings = expand_mappings,
		},
	},
})

-- fzf-native swaps telescope's Lua sorter for fzf's C implementation and adds
-- fzf query syntax: ^prefix, suffix$, 'exact, !invert. Compiled by the
-- PackChanged hook in user/pack.lua; fall back quietly if that did not run.
if not pcall(require("telescope").load_extension, "fzf") then
	vim.notify("telescope-fzf-native not built; using the Lua sorter", vim.log.levels.WARN)
end

-- Windows paths reach telescope with "\" from bufname, v:oldfiles and
-- vim.uri_to_fname (rg is told to print "/" above, but buffers and LSP results
-- do not come from rg), so typing "src/main" matched nothing there. Wrap both
-- sorters so the entry and the prompt are compared with "/" as the only
-- separator. Done after load_extension because fzf-native replaces the sorters
-- there. The prompt keeps "\ ", fzf's escape for a literal space; any other "\"
-- (a pasted Windows path) becomes "/". Display text is untouched; the highlighter
-- gets the same one-byte swap, so match positions still line up.
if vim.fn.has("win32") == 1 then
	local function prompt_slashes(prompt)
		return (prompt:gsub("()\\", function(pos)
			return prompt:sub(pos + 1, pos + 1) == " " and "\\" or "/"
		end))
	end

	local function slash_insensitive(make_sorter)
		return function(opts)
			local sorter = make_sorter(opts)
			local score, highlight = sorter.scoring_function, sorter.highlighter
			sorter.scoring_function = function(self, prompt, line, ...)
				return score(self, prompt_slashes(prompt), (line:gsub("\\", "/")), ...)
			end
			if highlight then
				sorter.highlighter = function(self, prompt, display)
					return highlight(self, prompt_slashes(prompt), (display:gsub("\\", "/")))
				end
			end
			return sorter
		end
	end

	local conf = require("telescope.config").values
	conf.file_sorter = slash_insensitive(conf.file_sorter)
	conf.generic_sorter = slash_insensitive(conf.generic_sorter)
end

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "LSP references" })
