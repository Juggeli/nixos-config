package main

import (
	"fmt"
	"log"
	"os"

	tea "github.com/charmbracelet/bubbletea"
)

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "--test-config":
			testConfig()
			return
		case "--help", "-h":
			showHelp()
			return
		}
	}

	config, err := LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	if err := config.ExpandPaths(); err != nil {
		log.Fatalf("Failed to expand configuration paths: %v", err)
	}

	if _, err := os.Stat(config.BaseDir); os.IsNotExist(err) {
		log.Fatalf("Base directory does not exist: %s", config.BaseDir)
	}

	model := NewModel(config)
	program := tea.NewProgram(model, tea.WithAltScreen())

	if _, err := program.Run(); err != nil {
		fmt.Printf("Error running program: %v\n", err)
		os.Exit(1)
	}
}

func testConfig() {
	config, err := LoadConfig()
	if err != nil {
		fmt.Printf("Failed to load config: %v\n", err)
		os.Exit(1)
	}

	if err := config.ExpandPaths(); err != nil {
		fmt.Printf("Failed to expand paths: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Config loaded successfully!\n")
	fmt.Printf("Base directory: %s\n", config.BaseDir)
	fmt.Printf("Categories:\n")
	for name, category := range config.Categories {
		fmt.Printf("  %s: %s (hotkey: %s)\n", name, category.Path, category.Hotkey)
	}
	fmt.Printf("Video extensions: %v\n", config.VideoExts)
	fmt.Printf("Player command: mpv --really-quiet (hardcoded)\n")
}

func showHelp() {
	fmt.Printf(`Sorter - Interactive Media File Organizer

USAGE:
    sorter [FLAGS]

FLAGS:
    -h, --help         Show this help message
        --test-config  Test configuration loading and exit

DESCRIPTION:
    Interactive TUI media file sorter. Scans a base directory for video files,
    allows you to preview them, and sort them into categories.

CONFIGURATION:
    Configuration is stored in ~/.config/sorter/config.yaml
    A default configuration will be created on first run.

CONTROLS (Interactive Mode):
    p/space   Play current file with media player
    d         Mark file for deletion
    s         Skip file (no action)
    x         Mark as junk pattern (adds filename pattern to config)
    h/←       Go to previous file
    l/→       Go to next file
    enter     Proceed to confirmation phase
    q         Quit program
    
    Category hotkeys are configurable in ~/.config/sorter/config.yaml
    Default category hotkeys:
    1         Move to category1
    2         Move to category2
    3         Move to category3
    a         Move to archive

WORKFLOW:
    1. Scan for video files in base directory
    2. Review each file and assign actions
    3. Confirm all operations
    4. Execute operations and cleanup

EXAMPLES:
    sorter                 # Start interactive mode
    sorter --test-config   # Test configuration
`)
}