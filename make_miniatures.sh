#!/bin/bash
#
# Script Name: make_miniatures.sh
# Description: Processes PNG images to create miniature sheets for printing and merges them into a single PDF.
# Created by: ChatGPT
#
# This script is created by ChatGPT, an AI language model developed by OpenAI.
#
# License: MIT License
# 
# The MIT License (MIT)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Ensure ImageMagick is installed
if ! command -v convert &> /dev/null
then
    echo "ImageMagick is not installed. Please install it and run this script again."
    exit 1
fi

# Source and destination directories
SRC_DIR="assets/silhouettes"
DST_DIR="assets/printnplay"

# Ensure the destination directory exists
mkdir -p "$DST_DIR"

# US Letter dimensions in pixels at 300 DPI (landscape orientation)
US_LETTER_WIDTH=3300
US_LETTER_HEIGHT=2550

# Target height for each miniature (28mm at 300 DPI)
TARGET_HEIGHT=330

# Padding between images and the edges of the US Letter sheet in pixels (1 cm)
PADDING=118

# Padding between miniature and its mirror image
MINI_PADDING=10

# Calculate the number of miniatures that can fit horizontally and vertically
NUM_COLS=$(( (US_LETTER_WIDTH - PADDING) / (TARGET_HEIGHT + PADDING) ))
NUM_ROWS=$(( (US_LETTER_HEIGHT - PADDING) / (2 * TARGET_HEIGHT + MINI_PADDING + PADDING) ))

# Ensure we consider the possibility of a third row
if (( NUM_ROWS < 3 )); then
    NUM_ROWS=3
fi

# Array to hold images for the current sheet
current_sheet_images=()
sheet_counter=1

# Function to create a new US Letter sheet with the given images
create_sheet() {
    local images=("$@")
    local sheet_file="$DST_DIR/sheet_$sheet_counter.png"
    
    # Create a blank US Letter canvas in landscape orientation
    convert -size ${US_LETTER_WIDTH}x${US_LETTER_HEIGHT} canvas:white "$sheet_file"
    
    # Position the images on the canvas
    local x_offset=$PADDING
    local y_offset=$PADDING
    for img in "${images[@]}"; do
        convert "$sheet_file" "$img" -gravity Northwest -geometry +$x_offset+$y_offset -composite "$sheet_file"
        x_offset=$((x_offset + TARGET_HEIGHT + PADDING))
        
        # Move to the next row if the end of the column is reached
        if (( x_offset + TARGET_HEIGHT + PADDING > US_LETTER_WIDTH )); then
            x_offset=$PADDING
            y_offset=$((y_offset + 2 * TARGET_HEIGHT + MINI_PADDING + PADDING))
        fi
    done

    # Add folding lines exactly between each image and its mirror image
    y_offset=$((TARGET_HEIGHT + MINI_PADDING / 2 + PADDING))
    for (( i=0; i<NUM_ROWS; i++ )); do
        convert "$sheet_file" -stroke black -strokewidth 2 -draw "line 0,$y_offset $US_LETTER_WIDTH,$y_offset" "$sheet_file"
        y_offset=$((y_offset + 2 * TARGET_HEIGHT + MINI_PADDING + PADDING))
    done
    
    echo "Created $sheet_file"
    sheet_counter=$((sheet_counter + 1))
}

# Process each PNG file in the source directory
for file in "$SRC_DIR"/*.png; do
    if [[ -f "$file" ]]; then
        # Get the base name of the file
        base_name=$(basename "$file")

        # Convert the image: trim transparent edges, resize to 330px height, and create a mirrored image
        temp_img="$DST_DIR/temp_$base_name"
        convert "$file" \
            -trim \
            -resize x$TARGET_HEIGHT \
            miff:- |\
        convert - \
            -alpha on -background none \
            -gravity center -extent ${TARGET_HEIGHT}x$((TARGET_HEIGHT + MINI_PADDING)) \
            \( +clone -flip \) \
            -append \
            -gravity center -background none -extent ${TARGET_HEIGHT}x$((2 * TARGET_HEIGHT + MINI_PADDING)) \
            "$temp_img"
        
        # Add the image to the current sheet
        current_sheet_images+=("$temp_img")
    fi
done

# Function to fill the sheet with images, repeating the assets if needed
fill_sheet() {
    local images=("$@")
    local total_images_needed=$((NUM_COLS * NUM_ROWS))
    local repeated_images=()
    
    while [[ ${#repeated_images[@]} -lt $total_images_needed ]]; do
        repeated_images+=("${images[@]}")
    done
    
    repeated_images=("${repeated_images[@]:0:$total_images_needed}")
    create_sheet "${repeated_images[@]}"
}

# Create sheets with the collected images, reusing assets if needed
while [[ ${#current_sheet_images[@]} -gt 0 ]]; do
    fill_sheet "${current_sheet_images[@]}"
    current_sheet_images=()
done

# Clean up temporary images
rm "$DST_DIR"/temp_*.png

# Merge all sheet PNGs into a single PDF
convert "$DST_DIR/sheet_*.png" "$DST_DIR/printnplay.pdf"

echo "Processing complete. Check the '$DST_DIR' directory for the output files."
