#!/bin/bash

# CREATE MARKDOWN FILES FROM JSON

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Please install jq before running this script."
    exit 1
fi

# Input JSON file
input_json="/Users/tlalocan/downloads/test.json"

# Output directory for Markdown files
output_dir="output_markdown"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Extract each object from JSON and convert to Markdown
jq -c '.[]' "$input_json" | while read -r obj; do
    # Generate a unique filename based on some property of the JSON object
    # filename="$output_dir/$(echo "$obj" | jq -r '"\(.time).\(.description)"').md"
    filename="$output_dir/$(echo "$obj" | jq -r '"\(.time|tostring|fromdate|strftime("%Y-%m-%d")).\(.description | ascii_downcase | gsub("\""; "\""))" | gsub(" "; "-") | gsub("\\("; "") | gsub("\\)"; "") | gsub("\\\""; "") | gsub("“"; "") | gsub("”"; "") | gsub(":"; "")').md"
    
    # Convert JSON object to Markdown and save it to the file
    echo -e "$obj" | jq -r '["---"] + (to_entries | map("\(.key): \(.value)")) + ["---"] | join("\n")' > "$filename"

    echo "Converted and saved to: $filename"
done

# END CREATE MARKDOWN FILES FROM JSON

# FORMAT MARKDOWN FILES

# Directory containing Markdown files
directory="/Users/tlalocan/downloads/output_markdown"

# Separator used in the tags field
tags_separator=" "

# Check if the directory exists
if [ ! -d "$directory" ]; then
    echo "Directory not found: $directory"
    exit 1
fi

# Process each Markdown file in the directory
for file in "$directory"/*.md; do
    # Check if the file is a regular file
    if [ -f "$file" ]; then
        # Process the Markdown file and create a temporary file
        temp_file=$(mktemp)
        awk -v sep="$tags_separator" -F': ' '            
            $1 == "tags" {
                # Convert the values into a list format
                printf "%s:\n", $1
                n = split($2, tags, sep)
                for (i = 1; i <= n; i++) {
                    printf " - %s\n", tags[i]
                }
            }
            $1 != "tags" {            
                # For other lines, print as is
                print
            }
        ' "$file" > "$temp_file"

        # Replace the original file with the updated content
        mv "$temp_file" "$file"
        echo "Updated: $file"
    fi
done

# END FORMAT MARKDOWN FILES

# ADD SINGLE TICKS TO SPECIFIED KEYS

# Specify the keys for which values should be enclosed in single quotes
target_keys=("href" "description" "time")

# Directory containing Markdown-like files
directory="/Users/tlalocan/downloads/output_markdown"

# Loop through each file in the directory
for file in "$directory"/*.md; do
    # Check if the file is a regular file
    if [ -f "$file" ]; then
        # Loop through target keys and add single quotes around values
        for key in "${target_keys[@]}"; do
            sed -E "s/^$key: (.*)$/$key: '\1'/" "$file" > "$file.temp"
            mv "$file.temp" "$file"
        done

        echo "Single quotes added to specified keys in: $file"
    fi
done

echo "Update complete."

# END ADD SINGLE TICKS TO SPECIFIED KEYS