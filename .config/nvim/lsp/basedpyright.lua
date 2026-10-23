return {
	settings = {
		basedpyright = {
			analysis = {
				-- basedpyright defaults to "recommended", which is much noisier
				-- than pyright; "standard" matches the old pyright behaviour
				typeCheckingMode = "standard",
				autoImportCompletions = true,
				diagnosticMode = "openFilesOnly",
				-- The first completion request in a workspace builds the
				-- auto-import index, and it scans every non-excluded file.
				-- The default exclude has no build/ or dist/, so a project with
				-- a bundled Python under dist/ (a whole second stdlib) took
				-- ~4s to answer. 'autocomplete' cancels the in-flight request
				-- on every keystroke, so at typing speed no request ever
				-- finished and the menu never opened. With these excluded the
				-- first answer takes ~0.5s.
				--
				-- The last three entries are basedpyright's defaults. The docs
				-- say user excludes are added on top of them, but on 1.39.9 a
				-- non-empty exclude from the language server REPLACES them:
				-- with only build/dist, .venv got enumerated (2168 source files
				-- vs 34). Listing them is right under either behaviour.
				--
				-- This is a fallback for projects with no config. exclude and
				-- typeCheckingMode are "discouraged" language-server settings:
				-- a pyrightconfig.json, or a [tool.basedpyright]/[tool.pyright]
				-- section in pyproject.toml, makes basedpyright ignore both.
				exclude = {
					"**/build",
					"**/dist",
					"**/node_modules",
					"**/__pycache__",
					"**/.*",
				},
			},
		},
	},
}
