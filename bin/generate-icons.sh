#!/bin/bash

# TimeSync Icon Generator
# Generates all required PWA icons from a high-resolution source image
# 
# Usage: ./bin/generate-icons.sh [source-image-path]
# Example: ./bin/generate-icons.sh icon-source.png
# 
# Requirements: ImageMagick (brew install imagemagick on macOS, apt install imagemagick on Ubuntu)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Icon sizes required for the PWA
declare -a ICON_SIZES=(
    "16:icon-16x16.png"
    "32:icon-32x32.png" 
    "72:icon-72x72.png"
    "96:icon-96x96.png"
    "128:icon-128x128.png"
    "144:icon-144x144.png"
    "152:icon-152x152.png"
    "192:icon-192x192.png"
    "384:icon-384x384.png"
    "512:icon-512x512.png"
)

# Favicon sizes
declare -a FAVICON_SIZES=(16 32 48)

function print_usage() {
    echo -e "${BLUE}TimeSync Icon Generator${NC}"
    echo -e "Usage: $0 <source-image-path>"
    echo -e ""
    echo -e "Example:"
    echo -e "  $0 timesync-logo.png"
    echo -e "  $0 ../design/icon-1024x1024.png"
    echo -e ""
    echo -e "Requirements:"
    echo -e "  - ImageMagick (convert command)"
    echo -e "  - Source image should be at least 512x512 pixels"
    echo -e "  - Source image should be square or will be cropped to square"
    echo -e ""
    echo -e "Generated files will be placed in:"
    echo -e "  - img/ directory for PWA icons"
    echo -e "  - Root directory for favicon.ico and apple-touch-icon.png"
}

function check_dependencies() {
    if ! command -v convert &> /dev/null; then
        echo -e "${RED}Error: ImageMagick 'convert' command not found${NC}"
        echo -e "Install with:"
        echo -e "  macOS: brew install imagemagick"
        echo -e "  Ubuntu: sudo apt install imagemagick"
        exit 1
    fi
    
    if ! command -v identify &> /dev/null; then
        echo -e "${RED}Error: ImageMagick 'identify' command not found${NC}"
        exit 1
    fi
}

function validate_source_image() {
    local source_path="$1"
    
    if [[ ! -f "$source_path" ]]; then
        echo -e "${RED}Error: Source image '$source_path' not found${NC}"
        exit 1
    fi
    
    # Get image dimensions
    local dimensions=$(identify -format "%wx%h" "$source_path" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Cannot read image '$source_path'${NC}"
        exit 1
    fi
    
    local width=$(echo "$dimensions" | cut -d'x' -f1)
    local height=$(echo "$dimensions" | cut -d'x' -f2)
    
    echo -e "${BLUE}Source image: $source_path${NC}"
    echo -e "Dimensions: ${width}x${height}"
    
    if [[ $width -lt 512 || $height -lt 512 ]]; then
        echo -e "${YELLOW}Warning: Source image is smaller than 512x512. Results may be poor quality.${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    if [[ $width -ne $height ]]; then
        echo -e "${YELLOW}Warning: Source image is not square. It will be cropped to square.${NC}"
    fi
}

function create_directories() {
    echo -e "${BLUE}Creating directories...${NC}"
    
    if [[ ! -d "img" ]]; then
        mkdir -p img
        echo -e "${GREEN}✅ Created img/ directory${NC}"
    else
        echo -e "${GREEN}✅ img/ directory exists${NC}"
    fi
}

function generate_png_icons() {
    local source_path="$1"
    
    echo -e "${BLUE}Generating PNG icons...${NC}"
    
    for size_info in "${ICON_SIZES[@]}"; do
        local size=$(echo "$size_info" | cut -d':' -f1)
        local filename=$(echo "$size_info" | cut -d':' -f2)
        local output_path="img/$filename"
        
        echo -e "Generating ${filename} (${size}x${size})..."
        
        # Convert with high quality settings
        convert "$source_path" \
            -resize "${size}x${size}^" \
            -gravity center \
            -extent "${size}x${size}" \
            -strip \
            -quality 95 \
            "$output_path"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Generated: $output_path${NC}"
        else
            echo -e "${RED}❌ Failed to generate: $output_path${NC}"
            exit 1
        fi
    done
}

function generate_favicon() {
    local source_path="$1"
    
    echo -e "${BLUE}Generating favicon.ico...${NC}"
    
    # Create temporary PNG files for ICO generation
    local temp_files=()
    
    for size in "${FAVICON_SIZES[@]}"; do
        local temp_file="temp_favicon_${size}.png"
        temp_files+=("$temp_file")
        
        convert "$source_path" \
            -resize "${size}x${size}^" \
            -gravity center \
            -extent "${size}x${size}" \
            -strip \
            "$temp_file"
    done
    
    # Combine into ICO file
    convert "${temp_files[@]}" favicon.ico
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Generated: favicon.ico${NC}"
    else
        echo -e "${RED}❌ Failed to generate: favicon.ico${NC}"
    fi
    
    # Clean up temporary files
    for temp_file in "${temp_files[@]}"; do
        rm -f "$temp_file"
    done
}

function generate_apple_touch_icon() {
    local source_path="$1"
    
    echo -e "${BLUE}Generating apple-touch-icon.png...${NC}"
    
    # Generate a 180x180 Apple touch icon
    convert "$source_path" \
        -resize "180x180^" \
        -gravity center \
        -extent "180x180" \
        -strip \
        -quality 95 \
        "apple-touch-icon.png"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Generated: apple-touch-icon.png${NC}"
    else
        echo -e "${RED}❌ Failed to generate: apple-touch-icon.png${NC}"
    fi
}

function show_summary() {
    echo -e "${BLUE}Generation complete!${NC}"
    echo -e ""
    echo -e "Generated files:"
    echo -e "  📁 img/ directory with ${#ICON_SIZES[@]} PNG icons"
    echo -e "  🍎 apple-touch-icon.png (180x180)"
    echo -e "  ⭐ favicon.ico (multi-size)"
    echo -e ""
    echo -e "File structure:"
    tree -L 2 . 2>/dev/null || {
        echo -e "  ./"
        echo -e "  ├── img/"
        ls img/ | sed 's/^/  │   ├── /'
        echo -e "  ├── apple-touch-icon.png"
        echo -e "  └── favicon.ico"
    }
    echo -e ""
    echo -e "${GREEN}All icons generated successfully!${NC}"
    echo -e "You can now deploy your PWA with all required icons."
}

# Main execution
function main() {
    if [[ $# -eq 0 ]]; then
        print_usage
        exit 1
    fi
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        print_usage
        exit 0
    fi
    
    local source_path="$1"
    
    echo -e "${BLUE}🎨 TimeSync Icon Generator${NC}"
    echo -e "=================================="
    
    check_dependencies
    validate_source_image "$source_path"
    create_directories
    generate_png_icons "$source_path"
    generate_favicon "$source_path"
    generate_apple_touch_icon "$source_path"
    show_summary
}

# Run main function with all arguments
main "$@"