#!/usr/bin/env lua

-- Main test runner for notes.nvim

-- Setup path
package.path = package.path .. ";./?.lua;./?/init.lua"

print("🧪 Running notes.nvim Test Suite")
print("================================")

-- Track overall results
local total_passed = 0
local total_tests = 0
local failed_suites = {}

-- Helper function to run a test suite
local function run_test_suite(suite_path, suite_name)
	local success, result = pcall(require, suite_path)

	if not success then
		print(string.format("\n❌ Failed to load %s", suite_name))
		print(string.format("   Error: %s", result))
		table.insert(failed_suites, suite_name)
		return 0, 1
	end

	if type(result) == "table" and result.passed and result.total then
		total_passed = total_passed + result.passed
		total_tests = total_tests + result.total

		if result.passed < result.total then
			table.insert(failed_suites, suite_name)
		end

		return result.passed, result.total
	else
		print(string.format("\n❌ Invalid test result from %s", suite_name))
		table.insert(failed_suites, suite_name)
		return 0, 1
	end
end

-- Run all test suites
local test_suites = {
	{ path = "tests.spec.dates_spec", name = "Date Parsing" },
	{ path = "tests.spec.templates_spec", name = "Template System" },
	{ path = "tests.spec.config_spec", name = "Configuration Validation" },
	{ path = "tests.spec.errors_spec", name = "Error Handling" },
	{ path = "tests.spec.add_frontmatter_spec", name = "Add Frontmatter" },
}

for _, suite in ipairs(test_suites) do
	run_test_suite(suite.path, suite.name)
end

-- Print final results
print("\n" .. string.rep("=", 50))
print("📊 Test Results Summary")
print(string.rep("=", 50))

if total_passed == total_tests then
	print(string.format("🎉 All tests passed! (%d/%d)", total_passed, total_tests))
	print("\n✅ Test suite is ready for production!")
else
	print(string.format("⚠️  %d/%d tests passed", total_passed, total_tests))
	print(string.format("❌ %d tests failed", total_tests - total_passed))

	if #failed_suites > 0 then
		print("\nFailed test suites:")
		for _, suite_name in ipairs(failed_suites) do
			print(string.format("  - %s", suite_name))
		end
	end
end

-- Exit with appropriate code for CI
if total_passed == total_tests then
	os.exit(0)
else
	os.exit(1)
end

