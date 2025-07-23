-- Template engine for notes.nvim plugin

local errors = require("notes.errors")
local M = {}

-- Create rich context object for template rendering
function M.create_context(timestamp, note_type, note_id)
	local date_table = os.date("*t", timestamp)
	local weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
	local months = {
		"January",
		"February",
		"March",
		"April",
		"May",
		"June",
		"July",
		"August",
		"September",
		"October",
		"November",
		"December",
	}

	local context = {
		-- Date information
		date = os.date("%Y-%m-%d", timestamp),
		year = date_table.year,
		month = date_table.month,
		day = date_table.day,
		weekday = weekdays[date_table.wday],
		month_name = months[date_table.month],

		-- Convenience booleans
		is_monday = date_table.wday == 2,
		is_tuesday = date_table.wday == 3,
		is_wednesday = date_table.wday == 4,
		is_thursday = date_table.wday == 5,
		is_friday = date_table.wday == 6,
		is_saturday = date_table.wday == 7,
		is_sunday = date_table.wday == 1,
		is_weekend = date_table.wday == 1 or date_table.wday == 7,
		is_workday = date_table.wday >= 2 and date_table.wday <= 6,

		-- Time information
		timestamp = os.date("%Y-%m-%dT%H:%M:%S", timestamp),
		time_12h = os.date("%I:%M %p", timestamp),
		time_24h = os.date("%H:%M", timestamp),

		-- Note information
		note_id = note_id,
		note_type = note_type,

		-- User information
		user_name = os.getenv("USER") or "user",

		-- Utility functions
		format_date = function(fmt)
			return os.date(fmt, timestamp)
		end,
	}

	return context
end

-- Default templates for zero-config users
M.defaults = {
	daily = {
		sections = {
			{ title = "Today's Focus", content = "" },
			{ title = "Notes", content = "" },
			{ title = "Tomorrow's Prep", content = "" },
		},
	},
	quick = {
		header = "# {{note_id}}",
		sections = {},
	},
}

-- Render template based on configuration type
function M.render_template(template_config, context)
	if not template_config then
		-- Use default template based on note type
		template_config = M.defaults[context.note_type] or M.defaults.quick
	end

	-- Handle different template configuration types
	if type(template_config) == "function" then
		return M.render_function_template(template_config, context)
	elseif type(template_config) == "table" then
		if template_config.file then
			return M.render_file_template(template_config, context)
		elseif template_config.sections then
			return M.render_object_template(template_config, context)
		elseif template_config[1] then -- Array of sections (legacy support)
			return M.render_array_template(template_config, context)
		else
			return M.render_object_template(template_config, context)
		end
	else
		errors.user_error("Invalid template configuration", "Template must be a function, table, or array")
		return M.render_template(M.defaults[context.note_type], context)
	end
end

-- Render function-based template
function M.render_function_template(template_func, context)
	local success, result = pcall(template_func, context)
	if not success then
		errors.user_error("Template function error: " .. tostring(result), "Check your template function for errors")
		return M.render_template(M.defaults[context.note_type], context)
	end

	if type(result) == "table" then
		return result
	else
		errors.user_error(
			"Template function must return a table of strings",
			"Return format: { 'line1', 'line2', ... }"
		)
		return M.render_template(M.defaults[context.note_type], context)
	end
end

-- Render array-based template (simple sections list)
function M.render_array_template(sections_array, context)
	local lines = {}

	-- Add header
	table.insert(
		lines,
		string.format("# %s, %s %d, %d", context.weekday, context.month_name, context.day, context.year)
	)
	table.insert(lines, "")

	-- Add sections
	for _, section in ipairs(sections_array) do
		table.insert(lines, "## " .. section)
		table.insert(lines, "")
	end

	return lines
end

-- Render object-based template (full control)
function M.render_object_template(template_obj, context)
	local lines = {}

	-- Add custom header or default
	if template_obj.header then
		local header = M.substitute_variables(template_obj.header, context)
		table.insert(lines, header)
		table.insert(lines, "")
	else
		table.insert(
			lines,
			string.format("# %s, %s %d, %d", context.weekday, context.month_name, context.day, context.year)
		)
		table.insert(lines, "")
	end

	-- Add sections
	if template_obj.sections then
		for _, section in ipairs(template_obj.sections) do
			-- Check condition if present
			if section.condition then
				local should_include = false
				if type(section.condition) == "function" then
					local success, result = pcall(section.condition, context)
					should_include = success and result
				elseif type(section.condition) == "string" then
					should_include = context[section.condition] == true
				end

				if not should_include then
					goto continue
				end
			end

			-- Add section title
			if section.title then
				table.insert(lines, "## " .. section.title)
			end

			-- Add section content
			if section.content then
				if type(section.content) == "table" then
					for _, line in ipairs(section.content) do
						table.insert(lines, line)
					end
				else
					table.insert(lines, section.content)
				end
			end

			table.insert(lines, "")

			::continue::
		end
	end

	-- Add custom footer if present
	if template_obj.footer then
		local footer = M.substitute_variables(template_obj.footer, context)
		table.insert(lines, footer)
	end

	return lines
end

-- Render file-based template
function M.render_file_template(template_config, context)
	local file_path = vim.fn.expand(template_config.file)

	if vim.fn.filereadable(file_path) == 0 then
		errors.user_error("Template file not found: " .. file_path, "Create the template file or check the path")
		return M.render_template(M.defaults[context.note_type], context)
	end

	local lines = vim.fn.readfile(file_path)

	-- Apply variable substitution to each line
	for i, line in ipairs(lines) do
		lines[i] = M.substitute_variables(line, context)
	end

	return lines
end

-- Simple variable substitution using {{variable}} syntax
function M.substitute_variables(text, context)
	if type(text) ~= "string" then
		return text
	end

	-- Replace {{variable}} with context values
	local result = text:gsub("{{([^}]+)}}", function(var_name)
		local value = context[var_name:trim()]
		if value ~= nil then
			return tostring(value)
		else
			return "{{" .. var_name .. "}}" -- Leave unchanged if variable not found
		end
	end)

	return result
end

-- String trim utility
string.trim = function(s)
	return s:match("^%s*(.-)%s*$")
end

-- Generate complete note content including frontmatter
function M.generate_note_content(template_config, context, tags, config)
	-- Generate frontmatter
	local utils = require("notes.utils")
	local frontmatter = utils.generate_frontmatter(context.note_id, tags or "[]", config)

	-- Generate template content
	local template_lines = M.render_template(template_config, context)

	-- Combine frontmatter and content
	local content = {}

	-- Add frontmatter
	for _, line in ipairs(frontmatter) do
		table.insert(content, line)
	end

	-- Add template content
	for _, line in ipairs(template_lines) do
		table.insert(content, line)
	end

	return content
end

return M
