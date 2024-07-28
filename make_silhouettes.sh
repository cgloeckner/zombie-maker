#!/bin/bash
#
# Script Name: make_silhouettes.sh
# Description: Processes PNG images to replace non-transparent pixels with black while preserving transparency.
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

SRC_DIR="assets/original"
DST_DIR="assets/silhouettes"

# Ensure the destination directory exists
mkdir -p "$DST_DIR"

# Process each PNG file in the source directory
for file in "$SRC_DIR"/*.png; do
    if [[ -f "$file" ]]; then
        # Get the base name of the file
        base_name=$(basename "$file")

        # Convert the image: replace non-transparent pixels with black and preserve transparency
        convert "$file" \
            -alpha extract -background black -alpha shape \
            -trim "$DST_DIR/$base_name"
    fi
done

echo "Processing complete. Check the '$DST_DIR' directory for the output files."