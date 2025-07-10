package main

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type AppState int

const (
	StateScanning AppState = iota
	StateReviewing
	StateConfirming
	StateProcessing
	StateDone
	StateQuitConfirm
)

type Model struct {
	state     AppState
	config    *Config
	scanner   *Scanner
	processor *Processor

	files        []FileInfo
	currentFile  int
	scanComplete bool
	scanError    error
	totalSize    int64

	pendingOps []Operation
	
	width  int
	height int
	
	runningPlayer *exec.Cmd
	previousState AppState
}

var (
	titleStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#FAFAFA")).
		Background(lipgloss.Color("#7D56F4")).
		Padding(0, 1)

	headerStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#FAFAFA"))

	fileStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("#04B575"))

	currentFileStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#EE6FF8")).
		Background(lipgloss.Color("#313244")).
		Padding(0, 1)

	helpStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("#626880"))

	errorStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#FF5F87"))

	successStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#04B575"))
)

func NewModel(config *Config) Model {
	scanner := NewScanner(config)
	processor := NewProcessor(config)

	return Model{
		state:     StateScanning,
		config:    config,
		scanner:   scanner,
		processor: processor,
		files:     []FileInfo{},
		currentFile: 0,
		runningPlayer: nil,
	}
}

func (m *Model) killPlayer() {
	if m.runningPlayer != nil && m.runningPlayer.Process != nil {
		m.runningPlayer.Process.Kill()
		m.runningPlayer = nil
	}
}

func (m Model) waitForPlayer(cmd *exec.Cmd) tea.Cmd {
	return tea.Cmd(func() tea.Msg {
		cmd.Wait()
		return playerFinishedMsg{}
	})
}

func (m Model) Init() tea.Cmd {
	return tea.Batch(
		m.scanFiles(),
		tea.EnterAltScreen,
	)
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		return m.handleKeyMsg(msg)

	case scanCompleteMsg:
		m.files = msg.files
		m.totalSize = m.scanner.CalculateTotalSize(msg.files)
		m.scanComplete = true
		if len(m.files) == 0 {
			m.state = StateDone
		} else {
			m.state = StateReviewing
		}
		return m, nil

	case scanErrorMsg:
		m.scanError = msg.err
		m.state = StateDone
		return m, nil

	case playerStartedMsg:
		// Kill any existing player first
		if m.runningPlayer != nil && m.runningPlayer.Process != nil {
			m.runningPlayer.Process.Kill()
		}
		m.runningPlayer = msg.cmd
		return m, m.waitForPlayer(msg.cmd)

	case playerFinishedMsg:
		if m.runningPlayer != nil {
			m.runningPlayer = nil
		}
		return m, nil
	}

	return m, nil
}

func (m Model) handleKeyMsg(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch m.state {
	case StateScanning:
		if msg.String() == "q" || msg.String() == "ctrl+c" {
			return m, tea.Quit
		}

	case StateReviewing:
		return m.handleReviewingKeys(msg)

	case StateConfirming:
		return m.handleConfirmingKeys(msg)

	case StateProcessing:
		if msg.String() == "q" || msg.String() == "ctrl+c" {
			return m, tea.Quit
		}

	case StateDone:
		return m, tea.Quit

	case StateQuitConfirm:
		return m.handleQuitConfirmKeys(msg)
	}

	return m, nil
}

func (m Model) handleReviewingKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	key := msg.String()

	switch key {
	case "q", "ctrl+c":
		if m.hasPendingOperations() {
			m.previousState = StateReviewing
			m.state = StateQuitConfirm
			return m, nil
		}
		return m, tea.Quit

	case "p", " ":
		if m.currentFile < len(m.files) {
			cmd = m.playFile(m.files[m.currentFile].Path)
		}

	case "d":
		if m.currentFile < len(m.files) {
			m.files[m.currentFile].Action = "delete"
			m.currentFile++
			if m.currentFile < len(m.files) {
				cmd = m.playFile(m.files[m.currentFile].Path)
			}
		}

	case "s":
		if m.currentFile < len(m.files) {
			m.files[m.currentFile].Action = "skip"
			m.currentFile++
		}

	case "x":
		if m.currentFile < len(m.files) {
			filename := m.files[m.currentFile].Path
			err := m.config.AddJunkVideoPattern(filename)
			if err == nil {
				logger := NewLogger(m.config)
				pattern := extractPattern(filename)
				if logErr := logger.LogJunkPatternAdded(filename, pattern); logErr != nil {
					fmt.Printf("Warning: failed to log junk pattern addition: %v\n", logErr)
				}
				m.files[m.currentFile].Action = "delete"
				
				// Re-evaluate all remaining files with the new pattern
				scanner := NewScanner(m.config)
				matchCount := 0
				for i := m.currentFile + 1; i < len(m.files); i++ {
					if m.files[i].Action == "pending" && scanner.IsJunkVideoFile(m.files[i].Path) {
						m.files[i].Action = "delete"
						matchCount++
					}
				}
				
				m.currentFile++
				if m.currentFile < len(m.files) {
					cmd = m.playFile(m.files[m.currentFile].Path)
				}
			}
		}

	case "left", "h":
		if m.currentFile > 0 {
			m.currentFile--
		}

	case "right", "l":
		if m.currentFile < len(m.files)-1 {
			m.currentFile++
		}

	case "enter":
		if m.runningPlayer != nil && m.runningPlayer.Process != nil {
			m.runningPlayer.Process.Kill()
			m.runningPlayer = nil
		}
		m.state = StateConfirming
		m.buildPendingOps()
		// Don't auto-play when going to confirmation
		cmd = nil

	default:
		for categoryName, category := range m.config.Categories {
			if key == category.Hotkey && m.currentFile < len(m.files) {
				m.files[m.currentFile].Action = "move"
				m.files[m.currentFile].Category = categoryName
				m.currentFile++
				if m.currentFile < len(m.files) {
					cmd = m.playFile(m.files[m.currentFile].Path)
				}
				break
			}
		}
	}

	if m.currentFile >= len(m.files) {
		if m.runningPlayer != nil && m.runningPlayer.Process != nil {
			m.runningPlayer.Process.Kill()
			m.runningPlayer = nil
		}
		m.state = StateConfirming
		m.buildPendingOps()
		// Don't auto-play when automatically going to confirmation
		cmd = nil
	}

	return m, cmd
}

func (m Model) handleConfirmingKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		if len(m.pendingOps) > 0 {
			m.previousState = StateConfirming
			m.state = StateQuitConfirm
			return m, nil
		}
		return m, tea.Quit

	case "y", "enter":
		m.state = StateProcessing
		return m, m.processOperations()

	case "n", "esc":
		m.state = StateReviewing
		m.currentFile = 0
	}

	return m, nil
}

func (m Model) handleQuitConfirmKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "Y":
		return m, tea.Quit
	case "n", "N", "esc":
		m.state = m.previousState
		return m, nil
	case "ctrl+c":
		return m, tea.Quit
	}
	return m, nil
}

func (m Model) hasPendingOperations() bool {
	for _, file := range m.files {
		if file.Action != "pending" && file.Action != "skip" {
			return true
		}
	}
	return false
}

func (m *Model) buildPendingOps() {
	m.pendingOps = []Operation{}

	for _, file := range m.files {
		switch file.Action {
		case "delete":
			m.pendingOps = append(m.pendingOps, Operation{
				Type:   OpDelete,
				Source: file.Path,
			})
		case "move":
			if category, ok := m.config.Categories[file.Category]; ok {
				m.pendingOps = append(m.pendingOps, Operation{
					Type:   OpMove,
					Source: file.Path,
					Dest:   category.Path,
				})
			}
		}
	}
}

func (m Model) View() string {
	switch m.state {
	case StateScanning:
		return m.viewScanning()
	case StateReviewing:
		return m.viewReviewing()
	case StateConfirming:
		return m.viewConfirming()
	case StateProcessing:
		return m.viewProcessing()
	case StateDone:
		return m.viewDone()
	case StateQuitConfirm:
		return m.viewQuitConfirm()
	}

	return ""
}

func (m Model) viewScanning() string {
	var s strings.Builder
	title := "Media Sorter"
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")
	s.WriteString("Scanning for video files...\n")
	s.WriteString(fmt.Sprintf("Directory: %s\n", m.config.BaseDir))
	
	if m.scanComplete {
		s.WriteString(fmt.Sprintf("Found %d files, total size: %s\n", len(m.files), FormatFileSize(m.totalSize)))
		
		autoJunkCount := 0
		for _, file := range m.files {
			scanner := NewScanner(m.config)
			if file.Action == "delete" && scanner.IsJunkVideoFile(file.Path) {
				autoJunkCount++
			}
		}
		if autoJunkCount > 0 {
			s.WriteString(fmt.Sprintf("Auto-detected %d junk files for deletion\n", autoJunkCount))
		}
	}
	
	s.WriteString("\nPress 'q' to quit")
	return s.String()
}

func (m Model) viewReviewing() string {
	if len(m.files) == 0 {
		return "No video files found."
	}

	var s strings.Builder
	title := "Media Sorter - Review Files"
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")

	s.WriteString(fmt.Sprintf("File %d of %d (Total size: %s)\n", m.currentFile+1, len(m.files), FormatFileSize(m.totalSize)))
	s.WriteString(fmt.Sprintf("Progress: %.1f%%\n\n", float64(m.currentFile)/float64(len(m.files))*100))

	if m.currentFile < len(m.files) {
		file := m.files[m.currentFile]
		s.WriteString(currentFileStyle.Render(file.Name))
		s.WriteString("\n")
		s.WriteString(fmt.Sprintf("Size: %s\n", FormatFileSize(file.Size)))
		s.WriteString(fmt.Sprintf("Path: %s\n", file.Path))
		if file.Action != "pending" {
			actionText := file.Action
			if file.Action == "delete" {
				scanner := NewScanner(m.config)
				if scanner.IsJunkVideoFile(file.Path) {
					actionText = "delete (auto-detected junk)"
				}
			}
			s.WriteString(fmt.Sprintf("Action: %s", actionText))
			if file.Category != "" {
				s.WriteString(fmt.Sprintf(" (%s)", file.Category))
			}
			s.WriteString("\n")
		}
	}

	s.WriteString("\n")
	s.WriteString(helpStyle.Render("Controls:"))
	s.WriteString("\n")
	
	// Sort categories by hotkey for consistent display order
	type categoryInfo struct {
		name   string
		hotkey string
	}
	var categories []categoryInfo
	for categoryName, category := range m.config.Categories {
		categories = append(categories, categoryInfo{
			name:   categoryName,
			hotkey: category.Hotkey,
		})
	}
	sort.Slice(categories, func(i, j int) bool {
		return categories[i].hotkey < categories[j].hotkey
	})
	
	var categoryHelp string
	for _, cat := range categories {
		if categoryHelp != "" {
			categoryHelp += "  "
		}
		categoryHelp += fmt.Sprintf("%s: %s", cat.hotkey, cat.name)
	}
	
	s.WriteString(helpStyle.Render(fmt.Sprintf("p/space: Play file  d: Delete  %s", categoryHelp)))
	s.WriteString("\n")
	s.WriteString(helpStyle.Render("s: Skip  x: Junk pattern  h/←: Previous  l/→: Next  enter: Confirm actions  q: Quit"))

	return s.String()
}

func (m Model) viewConfirming() string {
	var s strings.Builder
	title := "Media Sorter - Confirm Operations"
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")

	if len(m.pendingOps) == 0 {
		s.WriteString("No operations to perform.")
		s.WriteString("\n\nPress any key to continue...")
		return s.String()
	}

	s.WriteString(fmt.Sprintf("Ready to perform %d operations:\n\n", len(m.pendingOps)))

	// Group operations by type
	deleteOps := []Operation{}
	moveOps := map[string][]Operation{}

	for _, op := range m.pendingOps {
		if op.Type == OpDelete {
			deleteOps = append(deleteOps, op)
		} else if op.Type == OpMove {
			destName := filepath.Base(op.Dest)
			moveOps[destName] = append(moveOps[destName], op)
		}
	}

	// Show delete operations
	if len(deleteOps) > 0 {
		s.WriteString(errorStyle.Render(fmt.Sprintf("DELETE %d files:", len(deleteOps))))
		s.WriteString("\n")
		for _, op := range deleteOps {
			fileName := filepath.Base(op.Source)
			s.WriteString(fmt.Sprintf("  - %s\n", fileName))
		}
		s.WriteString("\n")
	}

	// Show move operations grouped by destination
	for destName, ops := range moveOps {
		s.WriteString(successStyle.Render(fmt.Sprintf("MOVE %d files to %s:", len(ops), destName)))
		s.WriteString("\n")
		for _, op := range ops {
			fileName := filepath.Base(op.Source)
			s.WriteString(fmt.Sprintf("  - %s\n", fileName))
		}
		s.WriteString("\n")
	}

	confirmText := "y/enter: Confirm  n/esc: Go back  q: Quit"
	s.WriteString(helpStyle.Render(confirmText))

	return s.String()
}

func (m Model) viewProcessing() string {
	var s strings.Builder
	title := "Media Sorter - Processing"
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")
	s.WriteString("Processing operations...\n")
	s.WriteString("This may take a while depending on file sizes.\n")
	s.WriteString("\nPress 'q' to quit")
	return s.String()
}

func (m Model) viewDone() string {
	var s strings.Builder
	title := "Media Sorter - Complete"
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")

	if m.scanError != nil {
		s.WriteString(errorStyle.Render("Error: " + m.scanError.Error()))
	} else {
		s.WriteString(successStyle.Render("All operations completed successfully!"))
	}

	s.WriteString("\n\nPress any key to exit...")
	return s.String()
}

func (m Model) viewQuitConfirm() string {
	var s strings.Builder
	s.WriteString(titleStyle.Render("Media Sorter - Confirm Quit"))
	s.WriteString("\n\n")
	
	pendingCount := 0
	for _, file := range m.files {
		if file.Action != "pending" && file.Action != "skip" {
			pendingCount++
		}
	}
	
	s.WriteString(fmt.Sprintf("You have %d pending file operations that will be lost.\n", pendingCount))
	s.WriteString("Are you sure you want to quit?\n\n")
	
	s.WriteString(helpStyle.Render("y: Yes, quit  n/esc: No, go back  ctrl+c: Force quit"))
	
	return s.String()
}

type scanCompleteMsg struct {
	files []FileInfo
}

type scanErrorMsg struct {
	err error
}

type playerFinishedMsg struct{}

type playerStartedMsg struct {
	cmd *exec.Cmd
}

func (m Model) scanFiles() tea.Cmd {
	return tea.Cmd(func() tea.Msg {
		files, err := m.scanner.ScanVideoFiles()
		if err != nil {
			return scanErrorMsg{err: err}
		}
		return scanCompleteMsg{files: files}
	})
}

func (m Model) playFile(path string) tea.Cmd {
	return tea.Cmd(func() tea.Msg {
		cmd := exec.Command("mpv", "--really-quiet", path)
		
		if err := cmd.Start(); err != nil {
			return scanErrorMsg{err: err}
		}
		
		// Return a message with the started command
		return playerStartedMsg{cmd: cmd}
	})
}

func (m Model) processOperations() tea.Cmd {
	return tea.Cmd(func() tea.Msg {
		err := m.processor.ProcessOperations(m.pendingOps)
		if err != nil {
			return scanErrorMsg{err: err}
		}
		return scanCompleteMsg{files: []FileInfo{}}
	})
}