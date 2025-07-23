# notes.nvim Test Suite

This directory contains the comprehensive test suite for notes.nvim.

## Running Tests

```bash
# Run all tests
lua tests/run_tests.lua

# Run individual test suites
lua tests/spec/dates_spec.lua
lua tests/spec/templates_spec.lua
lua tests/spec/config_spec.lua
lua tests/spec/errors_spec.lua
```

## Test Structure

```
tests/
├── spec/                    # Test specifications
│   ├── dates_spec.lua      # Date parsing tests (8 tests)
│   ├── templates_spec.lua  # Template system tests (9 tests)
│   ├── config_spec.lua     # Configuration validation tests (16 tests)
│   └── errors_spec.lua     # Error handling tests (18 tests)
├── helpers/                # Test utilities
│   ├── vim_mocks.lua      # Comprehensive Vim API mocks
│   └── test_utils.lua     # Assertion and test utilities
├── fixtures/              # Test data
│   ├── sample_configs.lua # Sample configurations for testing
│   └── test_templates/    # Sample template files
└── run_tests.lua         # Main test runner
```

## Test Coverage

The test suite covers the four most critical areas of the plugin:

1. **Date Parsing** (8 tests)
   - Relative dates (today, tomorrow, yesterday)
   - Weekday patterns (next monday, last friday)
   - Numeric offsets (1, -3, 7)
   - ISO and US date formats
   - Invalid input handling

2. **Template System** (9 tests)
   - Default template rendering
   - Array, function, object, and file templates
   - Variable substitution
   - Conditional sections
   - Error handling and fallbacks

3. **Configuration Validation** (16 tests)
   - Required field validation
   - Type checking for all options
   - Range validation for numeric values
   - Template structure validation
   - Error message formatting

4. **Error Handling** (18 tests)
   - Consistent error message formatting
   - Different error types (fatal, user, internal)
   - Helpful error messages with suggestions
   - Graceful error recovery

## CI/CD Integration

Tests are automatically run on all pull requests to `main` via GitHub Actions. The workflow:

1. Sets up Lua 5.1 environment
2. Runs the complete test suite
3. Fails the PR if any tests fail
4. Provides clear feedback on test results

## Writing New Tests

When adding new functionality:

1. Add tests to the appropriate spec file
2. Use the helper functions in `test_utils.lua`
3. Mock Vim APIs using `vim_mocks.lua`
4. Follow the existing test patterns
5. Ensure all tests pass before submitting PRs

The test suite ensures the plugin remains stable and reliable as it evolves.
