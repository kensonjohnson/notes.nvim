-- Configuration module for notes.nvim plugin

local errors = require("notes.errors")
local M = {}

-- Default configuration
M.defaults = {
	pkm_dir = nil, -- REQUIRED: Must be set by user

	frontmatter = {
		use_frontmatter = true,
		auto_update_modified = true,
		scan_lines = 20,
		fields = {
			id = true,
			created = true,
			modified = true,
			tags = true,
		},
	},
	templates = {
		daily = {
			sections = { "Tasks", "Blockers", "Impact" },
			tags = "[#daily]",
		},
		quick = {
			tags = "[]",
			id_length = 8,
		},
	},
}

-- Current configuration (will be merged with user config)
M.options = {}

-- Setup function to merge user config with defaults
function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})

	-- Expand the pkm_dir path if provided
	if M.options.pkm_dir then
		local utils = require("notes.utils")
		M.options.pkm_dir = utils.expand_path(M.options.pkm_dir)
	end

	-- Validate required configuration
	M.validate()
end

-- Validation helper functions using centralized error handling
local function validate_type(value, expected_type, path)
	if type(value) ~= expected_type then
		errors.type_error(path, expected_type, type(value))
	end
end

local function validate_number_range(value, min, max, path)
	validate_type(value, "number", path)
	if value < min or value > max then
		errors.range_error(path, min, max, value)
	end
end

local function validate_string_not_empty(value, path)
	validate_type(value, "string", path)
	if value == "" then
		errors.empty_string_error(path)
	end
end

local function validate_array(value, path)
	validate_type(value, "table", path)
	-- Check if it's an array (consecutive integer keys starting from 1)
	local count = 0
	for k, v in pairs(value) do
		count = count + 1
		if type(k) ~= "number" or k ~= count then
			errors.array_structure_error(path)
		end
		if type(v) ~= "string" then
			errors.type_error(path .. "[" .. k .. "]", "string", type(v))
		end
	end
end

-- Validate frontmatter configuration
local function validate_frontmatter(frontmatter)
	if not frontmatter then
		return
	end
	validate_type(frontmatter, "table", "frontmatter")

	-- Validate boolean fields
	local boolean_fields = { "use_frontmatter", "auto_update_modified" }
	for _, field in ipairs(boolean_fields) do
		if frontmatter[field] ~= nil then
			validate_type(frontmatter[field], "boolean", "frontmatter." .. field)
		end
	end

	-- Validate scan_lines
	if frontmatter.scan_lines ~= nil then
		validate_number_range(frontmatter.scan_lines, 1, 100, "frontmatter.scan_lines")
	end

	-- Validate fields table
	if frontmatter.fields ~= nil then
		validate_type(frontmatter.fields, "table", "frontmatter.fields")
		local valid_fields = { "id", "created", "modified", "tags" }
		for field, enabled in pairs(frontmatter.fields) do
			if type(field) ~= "string" then
				errors.type_error("frontmatter.fields key", "string", type(field))
			end

			local is_valid_field = false
			for _, valid_field in ipairs(valid_fields) do
				if field == valid_field then
					is_valid_field = true
					break
				end
			end

			if not is_valid_field then
				errors.unknown_field_error(field, "frontmatter.fields", valid_fields)
			end

			validate_type(enabled, "boolean", "frontmatter.fields." .. field)
		end
	end
end

-- Validate template configuration
local function validate_templates(templates)
	if not templates then
		return
	end
	validate_type(templates, "table", "templates")

	-- Validate daily template
	if templates.daily then
		validate_type(templates.daily, "table", "templates.daily")

		if templates.daily.sections ~= nil then
			validate_array(templates.daily.sections, "templates.daily.sections")
		end

		if templates.daily.tags ~= nil then
			validate_string_not_empty(templates.daily.tags, "templates.daily.tags")
		end
	end

	-- Validate quick template
	if templates.quick then
		validate_type(templates.quick, "table", "templates.quick")

		if templates.quick.tags ~= nil then
			validate_type(templates.quick.tags, "string", "templates.quick.tags")
		end

		if templates.quick.id_length ~= nil then
			validate_number_range(templates.quick.id_length, 4, 32, "templates.quick.id_length")
		end
	end
end

-- Main validation function
function M.validate()
	-- Validate required pkm_dir
	if not M.options.pkm_dir then
		errors.required_config_error("pkm_dir", "require('notes').setup({ pkm_dir = '/path/to/your/pkm' })")
	end

	validate_string_not_empty(M.options.pkm_dir, "pkm_dir")

	if not vim.fn.isdirectory(M.options.pkm_dir) then
		errors.directory_not_found_error(M.options.pkm_dir)
	end

	-- Validate other configuration sections
	validate_frontmatter(M.options.frontmatter)
	validate_templates(M.options.templates)
end

return M
