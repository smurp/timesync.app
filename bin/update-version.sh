#!/bin/bash

# update-version.sh - Update version across TimeSync PWA files
# Usage: ./bin/update-version.sh [patch|minor|major]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_usage() {
    echo -e "${BLUE}TimeSync Version Update Script${NC}"
    echo -e "Usage: $0 <patch|minor|major>"
    echo -e ""
    echo -e "Updates version in:"
    echo -e "  - package.json (via npm version)"
    echo -e "  - manifest.json"
    echo -e "  - sw.js (cache name)"
    echo -e ""
    echo -e "Examples:"
    echo -e "  $0 patch    # 0.5.7 → 0.5.8"
    echo -e "  $0 minor    # 0.5.7 → 0.6.0"
    echo -e "  $0 major    # 0.5.7 → 1.0.0"
}

function validate_git_status() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Not in a git repository${NC}"
        return 0
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
        echo -e "Consider committing your changes before updating the version."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

function get_current_version() {
    # Extract version from package.json
    if [[ -f "package.json" ]]; then
        node -p "require('./package.json').version" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

function update_package_version() {
    local version_type="$1"
    
    echo -e "${BLUE}Updating package.json version...${NC}"
    
    # Use npm version to update package.json and create git tag
    npm version "$version_type" --no-git-tag-version
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Updated package.json${NC}"
    else
        echo -e "${RED}❌ Failed to update package.json${NC}"
        exit 1
    fi
}

function get_new_version() {
    node -p "require('./package.json').version"
}

function update_manifest_version() {
    local new_version="$1"
    local manifest_file="manifest.json"
    
    echo -e "${BLUE}Updating manifest.json version...${NC}"
    
    if [[ ! -f "$manifest_file" ]]; then
        echo -e "${RED}Error: $manifest_file not found${NC}"
        exit 1
    fi
    
    # Use node to update the JSON file properly
    node -e "
        const fs = require('fs');
        const manifest = JSON.parse(fs.readFileSync('$manifest_file', 'utf8'));
        manifest.version = '$new_version';
        fs.writeFileSync('$manifest_file', JSON.stringify(manifest, null, 2) + '\n');
    "
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Updated $manifest_file${NC}"
    else
        echo -e "${RED}❌ Failed to update $manifest_file${NC}"
        exit 1
    fi
}

function update_service_worker_cache() {
    local new_version="$1"
    local sw_file="sw.js"
    
    echo -e "${BLUE}Updating service worker cache name...${NC}"
    
    if [[ ! -f "$sw_file" ]]; then
        echo -e "${RED}Error: $sw_file not found${NC}"
        exit 1
    fi
    
    # Update the CACHE_NAME in sw.js
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i '' "s/const CACHE_NAME = 'timesync-v.*';/const CACHE_NAME = 'timesync-v$new_version';/" "$sw_file"
    else
        # Linux sed
        sed -i "s/const CACHE_NAME = 'timesync-v.*';/const CACHE_NAME = 'timesync-v$new_version';/" "$sw_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Updated $sw_file cache name${NC}"
    else
        echo -e "${RED}❌ Failed to update $sw_file${NC}"
        exit 1
    fi
}

function show_changes() {
    local old_version="$1"
    local new_version="$2"
    
    echo -e "${BLUE}Version Update Summary${NC}"
    echo -e "======================"
    echo -e "Old version: ${YELLOW}$old_version${NC}"
    echo -e "New version: ${GREEN}$new_version${NC}"
    echo -e ""
    echo -e "Updated files:"
    echo -e "  📦 package.json"
    echo -e "  📋 manifest.json"
    echo -e "  🔧 sw.js (cache name)"
    echo -e ""
    
    # Show git status if in a git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${BLUE}Git status:${NC}"
        git status --porcelain | grep -E '(package\.json|manifest\.json|sw\.js)' || echo "  No tracked file changes"
        echo -e ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo -e "  git add package.json manifest.json sw.js"
        echo -e "  git commit -m \"Release v$new_version\""
        echo -e "  git tag -a v$new_version -m \"Version $new_version\""
    fi
}

function create_git_tag() {
    local new_version="$1"
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${BLUE}Creating git tag...${NC}"
        read -p "Create git tag v$new_version? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}Skipping git tag creation${NC}"
        else
            git add package.json manifest.json sw.js
            git commit -m "Release v$new_version" || echo -e "${YELLOW}No changes to commit${NC}"
            git tag -a "v$new_version" -m "Version $new_version"
            echo -e "${GREEN}✅ Created git tag v$new_version${NC}"
        fi
    fi
}

# Main execution
function main() {
    local version_type="$1"
    
    if [[ $# -ne 1 ]]; then
        print_usage
        exit 1
    fi
    
    if [[ "$version_type" != "patch" && "$version_type" != "minor" && "$version_type" != "major" ]]; then
        echo -e "${RED}Error: Version type must be 'patch', 'minor', or 'major'${NC}"
        print_usage
        exit 1
    fi
    
    echo -e "${BLUE}🚀 TimeSync Version Update${NC}"
    echo -e "============================"
    
    local old_version=$(get_current_version)
    echo -e "Current version: $old_version"
    echo -e "Update type: $version_type"
    echo -e ""
    
    validate_git_status
    
    # Update package.json version
    update_package_version "$version_type"
    
    # Get the new version
    local new_version=$(get_new_version)
    
    # Update other files
    update_manifest_version "$new_version"
    update_service_worker_cache "$new_version"
    
    # Show summary
    show_changes "$old_version" "$new_version"
    
    # Optionally create git tag
    create_git_tag "$new_version"
    
    echo -e "${GREEN}Version update complete! 🎉${NC}"
}

# Run main function with all arguments
main "$@"