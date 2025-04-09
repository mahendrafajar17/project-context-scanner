# Project Context Scanner

An extension for Visual Studio Code that scans your project files and generates a context analysis in JSON format.

## Features

- Automatically scans project files and generates a context analysis
- Updates the analysis when files change
- Configurable ignore patterns, file size limits, and more
- Shows summary of file types, structures, and dependencies

## Usage

1. Open a project folder in VS Code
2. Run the command "Scan Project Context" from the command palette (Ctrl+Shift+P)
3. A file named `project-context.json` will be created in your project root
4. Enable auto-scanning by running "Toggle Auto Scanning" from the command palette

## Extension Settings

This extension contributes the following settings:

* `projectContextScanner.maxFileSize`: Maximum file size to scan in bytes (default: 1MB)
* `projectContextScanner.maxFiles`: Maximum number of files to scan (default: 1000)
* `projectContextScanner.ignorePatterns`: Patterns to ignore when scanning files
* `projectContextScanner.outputFile`: Name of the output file (default: project-context.json)
* `projectContextScanner.autoScan`: Automatically scan project on file changes (default: false)

## Status Bar Indicator

The extension adds a status bar indicator:
- "PCS: Off" - Auto-scanning is disabled
- "PCS: On" - Auto-scanning is enabled
- "PCS: Scanning..." - Currently scanning project

Click on the indicator to toggle auto-scanning.