#!/bin/bash

# svg2png.sh - Convert SVG to PNG using Inkscape
# Usage: ./svg2png.sh input.svg [output.png] [--size WIDTHxHEIGHT]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_usage() {
    echo -e "${BLUE}SVG to PNG Converter${NC}"
    echo -e "Usage: $0 <input.svg> [output.png] [options]"
    echo -e ""
    echo -e "Arguments:"
    echo -e "  input.svg     Input SVG file (required)"
    echo -e "  output.png    Output PNG file (optional, defaults to input name)"
    echo -e ""
    echo -e "Options:"
    echo -e "  --size WxH    Output size in pixels (e.g., --size 512x512)"
    echo -e "  --width W     Output width in pixels (maintains aspect ratio)"
    echo -e "  --height H    Output height in pixels (maintains aspect ratio)"
    echo -e "  --dpi DPI     Output DPI (default: 96)"
    echo -e "  --quality Q   PNG quality 0-100 (default: 95)"
    echo -e "  -h, --help    Show this help message"
    echo -e ""
    echo -e "Examples:"
    echo -e "  $0 icon.svg                    # Convert to icon.png"
    echo -e "  $0 icon.svg logo.png           # Convert to logo.png"
    echo -e "  $0 icon.svg --size 512x512     # Convert to 512x512 PNG"
    echo -e "  $0 icon.svg icon-hd.png --width 1024  # Convert with 1024px width"
    echo -e ""
    echo -e "PWA Icon Generation:"
    echo -e "  $0 timesync.svg --size 16x16    # Favicon size"
    echo -e "  $0 timesync.svg --size 192x192  # Standard PWA icon"
    echo -e "  $0 timesync.svg --size 512x512  # Large PWA icon"
}

function check_dependencies() {
    if ! command -v inkscape &> /dev/null; then
        echo -e "${RED}Error: Inkscape not found${NC}"
        echo -e "Install with:"
        echo -e "  macOS: brew install inkscape"
        echo -e "  Ubuntu: sudo apt install inkscape"
        echo -e "  Or download from: https://inkscape.org/release/"
        exit 1
    fi
}

function validate_input() {
    local input_file="$1"
    
    if [[ ! -f "$input_file" ]]; then
        echo -e "${RED}Error: Input file '$input_file' not found${NC}"
        exit 1
    fi
    
    if [[ ! "$input_file" =~ \.svg$ ]]; then
        echo -e "${YELLOW}Warning: Input file doesn't have .svg extension${NC}"
    fi
    
    # Basic SVG validation
    if ! grep -q "<svg" "$input_file"; then
        echo -e "${RED}Error: '$input_file' doesn't appear to be a valid SVG file${NC}"
        exit 1
    fi
}

function get_output_filename() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -n "$output_file" ]]; then
        echo "$output_file"
    else
        # Replace .svg with .png
        echo "${input_file%.*}.png"
    fi
}

function convert_svg() {
    local input_file="$1"
    local output_file="$2"
    local width="$3"
    local height="$4"
    local dpi="$5"
    
    echo -e "${BLUE}Converting SVG to PNG...${NC}"
    echo -e "Input:  $input_file"
    echo -e "Output: $output_file"
    
    # Build inkscape command
    local cmd="inkscape"
    
    # Add size parameters
    if [[ -n "$width" && -n "$height" ]]; then
        cmd="$cmd --export-width=$width --export-height=$height"
        echo -e "Size:   ${width}x${height}px"
    elif [[ -n "$width" ]]; then
        cmd="$cmd --export-width=$width"
        echo -e "Width:  ${width}px (maintaining aspect ratio)"
    elif [[ -n "$height" ]]; then
        cmd="$cmd --export-height=$height"
        echo -e "Height: ${height}px (maintaining aspect ratio)"
    fi
    
    # Add DPI if specified
    if [[ -n "$dpi" ]]; then
        cmd="$cmd --export-dpi=$dpi"
        echo -e "DPI:    $dpi"
    fi
    
    # Add input and output files
    cmd="$cmd --export-filename='$output_file' '$input_file'"
    
    # Execute conversion
    if eval "$cmd"; then
        echo -e "${GREEN}✅ Conversion successful!${NC}"
        
        # Show file info
        if command -v file &> /dev/null; then
            echo -e "Output: $(file "$output_file")"
        fi
        
        # Show file size
        if [[ -f "$output_file" ]]; then
            local size=$(ls -lh "$output_file" | awk '{print $5}')
            echo -e "Size:   $size"
        fi
    else
        echo -e "${RED}❌ Conversion failed${NC}"
        exit 1
    fi
}

# Parse command line arguments
input_file=""
output_file=""
width=""
height=""
dpi="96"
quality="95"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        --size)
            if [[ -n "$2" && "$2" =~ ^[0-9]+x[0-9]+$ ]]; then
                width=$(echo "$2" | cut -d'x' -f1)
                height=$(echo "$2" | cut -d'x' -f2)
                shift 2
            else
                echo -e "${RED}Error: --size requires format WIDTHxHEIGHT (e.g., 512x512)${NC}"
                exit 1
            fi
            ;;
        --width)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                width="$2"
                shift 2
            else
                echo -e "${RED}Error: --width requires a numeric value${NC}"
                exit 1
            fi
            ;;
        --height)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                height="$2"
                shift 2
            else
                echo -e "${RED}Error: --height requires a numeric value${NC}"
                exit 1
            fi
            ;;
        --dpi)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                dpi="$2"
                shift 2
            else
                echo -e "${RED}Error: --dpi requires a numeric value${NC}"
                exit 1
            fi
            ;;
        --quality)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]] && [[ "$2" -ge 0 && "$2" -le 100 ]]; then
                quality="$2"
                shift 2
            else
                echo -e "${RED}Error: --quality requires a value between 0-100${NC}"
                exit 1
            fi
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            print_usage
            exit 1
            ;;
        *)
            if [[ -z "$input_file" ]]; then
                input_file="$1"
            elif [[ -z "$output_file" ]]; then
                output_file="$1"
            else
                echo -e "${RED}Error: Too many arguments${NC}"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Main execution
function main() {
    if [[ -z "$input_file" ]]; then
        echo -e "${RED}Error: Input SVG file is required${NC}"
        print_usage
        exit 1
    fi
    
    echo -e "${BLUE}🎨 SVG to PNG Converter${NC}"
    echo -e "========================="
    
    check_dependencies
    validate_input "$input_file"
    
    output_file=$(get_output_filename "$input_file" "$output_file")
    
    # Check if output file exists
    if [[ -f "$output_file" ]]; then
        echo -e "${YELLOW}Warning: Output file '$output_file' already exists${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Conversion cancelled${NC}"
            exit 0
        fi
    fi
    
    convert_svg "$input_file" "$output_file" "$width" "$height" "$dpi"
    
    echo -e "${GREEN}Conversion complete!${NC}"
}

# Run main function
main "$@"