return {
	settings = {
		basedpyright = {
			analysis = {
				-- basedpyright defaults to "recommended", which is much noisier
				-- than pyright; "standard" matches the old pyright behaviour
				typeCheckingMode = "standard",
				autoImportCompletions = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
}
