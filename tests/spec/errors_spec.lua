-- Error handling tests

-- Setup path and mocks
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local vim_mocks = require("tests.helpers.vim_mocks")
local test_utils = require("tests.helpers.test_utils")

vim_mocks.setup()

local errors = require("notes.errors")

local function test_fatal_error()
	test_utils.assert_error(function()
		errors.fatal("Test fatal error", "Fix by doing X")
	end, "notes%.nvim: Test fatal error", "Should throw fatal error with prefix")
end

local function test_user_error()
	vim_mocks.cleanup() -- Clear previous notifications
	errors.user_error("Test user error", "Try this instead")

	local notifications = vim_mocks.get_notifications()
	test_utils.assert_equal(1, #notifications, "Should send one notification")

	local notification = notifications[1]
	test_utils.assert_matches("notes%.nvim: Test user error", notification.message, "Should have plugin prefix")
	test_utils.assert_matches("Try this instead", notification.message, "Should include suggestion")
	test_utils.assert_equal(1, notification.level, "Should use ERROR level") -- vim.log.levels.ERROR = 1
end

local function test_user_warn()
	vim_mocks.cleanup() -- Clear previous notifications
	errors.user_warn("Test warning", "Consider this")

	local notifications = vim_mocks.get_notifications()
	test_utils.assert_equal(1, #notifications, "Should send one notification")

	local notification = notifications[1]
	test_utils.assert_matches("notes%.nvim: Test warning", notification.message, "Should have plugin prefix")
	test_utils.assert_equal(2, notification.level, "Should use WARN level") -- vim.log.levels.WARN = 2
end

local function test_user_info()
	vim_mocks.cleanup() -- Clear previous notifications
	errors.user_info("Test info message")

	local notifications = vim_mocks.get_notifications()
	test_utils.assert_equal(1, #notifications, "Should send one notification")

	local notification = notifications[1]
	test_utils.assert_matches("notes%.nvim: Test info message", notification.message, "Should have plugin prefix")
	test_utils.assert_equal(3, notification.level, "Should use INFO level") -- vim.log.levels.INFO = 3
end

local function test_internal_error()
	local result, error_msg = errors.internal_error("Internal problem")

	test_utils.assert_nil(result, "Should return nil for result")
	test_utils.assert_equal("Internal problem", error_msg, "Should return error message")
end

local function test_success()
	local result, error_msg = errors.success("operation completed")

	test_utils.assert_equal("operation completed", result, "Should return result")
	test_utils.assert_nil(error_msg, "Should return nil for error")
end

local function test_validation_error()
	test_utils.assert_error(function()
		errors.validation_error("field.path", "string", "number", "Use a string instead")
	end, "Invalid value for 'field%.path'", "Should format validation error")
end

local function test_type_error()
	test_utils.assert_error(function()
		errors.type_error("field.path", "string", "number")
	end, "Invalid type for 'field%.path'", "Should format type error")
end

local function test_range_error()
	test_utils.assert_error(function()
		errors.range_error("field.path", 1, 10, 15)
	end, "Expected number between 1 and 10, got 15", "Should format range error")
end

local function test_empty_string_error()
	test_utils.assert_error(function()
		errors.empty_string_error("field.path")
	end, "String cannot be empty", "Should format empty string error")
end

local function test_array_structure_error()
	test_utils.assert_error(function()
		errors.array_structure_error("field.path")
	end, "Expected array", "Should format array structure error")
end

local function test_unknown_field_error()
	test_utils.assert_error(function()
		errors.unknown_field_error("bad_field", "config.section", { "valid1", "valid2" })
	end, "Unknown field 'bad_field'", "Should format unknown field error")
end

local function test_directory_not_found_error()
	test_utils.assert_error(function()
		errors.directory_not_found_error("/nonexistent/path")
	end, "PKM directory does not exist", "Should format directory error")
end

local function test_required_config_error()
	test_utils.assert_error(function()
		errors.required_config_error("pkm_dir", "require('notes').setup({ pkm_dir = '/path' })")
	end, "'pkm_dir' is required", "Should format required config error")
end

local function test_invalid_date_input_error()
	vim_mocks.cleanup() -- Clear previous notifications
	errors.invalid_date_input_error("bad_date", "Custom error message")

	local notifications = vim_mocks.get_notifications()
	test_utils.assert_equal(1, #notifications, "Should send one notification")

	local notification = notifications[1]
	test_utils.assert_matches("Custom error message", notification.message, "Should use custom error message")
	test_utils.assert_matches("Valid formats:", notification.message, "Should include format suggestions")
	test_utils.assert_matches("Relative: today", notification.message, "Should include relative examples")
	test_utils.assert_matches("Offsets: 1, %-2", notification.message, "Should include offset examples")
end

local function test_daily_note_opened()
	vim_mocks.cleanup() -- Clear previous notifications
	errors.daily_note_opened("Wednesday, July 23, 2025", "today")

	local notifications = vim_mocks.get_notifications()
	test_utils.assert_equal(1, #notifications, "Should send one notification")

	local notification = notifications[1]
	test_utils.assert_matches(
		"Opening daily note for Wednesday, July 23, 2025 %(today%)",
		notification.message,
		"Should format success message"
	)
	test_utils.assert_equal(3, notification.level, "Should use INFO level")
end

local function test_error_message_consistency()
	-- Test that all error messages have consistent formatting
	local test_cases = {
		function()
			errors.fatal("Test message")
		end,
		function()
			errors.type_error("field", "string", "number")
		end,
		function()
			errors.range_error("field", 1, 10, 15)
		end,
	}

	for i, test_case in ipairs(test_cases) do
		local success, error_msg = pcall(test_case)
		test_utils.assert_false(success, "Test case " .. i .. " should throw error")
		test_utils.assert_matches("notes%.nvim:", error_msg, "Error " .. i .. " should have plugin prefix")
	end
end

local function test_suggestions_formatting()
	-- Test that suggestions are properly formatted
	test_utils.assert_error(function()
		errors.fatal("Test error", { "Suggestion 1", "Suggestion 2" })
	end, "Suggestion 1\nSuggestion 2", "Should format suggestion array")

	test_utils.assert_error(function()
		errors.fatal("Test error", "Single suggestion")
	end, "Single suggestion", "Should format single suggestion")
end

-- Run all tests
local tests = {
	["fatal error"] = test_fatal_error,
	["user error"] = test_user_error,
	["user warn"] = test_user_warn,
	["user info"] = test_user_info,
	["internal error"] = test_internal_error,
	["success"] = test_success,
	["validation error"] = test_validation_error,
	["type error"] = test_type_error,
	["range error"] = test_range_error,
	["empty string error"] = test_empty_string_error,
	["array structure error"] = test_array_structure_error,
	["unknown field error"] = test_unknown_field_error,
	["directory not found error"] = test_directory_not_found_error,
	["required config error"] = test_required_config_error,
	["invalid date input error"] = test_invalid_date_input_error,
	["daily note opened"] = test_daily_note_opened,
	["error message consistency"] = test_error_message_consistency,
	["suggestions formatting"] = test_suggestions_formatting,
}

local passed, total = test_utils.run_test_suite("Error Handling Tests", tests)

vim_mocks.cleanup()

return { passed = passed, total = total }

