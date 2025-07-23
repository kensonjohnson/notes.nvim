-- Utility functions for notes.nvim plugin

local M = {}

-- Helper function to ensure directory exists
function M.ensure_dir(path)
  vim.fn.mkdir(path, 'p')
end

-- Helper function to expand paths (handle ~ and environment variables)
function M.expand_path(path)
  if not path then return nil end
  
  -- Handle tilde expansion and environment variables (cross-platform)
  path = vim.fn.expand(path)
  
  -- Convert to absolute path with correct separators
  return vim.fn.fnamemodify(path, ':p')
end

-- Cross-platform path joining function
function M.join_path(...)
  local parts = {...}
  local separator = vim.fn.has('win32') == 1 and '\\' or '/'
  return table.concat(parts, separator)
end

-- Helper function to generate random alphanumeric string for IDs
function M.create_id(length)
  local chars = '0123456789abcdefghijklmnopqrstuvwxyz'
  local result = ''
  for _ = 1, length do
    local rand_index = math.random(1, #chars)
    result = result .. chars:sub(rand_index, rand_index)
  end
  return result
end

-- Helper function to get current timestamp in ISO format
function M.get_timestamp()
  return os.date('%Y-%m-%dT%H:%M:%S')
end

-- Helper function to check if file is in PKM directory
function M.is_pkm_file(filepath, pkm_dir)
  if not filepath then return false end
  -- Normalize path separators and convert to lowercase for comparison
  local normalized_path = filepath:gsub('/', '\\'):lower()
  local normalized_pkm = pkm_dir:lower()
  return normalized_path:find(normalized_pkm, 1, true) == 1
end

-- Helper function to generate frontmatter
function M.generate_frontmatter(id, tags, config)
  if not config.frontmatter.use_frontmatter then
    return {}
  end
  
  local frontmatter = { '---' }
  local timestamp = M.get_timestamp()
  
  if config.frontmatter.fields.id then
    table.insert(frontmatter, 'id: ' .. id)
  end
  
  if config.frontmatter.fields.created then
    table.insert(frontmatter, 'created: ' .. timestamp)
  end
  
  if config.frontmatter.fields.modified then
    table.insert(frontmatter, 'modified: ' .. timestamp)
  end
  
  if config.frontmatter.fields.tags then
    local tags_str = tags or '[]'
    table.insert(frontmatter, 'tags: ' .. tags_str)
  end
  
  table.insert(frontmatter, '---')
  table.insert(frontmatter, '')
  
  return frontmatter
end

-- Helper function to update modified timestamp in frontmatter
function M.update_modified_timestamp(config)
  if not config.frontmatter.auto_update_modified then return end
  
  local filepath = vim.fn.expand('%:p')
  if not M.is_pkm_file(filepath, config.pkm_dir) then return end
  
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 20, false) -- Check first 20 lines
  
  -- Check if file has frontmatter
  if #lines < 3 or lines[1] ~= '---' then return end
  
  -- Find the closing frontmatter delimiter
  local frontmatter_end = nil
  for i = 2, #lines do
    if lines[i] == '---' then
      frontmatter_end = i
      break
    end
  end
  
  if not frontmatter_end then return end
  
  -- Find and update the modified line
  local timestamp = M.get_timestamp()
  for i = 2, frontmatter_end - 1 do
    if lines[i]:match('^modified:') then
      lines[i] = 'modified: ' .. timestamp
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { lines[i] })
      break
    end
  end
end

return M
