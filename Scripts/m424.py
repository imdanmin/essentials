#!/home/dan/.local/env/misc/bin/python

import os
import sys
import tempfile
from moviepy import AudioFileClip, ImageClip
import moviepy
from PIL import Image

# Function to validate file existence and extension
def validate_file(file_path, expected_exts):
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    if not any(file_path.lower().endswith(ext) for ext in expected_exts):
        raise ValueError(f"File must have one of {expected_exts} extensions: {file_path}")

# Function to create a minimal solid black JPG
def create_black_image(output_path, width=640, height=360):
    # Create a black image using PIL with minimal resolution
    image = Image.new('RGB', (width, height), (0, 0, 0))  # Black color
    image.save(output_path, 'JPEG', quality=10)  # Very low quality to minimize file size
    return output_path

# Check if correct number of arguments is provided
if len(sys.argv) != 2:
    print("Usage: python convert_audio_to_mp4.py <input_audio> (supports .m4a or .mp4)")
    sys.exit(1)

# Get command-line argument
input_path = sys.argv[1]

# Validate input
validate_file(input_path, ('.m4a', '.mp4'))

# Generate output path automatically from input_path
base, ext = os.path.splitext(input_path)
output_path = base + ('_video' if ext.lower() == '.mp4' else '') + '.mp4'

# Create a temporary black JPG image
with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_image:
    image_path = create_black_image(temp_image.name)

try:
    # Load the audio
    audio = AudioFileClip(input_path)

    # Create a video clip from the black image, set to the audio's duration
    video = ImageClip(image_path).with_duration(audio.duration)

    # Set the audio to the video clip
    video = video.with_audio(audio)

    # Write the output MP4 file with optimized compression
    video.write_videofile(
        output_path,
        codec='libx264',
        audio_codec='aac',
        bitrate='500k',  # Low video bitrate for minimal file size
        audio_bitrate='64k',  # Low audio bitrate
        fps=1  # Single frame for static image
    )

    print(f"Successfully created {output_path}")

finally:
    # Clean up the temporary image file
    if os.path.exists(image_path):
        os.remove(image_path)
