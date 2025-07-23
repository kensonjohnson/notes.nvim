# notes.nvim

A powerful yet simple Neovim plugin for managing daily notes and quick notes with flexible templates and frontmatter support.

## ✨ Features

- **📅 Daily Notes**: Create and open daily notes with intelligent date parsing
- **⚡ Quick Notes**: Create random-named notes in an inbox for rapid capture
- **🎨 Flexible Templates**: Progressive enhancement from zero-config to fully customizable
- **📝 Smart Frontmatter**: Automatic YAML frontmatter with timestamps and metadata
- **🔄 Auto-timestamps**: Automatically update modified timestamps on save
- **🎯 Smart Completion**: Intelligent date completion with fuzzy matching
- **🛡️ Robust Error Handling**: Helpful error messages with actionable suggestions
- **🌍 Cross-platform**: Works seamlessly on macOS, Linux, and Windows

## 🚀 Quick Start

**Zero Configuration** - Just provide your PKM directory:

```lua
require('notes').setup({
  pkm_dir = '~/Documents/notes'  -- That's it!
})
```

This gives you sensible defaults with useful daily note templates:
- **Today's Focus** - Plan your priorities
- **Notes** - Capture thoughts throughout the day  
- **Tomorrow's Prep** - Set yourself up for success

## 📦 Installation

### Requirements

**IMPORTANT**: You must specify your PKM directory. The plugin will validate the path and provide helpful setup guidance.

Common PKM directory examples:
- **macOS/Linux**: `'~/Documents/pkm'` or `'/home/username/notes'`
- **Windows**: `'C:\\Users\\username\\Documents\\pkm'`
- **Obsidian vault**: `'~/Documents/MyVault'`
- **Any path**: The plugin supports `~` expansion and environment variables

### Setup with Lazy.nvim

```lua
return {
  "kensonjohnson/notes.nvim",
  config = function()
    require('notes').setup({
      pkm_dir = '~/Documents/notes',  -- REQUIRED: Your PKM directory
    })
  end,
  keys = {
    { '<leader>nd', function() require('notes').daily_note() end, desc = 'Open daily note' },
    { '<leader>nt', function() require('notes').tomorrow_note() end, desc = 'Open tomorrow note' },
    { '<leader>nn', function() require('notes').quick_note() end, desc = 'Create quick note' },
  },
  cmd = { 'DailyNote', 'TomorrowNote', 'QuickNote' },
}
```

## 🎨 Template System

The plugin features a **progressive enhancement** template system - start simple, customize as needed.

### Level 0: Zero Config (Sensible Defaults)

```lua
require('notes').setup({ pkm_dir = '~/notes' })
```

Creates daily notes with:
```markdown
# Wednesday, July 23, 2025

## Today's Focus


## Notes


## Tomorrow's Prep

```

### Level 1: Simple Customization

```lua
require('notes').setup({
  pkm_dir = '~/notes',
  templates = {
    daily = { "Morning Pages", "Work Log", "Gratitude" }
  }
})
```

### Level 2: Function Templates (Dynamic)

```lua
require('notes').setup({
  pkm_dir = '~/notes',
  templates = {
    daily = function(context)
      local sections = { "## Today's Goals" }
      
      if context.is_monday then
        table.insert(sections, "## Weekly Planning")
      end
      
      if context.is_friday then
        table.insert(sections, "## Week Review")
      end
      
      table.insert(sections, "## Notes")
      return sections
    end
  }
})
```

### Level 3: Object Templates (Full Control)

```lua
require('notes').setup({
  pkm_dir = '~/notes',
  templates = {
    daily = {
      header = "# {{weekday}} Focus - {{month_name}} {{day}}",
      sections = {
        { title = "Priority", content = "- " },
        { title = "Notes", content = "" },
        { 
          title = "Weekend Plans", 
          condition = "is_friday",
          content = { "- Plan weekend activities", "- Review week" }
        }
      },
      footer = "---\nCreated: {{timestamp}}"
    }
  }
})
```

### Level 4: External Template Files

```lua
require('notes').setup({
  pkm_dir = '~/notes',
  templates = {
    daily = { file = "~/.config/nvim/templates/daily.md" },
    meeting = { file = "~/.config/nvim/templates/meeting.md" }
  }
})
```

Template file example (`daily.md`):
```markdown
# {{weekday}}, {{month_name}} {{day}}, {{year}}

## Daily Focus
- Priority: {{user_name}}'s main task

## Notes

Created at {{time_12h}}
```

## 🎯 Smart Date Input

The `:DailyNote` command supports intelligent date parsing with smart completion:

### Supported Formats
- **Relative**: `today`, `tomorrow`, `yesterday`
- **Offsets**: `1`, `-2`, `7` (days from today)
- **Weekdays**: `next monday`, `last friday`
- **ISO dates**: `2025-07-23`
- **US dates**: `7/23/2025`, `7/23/25`

### Smart Completion
Type `:DailyNote ` and press `<Tab>` for intelligent suggestions:
- Filters based on your input
- Shows relative dates, weekdays, and date examples
- Fuzzy matching for easy selection

## ⚙️ Full Configuration

```lua
require('notes').setup({
  pkm_dir = '~/Documents/notes',  -- REQUIRED: Your PKM directory
  
  frontmatter = {
    use_frontmatter = true,          -- Enable/disable frontmatter
    auto_update_modified = true,     -- Auto-update modified timestamp on save
    scan_lines = 20,                 -- Lines to scan for frontmatter (1-100)
    fields = {
      id = true,                     -- Include ID field
      created = true,                -- Include created timestamp
      modified = true,               -- Include modified timestamp
      tags = true,                   -- Include tags field
    }
  },
  
  templates = {
    daily = {
      tags = "[#daily]",             -- Default tags for daily notes
      -- Use any template level here (array, function, object, or file)
    },
    quick = {
      tags = "[]",                   -- Default tags for quick notes
      id_length = 8,                 -- Random ID length (4-32)
      -- Custom template supported here too
    }
  }
})
```

## 📁 Directory Structure

Daily notes are organized as:
```
PKM_DIR/Daily/YYYY/MM-MMM/YYYY-MM-DD-Weekday.md
```

Quick notes go to:
```
PKM_DIR/+Inbox/randomname.md
```

## 🎮 Usage

### Commands
- `:DailyNote [date]` - Open daily note (supports smart date input)
- `:TomorrowNote` - Open tomorrow's daily note
- `:QuickNote` - Create a new quick note

### Examples
```vim
:DailyNote                " Today's note
:DailyNote tomorrow       " Tomorrow's note
:DailyNote next friday    " Next Friday's note
:DailyNote 2025-12-25     " Christmas note
:DailyNote -3             " Note from 3 days ago
```

### Programmatic Usage

```lua
-- Call functions directly
require('notes').daily_note()
require('notes').tomorrow_note()
require('notes').quick_note()
require('notes').dynamic_daily_note('next monday')
```

## 🔧 Template Context

Templates receive a rich context object with:

```lua
context = {
  -- Date information
  date = "2025-07-23",
  year = 2025,
  month = 7,
  day = 23,
  weekday = "Wednesday",
  month_name = "July",
  
  -- Convenience booleans
  is_monday = false,
  is_friday = false,
  is_weekend = false,
  is_workday = true,
  
  -- Time information
  timestamp = "2025-07-23T09:00:00",
  time_12h = "9:00 AM",
  time_24h = "09:00",
  
  -- Note information
  note_id = "2025-07-23",
  note_type = "daily", -- or "quick"
  user_name = "username",
  
  -- Utility functions
  format_date = function(fmt) return os.date(fmt, timestamp) end
}
```

## 🛡️ Error Handling

The plugin provides helpful error messages with actionable suggestions:

- **Configuration errors**: Clear guidance on fixing setup issues
- **Invalid dates**: Suggestions for valid date formats
- **Missing directories**: Step-by-step instructions for resolution
- **Template errors**: Graceful fallbacks with helpful debugging info

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## AI

Try using the [llms.md](/llms.md) file to improve generated output!

## 📄 License

MIT License - see LICENSE file for details.
