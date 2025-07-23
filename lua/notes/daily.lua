-- Daily notes functionality for notes.nvim plugin

local utils = require("notes.utils")
local dates = require("notes.dates")
local errors = require("notes.errors")
local templates = require("notes.templates")
local M = {}

-- Core function to create daily note for a given timestamp
function M.create_daily_note_for_timestamp(timestamp, config)
	local main_note_dir = utils.join_path(config.pkm_dir, "Daily")

	-- Get date components for the given timestamp
	local year = os.date("%Y", timestamp)
	local month_num = os.date("%m", timestamp)
	local month_abbr = os.date("%b", timestamp)
	local day = os.date("%d", timestamp)
	local weekday = os.date("%A", timestamp)

	-- Construct the directory structure and filename
	local note_dir = utils.join_path(main_note_dir, year, month_num .. "-" .. month_abbr)
	local note_name = year .. "-" .. month_num .. "-" .. day .. "-" .. weekday
	local full_path = utils.join_path(note_dir, note_name .. ".md")

	-- Ensure directory exists
	utils.ensure_dir(note_dir)

	-- Create the daily note if it doesn't exist
	if vim.fn.filereadable(full_path) == 0 then
		-- Create template context
		local context = templates.create_context(timestamp, "daily", note_name)

		-- Generate note content using template system
		local template_config = config.templates.daily
		local tags = (config.templates.daily and config.templates.daily.tags) or "[#daily]"

		-- If template only has tags (no actual template content), use nil to trigger defaults
		if
			template_config
			and not template_config.sections
			and not template_config.header
			and not template_config.footer
			and not template_config.file
			and not template_config[1]
			and type(template_config) ~= "function"
		then
			template_config = nil
		end

		local content = templates.generate_note_content(template_config, context, tags, config)

		vim.fn.writefile(content, full_path)
	end

	-- Change to PKM directory and open the file
	vim.cmd("cd " .. config.pkm_dir)
	vim.cmd("edit " .. vim.fn.fnameescape(full_path))
end

-- Dynamic daily note function - accepts date input
function M.dynamic_daily_note(input, config)
	local timestamp, error_msg = dates.parse_date_input(input)

	if not timestamp then
		errors.invalid_date_input_error(input, error_msg)
		return
	end

	-- Show user what date we're opening
	local description = dates.get_relative_description(timestamp)
	local date_str = os.date("%A, %B %d, %Y", timestamp)
	errors.daily_note_opened(date_str, description)

	M.create_daily_note_for_timestamp(timestamp, config)
end

-- Today's daily note
function M.daily_note(config)
	M.create_daily_note_for_timestamp(os.time(), config)
end

-- Tomorrow's daily note
function M.tomorrow_note(config)
	local tomorrow_timestamp = dates.add_days(os.time(), 1)
	M.create_daily_note_for_timestamp(tomorrow_timestamp, config)
end

-- Quick note function
function M.quick_note(config)
	local inbox_dir = utils.join_path(config.pkm_dir, "+Inbox")

	-- Generate a random filename
	local random_name = utils.create_id(config.templates.quick.id_length)
	local full_path = utils.join_path(inbox_dir, random_name .. ".md")

	-- Ensure inbox directory exists
	utils.ensure_dir(inbox_dir)

	-- Create the note file with template
	-- Create template context
	local context = templates.create_context(os.time(), "quick", random_name)

	-- Generate note content using template system
	local template_config = config.templates.quick
	local tags = (config.templates.quick and config.templates.quick.tags) or "[]"

	-- If template only has tags/id_length (no actual template content), use nil to trigger defaults
	if
		template_config
		and not template_config.sections
		and not template_config.header
		and not template_config.footer
		and not template_config.file
		and not template_config[1]
		and type(template_config) ~= "function"
	then
		template_config = nil
	end

	local content = templates.generate_note_content(template_config, context, tags, config)

	vim.fn.writefile(content, full_path)

	-- Change to PKM directory and open the file
	vim.cmd("cd " .. config.pkm_dir)
	vim.cmd("edit " .. vim.fn.fnameescape(full_path))
end

return M
