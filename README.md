# Project Context Scanner

An extension for Visual Studio Code that scans your project files and generates a context analysis in JSON format.

## Features

- Automatically scans project files and generates a context analysis
- Updates the analysis when files change
- Advanced configurable exclude patterns with glob support
- Integration with VSCode exclude settings and .gitignore files
- Configurable file size limits and more
- Shows summary of file types, structures, and dependencies

## Usage

1. Open a project folder in VS Code
2. Run the command "Scan Project Context" from the command palette (Ctrl+Shift+P)
3. A file named `project-context.json` will be created in your project root
4. Enable auto-scanning by running "Toggle Auto Scanning" from the command palette
5. Configure exclusion patterns via settings or by running "Configure Exclude Patterns"

## Extension Settings

This extension contributes the following settings:

* `projectContextScanner.maxFileSize`: Maximum file size to scan in bytes (default: 1MB)
* `projectContextScanner.maxFiles`: Maximum number of files to scan (default: 500)
* `projectContextScanner.outputFile`: Name of the output file (default: project-context.json)
* `projectContextScanner.autoScan`: Automatically scan project on file changes (default: false)
* `projectContextScanner.ignorePatterns`: Legacy patterns to ignore when scanning files (deprecated)
* `projectContextScanner.excludePatterns`: Patterns to exclude when scanning (supports glob patterns)
* `projectContextScanner.useGitignore`: Include patterns from .gitignore file (default: true)
* `projectContextScanner.useVSCodeExclude`: Include patterns from VSCode files.exclude setting (default: true)

### Exclude Pattern Examples

The extension supports various exclude pattern formats:

```json
"projectContextScanner.excludePatterns": [
  "node_modules",            // Exclude specific folder
  "**/tests/**",             // Exclude all tests folders anywhere
  "**/*.min.js",             // Exclude all minified JS files
  ".github/",                // Exclude directory with trailing slash
  "**/temp*",                // Wildcards for partial matching
  "**/{build,dist,out}/**"   // Multiple patterns with brace expansion
]
```

## Commands

* `Project Context Scanner: Scan Project` - Manually scan the project
* `Project Context Scanner: Toggle Auto-Scan` - Toggle automatic scanning
* `Project Context Scanner: Configure Exclude Patterns` - Open settings to configure exclusion patterns

## Status Bar Indicator

The extension adds a status bar indicator:
- "PCS: Off" - Auto-scanning is disabled
- "PCS: On" - Auto-scanning is enabled
- "PCS: Scanning..." - Currently scanning project

Click on the indicator to toggle auto-scanning.