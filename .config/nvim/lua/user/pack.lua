-- Native plugin manager (nvim 0.12) — replaces vim-plug.
-- Update installed plugins with :lua vim.pack.update()

-- vim.pack has no inline equivalent of vim-plug's { 'do': 'make' }; build steps
-- run from a PackChanged autocmd, and it must be registered BEFORE vim.pack.add
-- so that it also fires on the very first install.
--
-- telescope-fzf-native is a single C file compiled to build/libfzf.dll. Its
-- Makefile hardcodes CC = gcc on Windows, so take the CMake path instead: the
-- CMakeLists is MSVC-aware and cmake locates cl.exe through vswhere with no
-- vcvars setup. The install target matters -- CMakeLists installs to
-- CMAKE_BINARY_DIR, which is where the plugin's ffi.load looks; a plain
-- --build leaves the dll in build/Release/ where it will not be found.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("user_pack_build", { clear = true }),
	callback = function(ev)
		if ev.data.spec.name ~= "telescope-fzf-native.nvim" then
			return
		end
		if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
			return
		end
		if vim.fn.executable("cmake") ~= 1 then
			vim.notify("telescope-fzf-native: cmake not found, keeping the Lua sorter", vim.log.levels.WARN)
			return
		end

		vim.notify("telescope-fzf-native: building libfzf...", vim.log.levels.INFO)
		local steps = {
			{ "cmake", "-S.", "-Bbuild", "-DCMAKE_BUILD_TYPE=Release" },
			{ "cmake", "--build", "build", "--config", "Release", "--target", "install" },
		}
		for _, cmd in ipairs(steps) do
			-- synchronous: user.telescope loads the extension later in init.lua
			local res = vim.system(cmd, { cwd = ev.data.path, text = true }):wait()
			if res.code ~= 0 then
				vim.notify(
					("telescope-fzf-native build failed (%s)\n%s"):format(
						table.concat(cmd, " "),
						(res.stderr or "") .. (res.stdout or "")
					),
					vim.log.levels.ERROR
				)
				return
			end
		end
		vim.notify("telescope-fzf-native: built", vim.log.levels.INFO)
	end,
})

vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/olivercederborg/poimandres.nvim",
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-obsession",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/neovim/nvim-lspconfig",
})
