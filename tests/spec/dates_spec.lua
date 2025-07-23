-- Date parsing tests

-- Setup path and mocks
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local vim_mocks = require("tests.helpers.vim_mocks")
local test_utils = require("tests.helpers.test_utils")

vim_mocks.setup()

local dates = require("notes.dates")

local function test_parse_relative_dates()
	local test_cases = {
		{ input = "today", should_succeed = true },
		{ input = "tomorrow", should_succeed = true },
		{ input = "yesterday", should_succeed = true },
	}

	for _, case in ipairs(test_cases) do
		local timestamp, error_msg = dates.parse_date_input(case.input)
		if case.should_succeed then
			test_utils.assert_not_nil(timestamp, "Should parse '" .. case.input .. "'")
			test_utils.assert_nil(error_msg, "Should not have error for '" .. case.input .. "'")
		else
			test_utils.assert_nil(timestamp, "Should not parse '" .. case.input .. "'")
			test_utils.assert_not_nil(error_msg, "Should have error for '" .. case.input .. "'")
		end
	end
end

local function test_parse_weekday_patterns()
	local test_cases = {
		"next monday",
		"last friday",
		"next tuesday",
		"last sunday",
	}

	for _, input in ipairs(test_cases) do
		local timestamp, error_msg = dates.parse_date_input(input)
		test_utils.assert_not_nil(timestamp, "Should parse '" .. input .. "'")
		test_utils.assert_nil(error_msg, "Should not have error for '" .. input .. "'")
		test_utils.assert_type("number", timestamp, "Should return timestamp for '" .. input .. "'")
	end
end

local function test_parse_numeric_offsets()
	local test_cases = {
		"1",
		"3",
		"7",
		"-1",
		"-3",
		"-7",
	}

	for _, input in ipairs(test_cases) do
		local timestamp, error_msg = dates.parse_date_input(input)
		test_utils.assert_not_nil(timestamp, "Should parse '" .. input .. "'")
		test_utils.assert_nil(error_msg, "Should not have error for '" .. input .. "'")
		test_utils.assert_type("number", timestamp, "Should return timestamp for '" .. input .. "'")
	end
end

local function test_parse_iso_dates()
	local test_cases = {
		"2025-07-23",
		"2025-12-25",
		"2024-02-29", -- Leap year
	}

	for _, input in ipairs(test_cases) do
		local timestamp, error_msg = dates.parse_date_input(input)
		test_utils.assert_not_nil(timestamp, "Should parse '" .. input .. "'")
		test_utils.assert_nil(error_msg, "Should not have error for '" .. input .. "'")
	end
end

local function test_parse_us_dates()
	local test_cases = {
		"7/23/2025",
		"12/25/2025",
		"7/23/25", -- Short year
	}

	for _, input in ipairs(test_cases) do
		local timestamp, error_msg = dates.parse_date_input(input)
		test_utils.assert_not_nil(timestamp, "Should parse '" .. input .. "'")
		test_utils.assert_nil(error_msg, "Should not have error for '" .. input .. "'")
	end
end

local function test_invalid_input_handling()
	local test_cases = {
		"invalid_date",
		"next invalid_day",
		"2025-13-45", -- Invalid date
		"not_a_date",
	}

	for _, input in ipairs(test_cases) do
		local timestamp, error_msg = dates.parse_date_input(input)
		test_utils.assert_nil(timestamp, "Should not parse '" .. input .. "'")
		test_utils.assert_not_nil(error_msg, "Should have error for '" .. input .. "'")
		test_utils.assert_matches("Invalid date input", error_msg, "Error should mention invalid input")
	end
end

local function test_date_validation()
	-- Test invalid dates
	test_utils.assert_false(dates.is_valid_date(2025, 13, 1), "Should reject invalid month")
	test_utils.assert_false(dates.is_valid_date(2025, 2, 30), "Should reject invalid day for February")
	test_utils.assert_false(dates.is_valid_date(1800, 1, 1), "Should reject year too early")

	-- Test valid dates
	test_utils.assert_true(dates.is_valid_date(2025, 7, 23), "Should accept valid date")
	test_utils.assert_true(dates.is_valid_date(2024, 2, 29), "Should accept leap year date")
end

local function test_relative_descriptions()
	local today = os.time()
	local tomorrow = today + 24 * 60 * 60
	local yesterday = today - 24 * 60 * 60

	test_utils.assert_equal("today", dates.get_relative_description(today))
	test_utils.assert_equal("tomorrow", dates.get_relative_description(tomorrow))
	test_utils.assert_equal("yesterday", dates.get_relative_description(yesterday))
end

-- Run all tests
local tests = {
	["parse relative dates"] = test_parse_relative_dates,
	["parse weekday patterns"] = test_parse_weekday_patterns,
	["parse numeric offsets"] = test_parse_numeric_offsets,
	["parse ISO dates"] = test_parse_iso_dates,
	["parse US dates"] = test_parse_us_dates,
	["handle invalid input"] = test_invalid_input_handling,
	["validate dates"] = test_date_validation,
	["relative descriptions"] = test_relative_descriptions,
}

local passed, total = test_utils.run_test_suite("Date Parsing Tests", tests)

vim_mocks.cleanup()

return { passed = passed, total = total }

