const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const childProcess = require('child_process');
const exec = promisify(childProcess.exec);
const stat = promisify(fs.stat);
const readdir = promisify(fs.readdir);
const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);

// Map of file extensions to languages
const FILE_TYPE_MAP = {
    js: "JavaScript",
    jsx: "JavaScript",
    ts: "TypeScript",
    tsx: "TypeScript",
    py: "Python",
    java: "Java",
    rb: "Ruby",
    php: "PHP",
    go: "Go",
    rs: "Rust",
    c: "C/C++",
    cpp: "C/C++",
    h: "C/C++",
    hpp: "C/C++",
    html: "HTML",
    htm: "HTML",
    css: "CSS",
    scss: "CSS",
    sass: "CSS",
    json: "JSON",
    md: "Markdown",
    markdown: "Markdown",
    sh: "Shell",
    bash: "Shell"
};

// Map of file extensions to dependency extraction regex patterns
const DEPENDENCY_REGEX_MAP = {
    js: /^import|^require/,
    jsx: /^import|^require/,
    ts: /^import|^require/,
    tsx: /^import|^require/,
    py: /^import|^from/,
    java: /^import/,
    go: /^import/
};

// Map of file extensions to structure extraction regex patterns
const STRUCTURE_REGEX_MAP = {
    js: /^(class|function|const.*=.*=>|export)/,
    jsx: /^(class|function|const.*=.*=>|export)/,
    ts: /^(class|function|const.*=.*=>|export|interface|type)/,
    tsx: /^(class|function|const.*=.*=>|export|interface|type)/,
    py: /^(def|class)/,
    java: /^[\\s]*(public|private|protected).*class|^[\\s]*(public|private|protected).*method/,
    go: /^(func|type|var|const|package|import)/
};

// Global variables for file watcher and scanning status
let fileWatcher = null;
let isScanning = false;
let scanDebounceTimer = null;
let statusBarItem = null;

/**
 * Activate the extension
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    console.log('Project Context Scanner is now active');

    // Create status bar item
    statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
    statusBarItem.text = '$(sync) PCS: Off';
    statusBarItem.tooltip = 'Project Context Scanner';
    statusBarItem.command = 'project-context-scanner.toggle';
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);

    // Register commands
    let scanCommand = vscode.commands.registerCommand('project-context-scanner.scan', scanProjectContext);
    let toggleCommand = vscode.commands.registerCommand('project-context-scanner.toggle', toggleAutoScan);

    context.subscriptions.push(scanCommand);
    context.subscriptions.push(toggleCommand);

    // Set up auto-scanning if enabled in settings
    const config = vscode.workspace.getConfiguration('projectContextScanner');
    if (config.get('autoScan')) {
        enableAutoScan();
    }
}

/**
 * Deactivate the extension
 */
function deactivate() {
    if (fileWatcher) {
        fileWatcher.dispose();
        fileWatcher = null;
    }
    if (statusBarItem) {
        statusBarItem.dispose();
    }
}

/**
 * Toggle auto-scanning on file changes
 */
async function toggleAutoScan() {
    const config = vscode.workspace.getConfiguration('projectContextScanner');
    const autoScan = config.get('autoScan');

    await config.update('autoScan', !autoScan, true);

    if (!autoScan) {
        enableAutoScan();
        vscode.window.showInformationMessage('Project Context Scanner: Auto-scanning enabled');
    } else {
        disableAutoScan();
        vscode.window.showInformationMessage('Project Context Scanner: Auto-scanning disabled');
    }
}

/**
 * Enable auto-scanning on file changes
 */
function enableAutoScan() {
    if (fileWatcher) {
        fileWatcher.dispose();
    }

    if (vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders.length > 0) {
        const workspaceFolder = vscode.workspace.workspaceFolders[0].uri.fsPath;
        const pattern = new vscode.RelativePattern(workspaceFolder, '**/*');

        fileWatcher = vscode.workspace.createFileSystemWatcher(pattern, false, false, false);

        fileWatcher.onDidCreate(() => debounceScan());
        fileWatcher.onDidChange(() => debounceScan());
        fileWatcher.onDidDelete(() => debounceScan());

        statusBarItem.text = '$(sync) PCS: On';
    }
}

/**
 * Disable auto-scanning
 */
function disableAutoScan() {
    if (fileWatcher) {
        fileWatcher.dispose();
        fileWatcher = null;
    }

    statusBarItem.text = '$(sync) PCS: Off';
}

/**
 * Debounce scan to prevent excessive scans on multiple file changes
 */
function debounceScan() {
    if (scanDebounceTimer) {
        clearTimeout(scanDebounceTimer);
    }

    scanDebounceTimer = setTimeout(() => {
        scanProjectContext();
    }, 2000); // Wait 2 seconds after last file change
}

/**
 * Main function to scan project context
 */
async function scanProjectContext() {
    // Check if already scanning
    if (isScanning) {
        vscode.window.showInformationMessage('Project Context Scanner: Already scanning...');
        return;
    }

    // Check if workspace folder exists
    if (!vscode.workspace.workspaceFolders || vscode.workspace.workspaceFolders.length === 0) {
        vscode.window.showErrorMessage('Project Context Scanner: No workspace folder open');
        return;
    }

    isScanning = true;

    // Update status bar
    statusBarItem.text = '$(sync~spin) PCS: Scanning...';

    try {
        const workspaceFolder = vscode.workspace.workspaceFolders[0].uri.fsPath;
        const config = vscode.workspace.getConfiguration('projectContextScanner');
        const outputFileName = config.get('outputFile');
        const outputFilePath = path.join(workspaceFolder, outputFileName);

        // Start scanning
        vscode.window.showInformationMessage(`Project Context Scanner: Scanning project...`);

        // Get project files and analyze them
        const result = await analyzeProject(workspaceFolder);

        // Write result to file
        await writeFile(outputFilePath, JSON.stringify(result, null, 2));

        vscode.window.showInformationMessage(`Project Context Scanner: Scan complete. Output saved to ${outputFileName}`);
    } catch (error) {
        vscode.window.showErrorMessage(`Project Context Scanner: Error - ${error.message}`);
        console.error(error);
    } finally {
        isScanning = false;

        // Update status bar
        const config = vscode.workspace.getConfiguration('projectContextScanner');
        statusBarItem.text = config.get('autoScan') ? '$(sync) PCS: On' : '$(sync) PCS: Off';
    }
}

/**
 * Analyze project structure
 * @param {string} directory Directory to scan
 * @returns {Object} Project analysis result
 */
async function analyzeProject(directory) {
    const config = vscode.workspace.getConfiguration('projectContextScanner');
    const maxFileSize = config.get('maxFileSize');
    const maxFiles = config.get('maxFiles');
    const ignorePatterns = config.get('ignorePatterns');

    let fileCount = 0;
    const files = [];

    // Check if Go project
    const isGoProject = await isFileExists(path.join(directory, 'go.mod')) ||
        await isFileExists(path.join(directory, 'go.sum'));

    // Function to recursively scan directory
    async function scanDirectory(dir, relativePath = '') {
        if (fileCount >= maxFiles) {
            return;
        }

        const entries = await readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            const relPath = path.join(relativePath, entry.name);

            // Skip if should ignore
            if (shouldIgnore(relPath, ignorePatterns)) {
                continue;
            }

            if (entry.isDirectory()) {
                await scanDirectory(fullPath, relPath);
            } else {
                // Check file size
                const stats = await stat(fullPath);
                if (stats.size > maxFileSize) {
                    continue;
                }

                // Increment file count and check limit
                fileCount++;
                if (fileCount > maxFiles) {
                    files.push({
                        warning: "Max file limit reached. Some files were not analyzed."
                    });
                    break;
                }

                // Get file type and analyze
                const fileExt = path.extname(entry.name).slice(1).toLowerCase();
                const fileType = FILE_TYPE_MAP[fileExt] || "Unknown";

                try {
                    // Read file content
                    const content = await readFile(fullPath, 'utf8');

                    // Extract dependencies
                    const dependencies = extractDependencies(content, fileExt);

                    // Extract structure
                    const structure = extractStructure(content, fileExt);

                    // Add file info
                    files.push({
                        path: relPath,
                        type: fileType,
                        size: stats.size,
                        dependencies: dependencies,
                        structure: structure
                    });
                } catch (error) {
                    console.error(`Error reading file ${fullPath}:`, error);
                }
            }
        }
    }

    // Start scanning from root directory
    await scanDirectory(directory);

    // Create result object
    return {
        projectStructure: {
            files: files,
            summary: {
                fileCount: fileCount,
                scannedAt: new Date().toISOString()
            }
        }
    };
}

/**
 * Check if a file exists
 * @param {string} filePath File path to check
 * @returns {boolean} True if file exists
 */
async function isFileExists(filePath) {
    try {
        await stat(filePath);
        return true;
    } catch (error) {
        return false;
    }
}

/**
 * Check if a file should be ignored based on patterns
 * @param {string} filePath File path to check
 * @param {string[]} ignorePatterns Patterns to ignore
 * @returns {boolean} True if file should be ignored
 */
function shouldIgnore(filePath, ignorePatterns) {
    for (const pattern of ignorePatterns) {
        // Handle wildcards at the end of pattern
        if (pattern.endsWith('*')) {
            const basePattern = pattern.slice(0, -1);
            if (filePath.includes(basePattern)) {
                return true;
            }
        } else if (pattern.endsWith('/')) {
            // For directory patterns
            if (filePath.includes(`/${pattern}`) || filePath.includes(pattern)) {
                return true;
            }
        } else if (filePath.includes(pattern)) {
            return true;
        }
    }

    return false;
}

/**
 * Extract dependencies from file content
 * @param {string} content File content
 * @param {string} fileExt File extension
 * @returns {string[]} Array of dependencies
 */
function extractDependencies(content, fileExt) {
    const regex = DEPENDENCY_REGEX_MAP[fileExt];
    if (!regex) {
        return [];
    }

    // Split content by lines and filter for dependencies
    const lines = content.split('\n');
    return lines
        .filter(line => regex.test(line))
        .map(line => line.trim())
        .filter((line, index, self) => self.indexOf(line) === index); // Unique only
}

/**
 * Extract structure from file content
 * @param {string} content File content
 * @param {string} fileExt File extension
 * @returns {string[]} Array of structure elements
 */
function extractStructure(content, fileExt) {
    const regex = STRUCTURE_REGEX_MAP[fileExt];
    if (!regex) {
        return [];
    }

    // Split content by lines and filter for structure
    const lines = content.split('\n');
    return lines
        .filter(line => regex.test(line))
        .map(line => line.trim())
        .slice(0, 10); // Limit to 10 elements
}

module.exports = {
    activate,
    deactivate
};