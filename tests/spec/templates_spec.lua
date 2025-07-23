-- Template system tests

-- Setup path and mocks
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local vim_mocks = require("tests.helpers.vim_mocks")
local test_utils = require("tests.helpers.test_utils")

vim_mocks.setup()

local templates = require("notes.templates")

local function test_context_creation()
	local timestamp = test_utils.get_test_timestamp()
	local context = templates.create_context(timestamp, "daily", "test-id")

	test_utils.assert_not_nil(context, "Should create context")
	test_utils.assert_equal("daily", context.note_type, "Should set note type")
	test_utils.assert_equal("test-id", context.note_id, "Should set note ID")
	test_utils.assert_equal("Wednesday", context.weekday, "Should set weekday")
	test_utils.assert_equal("July", context.month_name, "Should set month name")
	test_utils.assert_equal(2025, context.year, "Should set year")
	test_utils.assert_true(context.is_wednesday, "Should set weekday boolean")
	test_utils.assert_true(context.is_workday, "Should set workday boolean")
	test_utils.assert_false(context.is_weekend, "Should set weekend boolean")
	test_utils.assert_equal("testuser", context.user_name, "Should set user name")
end

local function test_default_template_rendering()
	local context = templates.create_context(test_utils.get_test_timestamp(), "daily", "test")
	local result = templates.render_template(nil, context)

	test_utils.assert_not_nil(result, "Should render default template")
	test_utils.assert_type("table", result, "Should return table of lines")

	local content = table.concat(result, "\n")
	test_utils.assert_contains(content, "Wednesday, July 23, 2025", "Should contain date header")
	test_utils.assert_contains(content, "Today's Focus", "Should contain focus section")
	test_utils.assert_contains(content, "Notes", "Should contain notes section")
	test_utils.assert_contains(content, "Tomorrow's Prep", "Should contain prep section")
end

local function test_array_template_rendering()
	local template_config = { "Morning Pages", "Work Log", "Gratitude" }
	local context = templates.create_context(test_utils.get_test_timestamp(), "daily", "test")
	local result = templates.render_template(template_config, context)

	test_utils.assert_not_nil(result, "Should render array template")

	local content = table.concat(result, "\n")
	test_utils.assert_contains(content, "Wednesday, July 23, 2025", "Should contain date header")
	test_utils.assert_contains(content, "## Morning Pages", "Should contain first section")
	test_utils.assert_contains(content, "## Work Log", "Should contain second section")
	test_utils.assert_contains(content, "## Gratitude", "Should contain third section")
end

local function test_function_template_rendering()
	local template_func = function(ctx)
		local lines = { string.format("# %s Planning", ctx.weekday) }
		if ctx.is_monday then
			table.insert(lines, "## Weekly Goals")
		end
		table.insert(lines, "## Today's Focus")
		return lines
	end

	local context = templates.create_context(test_utils.get_test_timestamp(), "daily", "test")
	local result = templates.render_template(template_func, context)

	test_utils.assert_not_nil(result, "Should render function template")
	test_utils.assert_contains(result, "# Wednesday Planning", "Should contain custom header")
	test_utils.assert_contains(result, "## Today's Focus", "Should contain focus section")
	-- Should not contain weekly goals since it's Wednesday, not Monday
	local content = table.concat(result, "\n")
	test_utils.assert_false(content:find("Weekly Goals"), "Should not contain Monday-specific content")
end

local function test_object_template_rendering()
	local template_config = {
		header = "# {{weekday}} Focus - {{month_name}} {{day}}",
		sections = {
			{ title = "Priority", content = "" },
			{ title = "Notes", content = "" },
			{
				title = "Weekend Plans",
				condition = "is_friday",
				content = { "- Plan weekend activities" },
			},
		},
		footer = "Created: {{timestamp}}",
	}

	local context = templates.create_context(test_utils.get_test_timestamp(), "daily", "test")
	local result = templates.render_template(template_config, context)

	test_utils.assert_not_nil(result, "Should render object template")

	local content = table.concat(result, "\n")
	test_utils.assert_contains(content, "# Wednesday Focus - July 23", "Should contain custom header")
	test_utils.assert_contains(content, "## Priority", "Should contain priority section")
	test_utils.assert_contains(content, "## Notes", "Should contain notes section")
	test_utils.assert_contains(content, "Created: 2025-07-23T14:30:00", "Should contain footer")
	-- Should not contain weekend plans since it's Wednesday, not Friday
	test_utils.assert_false(content:find("Weekend Plans"), "Should not contain Friday-specific content")
end

local function test_file_template_rendering()
	local template_config = { file = "/tmp/test_template.md" }
	local context = templates.create_context(test_utils.get_test_timestamp(), "daily", "test")
	local result = templates.render_template(template_config, context)

	test_utils.assert_not_nil(result, "Should render file template")

	local content = table.concat(result, "\n")
	test_utils.assert_contains(content, "# Wednesday, July 23, 2025", "Should substitute variables")
	test_utils.assert_contains(content, "Content: testuser", "Should substitute user name")
end

local function test_variable_substitution()
	local context = {
		user_name = "testuser",
		weekday = "Wednesday",
		month_name = "July",
		day = 23,
	}

	local text = "Hello {{user_name}}, today is {{weekday}} {{month_name}} {{day}}"
	local result = templates.substitute_variables(text, context)

	test_utils.assert_equal("Hello testuser, today is Wednesday July 23", result, "Should substitute all variables")

	-- Test with missing variable
	local text_with_missing = "Hello {{user_name}}, missing: {{missing_var}}"
	local result_with_missing = templates.substitute_variables(text_with_missing, context)
	test_utils.assert_equal(
		"Hello testuser, missing: {{missing_var}}",
		result_with_missing,
		"Should leave missing variables unchanged"
	)
end

local function test_conditional_sections()
	-- Test with Friday context (should include weekend plans)
	local friday_timestamp = os.time({ year = 2025, month = 7, day = 25, hour = 14, min = 30, sec = 0 }) -- Friday
	local friday_context = templates.create_context(friday_timestamp, "daily", "test")

	local template_config = {
		sections = {
			{ title = "Always Present", content = "" },
			{
				title = "Weekend Plans",
				condition = "is_friday",
				content = "Plan weekend",
			},
		},
	}

	local result = templates.render_template(template_config, friday_context)
	local content = table.concat(result, "\n")

	test_utils.assert_contains(content, "## Always Present", "Should contain unconditional section")
	test_utils.assert_contains(content, "## Weekend Plans", "Should contain Friday-specific section")
	test_utils.assert_contains(content, "Plan weekend", "Should contain Friday-specific content")
end

local function test_error_handling()
	-- Test function template that throws error
	local bad_template = function(ctx)
		error("Template function error!")
	end

	local context = templates.create_context(test_utils.get_test_timestamp(), "daily", "test")
	local result = templates.render_template(bad_template, context)

	-- Should fall back to default template
	test_utils.assert_not_nil(result, "Should handle template errors gracefully")
	local content = table.concat(result, "\n")
	test_utils.assert_contains(content, "Today's Focus", "Should fall back to default template")
end

-- Run all tests
local tests = {
	["create context"] = test_context_creation,
	["render default template"] = test_default_template_rendering,
	["render array template"] = test_array_template_rendering,
	["render function template"] = test_function_template_rendering,
	["render object template"] = test_object_template_rendering,
	["render file template"] = test_file_template_rendering,
	["substitute variables"] = test_variable_substitution,
	["conditional sections"] = test_conditional_sections,
	["handle errors"] = test_error_handling,
}

local passed, total = test_utils.run_test_suite("Template System Tests", tests)

vim_mocks.cleanup()

return { passed = passed, total = total }

