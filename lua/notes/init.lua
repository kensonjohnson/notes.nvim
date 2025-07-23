-- Main module for notes.nvim plugin

local config = require("notes.config")
local daily = require("notes.daily")
local utils = require("notes.utils")
local completion = require("notes.completion")
local M = {}

-- Setup function called by users
function M.setup(user_config)
	-- Setup configuration
	config.setup(user_config)
	local opts = config.options

	-- Setup autocommands
	M.setup_autocommands(opts)

	-- Setup commands
	M.setup_commands(opts)
end

-- Setup autocommands
function M.setup_autocommands(opts)
	local augroup = vim.api.nvim_create_augroup("NotesNvimAutoUpdate", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		pattern = "*.md",
		callback = function()
			utils.update_modified_timestamp(opts)
		end,
		desc = "Update modified timestamp in PKM notes frontmatter",
	})
end

-- Setup user commands
function M.setup_commands(opts)
	vim.api.nvim_create_user_command("DailyNote", function(cmd_opts)
		if cmd_opts.args and cmd_opts.args ~= "" then
			daily.dynamic_daily_note(cmd_opts.args, opts)
		else
			daily.daily_note(opts)
		end
	end, {
		desc = "Open daily note (optionally specify date/offset)",
		nargs = "?",
		complete = completion.daily_note_complete,
	})

	vim.api.nvim_create_user_command("TomorrowNote", function()
		daily.tomorrow_note(opts)
	end, { desc = "Open tomorrow's daily note" })

	vim.api.nvim_create_user_command("QuickNote", function()
		daily.quick_note(opts)
	end, { desc = "Create a new quick note" })
end

-- Helper function to wrap daily functions with config
local function with_config(fn)
	return function(...)
		return fn(..., config.options)
	end
end

-- Export individual functions for advanced users
M.daily_note = with_config(daily.daily_note)
M.tomorrow_note = with_config(daily.tomorrow_note)
M.quick_note = with_config(daily.quick_note)
M.dynamic_daily_note = with_config(daily.dynamic_daily_note)

return M
