-- Test utilities and helpers

local M = {}

-- Simple assertion functions
function M.assert_true(condition, message)
	if not condition then
		error(message or "Assertion failed: expected true")
	end
end

function M.assert_false(condition, message)
	if condition then
		error(message or "Assertion failed: expected false")
	end
end

function M.assert_equal(expected, actual, message)
	if expected ~= actual then
		error(
			string.format(
				"%s\nExpected: %s\nActual: %s",
				message or "Assertion failed",
				tostring(expected),
				tostring(actual)
			)
		)
	end
end

function M.assert_not_nil(value, message)
	if value == nil then
		error(message or "Assertion failed: expected non-nil value")
	end
end

function M.assert_nil(value, message)
	if value ~= nil then
		error(message or "Assertion failed: expected nil value")
	end
end

function M.assert_type(expected_type, value, message)
	local actual_type = type(value)
	if actual_type ~= expected_type then
		error(
			string.format(
				"%s\nExpected type: %s\nActual type: %s",
				message or "Type assertion failed",
				expected_type,
				actual_type
			)
		)
	end
end

function M.assert_contains(haystack, needle, message)
	if type(haystack) == "string" then
		if not haystack:find(needle, 1, true) then
			error(
				string.format(
					"%s\nExpected '%s' to contain '%s'",
					message or "Contains assertion failed",
					haystack,
					needle
				)
			)
		end
	elseif type(haystack) == "table" then
		local found = false
		for _, v in ipairs(haystack) do
			if v == needle then
				found = true
				break
			end
		end
		if not found then
			error(
				string.format(
					"%s\nExpected table to contain '%s'",
					message or "Contains assertion failed",
					tostring(needle)
				)
			)
		end
	else
		error("assert_contains: haystack must be string or table")
	end
end

function M.assert_matches(pattern, text, message)
	if not text:match(pattern) then
		error(
			string.format(
				"%s\nExpected '%s' to match pattern '%s'",
				message or "Pattern assertion failed",
				text,
				pattern
			)
		)
	end
end

function M.assert_error(func, expected_pattern, message)
	local success, error_msg = pcall(func)
	if success then
		error(message or "Expected function to throw an error")
	end
	if expected_pattern and not error_msg:match(expected_pattern) then
		error(
			string.format(
				"%s\nExpected error matching '%s', got '%s'",
				message or "Error pattern assertion failed",
				expected_pattern,
				error_msg
			)
		)
	end
end

function M.assert_no_error(func, message)
	local success, error_msg = pcall(func)
	if not success then
		error(string.format("%s\nUnexpected error: %s", message or "Expected no error", error_msg))
	end
end

-- Test runner utilities
function M.run_test(name, test_func)
	local success, error_msg = pcall(test_func)
	if success then
		print(string.format("  ✅ %s", name))
		return true
	else
		print(string.format("  ❌ %s", name))
		print(string.format("     Error: %s", error_msg))
		return false
	end
end

function M.run_test_suite(suite_name, tests)
	print(string.format("\n🧪 %s", suite_name))
	local passed = 0
	local total = 0

	for test_name, test_func in pairs(tests) do
		total = total + 1
		if M.run_test(test_name, test_func) then
			passed = passed + 1
		end
	end

	print(string.format("   %d/%d tests passed", passed, total))
	return passed, total
end

-- Time utilities for testing
function M.with_fixed_time(timestamp, func)
	local original_time = os.time
	os.time = function()
		return timestamp
	end

	local success, result = pcall(func)

	os.time = original_time

	if not success then
		error(result)
	end

	return result
end

-- Create a fixed timestamp for consistent testing
function M.get_test_timestamp()
	-- Wednesday, July 23, 2025, 2:30 PM
	return os.time({ year = 2025, month = 7, day = 23, hour = 14, min = 30, sec = 0 })
end

return M

