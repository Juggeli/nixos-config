package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"

	tea "github.com/charmbracelet/bubbletea"
)

func main() {
	guiMode := false
	dryRun := false

	for _, arg := range os.Args[1:] {
		switch arg {
		case "--test-config":
			testConfig()
			return
		case "--help", "-h":
			showHelp()
			return
		case "--gui", "-g":
			guiMode = true
		case "--dry-run", "-n":
			dryRun = true
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

	if guiMode {
		runGUI(config, dryRun)
	} else {
		runTUI(config)
	}
}

func runTUI(config *Config) {
	model := NewModel(config)
	program := tea.NewProgram(model, tea.WithAltScreen())

	if _, err := program.Run(); err != nil {
		fmt.Printf("Error running program: %v\n", err)
		os.Exit(1)
	}
}

func runGUI(config *Config, dryRun bool) {
	// Validate dependencies before starting GUI
	if err := validateDependencies(); err != nil {
		log.Fatalf("Dependency validation failed: %v", err)
	}

	scanner := NewScanner(config)
	files, err := scanner.ScanVideoFiles()
	if err != nil {
		log.Fatalf("Failed to scan video files: %v", err)
	}

	if len(files) == 0 {
		log.Fatalf("No video files found in %s", config.BaseDir)
	}

	gui, err := NewGUI(config, files, dryRun)
	if err != nil {
		log.Fatalf("Failed to create GUI: %v", err)
	}

	gui.Run()
}

func validateDependencies() error {
	dependencies := []string{"ffmpeg", "ffprobe", "mpv"}

	for _, dep := range dependencies {
		if _, err := exec.LookPath(dep); err != nil {
			return fmt.Errorf("required dependency '%s' not found in PATH: %w", dep, err)
		}
	}

	return nil
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
    -g, --gui          Launch GUI mode (TV-friendly interface)
    -n, --dry-run      Preview operations without executing (GUI only)
        --test-config  Test configuration loading and exit

DESCRIPTION:
    Interactive media file sorter with TUI and GUI modes. Scans a base directory
    for video files, allows you to preview them, and sort them into categories.

MODES:
    TUI Mode (default)   Terminal-based interface with keyboard controls
    GUI Mode (--gui)     Graphical interface optimized for TV and mouse

CONFIGURATION:
    Configuration is stored in ~/.config/sorter/config.yaml
    A default configuration will be created on first run.

TUI CONTROLS:
    p/space   Play current file with media player
    d         Mark file for deletion
    s         Skip file (no action)
    x         Mark as junk pattern (adds filename pattern to config)
    h/←       Go to previous file
    l/→       Go to next file
    enter     Proceed to confirmation phase
    q         Quit program

    Category hotkeys are configurable in ~/.config/sorter/config.yaml

GUI CONTROLS:
    Mouse-only interface with large buttons for TV viewing
    Category buttons dynamically generated from configuration
    Auto-play video preview with mpv

WORKFLOW:
    1. Scan for video files in base directory
    2. Review each file and assign actions
    3. Confirm all operations
    4. Execute operations and cleanup

EXAMPLES:
    sorter                 # Start TUI mode
    sorter --gui           # Start GUI mode
    sorter --gui --dry-run # Preview GUI operations
    sorter --test-config   # Test configuration
`)
}
