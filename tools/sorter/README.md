# Sorter - Interactive Media File Organizer

A modern, interactive TUI replacement for the Fish shell sorter script. Built with Go and Charm's Bubble Tea framework.

## Features

- **Interactive TUI**: Beautiful terminal interface with progress indicators and intuitive controls
- **Configurable**: YAML configuration file with customizable directories and file extensions
- **Media Preview**: Integrates with mpv for file preview during sorting
- **Batch Operations**: Review all actions before executing them
- **Smart Cleanup**: Automatically removes junk files and empty directories
- **Multi-platform**: Works on Linux and macOS

## Installation

This package is integrated into the NixOS/Darwin dotfiles configuration. Build with:

```bash
nix build .#sorter
```

## Configuration

Configuration is stored in `~/.config/sorter/config.yaml`. On first run, a default configuration will be created with the following structure:

```yaml
base_dir: "~/Downloads/unsorted/"
categories:
  category1:
    path: "~/sorted/category1/"
    hotkey: "1"
  category2:
    path: "~/sorted/category2/"
    hotkey: "2"
  category3:
    path: "~/sorted/category3/"
    hotkey: "3"
  archive:
    path: "~/sorted/archive/"
    hotkey: "a"
video_extensions:
  - .mkv
  - .mp4
  - .avi
  # ... more extensions
junk_extensions:
  - .apk
  - .ass
  - .srt
  # ... more extensions
player_command: "mpv --really-quiet"
junk_video_patterns:
  - "sample*"
  - "trailer*" 
  - "preview*"
```

### Customizing Categories and Hotkeys

You can customize categories by editing the config file:

```yaml
categories:
  movies:
    path: "~/media/movies/"
    hotkey: "m"
  shows:
    path: "~/media/shows/"
    hotkey: "s"
  documentaries:
    path: "~/media/documentaries/"
    hotkey: "d"
```

This allows you to:
- Add/remove categories
- Change destination paths
- Customize hotkeys (can be any single character)
- The hotkeys will automatically appear in the TUI help text

### Junk Video Pattern Detection

The sorter can automatically detect and mark junk video files for deletion based on filename patterns:

- **Automatic Detection**: Files matching patterns in `junk_video_patterns` are automatically marked for deletion during scanning
- **Dynamic Pattern Addition**: Press `x` during file review to add the current file's pattern to the config
- **Pattern Matching**: Supports wildcards (`*`) for flexible matching:
  - `sample*` matches "sample_video.mkv", "sample123.mp4", etc.
  - `*trailer` matches "movie_trailer.mkv", "test_trailer.avi", etc.
  - `*preview*` matches "movie_preview_clip.mkv", etc.

**Examples of useful patterns:**
```yaml
junk_video_patterns:
  - "sample*"      # Sample videos
  - "trailer*"     # Trailer files
  - "preview*"     # Preview clips
  - "*test*"       # Test files
  - "*temp*"       # Temporary files
```

## Usage

### Interactive Mode
Run the program to start the interactive TUI:
```bash
sorter
```

### Dry Run Mode
Preview what actions would be performed without modifying any files:
```bash
sorter --dry-run
# or
sorter -n
```

### Controls
- **p/space**: Play current file with configured media player
- **d**: Mark file for deletion
- **s**: Skip file (no action)
- **h/←**: Go to previous file
- **l/→**: Go to next file
- **enter**: Proceed to confirmation phase
- **q**: Quit program

**Category Hotkeys** (configurable in config.yaml):
- Category hotkeys are defined in your configuration file
- Default configuration includes numbered categories (1, 2, 3) and archive (a)
- Customize these in ~/.config/sorter/config.yaml

**Junk Pattern Detection:**
- **x**: Add current file's pattern to junk_video_patterns (also marks for deletion)
- Files matching existing patterns are automatically marked for deletion during scanning
- Auto-detected junk files are clearly labeled in the interface

### Help and Testing
Get help information:
```bash
sorter --help
```

Test your configuration file:
```bash
sorter --test-config
```

## Workflow

### Normal Mode
1. **Scanning Phase**: The program scans for video files in the base directory
2. **Review Phase**: Go through each file, preview with media player, and assign actions
3. **Confirmation Phase**: Review all pending operations before execution
4. **Processing Phase**: Execute all file operations and cleanup
5. **Completion**: Show results and cleanup empty directories/junk files

### Dry Run Mode
1. **Scanning Phase**: Same as normal mode
2. **Review Phase**: Same as normal mode, but with visual indicators showing no files will be modified
3. **Confirmation Phase**: Shows what operations would be performed
4. **Processing Phase**: Generates a detailed report of all operations that would be executed, including:
   - File moves with source and destination paths
   - Files that would be deleted
   - Junk files that would be cleaned up
   - Empty directories that would be removed
5. **Completion**: Shows summary without making any actual changes

## Migration from Fish Script

This Go program provides the same functionality as the original Fish script with these improvements:

- Better user interface with progress tracking
- Configurable categories and paths
- Batch confirmation of operations
- More robust error handling
- Cross-platform compatibility
- Undo/navigation capabilities during review
- **Dry-run mode for safe testing**

The default configuration provides a generic template that you can customize for your needs.

## Examples

```bash
# Start interactive mode
sorter

# Preview what would be done without making changes
sorter --dry-run

# Test configuration loading
sorter --test-config

# Show help
sorter --help
```