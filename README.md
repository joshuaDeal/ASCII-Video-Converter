# vid2ascii

A Bash script to render video files into ASCII art using `jp2a`, `ffmpeg`, and `ImageMagick`.

## Features

- Extracts frames from a video and converts them to ASCII art.
- Reassembles the ASCII art frames back into a video.
- Supports audio extraction and inclusion in the output video.

## Requirements

- `ffmpeg`
- `jp2a`
- `ImageMagick`

## Usage

```bash
./vid2ascii.sh [options] <video_file>
```

### Options

- `-h, --help`          Show help message and exit.
- `-o, --output FILE`   Specify output video file name (default: `ascii_video.mp4`).
- `-j, --jp2a`          Pass arguments to jp2a.

### Examples

```bash
./vid2ascii.sh -o output.mp4 input.mp4    # Render 'input.mp4' and save as 'output.mp4'.
./vid2ascii.sh input.mp4                  # Render 'input.mp4' and save as 'ascii_video.mp4'.
./vid2ascii.sh -j "--color" input.mp4     # Render 'input.mp4' an ascii video in color.
```
