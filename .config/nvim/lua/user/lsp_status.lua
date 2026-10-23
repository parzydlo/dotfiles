-- Tabline component: one glyph + name per LSP client attached to the current
-- buffer.
--
--   ○ starting  attached, but the server has not answered `initialize` yet
--   ◐ working   spins while the server has $/progress in flight (indexing,
--               "Analyzing ...", workspace loading)
--   ● ready     initialized and idle
--
-- Both states come from nvim itself. vim.lsp.start() attaches the buffer
-- before `initialize` completes, but get_clients() hides uninitialized clients
-- unless given the private `_uninitialized = true` filter (runtime
-- lua/vim/lsp.lua, get_clients). If a later nvim drops that flag the only loss
-- is the starting state. The $/progress handler keeps in-flight tokens in
-- client.progress.pending (lua/vim/lsp/handlers.lua). Do not call
-- vim.lsp.status() here: it drains the progress ring buffer that other
-- consumers read.

local p = require("poimandres.palette")

local SPINNER = { "◐", "◓", "◑", "◒" }
local FRAME_MS = 120

local M = require("lualine.component"):extend()

local function client_state(client)
	if not client.initialized then
		return "starting"
	end
	if next(client.progress.pending) ~= nil then
		return "working"
	end
	return "ready"
end

local function any_busy()
	for _, client in ipairs(vim.lsp.get_clients({ _uninitialized = true })) do
		if client_state(client) ~= "ready" then
			return true
		end
	end
	return false
end

local function refresh()
	require("lualine").refresh({ place = { "tabline" } })
end

-- lualine caches the tabline between refreshes, and neither the starting
-- state nor the spinner frames produce an event of their own (LspAttach only
-- fires after `initialize`, and basedpyright can sit on one "Analyzing" token
-- for seconds). So a timer redraws while any client is starting or working
-- and stops itself on the first tick where every client is ready.
local timer = nil

local function ensure_timer()
	if timer or not any_busy() then
		return
	end
	timer = vim.uv.new_timer()
	timer:start(
		FRAME_MS,
		FRAME_MS,
		vim.schedule_wrap(function()
			if not any_busy() and timer then
				timer:stop()
				timer:close()
				timer = nil
			end
			refresh()
		end)
	)
end

-- FileType is where vim.lsp.enable() starts clients. Scheduling puts this
-- after every FileType handler, so the new client already exists (attached,
-- not yet initialized) when the timer checks for it. LspDetach fires before
-- the client is removed from the list, which scheduling also covers.
vim.api.nvim_create_autocmd({ "FileType", "LspAttach", "LspDetach", "LspProgress" }, {
	group = vim.api.nvim_create_augroup("user_lsp_status", { clear = true }),
	callback = function()
		vim.schedule(function()
			ensure_timer()
			refresh()
		end)
	end,
})

function M:init(options)
	M.super.init(self, options)
	self.state_hl = {
		starting = self:create_hl({ fg = p.blueGray3 }, "starting"),
		working = self:create_hl({ fg = p.yellow }, "working"),
		ready = self:create_hl({ fg = p.teal1 }, "ready"),
	}
end

function M:update_status()
	local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf(), _uninitialized = true })
	if #clients == 0 then
		return ""
	end

	local frame = SPINNER[math.floor(vim.uv.hrtime() / 1e6 / FRAME_MS) % #SPINNER + 1]
	local glyph = { starting = "○", working = frame, ready = "●" }
	local default_hl = self:get_default_hl()

	local parts = {}
	for _, client in ipairs(clients) do
		local state = client_state(client)
		parts[#parts + 1] = self:format_hl(self.state_hl[state]) .. glyph[state] .. default_hl .. " " .. client.name
	end
	return table.concat(parts, "  ")
end

return M
