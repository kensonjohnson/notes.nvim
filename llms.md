# notes.nvim

> A Neovim plugin for managing daily notes and quick notes with flexible templates and frontmatter support. Designed as a local plugin for personal knowledge management (PKM) systems with progressive template enhancement from zero-config to fully customizable.

Key features and concepts:

- **Daily Notes**: Organized by date with intelligent parsing (supports relative dates, offsets, weekdays, ISO dates)
- **Quick Notes**: Random-named notes in an inbox for rapid capture
- **Progressive Templates**: Zero config → Array → Function → Object → File-based templates
- **Smart Frontmatter**: Automatic YAML frontmatter with timestamps and metadata
- **Cross-platform**: Works on macOS, Linux, and Windows with proper path handling

The plugin follows a modular architecture with clear separation of concerns: configuration management, date utilities, template engine, completion system, and error handling.

## Core Files

- [init.lua](lua/notes/init.lua): Main module entry point with setup() function and command registration
- [config.lua](lua/notes/config.lua): Configuration management and validation with helpful error messages
- [daily.lua](lua/notes/daily.lua): Core daily/quick note functionality and file creation logic
- [dates.lua](lua/notes/dates.lua): Date parsing and manipulation utilities with smart input handling
- [templates.lua](lua/notes/templates.lua): Flexible template engine with progressive enhancement system
- [completion.lua](lua/notes/completion.lua): Smart command completion system for date inputs
- [errors.lua](lua/notes/errors.lua): Centralized error handling utilities with consistent messaging
- [utils.lua](lua/notes/utils.lua): General utility functions for file operations and ID generation

## Templates

- [Template Examples](tests/fixtures/test_templates/daily.md): Sample daily note template showing variable substitution
- [Template System Documentation](REFACTORING.md): Detailed explanation of the progressive template enhancement system

## Configuration

- [Sample Configurations](tests/fixtures/sample_configs.lua): Example configurations showing different template levels
- [Setup Guide](README.md): Complete setup instructions with zero-config and advanced examples

## API Reference

- [Main Commands](README.md#usage): `:DailyNote [date]`, `:TomorrowNote`, `:QuickNote` with smart date parsing
- [Programmatic API](README.md#programmatic-usage): Direct function calls for advanced integration
- [Template Context](README.md#template-context): Rich context object available to templates with date, time, and utility information

## Development

- [Test Suite](tests/run_tests.lua): Comprehensive test runner covering dates, templates, config, and error handling
- [Development Guide](AGENTS.md): Project overview, code style guidelines, and development commands
- [Test Helpers](tests/helpers/): Utilities for testing including vim mocks and test utilities

## Examples

- [Zero Config Setup](README.md#quick-start): Minimal setup with sensible defaults
- [Progressive Template Examples](README.md#template-system): From simple arrays to complex file-based templates
- [Smart Date Input Examples](README.md#smart-date-input): Various date formats and relative date parsing

## Optional

- [Refactoring Notes](REFACTORING.md): Internal architecture decisions and design patterns
- [Test Fixtures](tests/fixtures/): Sample data and configurations used in testing
- [GitHub Workflow](/.github/workflows/test.yml): CI/CD configuration for automated testing