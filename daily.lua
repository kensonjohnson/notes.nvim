-- Daily notes functionality for notes-nvim plugin

local utils = require('notes-nvim.utils')
local dates = require('notes-nvim.dates')

local M = {}

-- Core function to create daily note for a given timestamp
function M.create_daily_note_for_timestamp(timestamp, config)
  local main_note_dir = utils.join_path(config.pkm_dir, 'Daily')

  -- Get date components for the given timestamp
  local year = os.date('%Y', timestamp)
  local month_num = os.date('%m', timestamp)
  local month_abbr = os.date('%b', timestamp)
  local day = os.date('%d', timestamp)
  local weekday = os.date('%A', timestamp)

  -- Construct the directory structure and filename
  local note_dir = utils.join_path(main_note_dir, year, month_num .. '-' .. month_abbr)
  local note_name = year .. '-' .. month_num .. '-' .. day .. '-' .. weekday
  local full_path = utils.join_path(note_dir, note_name .. '.md')

  -- Ensure directory exists
  utils.ensure_dir(note_dir)

  -- Create the daily note if it doesn't exist
  if vim.fn.filereadable(full_path) == 0 then
    local frontmatter = utils.generate_frontmatter(note_name, config.templates.daily.tags, config)
    
    local template = {}
    -- Add frontmatter
    for _, line in ipairs(frontmatter) do
      table.insert(template, line)
    end
    
    -- Add content header
    table.insert(template, '# ' .. weekday .. ', ' .. month_abbr .. ' ' .. day .. ', ' .. year)
    table.insert(template, '')
    
    -- Add sections from config
    for _, section in ipairs(config.templates.daily.sections) do
      table.insert(template, '## ' .. section)
      table.insert(template, '')
    end
    
    vim.fn.writefile(template, full_path)
  end

  -- Change to PKM directory and open the file
  vim.cmd('cd ' .. config.pkm_dir)
  vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
end

-- Dynamic daily note function - accepts date input
function M.dynamic_daily_note(input, config)
  local timestamp, error_msg = dates.parse_date_input(input)
  
  if not timestamp then
    vim.notify("Error: " .. (error_msg or "Invalid date input"), vim.log.levels.ERROR)
    return
  end
  
  -- Show user what date we're opening
  local description = dates.get_relative_description(timestamp)
  local date_str = os.date('%A, %B %d, %Y', timestamp)
  vim.notify("Opening daily note for " .. date_str .. " (" .. description .. ")")
  
  M.create_daily_note_for_timestamp(timestamp, config)
end

-- Today's daily note
function M.daily_note(config)
  M.create_daily_note_for_timestamp(os.time(), config)
end

-- Tomorrow's daily note
function M.tomorrow_note(config)
  local tomorrow_timestamp = os.time() + 24 * 60 * 60
  M.create_daily_note_for_timestamp(tomorrow_timestamp, config)
end

-- Quick note function
function M.quick_note(config)
  local inbox_dir = utils.join_path(config.pkm_dir, '+Inbox')

  -- Generate a random filename (8 characters)
  local random_name = utils.create_id(8)
  local full_path = utils.join_path(inbox_dir, random_name .. '.md')

  -- Ensure inbox directory exists
  utils.ensure_dir(inbox_dir)

  -- Create the note file with template
  local frontmatter = utils.generate_frontmatter(random_name, config.templates.quick.tags, config)
  
  local template = {}
  -- Add frontmatter
  for _, line in ipairs(frontmatter) do
    table.insert(template, line)
  end
  
  -- Add content
  vim.list_extend(template, {
    '# ' .. random_name,
    '',
  })
  
  vim.fn.writefile(template, full_path)

  -- Change to PKM directory and open the file
  vim.cmd('cd ' .. config.pkm_dir)
  vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
end

return M
