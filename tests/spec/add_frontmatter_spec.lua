-- Add frontmatter functionality tests

-- Setup path and mocks
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local vim_mocks = require("tests.helpers.vim_mocks")
local test_utils = require("tests.helpers.test_utils")

vim_mocks.setup()

-- Mock buffer for testing
local mock_buffer = {}
local mock_buffer_lines = {}

-- Add buffer API mocks
vim.api.nvim_get_current_buf = function()
	return 1
end

vim.api.nvim_buf_get_lines = function(buf, start, end_line, strict)
	local lines = {}
	for i = start + 1, (end_line == -1 and #mock_buffer_lines or end_line) do
		if mock_buffer_lines[i] then
			table.insert(lines, mock_buffer_lines[i])
		end
	end
	return lines
end

vim.api.nvim_buf_set_lines = function(buf, start, end_line, strict, lines)
	-- nvim uses 0-based indexing, Lua uses 1-based
	-- start is 0-based, inclusive
	-- end_line is 0-based, exclusive
	
	-- Remove lines from start to end (convert to 1-based)
	for i = end_line, start + 1, -1 do
		table.remove(mock_buffer_lines, i)
	end
	
	-- Insert new lines at start position (convert to 1-based)
	for i = #lines, 1, -1 do
		table.insert(mock_buffer_lines, start + 1, lines[i])
	end
end

local function reset_buffer(initial_lines)
	mock_buffer_lines = {}
	if initial_lines then
		for _, line in ipairs(initial_lines) do
			table.insert(mock_buffer_lines, line)
		end
	end
end

local function get_buffer_lines()
	-- Simple copy of lines table
	local copy = {}
	for i, line in ipairs(mock_buffer_lines) do
		copy[i] = line
	end
	return copy
end

local utils = require("notes.utils")
local config = require("notes.config")

local function test_add_frontmatter_to_buffer_without_frontmatter()
	reset_buffer({ "# My Note", "", "Some content here" })

	config.setup({
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			overwrite_frontmatter = false,
		},
	})

	utils.add_frontmatter_to_current_buffer(config.options)

	local lines = get_buffer_lines()
	test_utils.assert_equal("---", lines[1], "Should start with frontmatter delimiter")
	test_utils.assert_matches("^id: %w+", lines[2], "Should have ID field")
	test_utils.assert_matches("^created: %d%d%d%d%-", lines[3], "Should have created timestamp")
	test_utils.assert_matches("^modified: %d%d%d%d%-", lines[4], "Should have modified timestamp")
	test_utils.assert_equal("tags: []", lines[5], "Should have empty tags")
	test_utils.assert_equal("---", lines[6], "Should close frontmatter")
	test_utils.assert_equal("", lines[7], "Should have blank line after frontmatter")
	test_utils.assert_equal("# My Note", lines[8], "Should preserve original content")
end

local function test_preserves_existing_content()
	reset_buffer({ "Line 1", "Line 2", "Line 3" })

	config.setup({
		pkm_dir = "/tmp/test_pkm",
	})

	utils.add_frontmatter_to_current_buffer(config.options)

	local lines = get_buffer_lines()
	-- Find where content starts (after frontmatter)
	local content_start = 8 -- After: ---, id, created, modified, tags, ---, blank line
	test_utils.assert_equal("Line 1", lines[content_start], "Should preserve first line")
	test_utils.assert_equal("Line 2", lines[content_start + 1], "Should preserve second line")
	test_utils.assert_equal("Line 3", lines[content_start + 2], "Should preserve third line")
end

local function test_error_when_frontmatter_exists_and_no_overwrite()
	reset_buffer({
		"---",
		"id: existing-id",
		"created: 2025-01-01T00:00:00",
		"---",
		"",
		"Content",
	})

	config.setup({
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			overwrite_frontmatter = false,
		},
	})

	-- Clear previous notifications
	_G._test_notifications = {}

	utils.add_frontmatter_to_current_buffer(config.options)

	-- Check that error notification was sent
	local notifications = vim_mocks.get_notifications()
	test_utils.assert_true(#notifications > 0, "Should send notification")
	test_utils.assert_matches("already exists", notifications[1].message, "Should mention existing frontmatter")

	-- Verify buffer wasn't modified
	local lines = get_buffer_lines()
	test_utils.assert_equal("existing-id", lines[2]:match("id: (.+)"), "Should not change existing ID")
end

local function test_replaces_frontmatter_when_overwrite_enabled()
	reset_buffer({
		"---",
		"id: old-id",
		"created: 2020-01-01T00:00:00",
		"modified: 2020-01-01T00:00:00",
		"tags: [#old]",
		"---",
		"",
		"Content here",
	})

	config.setup({
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			overwrite_frontmatter = true,
		},
	})

	utils.add_frontmatter_to_current_buffer(config.options)

	local lines = get_buffer_lines()
	test_utils.assert_equal("---", lines[1], "Should start with frontmatter delimiter")
	
	-- Verify old ID is replaced with new random ID
	local new_id = lines[2]:match("id: (.+)")
	test_utils.assert_false(new_id == "old-id", "Should generate new ID")
	test_utils.assert_matches("^%w+$", new_id, "New ID should be alphanumeric")
	
	-- Verify tags are reset to empty
	test_utils.assert_equal("tags: []", lines[5], "Should reset to empty tags")
	
	-- Verify content is preserved
	-- Original buffer: --- id created modified tags --- blank Content (8 lines)
	-- After removing frontmatter (lines 1-6): blank Content (2 lines)
	-- After adding new frontmatter (7 lines): --- id created modified tags --- blank blank Content
	-- Content should be at line 9
	test_utils.assert_not_nil(lines[9], "Should have content preserved")
	if lines[9] then
		test_utils.assert_equal("Content here", lines[9], "Should preserve content after frontmatter")
	end
end

local function test_incomplete_frontmatter_handled()
	reset_buffer({
		"---",
		"id: incomplete",
		"Some content without closing delimiter",
	})

	config.setup({
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			overwrite_frontmatter = false,
		},
	})

	-- Should not detect this as valid frontmatter since there's no closing ---
	-- Therefore it should add frontmatter
	utils.add_frontmatter_to_current_buffer(config.options)

	local lines = get_buffer_lines()
	test_utils.assert_equal("---", lines[1], "Should add frontmatter at start")
	test_utils.assert_matches("^id: %w+", lines[2], "Should have new ID field")
end

-- Run all tests
local tests = {
	["add frontmatter to buffer without frontmatter"] = test_add_frontmatter_to_buffer_without_frontmatter,
	["preserve existing content"] = test_preserves_existing_content,
	["error when frontmatter exists and no overwrite"] = test_error_when_frontmatter_exists_and_no_overwrite,
	["replace frontmatter when overwrite enabled"] = test_replaces_frontmatter_when_overwrite_enabled,
	["handle incomplete frontmatter"] = test_incomplete_frontmatter_handled,
}

local passed, total = test_utils.run_test_suite("Add Frontmatter Tests", tests)

vim_mocks.cleanup()

return { passed = passed, total = total }
