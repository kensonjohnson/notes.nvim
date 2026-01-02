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
		overwrite_frontmatter = false,
		fields = {
			id = true,
			created = true,
			modified = true,
			tags = true,
		},
	},
	templates = {
		daily = {},
		quick = {
			id_length = 8,
		},
	},
}

-- Current configuration (will be merged with user config)
M.options = {}

-- Setup function to merge user config with defaults
function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})

	-- Validate required configuration first
	M.validate()

	-- Expand the pkm_dir path after validation
	if M.options.pkm_dir then
		local utils = require("notes.utils")
		M.options.pkm_dir = utils.expand_path(M.options.pkm_dir)
	end
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

-- Validate template section configuration
local function validate_template_section(section, path)
	validate_type(section, "table", path)

	if section.title then
		validate_type(section.title, "string", path .. ".title")
	end

	if section.content then
		if type(section.content) ~= "string" and type(section.content) ~= "table" then
			errors.type_error(path .. ".content", "string or table", type(section.content))
		end
	end

	if section.condition then
		if type(section.condition) ~= "string" and type(section.condition) ~= "function" then
			errors.type_error(path .. ".condition", "string or function", type(section.condition))
		end
	end
end

-- Validate individual template configuration
local function validate_template_config(template, path)
	-- Template can be a function, table, or nil
	if template == nil then
		return
	end

	if type(template) == "function" then
		-- Function templates are always valid (will be validated at runtime)
		return
	end

	if type(template) ~= "table" then
		errors.type_error(path, "function or table", type(template))
	end

	-- Determine template type and validate accordingly
	if template.file then
		-- File-based template
		validate_type(template.file, "string", path .. ".file")
		-- File templates can have additional properties like tags
		if template.tags then
			validate_type(template.tags, "string", path .. ".tags")
		end
	elseif template.sections then
		-- Object-based template with sections
		validate_type(template.sections, "table", path .. ".sections")
		for i, section in ipairs(template.sections) do
			validate_template_section(section, path .. ".sections[" .. i .. "]")
		end
		-- Object templates can have additional properties
		if template.header then
			validate_type(template.header, "string", path .. ".header")
		end
		if template.footer then
			validate_type(template.footer, "string", path .. ".footer")
		end
		if template.tags then
			validate_type(template.tags, "string", path .. ".tags")
		end
	elseif template[1] then
		-- Array-based template - should ONLY contain array elements
		validate_array(template, path)
		-- Array templates should not have other properties mixed in
	else
		-- Configuration-only template (just tags, id_length, etc.)
		-- This is valid - just validate the properties
		if template.tags then
			validate_type(template.tags, "string", path .. ".tags")
		end
		if template.header then
			validate_type(template.header, "string", path .. ".header")
		end
		if template.footer then
			validate_type(template.footer, "string", path .. ".footer")
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
		validate_template_config(templates.daily, "templates.daily")
	end

	-- Validate quick template
	if templates.quick then
		validate_template_config(templates.quick, "templates.quick")

		-- Validate quick-specific options
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
