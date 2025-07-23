-- Configuration module for notes.nvim plugin

local M = {}

-- Default configuration
M.defaults = {
  pkm_dir = nil,  -- REQUIRED: Must be set by user
  frontmatter = {
    use_frontmatter = true,
    auto_update_modified = true,
    fields = {
      id = true,
      created = true,
      modified = true,
      tags = true,
    }
  },
  templates = {
    daily = {
      sections = { 'Tasks', 'Blockers', 'Impact' },
      tags = '[#daily]'
    },
    quick = {
      tags = '[]'
    }
  }
}

-- Current configuration (will be merged with user config)
M.options = {}

-- Setup function to merge user config with defaults
function M.setup(user_config)
  M.options = vim.tbl_deep_extend('force', M.defaults, user_config or {})
  
  -- Expand the pkm_dir path if provided
  if M.options.pkm_dir then
    local utils = require('notes.utils')
    M.options.pkm_dir = utils.expand_path(M.options.pkm_dir)
  end
  
  -- Validate required configuration
  M.validate()
end

-- Validate configuration
function M.validate()
  if not M.options.pkm_dir then
    error("notes.nvim: pkm_dir is required. Please set it in your configuration:\n" ..
          "require('notes').setup({ pkm_dir = '/path/to/your/pkm' })")  end
  
  if not vim.fn.isdirectory(M.options.pkm_dir) then
    error("notes.nvim: PKM directory does not exist: " .. M.options.pkm_dir .. "\n" ..
          "Please create the directory or check your configuration.")  end
end

return M
