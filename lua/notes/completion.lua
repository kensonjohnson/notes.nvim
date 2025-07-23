-- Command completion utilities for notes.nvim plugin

local M = {}

-- Generate dynamic completion suggestions for date inputs
function M.get_date_completions(arg_lead)
	local completions = {}

	-- Basic relative dates
	local basic_dates = { "today", "tomorrow", "yesterday" }
	for _, date in ipairs(basic_dates) do
		table.insert(completions, date)
	end

	-- Number offsets (days from today)
	for i = 1, 7 do
		table.insert(completions, tostring(i))
		table.insert(completions, tostring(-i))
	end

	-- Current year date examples
	local current_year = os.date("%Y")
	local current_month = os.date("%m")
	local current_day = os.date("%d")

	-- Add some example dates for current year
	table.insert(completions, current_year .. "-" .. current_month .. "-" .. current_day)
	table.insert(completions, current_year .. "-12-25") -- Christmas
	table.insert(completions, current_year .. "-01-01") -- New Year

	-- Weekday completions (next/last + weekday)
	local weekdays = { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" }
	for _, day in ipairs(weekdays) do
		table.insert(completions, "next " .. day)
		table.insert(completions, "last " .. day)
	end

	-- US date format examples
	local us_month = tonumber(current_month)
	local us_day = tonumber(current_day)
	table.insert(completions, us_month .. "/" .. us_day .. "/" .. current_year)
	table.insert(completions, "12/25/" .. current_year)

	-- Filter completions based on user input
	if arg_lead and arg_lead ~= "" then
		return M.filter_completions(completions, arg_lead)
	end

	return completions
end

-- Escape special pattern characters for Lua pattern matching
local function escape_pattern(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

-- Filter completions based on user input with fuzzy matching
function M.filter_completions(completions, arg_lead)
	local filtered = {}
	local arg_lower = arg_lead:lower()
	local escaped_arg = escape_pattern(arg_lower)

	for _, completion in ipairs(completions) do
		local comp_lower = completion:lower()

		-- Exact prefix match (highest priority)
		if comp_lower:find("^" .. escaped_arg) then
			table.insert(filtered, completion)
		-- Contains match (lower priority)
		elseif comp_lower:find(escaped_arg) then
			table.insert(filtered, completion)
		end
	end

	-- Sort filtered results: exact prefix matches first
	table.sort(filtered, function(a, b)
		local a_lower = a:lower()
		local b_lower = b:lower()
		local a_prefix = a_lower:find("^" .. escaped_arg) ~= nil
		local b_prefix = b_lower:find("^" .. escaped_arg) ~= nil

		if a_prefix and not b_prefix then
			return true
		elseif not a_prefix and b_prefix then
			return false
		else
			return a < b
		end
	end)

	return filtered
end

-- Generate completion suggestions for DailyNote command
function M.daily_note_complete(arg_lead, cmd_line, cursor_pos)
	return M.get_date_completions(arg_lead)
end

return M

