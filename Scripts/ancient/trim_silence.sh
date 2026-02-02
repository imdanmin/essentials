#!/usr/bin/env bash
# trim_silence.sh: remove silence in audio file using ffmpeg silenceremove

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
    echo "Error: Please provide an audio file." >&2
    echo "Usage: $0 <audio file>" >&2
    exit 1
fi

input="$*"

# Validate that the input file exists
if [ ! -f "$input" ]; then
    echo "Error: File '$input' does not exist or is not a regular file." >&2
    exit 1
fi

# Extract filename and extension
filename="${input%.*}"
extension="${input##*.}"

# Validate that the file has an extension
if [ "$extension" = "$input" ]; then
    echo "Error: File '$input' has no extension." >&2
    exit 1
fi

# Run ffmpeg with quoted variables to handle spaces
ffmpeg -i "$input" -af silenceremove=1:0:-50dB "${filename}_TRIMMED.${extension}"

# Check if ffmpeg succeeded
if [ $? -ne 0 ]; then
    echo "Error: ffmpeg failed to process the file." >&2
    exit 1
fi

echo "Successfully processed '$input' to '${filename}_TRIMMED.${extension}'"
