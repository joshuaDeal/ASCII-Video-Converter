#!/bin/bash

# Render video files with jp2a

# Print a helpful message.
printHelp() {
 	echo "Usage: $0 [options] <video_file>"
 	echo ""
 	echo "Render video files with jp2a."
 	echo ""
 	echo "Options:"
 	echo "  -h, --help          Show this help message and exit."
 	echo "  -o, --output FILE   Specify the output video file name. Default is 'ascii_video.mp4'."
 	echo "  -j, --jp2a OPTIONS  Additional options to pass to jp2a (enclosed in quotes)."
 	echo ""
 	echo "Arguments:"
 	echo "  <video_file>        The video file to process."
 	echo ""
 	echo "Examples:"
 	echo "  $0 -o output.mp4 input.mp4  # Render 'input.mp4' and save as 'output.mp4'."
 	echo "  $0 -j '--fill --color' input.mp4  # Render with additional jp2a options."
 	echo "  $0 input.mp4               # Render 'input.mp4' and save as 'ascii_video.mp4'."
 	echo ""
 	echo "This script extracts frames from the specified video file, converts them to ASCII art,"
 	echo "and rebuilds a video from the ASCII representations."
 	echo ""
 	echo "Dependencies:"
 	echo "  - ffmpeg"
 	echo "  - jp2a"
 	echo "  - ImageMagick (for capturing screenshots)"
 	echo ""
}

# Evaluate command line arguments.
evalArgs() {
	arguments=("$@")

	for ((i =0; i < ${#arguments[@]}; i++)); do
		# Print help message.
		if [ "${arguments[i]}" == "-h" ] || [ "${arguments[i]}" == "--help" ]; then
			printHelp
			exit
		fi

		# Specify output file name.
		if [ "${arguments[i]}" == "-o" ] || [ "${arguments[i]}" == "--output" ]; then
			out_file=${arguments[i + 1]}
		fi

		# Specify jp2a options.
		if [ "${arguments[i]}" == "-j" ] || [ "${arguments[i]}" == "--jp2a" ]; then
			jp2a_options=${arguments[i + 1]}
		fi
	done
}

# Get details about video like frame count and frame rate.
getVideoDetails() {
	FILE=$1

	# Get frame rate.
	frame_rate=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of csv=p=0 "$FILE")

	# convert frame_rate from fractions to a float value (to get the actual frame rate)
	frame_rate_value=$(echo "scale=2; $frame_rate" | bc)

	# Get frame count.
	frame_count=$(ffmpeg -i "$FILE" -map 0:v:0 -c copy -f null - 2>&1 | grep -oP 'frame=\s*\K[0-9]+')

	echo "Video file: $FILE"
	echo "Frame Rate: $frame_rate_value fps"
	echo "Number of Frames: $frame_count"
}

# Break video into individual frames.
breakVideo() {
	frame_count=$1

	# Create directory.
	dir_name=$(mktemp -d /tmp/frames_XXXXXX)

	# Get number of digits for file names.
	num_digits=${#frame_count}

	# Use ffmpeg to extract frames.
	ffmpeg -i "$FILE" "$dir_name/%0${num_digits}d.png"

	echo "Frames saved to: $dir_name"
}

# Convert each frame into ascii.
frames2Text() {
	dir_name=$1
	frame_count=$2

	# Iterate over all frames.
	for frame in "$dir_name"/*.png; do
		base_name=$(basename "$frame" .png)

		# Convert each image to text with provided jp2a options.
		jp2a $jp2a_options "$frame" > "$dir_name/$base_name.txt"

	done
}

# Screen shot each textual frame to create new image files.
text2Img() {
	dir_name=$1

	mkdir "$dir_name/ascii"

	for file in "$dir_name"/*.txt; do
		base_name=$(basename "$file" .txt)

		clear
		cat "$file"
		sleep .1s
		import -window "$WINDOWID" "$dir_name/ascii/$base_name-ascii.png"
	done

	# Remove old images.
	rm "$dir_name"/*.png
}

# Reassemble video using ascii rendered frames.
remakeVideo() {
	dir_name=$1
	frame_count=$2
	frame_rate=$3
	newfile=$4

	# Create new video.
	ffmpeg -framerate "$frame_rate" -i "$dir_name/ascii/%0${#frame_count}d-ascii.png" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -bf 2 -b:v 4M -c:a aac -b:a 192k -shortest "$dir_name/no-sound.mp4"

	# Process audio if it exists.
	if [ -n "$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 $FILE)" ]; then
		# Extract audio from original video.
		ffmpeg -i "$FILE" -q:a 0 -map a "$dir_name/audio.mp3"

		# Add sound to the new video.
		ffmpeg -i "$dir_name/no-sound.mp4" -i "$dir_name/audio.mp3" -c:v copy -c:a aac -b:a 192k -shortest "$newfile"

	else
		mv "$dir_name/no-sound.mp4" "$newfile"
	fi

	echo "Reassembled video created: $newfile"
}

# Clean up old files.
cleanUp() {
	dir_name=$1
	if [[ -d "$dir_name" ]]; then
		rm -r "$dir_name"
		echo "Cleaned up temporary files in: $dir_name"
	else
		echo "No temporary files to clean up."
	fi
}

set -e

out_file=ascii_video.mp4
jp2a_options=""  # Default to no options.
evalArgs "$@"
getVideoDetails "${!#}"
breakVideo "$frame_count"
frames2Text "$dir_name" "$frame_count"
text2Img "$dir_name"
remakeVideo "$dir_name" "$frame_count" "$frame_rate_value" "$out_file"
cleanUp "$dir_name"

