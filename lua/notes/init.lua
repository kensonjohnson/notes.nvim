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
			utils.update_modified_timestamp(config.options)
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

-- Helper function to ensure setup has been called
local function ensure_setup()
	if not config or not config.options then
		error("notes.nvim config module not loaded properly. Try restarting Neovim.")
	end
	if not config.options.pkm_dir then
		error("notes.nvim not configured. Call require('notes').setup({ pkm_dir = '/path/to/your/notes' }) first")
	end
	return config.options
end

-- Export individual functions for advanced users
M.daily_note = function()
	return daily.daily_note(ensure_setup())
end

M.tomorrow_note = function()
	return daily.tomorrow_note(ensure_setup())
end

M.quick_note = function()
	return daily.quick_note(ensure_setup())
end

M.dynamic_daily_note = function(input)
	return daily.dynamic_daily_note(input, ensure_setup())
end

return M
