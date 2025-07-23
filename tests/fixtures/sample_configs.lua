-- Sample configurations for testing

local M = {}

-- Minimal valid configuration
M.minimal = {
	pkm_dir = "/tmp/test_pkm",
}

-- Full configuration with all options
M.full = {
	pkm_dir = "/tmp/test_pkm",
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
		daily = { "Goals", "Log", "Reflection" }, -- Simple array template
		quick = {
			tags = "[#quick]",
			id_length = 12,
		},
	},
}

-- Configuration with function template
M.function_template = {
	pkm_dir = "/tmp/test_pkm",
	templates = {
		daily = function(context)
			local sections = { "## Today's Goals" }
			if context.is_monday then
				table.insert(sections, "## Weekly Planning")
			end
			table.insert(sections, "## Notes")
			return sections
		end,
	},
}

-- Configuration with object template
M.object_template = {
	pkm_dir = "/tmp/test_pkm",
	templates = {
		daily = {
			header = "# {{weekday}} Focus - {{month_name}} {{day}}",
			sections = {
				{ title = "Priority", content = "" },
				{ title = "Notes", content = "" },
				{
					title = "Weekend Plans",
					condition = "is_friday",
					content = { "- Plan weekend activities", "- Review week" },
				},
			},
			footer = "---\nCreated: {{timestamp}}",
		},
	},
}

-- Configuration with file template
M.file_template = {
	pkm_dir = "/tmp/test_pkm",
	templates = {
		daily = { file = "/tmp/test_template.md" },
	},
}

-- Invalid configurations for testing validation
M.invalid = {
	-- Missing pkm_dir
	missing_pkm_dir = {},

	-- Invalid pkm_dir type
	invalid_pkm_dir_type = {
		pkm_dir = 123,
	},

	-- Invalid template type
	invalid_template_type = {
		pkm_dir = "/tmp/test_pkm",
		templates = {
			daily = 123,
		},
	},

	-- Invalid frontmatter fields
	invalid_frontmatter_fields = {
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			fields = {
				invalid_field = true,
			},
		},
	},

	-- Invalid scan_lines range
	invalid_scan_lines = {
		pkm_dir = "/tmp/test_pkm",
		frontmatter = {
			scan_lines = 150,
		},
	},

	-- Invalid id_length range
	invalid_id_length = {
		pkm_dir = "/tmp/test_pkm",
		templates = {
			quick = {
				id_length = 100,
			},
		},
	},
}

return M

