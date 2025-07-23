# notes.nvim

A Neovim plugin for managing daily notes and quick notes with frontmatter support.

## Features

- **Daily Notes**: Create and open daily notes with automatic directory structure
- **Tomorrow Notes**: Create notes for tomorrow
- **Quick Notes**: Create random-named notes in an inbox
- **Frontmatter Support**: Automatic YAML frontmatter generation
- **Auto-timestamps**: Automatically update modified timestamps
- **Customizable**: Configure paths, templates, and keymaps
## Installation

### Requirements

**IMPORTANT**: You must specify your PKM directory in the configuration. The plugin will not load without it.

Common PKM directory examples:
- **macOS/Linux**: `'~/Documents/pkm'` or `'/home/username/pkm'`
- **Windows**: `'C:\\Users\\username\\Documents\\pkm'` or `'%USERPROFILE%\\Documents\\pkm'`
- **Cross-platform**: `vim.fn.expand('~/Documents/pkm')` (works everywhere)
- **Obsidian vault**: `'~/Documents/MyVault'`

The plugin supports tilde (`~`) expansion and environment variables on all platforms.

### Setup with Lazy.nvim

Add this to your Lazy.nvim plugin configuration:

```lua
return {
  "kensonjohnson/notes.nvim",
  config = function()
    require('notes').setup({
      pkm_dir = '~/Documents/pkm',  -- REQUIRED: Change to your PKM directory
      -- Optional: customize other settings
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
    })
  end,
  keys = {
    { '<leader>nd', function() require('notes').daily_note() end, desc = 'Open daily note' },
    { '<leader>nt', function() require('notes').tomorrow_note() end, desc = 'Open tomorrow note' },
    { '<leader>nn', function() require('notes').quick_note() end, desc = 'Create quick note' },  },
  cmd = { 'DailyNote', 'TomorrowNote', 'QuickNote' },
}
```

## Configuration

The `setup()` function accepts the following options:

```lua
{
  pkm_dir = '~/Documents/pkm',  -- REQUIRED: Your PKM directory (supports ~ and env vars)
  frontmatter = {
    use_frontmatter = true,          -- Enable/disable frontmatter
    auto_update_modified = true,     -- Auto-update modified timestamp on save
    fields = {
      id = true,                     -- Include ID field
      created = true,                -- Include created timestamp
      modified = true,               -- Include modified timestamp
      tags = true,                   -- Include tags field
    }
  },
  templates = {
    daily = {
      sections = { 'Tasks', 'Blockers', 'Impact' },  -- Daily note sections
      tags = '[#daily]'                               -- Default tags for daily notes
    },
    quick = {
      tags = '[]'                                     -- Default tags for quick notes
    }
  }
}
```

## Usage

### Keymaps (as configured above)

- `<leader>nd` - Open today's daily note
- `<leader>nt` - Open tomorrow's daily note  
- `<leader>nn` - Create a new quick note

### Commands

- `:DailyNote` - Open today's daily note
- `:TomorrowNote` - Open tomorrow's daily note
- `:QuickNote` - Create a new quick note

### Programmatic Usage

```lua
-- Call functions directly
require('notes').daily_note()
require('notes').tomorrow_note()
require('notes').quick_note()
```
## Directory Structure

Daily notes are organized as:
```
PKM_DIR/Daily/YYYY/MM-MMM/YYYY-MM-DD-Weekday.md
```

Quick notes go to:
```
PKM_DIR/+Inbox/randomname.md
```

## Features

### Automatic Frontmatter
All notes include YAML frontmatter with:
- Unique ID
- Created timestamp
- Modified timestamp (auto-updated on save)
- Tags

### Auto-timestamping
The plugin automatically updates the `modified` field in frontmatter when you save any `.md` file in your PKM directory.

### Customizable Templates
Daily notes include configurable sections and tags. You can modify the template structure through the configuration.
