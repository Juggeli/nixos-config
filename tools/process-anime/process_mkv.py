#!/usr/bin/env python3
"""
Process MKV files to keep only the best Japanese audio track and convert to OPUS.
"""

import os
import sys
from pathlib import Path
import ffmpeg
import argparse


def get_audio_streams(file_path):
    """Get audio stream information from the video file."""
    try:
        probe = ffmpeg.probe(file_path)
        audio_streams = []
        
        for stream in probe['streams']:
            if stream['codec_type'] == 'audio':
                stream_info = {
                    'index': stream['index'],
                    'language': stream.get('tags', {}).get('language', 'und'),
                    'codec': stream['codec_name'],
                    'channels': stream.get('channels', 0),
                    'sample_rate': stream.get('sample_rate', 0),
                    'bit_rate': int(stream.get('bit_rate', 0)) if stream.get('bit_rate') else 0
                }
                audio_streams.append(stream_info)
        
        return audio_streams
    except ffmpeg.Error as e:
        print(f"Error probing {file_path}: {e}")
        return []


def find_best_japanese_stream(audio_streams):
    """Find the best quality Japanese audio stream."""
    japanese_streams = [s for s in audio_streams if s['language'] in ['jpn', 'ja', 'japanese']]
    
    if not japanese_streams:
        print("  No Japanese audio streams found")
        return None
    
    # Sort by quality: channels first, then bit_rate, then sample_rate
    japanese_streams.sort(key=lambda x: (x['channels'], x['bit_rate'], x['sample_rate']), reverse=True)
    
    best_stream = japanese_streams[0]
    print(f"  Found {len(japanese_streams)} Japanese stream(s), selecting: "
          f"Stream {best_stream['index']} ({best_stream['channels']}ch, "
          f"{best_stream['bit_rate']}bps, {best_stream['codec']})")
    
    return best_stream


def get_opus_bitrate(channels):
    """Get appropriate OPUS bitrate based on channel count."""
    if channels <= 2:
        return "128k"  # Stereo/mono
    else:
        return "256k"  # Multi-channel


def process_mkv_file(input_path, output_dir=None):
    """Process a single MKV file."""
    print(f"Processing: {input_path}")
    
    audio_streams = get_audio_streams(input_path)
    if not audio_streams:
        print("  No audio streams found, skipping")
        return False
    
    best_japanese = find_best_japanese_stream(audio_streams)
    if not best_japanese:
        print("  No Japanese audio stream found, skipping")
        return False
    
    # Determine output path
    if output_dir:
        output_path = Path(output_dir) / Path(input_path).name
    else:
        output_path = Path(input_path).parent / f"{Path(input_path).stem}_processed.mkv"
    
    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Check if audio is already OPUS
    is_opus = best_japanese['codec'] == 'opus'
    
    try:
        if is_opus:
            print(f"  Audio already OPUS, copying without re-encoding")
            audio_codec = 'copy'
            audio_bitrate = None
        else:
            # Get OPUS bitrate based on channel count
            opus_bitrate = get_opus_bitrate(best_japanese['channels'])
            print(f"  Converting to OPUS {opus_bitrate} ({best_japanese['channels']} channels)")
            audio_codec = 'libopus'
            audio_bitrate = opus_bitrate
        
        print(f"  Output: {output_path}")
        
        # Build ffmpeg command
        input_stream = ffmpeg.input(str(input_path))
        
        # Copy video stream as-is, select and convert/copy the Japanese audio stream
        output_args = {
            'vcodec': 'copy',  # Copy video without re-encoding
            'acodec': audio_codec,
            'map_metadata': 0,  # Copy metadata
            'disposition:a:0': 'default'  # Set audio as default
        }
        
        if audio_bitrate:
            output_args['audio_bitrate'] = audio_bitrate
        
        output = ffmpeg.output(
            input_stream['v:0'],  # Copy first video stream
            input_stream[f'{best_japanese["index"]}'],  # Select the Japanese audio stream
            str(output_path),
            **output_args
        )
        
        # Run the conversion
        ffmpeg.run(output, overwrite_output=True, quiet=True)
        print(f"  ✓ Successfully processed")
        return True
        
    except ffmpeg.Error as e:
        print(f"  ✗ Error processing file: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description='Process MKV files to keep only Japanese audio in OPUS format')
    parser.add_argument('input_dir', help='Directory containing MKV files to process')
    parser.add_argument('-o', '--output', help='Output directory (default: same as input with _processed suffix)')
    parser.add_argument('-r', '--recursive', action='store_true', help='Process directories recursively')
    
    args = parser.parse_args()
    
    input_path = Path(args.input_dir)
    if not input_path.exists():
        print(f"Error: Input directory '{input_path}' does not exist")
        sys.exit(1)
    
    # Find all MKV files
    if args.recursive:
        mkv_files = list(input_path.rglob('*.mkv'))
    else:
        mkv_files = list(input_path.glob('*.mkv'))
    
    if not mkv_files:
        print(f"No MKV files found in {input_path}")
        sys.exit(1)
    
    print(f"Found {len(mkv_files)} MKV file(s) to process")
    
    success_count = 0
    for mkv_file in mkv_files:
        if process_mkv_file(mkv_file, args.output):
            success_count += 1
        print()  # Empty line between files
    
    print(f"Processing complete: {success_count}/{len(mkv_files)} files processed successfully")


if __name__ == '__main__':
    main()