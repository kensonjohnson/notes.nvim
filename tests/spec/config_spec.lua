-- Configuration validation tests

-- Setup path and mocks
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local vim_mocks = require("tests.helpers.vim_mocks")
local test_utils = require("tests.helpers.test_utils")
local sample_configs = require("tests.fixtures.sample_configs")

vim_mocks.setup()

local config = require("notes.config")

-- Helper to reset config state between tests
local function reset_config()
	config.options = {}
end

local function test_minimal_valid_config()
	reset_config()
	test_utils.assert_no_error(function()
		config.setup(sample_configs.minimal)
	end, "Should accept minimal valid configuration")

	test_utils.assert_not_nil(config.options.pkm_dir, "Should set pkm_dir")
	test_utils.assert_not_nil(config.options.templates, "Should have default templates")
	test_utils.assert_not_nil(config.options.frontmatter, "Should have default frontmatter settings")
end

local function test_full_valid_config()
	reset_config()
	test_utils.assert_no_error(function()
		config.setup(sample_configs.full)
	end, "Should accept full valid configuration")

	test_utils.assert_equal("/tmp/test_pkm", config.options.pkm_dir, "Should set custom pkm_dir")
	test_utils.assert_equal(20, config.options.frontmatter.scan_lines, "Should set custom scan_lines")
	test_utils.assert_equal(12, config.options.templates.quick.id_length, "Should set custom id_length")
end

local function test_missing_pkm_dir()
	test_utils.assert_error(function()
		config.setup(sample_configs.invalid.missing_pkm_dir)
	end, "pkm_dir.*required", "Should require pkm_dir")
end

local function test_invalid_pkm_dir_type()
	test_utils.assert_error(function()
		config.setup(sample_configs.invalid.invalid_pkm_dir_type)
	end, "Invalid type.*pkm_dir", "Should validate pkm_dir type")
end

local function test_invalid_template_type()
	test_utils.assert_error(function()
		config.setup(sample_configs.invalid.invalid_template_type)
	end, "Expected.*function or table", "Should validate template type")
end

local function test_invalid_frontmatter_fields()
	test_utils.assert_error(function()
		config.setup(sample_configs.invalid.invalid_frontmatter_fields)
	end, "Unknown field.*invalid_field", "Should validate frontmatter field names")
end

local function test_invalid_scan_lines_range()
	test_utils.assert_error(function()
		config.setup(sample_configs.invalid.invalid_scan_lines)
	end, "between 1 and 100", "Should validate scan_lines range")
end

local function test_invalid_id_length_range()
	test_utils.assert_error(function()
		config.setup(sample_configs.invalid.invalid_id_length)
	end, "between 4 and 32", "Should validate id_length range")
end

local function test_function_template_validation()
	test_utils.assert_no_error(function()
		config.setup(sample_configs.function_template)
	end, "Should accept function templates")
end

local function test_object_template_validation()
	test_utils.assert_no_error(function()
		config.setup(sample_configs.object_template)
	end, "Should accept object templates")
end

local function test_file_template_validation()
	test_utils.assert_no_error(function()
		config.setup(sample_configs.file_template)
	end, "Should accept file templates")
end

local function test_array_template_validation()
	reset_config()
	local array_config = {
		pkm_dir = "/tmp/test_pkm",
		templates = {
			daily = { "Section 1", "Section 2" },
		},
	}

	test_utils.assert_no_error(function()
		config.setup(array_config)
	end, "Should accept array templates")
end

local function test_invalid_array_template()
	local invalid_array_config = {
		pkm_dir = "/tmp/test_pkm",
		templates = {
			daily = { [1] = "Section 1", [3] = "Section 3" }, -- Non-consecutive keys
		},
	}

	test_utils.assert_error(function()
		config.setup(invalid_array_config)
	end, "Expected array", "Should reject invalid array structure")
end

local function test_template_section_validation()
	local invalid_section_config = {
		pkm_dir = "/tmp/test_pkm",
		templates = {
			daily = {
				sections = {
					{ title = "Valid Section" },
					{ title = 123 }, -- Invalid title type
				},
			},
		},
	}

	test_utils.assert_error(function()
		config.setup(invalid_section_config)
	end, "Expected string", "Should validate section title type")
end

local function test_boolean_field_validation()
	local invalid_boolean_config = {
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			use_frontmatter = "yes", -- Should be boolean
		},
	}

	test_utils.assert_error(function()
		config.setup(invalid_boolean_config)
	end, "Expected boolean", "Should validate boolean fields")
end

local function test_error_message_format()
	local success, error_msg = pcall(function()
		config.setup({})
	end)

	test_utils.assert_false(success, "Should fail validation")
	test_utils.assert_matches("notes%.nvim:", error_msg, "Error should have plugin prefix")
	test_utils.assert_matches("pkm_dir.*required", error_msg, "Error should mention missing field")
end

-- Run all tests
local tests = {
	["accept minimal valid config"] = test_minimal_valid_config,
	["accept full valid config"] = test_full_valid_config,
	["require pkm_dir"] = test_missing_pkm_dir,
	["validate pkm_dir type"] = test_invalid_pkm_dir_type,
	["validate template type"] = test_invalid_template_type,
	["validate frontmatter fields"] = test_invalid_frontmatter_fields,
	["validate scan_lines range"] = test_invalid_scan_lines_range,
	["validate id_length range"] = test_invalid_id_length_range,
	["accept function templates"] = test_function_template_validation,
	["accept object templates"] = test_object_template_validation,
	["accept file templates"] = test_file_template_validation,
	["accept array templates"] = test_array_template_validation,
	["reject invalid arrays"] = test_invalid_array_template,
	["validate template sections"] = test_template_section_validation,
	["validate boolean fields"] = test_boolean_field_validation,
	["format error messages"] = test_error_message_format,
}

local passed, total = test_utils.run_test_suite("Configuration Validation Tests", tests)

vim_mocks.cleanup()

return { passed = passed, total = total }

