-- Date parsing and manipulation module for notes.nvim plugin

local M = {}

-- Constants
local SECONDS_PER_DAY = 24 * 60 * 60

-- Parse date input and return a timestamp
-- Accepts: integers (days offset), date strings, or nil (today)
function M.parse_date_input(input)
	if not input then
		-- No input = today
		return os.time(), nil
	end

	-- Convert to string if it's a number
	local input_str = tostring(input)

	-- Check if it's an integer (positive or negative)
	local days_offset = tonumber(input_str)
	if days_offset then
		-- Integer input: add/subtract days from today
		local today = os.time()
		local target_timestamp = today + (days_offset * SECONDS_PER_DAY)
		return target_timestamp, nil
	end

	-- Try to parse as date string
	local timestamp = M.parse_date_string(input_str)
	if timestamp then
		return timestamp, nil
	end

	-- If we get here, the input is invalid
	return nil, "Invalid date input: " .. input_str
end

-- Parse various date string formats
function M.parse_date_string(date_str)
	-- Remove extra whitespace
	date_str = date_str:gsub("^%s*(.-)%s*$", "%1")

	-- Try ISO format: YYYY-MM-DD
	local year, month, day = date_str:match("^(%d%d%d%d)-(%d%d?)-(%d%d?)$")
	if year and month and day then
		return M.create_timestamp(tonumber(year), tonumber(month), tonumber(day))
	end

	-- Try US format: MM/DD/YYYY
	month, day, year = date_str:match("^(%d%d?)/(%d%d?)/(%d%d%d%d)$")
	if year and month and day then
		return M.create_timestamp(tonumber(year), tonumber(month), tonumber(day))
	end

	-- Try short US format: MM/DD/YY
	month, day, year = date_str:match("^(%d%d?)/(%d%d?)/(%d%d)$")
	if year and month and day then
		-- Convert 2-digit year to 4-digit (assume 20xx)
		local full_year = 2000 + tonumber(year)
		return M.create_timestamp(full_year, tonumber(month), tonumber(day))
	end

	-- Try relative dates
	local relative_timestamp = M.parse_relative_date(date_str)
	if relative_timestamp then
		return relative_timestamp
	end

	-- Could not parse
	return nil
end

-- Parse relative date strings like "tomorrow", "yesterday", etc.
function M.parse_relative_date(date_str)
	local lower_str = date_str:lower()
	local today = os.time()

	if lower_str == "today" then
		return today
	elseif lower_str == "tomorrow" then
		return today + SECONDS_PER_DAY
	elseif lower_str == "yesterday" then
		return today - SECONDS_PER_DAY
	end

	-- Parse "next/last weekday" patterns
	local direction, weekday = lower_str:match("^(next)%s+(%w+)$")
	if not direction then
		direction, weekday = lower_str:match("^(last)%s+(%w+)$")
	end

	if direction and weekday then
		local weekday_timestamp = M.get_weekday_timestamp(weekday, direction == "next")
		if weekday_timestamp then
			return weekday_timestamp
		end
	end

	return nil
end

-- Create timestamp from year, month, day
function M.create_timestamp(year, month, day)
	-- Validate the date
	if not M.is_valid_date(year, month, day) then
		return nil
	end

	-- Create the timestamp for noon on that day to avoid timezone issues
	local date_table = {
		year = year,
		month = month,
		day = day,
		hour = 12,
		min = 0,
		sec = 0,
	}

	return os.time(date_table)
end

-- Validate that a date is valid
function M.is_valid_date(year, month, day)
	if not year or not month or not day then
		return false
	end

	if year < 1900 or year > 2100 then
		return false
	end

	if month < 1 or month > 12 then
		return false
	end

	if day < 1 or day > 31 then
		return false
	end

	-- Check days in month
	local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

	-- Handle leap years
	if M.is_leap_year(year) then
		days_in_month[2] = 29
	end

	if day > days_in_month[month] then
		return false
	end

	return true
end

-- Check if a year is a leap year
function M.is_leap_year(year)
	return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

-- Add days to a timestamp
function M.add_days(timestamp, days)
	return timestamp + (days * SECONDS_PER_DAY)
end

-- Get a human-readable description of a date relative to today
function M.get_relative_description(timestamp)
	local today = os.time()
	local diff_seconds = timestamp - today
	local diff_days = math.floor(diff_seconds / SECONDS_PER_DAY)

	if diff_days == 0 then
		return "today"
	elseif diff_days == 1 then
		return "tomorrow"
	elseif diff_days == -1 then
		return "yesterday"
	elseif diff_days > 0 then
		return diff_days .. " days from now"
	else
		return math.abs(diff_days) .. " days ago"
	end
end

-- Get timestamp for next/last occurrence of a weekday
function M.get_weekday_timestamp(weekday_name, is_next)
	local weekday_map = {
		monday = 2,
		tuesday = 3,
		wednesday = 4,
		thursday = 5,
		friday = 6,
		saturday = 7,
		sunday = 1,
		mon = 2,
		tue = 3,
		wed = 4,
		thu = 5,
		fri = 6,
		sat = 7,
		sun = 1,
	}

	local target_weekday = weekday_map[weekday_name:lower()]
	if not target_weekday then
		return nil
	end

	local today = os.time()
	local today_weekday = tonumber(os.date("%w", today)) -- 0=Sunday, 1=Monday, etc.

	-- Convert to our format (1=Sunday, 2=Monday, etc.)
	if today_weekday == 0 then
		today_weekday = 1
	else
		today_weekday = today_weekday + 1
	end

	local days_diff
	if is_next then
		-- Find next occurrence
		if target_weekday > today_weekday then
			days_diff = target_weekday - today_weekday
		else
			days_diff = 7 - (today_weekday - target_weekday)
		end
	else
		-- Find last occurrence
		if target_weekday < today_weekday then
			days_diff = -(today_weekday - target_weekday)
		else
			days_diff = -(7 - (target_weekday - today_weekday))
		end
	end

	return today + (days_diff * SECONDS_PER_DAY)
end

return M
