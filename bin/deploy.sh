#!/bin/bash

# deploy.sh - Deploy TimeSync PWA to production (deploy branch)
# Usage: ./bin/deploy.sh [--force]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_usage() {
    echo -e "${BLUE}TimeSync Deployment Script${NC}"
    echo -e "Usage: $0 [--force]"
    echo -e ""
    echo -e "Deploys current branch to 'deploy' branch for GitHub Pages"
    echo -e ""
    echo -e "Options:"
    echo -e "  --force    Skip confirmation prompts"
    echo -e ""
    echo -e "What it does:"
    echo -e "  1. Builds all assets (npm run build)"
    echo -e "  2. Switches to 'deploy' branch"
    echo -e "  3. Merges current branch"
    echo -e "  4. Commits built assets"
    echo -e "  5. Pushes to GitHub (triggers GitHub Pages deploy)"
}

function validate_git_status() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        exit 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}Error: You have uncommitted changes${NC}"
        echo -e "Please commit or stash your changes before deploying."
        exit 1
    fi
    
    # Check if we're on main branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" == "deploy" ]]; then
        echo -e "${RED}Error: Cannot deploy from 'deploy' branch${NC}"
        echo -e "Switch to 'main' or development branch first."
        exit 1
    fi
}

function get_current_version() {
    if [[ -f "package.json" ]]; then
        node -p "require('./package.json').version" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

function deploy_to_production() {
    local force="$1"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    local version=$(get_current_version)
    
    echo -e "${BLUE}Deployment Summary${NC}"
    echo -e "=================="
    echo -e "Source branch: ${YELLOW}$current_branch${NC}"
    echo -e "Version: ${YELLOW}$version${NC}"
    echo -e "Target: ${YELLOW}deploy${NC} branch → ${GREEN}https://timesync.app${NC}"
    echo -e ""
    
    if [[ "$force" != "true" ]]; then
        read -p "Continue with deployment? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}Deployment cancelled${NC}"
            exit 0
        fi
    fi
    
    # Build assets first
    echo -e "${BLUE}Building assets...${NC}"
    npm run build
    echo -e "${GREEN}✅ Assets built${NC}"
    
    # Check if deploy branch exists
    if git show-ref --verify --quiet refs/heads/deploy; then
        echo -e "${BLUE}Switching to deploy branch...${NC}"
        git checkout deploy
        
        echo -e "${BLUE}Merging $current_branch into deploy...${NC}"
        git merge "$current_branch" --no-edit
    else
        echo -e "${BLUE}Creating deploy branch...${NC}"
        git checkout -b deploy
    fi
    
    # Add the built files (these should be in .gitignore for main branch)
    echo -e "${BLUE}Adding built assets...${NC}"
    git add img/ apple-touch-icon.png favicon.ico -f
    
    # Commit if there are changes
    if ! git diff --staged --quiet; then
        git commit -m "Deploy v$version assets"
        echo -e "${GREEN}✅ Committed deployment assets${NC}"
    else
        echo -e "${YELLOW}No asset changes to commit${NC}"
    fi
    
    # Push to deploy branch
    echo -e "${BLUE}Pushing to GitHub...${NC}"
    git push origin deploy
    echo -e "${GREEN}✅ Pushed to deploy branch${NC}"
    
    # Return to original branch
    git checkout "$current_branch"
    echo -e "${BLUE}Returned to $current_branch branch${NC}"
    
    echo -e ""
    echo -e "${GREEN}🚀 Deployment complete!${NC}"
    echo -e "🌐 Production URL: ${GREEN}https://timesync.app${NC}"
    echo -e "⏱️  GitHub Pages typically updates within 1-2 minutes"
}

# Main execution
function main() {
    local force="false"
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        print_usage
        exit 0
    fi
    
    if [[ "$1" == "--force" ]]; then
        force="true"
    fi
    
    echo -e "${BLUE}🚀 TimeSync Deployment${NC}"
    echo -e "======================"
    
    validate_git_status
    deploy_to_production "$force"
}

# Run main function with all arguments
main "$@"