#!/bin/bash
# project-context-scanner.sh
# A shell script to scan and analyze project context
# Inspired by Cline's context management

# Configuration
MAX_FILE_SIZE=1000000  # 1MB max file size
MAX_FILES=1000         # Maximum number of files to scan
IGNORE_PATTERNS=(
  "node_modules/"
  ".git/"
  "dist/"
  "build/"
  ".cache/"
  "__pycache__/"
  "*.jpg"
  "*.jpeg"
  "*.png"
  "*.gif"
  "*.pdf"
  "*.zip"
  "*.tar"
  "*.gz"
  "*.exe"
  "*.dll"
  "*.so"
  "*.dylib"
  "*.class"
  "*.log"
)

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a file should be ignored
should_ignore() {
  local file="$1"
  
  # Check file size
  local size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
  if [[ $size -gt $MAX_FILE_SIZE ]]; then
    return 0  # True, should ignore
  fi
  
  # Check against ignore patterns
  for pattern in "${IGNORE_PATTERNS[@]}"; do
    # Handle wildcards at the end of pattern
    if [[ "$pattern" == *\** ]]; then
      local base_pattern="${pattern%\*}"
      if [[ "$file" == *"$base_pattern"* ]]; then
        return 0  # True, should ignore
      fi
    else
      # For directory patterns, check if the path contains /pattern/
      if [[ "$pattern" == */ ]]; then
        if [[ "$file" == *"/$pattern"* || "$file" == *"$pattern"* ]]; then
          return 0  # True, should ignore
        fi
      else
        if [[ "$file" == *"$pattern"* ]]; then
          return 0  # True, should ignore
        fi
      fi
    fi
  done
  
  # Check if file is binary
  if file "$file" | grep -q "binary"; then
    return 0  # True, should ignore
  fi
  
  return 1  # False, should not ignore
}

# Function to detect file type and language
detect_file_type() {
  local file="$1"
  local extension="${file##*.}"
  
  case "$extension" in
    js|jsx|ts|tsx)
      echo "JavaScript/TypeScript"
      ;;
    py)
      echo "Python"
      ;;
    java)
      echo "Java"
      ;;
    rb)
      echo "Ruby"
      ;;
    php)
      echo "PHP"
      ;;
    go)
      echo "Go"
      ;;
    rs)
      echo "Rust"
      ;;
    c|cpp|h|hpp)
      echo "C/C++"
      ;;
    html|htm)
      echo "HTML"
      ;;
    css|scss|sass)
      echo "CSS"
      ;;
    json)
      echo "JSON"
      ;;
    md|markdown)
      echo "Markdown"
      ;;
    sh|bash)
      echo "Shell"
      ;;
    *)
      echo "Unknown"
      ;;
  esac
}

# Function to extract imports/dependencies from a file
extract_dependencies() {
  local file="$1"
  local extension="${file##*.}"
  
  case "$extension" in
    js|jsx|ts|tsx)
      grep -E "^import|^require" "$file" | sort | uniq
      ;;
    py)
      grep -E "^import|^from" "$file" | sort | uniq
      ;;
    java)
      grep -E "^import" "$file" | sort | uniq
      ;;
    go)
      grep -E "^import" "$file" | sort | uniq
      ;;
    *)
      # No specific extraction for other types
      ;;
  esac
}

# Function to extract basic code structure
extract_structure() {
  local file="$1"
  local extension="${file##*.}"
  
  case "$extension" in
    js|jsx|ts|tsx)
      grep -E "^(class|function|const.*=.*=>|export)" "$file" | head -10
      ;;
    py)
      grep -E "^(def|class)" "$file" | head -10
      ;;
    java)
      grep -E "^[[:space:]]*(public|private|protected).*class|^[[:space:]]*(public|private|protected).*method" "$file" | head -10
      ;;
    go)
      # Improved Go structure extraction
      grep -E "^(func|type|var|const|package|import)" "$file" | head -10
      ;;
    *)
      # No specific extraction for other types
      ;;
  esac
}

# Function to analyze project structure
analyze_project() {
  local dir="$1"
  local output_file="$2"
  local file_count=0
  
  # Add special handling for Go projects
  local is_go_project=false
  if [ -f "$dir/go.mod" ] || [ -f "$dir/go.sum" ]; then
    is_go_project=true
    echo "Detected Go project - using specialized scanning..."
  fi
  
  echo "{" > "$output_file"
  echo "  \"projectStructure\": {" >> "$output_file"
  echo "    \"files\": [" >> "$output_file"
  
  # Use find with exclusion patterns for better performance
  find_command="find \"$dir\" -type f -not -path \"*/\.*\""
  
  # Add explicit exclusions to the find command for better performance
  for pattern in "${IGNORE_PATTERNS[@]}"; do
    # Convert wildcard patterns to find-compatible patterns
    if [[ "$pattern" == */ ]]; then
      # Directory pattern
      find_command+=" -not -path \"*/$pattern*\""
    elif [[ "$pattern" == *\** ]]; then
      # File pattern with wildcard
      local base_pattern="${pattern%\*}"
      find_command+=" -not -path \"*$base_pattern*\""
    else
      # Normal pattern
      find_command+=" -not -path \"*$pattern*\""
    fi
  done
  
  # Add print0 and sort
  find_command+=" -print0 | sort -z"
  
  # Run the find command and process results
  while IFS= read -r -d '' file; do
    if ! should_ignore "$file"; then
      # Get relative path
      local rel_path="${file#$dir/}"
      local file_type=$(detect_file_type "$file")
      
      # Increment file count and check limit
      ((file_count++))
      if [[ $file_count -gt $MAX_FILES ]]; then
        echo "    { \"warning\": \"Max file limit reached. Some files were not analyzed.\" }" >> "$output_file"
        break
      fi
      
      echo "    {" >> "$output_file"
      # Escape the path for JSON
      local escaped_path=$(echo "$rel_path" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
      echo "      \"path\": \"$escaped_path\"," >> "$output_file"
      echo "      \"type\": \"$file_type\"," >> "$output_file"
      echo "      \"size\": \"$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)\"," >> "$output_file"
      
      echo "      \"dependencies\": [" >> "$output_file"
      # Extract and format dependencies
      local deps=$(extract_dependencies "$file")
      if [[ -n "$deps" ]]; then
        while IFS= read -r dep; do
          # Escape special characters for JSON
          dep=$(echo "$dep" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
          echo "        \"$dep\"," >> "$output_file"
        done <<< "$deps"
        # Remove trailing comma from last item
        sed -i '' -e '$ s/,$//' "$output_file" 2>/dev/null || sed -i -e '$ s/,$//' "$output_file" 2>/dev/null
      fi
      echo "      ]," >> "$output_file"
      
      echo "      \"structure\": [" >> "$output_file"
      # Extract and format structure
      local structs=$(extract_structure "$file")
      if [[ -n "$structs" ]]; then
        while IFS= read -r struct; do
          # Escape special characters for JSON
          struct=$(echo "$struct" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
          echo "        \"$struct\"," >> "$output_file"
        done <<< "$structs"
        # Remove trailing comma from last item
        sed -i '' -e '$ s/,$//' "$output_file" 2>/dev/null || sed -i -e '$ s/,$//' "$output_file" 2>/dev/null
      fi
      echo "      ]" >> "$output_file"
      
      echo "    }," >> "$output_file"
    fi
  done < <(eval "$find_command")
  
  # Remove trailing comma from last file entry
  sed -i '' -e '$ s/,$//' "$output_file" 2>/dev/null || sed -i -e '$ s/,$//' "$output_file" 2>/dev/null
  
  echo "    ]," >> "$output_file"
  
  # Add summary information
  echo "    \"summary\": {" >> "$output_file"
  echo "      \"fileCount\": $file_count," >> "$output_file"
  echo "      \"scannedAt\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" >> "$output_file"
  echo "    }" >> "$output_file"
  echo "  }" >> "$output_file"
  echo "}" >> "$output_file"
  
  # Add a simple JSON validation before using jq
  if grep -q "Invalid\|Error" "$output_file"; then
    echo -e "${RED}Error: JSON file contains errors${NC}"
    echo -e "${YELLOW}Skipping jq formatting...${NC}"
  else
    # Format JSON properly (if jq is available)
    if command -v jq &> /dev/null; then
      # Use a safeguard to prevent crashing on invalid JSON
      if jq . "$output_file" > "${output_file}.tmp" 2>/dev/null; then
        mv "${output_file}.tmp" "$output_file"
      else
        echo -e "${RED}Error: jq could not parse the JSON file${NC}"
        echo -e "${YELLOW}Original file preserved${NC}"
        rm -f "${output_file}.tmp"
      fi
    fi
  fi
}

# Function to print summary
print_summary() {
  local output_file="$1"
  
  echo -e "\n${GREEN}Project Context Analysis Summary:${NC}"
  echo -e "${BLUE}=================================${NC}"
  
  if command -v jq &> /dev/null; then
    echo -e "${YELLOW}Files scanned:${NC} $(jq '.projectStructure.summary.fileCount' "$output_file")"
    echo -e "${YELLOW}Scan time:${NC} $(jq -r '.projectStructure.summary.scannedAt' "$output_file")"
    echo -e "${YELLOW}Output file:${NC} $output_file"
    
    # Print file type distribution
    echo -e "\n${YELLOW}File types:${NC}"
    jq -r '.projectStructure.files[].type' "$output_file" | sort | uniq -c | sort -nr | while read count type; do
      echo -e "  ${BLUE}$type:${NC} $count"
    done
  else
    echo -e "${YELLOW}Output file:${NC} $output_file"
    echo -e "${RED}Install jq for more detailed summary output${NC}"
  fi
}

# Main execution
main() {
  local project_dir="."
  local output_file="project-context.json"
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--directory)
        project_dir="$2"
        shift 2
        ;;
      -o|--output)
        output_file="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: $0 [-d|--directory DIR] [-o|--output FILE]"
        echo "Scans project files and generates a context analysis in JSON format"
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
  done
  
  # Check if directory exists
  if [[ ! -d "$project_dir" ]]; then
    echo -e "${RED}Error: Directory '$project_dir' not found${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Scanning project in ${BLUE}$project_dir${NC}"
  echo -e "${GREEN}This may take a while depending on project size...${NC}"
  
  # Call the analyze function
  analyze_project "$project_dir" "$output_file"
  
  # Print summary
  print_summary "$output_file"
  
  echo -e "\n${GREEN}Done!${NC}"
}

# Run the main function with all arguments
main "$@"