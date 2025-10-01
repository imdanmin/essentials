#!/bin/bash

set -euo pipefail

# 1. Number of parallel jobs = 3/5 of available cores (rounded down)
CORES=$(nproc)
JOBS=$(( (CORES * 3) / 5 ))
if [ "$JOBS" -lt 1 ]; then
    JOBS=1
fi

echo "Detected $CORES cores, using $JOBS parallel jobs."

# 2. Function to process a single file
process_file() {
    infile="$1"
    dir="$(dirname "$infile")"
    base="$(basename "$infile")"
    name="${base%.*}"
    ext="${base##*.}"

    outdir="$dir/Trimmed"
    outfile="$outdir/${name}_TRIMMED.${ext}"

    mkdir -p "$outdir"

    # liberal silence removal: anything quieter than -30dB for 0.3s
    # ffmpeg -hide_banner -loglevel error -y -i "$infile" \
        # -af "silenceremove=start_periods=1:start_threshold=-30dB:start_silence=0.3:stop_periods=-1:stop_threshold=-30dB:stop_silence=0.3" \
        # "$outfile"

    echo "Processed: $infile -> $outfile"
}

export -f process_file

# 3. Find all audio files (add extensions as needed)
find . -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.opus" -o -iname "*.flac" -o -iname "*.m4a" \) \
    | parallel -j "$JOBS" process_file {}
