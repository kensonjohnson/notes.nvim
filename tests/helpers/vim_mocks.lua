-- Vim API mocks for testing

local M = {}

-- Setup comprehensive vim mocks for testing
function M.setup()
	_G.vim = {
		fn = {
			isdirectory = function(path)
				-- Mock: /tmp and paths containing 'test' exist
				if type(path) ~= "string" then
					return 0
				end
				return (path == "/tmp" or path:match("test")) and 1 or 0
			end,
			expand = function(path)
				-- Mock tilde expansion
				if type(path) ~= "string" then
					return tostring(path)
				end
				if path:match("^~/") then
					return "/home/user" .. path:sub(2)
				end
				return path
			end,
			fnamemodify = function(path)
				-- Simple mock - just return path
				if type(path) ~= "string" then
					return tostring(path)
				end
				return path
			end,
			filereadable = function(path)
				-- Mock: template files are readable
				return path:match("template") and 1 or 0
			end,
			readfile = function(path)
				-- Mock template file content
				if path:match("template") then
					return {
						"# {{weekday}}, {{month_name}} {{day}}, {{year}}",
						"",
						"## Test Section",
						"Content: {{user_name}}",
					}
				end
				return {}
			end,
			writefile = function(lines, path)
				-- Mock file writing - store in global for testing
				_G._test_written_files = _G._test_written_files or {}
				_G._test_written_files[path] = lines
				return 0
			end,
			fnameescape = function(path)
				return path
			end,
			has = function(feature)
				-- Mock: not Windows
				return feature == "win32" and 0 or 1
			end,
			mkdir = function(path, mode)
				-- Mock directory creation
				_G._test_created_dirs = _G._test_created_dirs or {}
				table.insert(_G._test_created_dirs, path)
				return 0
			end,
		},
		api = {
			nvim_create_augroup = function(name, opts)
				return 1
			end,
			nvim_create_autocmd = function(event, opts)
				return 1
			end,
			nvim_create_user_command = function(name, command, opts) end,
		},
		tbl_deep_extend = function(behavior, ...)
			local result = {}
			for i = 1, select("#", ...) do
				local tbl = select(i, ...)
				if tbl then
					for k, v in pairs(tbl) do
						if type(v) == "table" and type(result[k]) == "table" then
							result[k] = vim.tbl_deep_extend(behavior, result[k], v)
						else
							result[k] = v
						end
					end
				end
			end
			return result
		end,
		log = {
			levels = { ERROR = 1, WARN = 2, INFO = 3 },
		},
		notify = function(message, level)
			-- Store notifications for testing
			_G._test_notifications = _G._test_notifications or {}
			table.insert(_G._test_notifications, { message = message, level = level })
		end,
		cmd = function(cmd)
			-- Store commands for testing
			_G._test_commands = _G._test_commands or {}
			table.insert(_G._test_commands, cmd)
		end,
	}

	-- Mock os.getenv
	local original_getenv = os.getenv
	os.getenv = function(var)
		if var == "USER" then
			return "testuser"
		end
		return original_getenv(var)
	end
end

-- Clean up test globals
function M.cleanup()
	_G._test_written_files = nil
	_G._test_created_dirs = nil
	_G._test_notifications = nil
	_G._test_commands = nil
end

-- Get test data for assertions
function M.get_written_files()
	return _G._test_written_files or {}
end

function M.get_created_dirs()
	return _G._test_created_dirs or {}
end

function M.get_notifications()
	return _G._test_notifications or {}
end

function M.get_commands()
	return _G._test_commands or {}
end

return M

