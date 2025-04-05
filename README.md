# Project Context Scanner

A shell script to scan and analyze project context, generating a comprehensive JSON structure of your codebase. This tool helps you understand your project organization, dependencies, and structure without manual inspection.

## Features

- 🔍 **Project Structure Analysis**: Scans your entire project to create a map of all files
- 🚫 **Smart Filtering**: Automatically ignores common non-code directories and binary files
- 🧩 **Dependency Detection**: Extracts imports and dependencies from common languages
- 📊 **Code Structure Analysis**: Identifies classes, functions, and other structural elements
- 📦 **Format-Friendly Output**: Generates clean JSON output for further processing
- 💻 **Multi-Language Support**: Works with JavaScript, TypeScript, Python, Go, Java, and more
- 🚀 **Performance Optimized**: Designed to handle large projects efficiently

## Installation

1. Clone this repository or download the script
2. Make the script executable:
   ```bash
   chmod +x project-context-scanner.sh
   ```

## Usage

Run the script in your project directory:

```bash
./project-context-scanner.sh
```

Or specify a custom directory and output file:

```bash
./project-context-scanner.sh -d /path/to/your/project -o output.json
```

### Options

- `-d, --directory DIR`: Specify the project directory to scan (default: current directory)
- `-o, --output FILE`: Specify the output JSON file (default: project-context.json)
- `-h, --help`: Display help information

## Output

The script generates a JSON file with the following structure:

```json
{
  "projectStructure": {
    "files": [
      {
        "path": "src/main.js",
        "type": "JavaScript/TypeScript",
        "size": "1234",
        "dependencies": [
          "import React from 'react'",
          "import { useState } from 'react'"
        ],
        "structure": [
          "function App() {",
          "export default App"
        ]
      }
      // ...more files
    ],
    "summary": {
      "fileCount": 42,
      "scannedAt": "2025-04-05T12:34:56Z"
    }
  }
}
```

## Supported Languages

- JavaScript/TypeScript
- Python
- Java
- Ruby
- PHP
- Go
- Rust
- C/C++
- HTML
- CSS/SCSS/SASS
- JSON
- Markdown
- Shell scripts

## Customization

You can customize the script by modifying the configuration variables at the top:

- `MAX_FILE_SIZE`: Maximum file size to analyze (default: 1MB)
- `MAX_FILES`: Maximum number of files to scan (default: 1000)
- `IGNORE_PATTERNS`: Directories and file patterns to ignore

## Special Go Project Support

The script automatically detects and optimizes scanning for Go projects by looking for `go.mod` or `go.sum` files, providing enhanced structure extraction for Go code.

## Requirements

- Bash shell
- Optional: `jq` for pretty-printed JSON output

## License

This project is open-source and available under the MIT License.

## Acknowledgements

Inspired by Cline's context management approach to large codebases.