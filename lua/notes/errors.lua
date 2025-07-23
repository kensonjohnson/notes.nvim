-- Centralized error handling utilities for notes.nvim plugin

local M = {}

-- Error types for consistent handling
M.ErrorType = {
	FATAL = "fatal", -- Unrecoverable errors (configuration, setup)
	USER = "user", -- User input errors (recoverable)
	INTERNAL = "internal", -- Internal logic errors (return nil pattern)
	INFO = "info", -- Informational messages
}

-- Standard error message prefix
local PREFIX = "notes.nvim: "

-- Format error message with consistent prefix and structure
local function format_message(message, suggestions)
	local formatted = PREFIX .. message
	if suggestions then
		if type(suggestions) == "string" then
			formatted = formatted .. "\n\n" .. suggestions
		elseif type(suggestions) == "table" then
			formatted = formatted .. "\n\n" .. table.concat(suggestions, "\n")
		end
	end
	return formatted
end

-- Handle fatal errors (configuration, setup issues)
-- These should stop execution and require user intervention
function M.fatal(message, suggestions)
	local formatted = format_message(message, suggestions)
	error(formatted)
end

-- Handle user-facing errors with vim.notify
-- These are recoverable and should provide helpful feedback
function M.user_error(message, suggestions)
	local formatted = format_message(message, suggestions)
	vim.notify(formatted, vim.log.levels.ERROR)
end

-- Handle user-facing warnings
function M.user_warn(message, suggestions)
	local formatted = format_message(message, suggestions)
	vim.notify(formatted, vim.log.levels.WARN)
end

-- Handle user-facing info messages
function M.user_info(message)
	local formatted = format_message(message)
	vim.notify(formatted, vim.log.levels.INFO)
end

-- Create internal error result (for return nil, error pattern)
-- These are for internal function communication
function M.internal_error(message)
	return nil, message
end

-- Create success result (for consistency with internal_error)
function M.success(result)
	return result, nil
end

-- Validation error helpers for consistent configuration validation
function M.validation_error(field_path, expected, actual, suggestions)
	local message = string.format("Invalid value for '%s'. Expected %s, got %s.", field_path, expected, actual)
	M.fatal(message, suggestions or "Please check your configuration.")
end

function M.type_error(field_path, expected_type, actual_type)
	local message = string.format("Invalid type for '%s'. Expected %s, got %s.", field_path, expected_type, actual_type)
	M.fatal(message, "Please check your configuration.")
end

function M.range_error(field_path, min, max, actual)
	local message = string.format(
		"Invalid value for '%s'. Expected number between %d and %d, got %d.",
		field_path,
		min,
		max,
		actual
	)
	M.fatal(message, "Please adjust your configuration.")
end

function M.empty_string_error(field_path)
	local message = string.format("Invalid value for '%s'. String cannot be empty.", field_path)
	M.fatal(message, "Please provide a valid value.")
end

function M.array_structure_error(field_path)
	local message = string.format(
		"Invalid value for '%s'. Expected array (table with consecutive integer keys), got table with mixed keys.",
		field_path
	)
	M.fatal(message, "Example: { 'item1', 'item2', 'item3' }")
end

function M.unknown_field_error(field_name, field_path, valid_fields)
	local message = string.format("Unknown field '%s' in '%s'.", field_name, field_path)
	local suggestion = "Valid fields: " .. table.concat(valid_fields, ", ")
	M.fatal(message, suggestion)
end

-- Directory/file error helpers
function M.directory_not_found_error(path)
	local message = "PKM directory does not exist: " .. path
	local suggestions = {
		"Please either:",
		"1. Create the directory: mkdir -p '" .. path .. "'",
		"2. Update your configuration to point to an existing directory",
		"3. Use ~ for home directory: ~/Documents/notes",
	}
	M.fatal(message, suggestions)
end

function M.required_config_error(field_name, example)
	local message = string.format("'%s' is required. Please set it in your configuration:", field_name)
	local suggestions = {
		example,
		"",
		"This should be the path to your Personal Knowledge Management directory.",
	}
	M.fatal(message, suggestions)
end

-- User input error helpers
function M.invalid_date_input_error(input, error_msg)
	local message = error_msg or ("Invalid date input: " .. tostring(input))
	local suggestions = {
		"Valid formats:",
		"• Relative: today, tomorrow, yesterday",
		"• Offsets: 1, -2, 7 (days from today)",
		"• Dates: 2025-12-25, 12/25/2025",
		"• Weekdays: next monday, last friday",
	}
	M.user_error(message, suggestions)
end

-- Success message helpers
function M.daily_note_opened(date_str, description)
	local message = string.format("Opening daily note for %s (%s)", date_str, description)
	M.user_info(message)
end

return M

