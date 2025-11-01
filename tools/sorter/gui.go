package main

import (
	"fmt"
	"image/color"
	"log"
	"sort"
	"sync"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
)

type GUI struct {
	app              fyne.App
	window           fyne.Window
	config           *Config
	files            []FileInfo
	currentIndex     int
	player           *VideoPlayer
	thumbnailCache   *ThumbnailCache
	logger           *Logger
	scanner          *Scanner
	processor        *Processor
	dryRun           bool

	thumbnailImage   *canvas.Image
	fileInfoLabel    *widget.Label
	progressLabel    *widget.Label
	categoryButtons  *fyne.Container
	actionButtons    *fyne.Container

	// Synchronization
	mutex        sync.RWMutex
	isProcessing bool
}

func NewGUI(config *Config, files []FileInfo, dryRun bool) (*GUI, error) {
	a := app.New()
	fontSize := float32(24)
	if config.GUI.FontSize > 0 {
		fontSize = float32(config.GUI.FontSize)
	}
	a.Settings().SetTheme(&darkTheme{fontSize: fontSize})

	w := a.NewWindow("Sorter")
	w.Resize(fyne.NewSize(float32(config.GUI.WindowWidth), float32(config.GUI.WindowHeight)))
	w.CenterOnScreen()

	cacheDir := config.GUI.ThumbnailCache
	if cacheDir == "" {
		cacheDir = config.ConfigDir + "/thumbnails"
	}
	thumbnailCache, err := NewThumbnailCache(cacheDir)
	if err != nil {
		return nil, fmt.Errorf("failed to create thumbnail cache: %w", err)
	}

	playerPath := config.GUI.PlayerPath
	if playerPath == "" {
		playerPath = "mpv"
	}
	player := NewVideoPlayer(playerPath, config.GUI.PlayerFullscreen, config.GUI.AutoPlay)

	logger := NewLogger(config)
	scanner := NewScanner(config)
	processor := NewProcessor(config)

	gui := &GUI{
		app:            a,
		window:         w,
		config:         config,
		files:          files,
		currentIndex:   0,
		player:         player,
		thumbnailCache: thumbnailCache,
		logger:         logger,
		scanner:        scanner,
		processor:      processor,
		dryRun:         dryRun,
	}

	gui.buildUI()
	gui.window.SetOnClosed(func() {
		gui.player.Stop()
	})

	return gui, nil
}

func (g *GUI) buildUI() {
	g.thumbnailImage = canvas.NewImageFromFile("")
	g.thumbnailImage.FillMode = canvas.ImageFillContain
	g.thumbnailImage.SetMinSize(fyne.NewSize(640, 360))

	g.fileInfoLabel = widget.NewLabel("")
	g.fileInfoLabel.TextStyle = fyne.TextStyle{Bold: true}
	g.fileInfoLabel.Alignment = fyne.TextAlignCenter

	g.progressLabel = widget.NewLabel("")
	g.progressLabel.Alignment = fyne.TextAlignCenter

	thumbnailContainer := container.NewCenter(g.thumbnailImage)

	infoBox := container.NewVBox(
		g.progressLabel,
		widget.NewSeparator(),
		g.fileInfoLabel,
	)

	g.categoryButtons = g.createCategoryButtons()
	g.actionButtons = g.createActionButtons()

	buttonsBox := container.NewVBox(
		widget.NewLabel("Categories:"),
		g.categoryButtons,
		widget.NewSeparator(),
		widget.NewLabel("Actions:"),
		g.actionButtons,
	)

	content := container.NewBorder(
		infoBox,
		buttonsBox,
		nil,
		nil,
		thumbnailContainer,
	)

	g.window.SetContent(content)
	g.updateDisplay()
}

func (g *GUI) createCategoryButtons() *fyne.Container {
	var categoryNames []string
	for name := range g.config.Categories {
		categoryNames = append(categoryNames, name)
	}
	sort.Strings(categoryNames)

	buttons := make([]fyne.CanvasObject, 0)
	for _, name := range categoryNames {
		categoryName := name
		categoryConfig := g.config.Categories[name]

		label := fmt.Sprintf("%s (%s)", categoryName, categoryConfig.Hotkey)
		btn := widget.NewButton(label, func() {
			g.categorizeFile(categoryName)
		})
		btn.Importance = widget.HighImportance
		buttons = append(buttons, btn)
	}

	grid := container.New(layout.NewGridLayout(2), buttons...)
	return grid
}

func (g *GUI) createActionButtons() *fyne.Container {
	playBtn := widget.NewButton("Play Video", func() {
		g.playCurrentFile()
	})

	deleteBtn := widget.NewButton("Delete", func() {
		g.deleteFile()
	})
	deleteBtn.Importance = widget.DangerImportance

	nextBtn := widget.NewButton("Next", func() {
		g.nextFile()
	})

	previousBtn := widget.NewButton("Previous", func() {
		g.previousFile()
	})

	confirmBtn := widget.NewButton("Confirm All", func() {
		g.showConfirmation()
	})
	confirmBtn.Importance = widget.HighImportance

	fullscreenBtn := widget.NewButton("Fullscreen", func() {
		g.toggleFullscreen()
	})

	quitBtn := widget.NewButton("Quit", func() {
		g.quitApp()
	})
	quitBtn.Importance = widget.WarningImportance

	navigationRow := container.New(
		layout.NewGridLayout(3),
		previousBtn,
		playBtn,
		nextBtn,
	)

	fileActionsRow := container.New(
		layout.NewGridLayout(2),
		deleteBtn,
		confirmBtn,
	)

	appActionsRow := container.New(
		layout.NewGridLayout(2),
		fullscreenBtn,
		quitBtn,
	)

	return container.NewVBox(
		navigationRow,
		fileActionsRow,
		appActionsRow,
	)
}

func (g *GUI) updateDisplay() {
	g.mutex.Lock()
	defer g.mutex.Unlock()
	g.updateDisplayUnsafe()
}

func (g *GUI) updateDisplayUnsafe() {
	if g.currentIndex >= len(g.files) {
		g.currentIndex = len(g.files) - 1
		if g.currentIndex < 0 {
			g.currentIndex = 0
		}
		return
	}

	file := g.files[g.currentIndex]

	g.progressLabel.SetText(fmt.Sprintf("File %d of %d", g.currentIndex+1, len(g.files)))
	g.fileInfoLabel.SetText(fmt.Sprintf("%s\n%s", file.Name, FormatFileSize(file.Size)))

	// Start thumbnail loading in goroutine with proper synchronization
	go g.loadThumbnail(file.Path)

	if g.player.autoPlay {
		go func() {
			if err := g.player.Play(file.Path); err != nil {
				log.Printf("Failed to play video: %v", err)
			}
		}()
	}
}

func (g *GUI) loadThumbnail(videoPath string) {
	thumbnailPath, err := g.thumbnailCache.GetThumbnail(videoPath)
	if err != nil {
		log.Printf("Failed to get thumbnail: %v", err)
		fyne.Do(func() {
			// Use minimal lock for UI update only
			g.mutex.Lock()
			g.thumbnailImage.File = ""
			g.mutex.Unlock()
			g.thumbnailImage.Refresh()
		})
		return
	}

	fyne.Do(func() {
		// Use minimal lock for UI update only
		g.mutex.Lock()
		g.thumbnailImage.File = thumbnailPath
		g.mutex.Unlock()
		g.thumbnailImage.Refresh()
	})
}

func (g *GUI) categorizeFile(category string) {
	// Use write lock only for the critical section that modifies shared state
	g.mutex.Lock()
	if g.currentIndex < len(g.files) {
		g.files[g.currentIndex].Action = "move"
		g.files[g.currentIndex].Category = category
	}
	g.currentIndex++
	g.mutex.Unlock()

	g.player.Stop()

	// Update display without holding the lock
	g.updateDisplay()

	// If we skipped to next file, ensure we're not accessing out of bounds
	g.mutex.RLock()
	if g.currentIndex >= len(g.files) {
		g.currentIndex = len(g.files) - 1
	}
	g.mutex.RUnlock()
}

func (g *GUI) deleteFile() {
	// Use write lock only for the critical section that modifies shared state
	g.mutex.Lock()
	if g.currentIndex < len(g.files) {
		g.files[g.currentIndex].Action = "delete"
	}
	g.currentIndex++
	g.mutex.Unlock()

	g.player.Stop()
	g.updateDisplay()

	// Ensure we're not accessing out of bounds
	g.mutex.RLock()
	if g.currentIndex >= len(g.files) {
		g.currentIndex = len(g.files) - 1
	}
	g.mutex.RUnlock()
}

func (g *GUI) nextFile() {
	// Use write lock only for the critical section that modifies shared state
	g.mutex.Lock()
	if g.currentIndex < len(g.files) && g.files[g.currentIndex].Action == "pending" {
		g.files[g.currentIndex].Action = "skip"
	}
	g.currentIndex++
	g.mutex.Unlock()

	g.player.Stop()
	g.updateDisplay()

	// Ensure we're not accessing out of bounds
	g.mutex.RLock()
	if g.currentIndex >= len(g.files) {
		g.currentIndex = len(g.files) - 1
	}
	g.mutex.RUnlock()
}

func (g *GUI) previousFile() {
	// Use write lock only for the critical section that modifies shared state
	g.mutex.Lock()
	canGoBack := g.currentIndex > 0
	if canGoBack {
		g.currentIndex--
	}
	g.mutex.Unlock()

	if canGoBack {
		g.player.Stop()
		g.updateDisplay()
	}
}

func (g *GUI) playCurrentFile() {
	if g.currentIndex < len(g.files) {
		file := g.files[g.currentIndex]
		if err := g.player.Play(file.Path); err != nil {
			log.Printf("Failed to play video: %v", err)
		}
	}
}

func (g *GUI) toggleFullscreen() {
	g.window.SetFullScreen(!g.window.FullScreen())
}

func (g *GUI) quitApp() {
	g.mutex.Lock()
	defer g.mutex.Unlock()

	g.player.Stop()

	// Cleanup thumbnail cache
	if g.thumbnailCache != nil {
		// Note: We don't clear the cache on exit as it's useful for next run
		// But we could add a config option for this if needed
	}

	g.window.Close()
}

func (g *GUI) showConfirmation() {
	g.player.Stop()

	moveCount := 0
	deleteCount := 0
	skipCount := 0

	for _, file := range g.files {
		switch file.Action {
		case "move":
			moveCount++
		case "delete":
			deleteCount++
		case "skip":
			skipCount++
		}
	}

	message := fmt.Sprintf("Operations Summary:\n\n"+
		"Move: %d files\n"+
		"Delete: %d files\n"+
		"Skip: %d files\n\n"+
		"Do you want to proceed?",
		moveCount, deleteCount, skipCount)

	dialog.ShowConfirm("Confirm Operations", message, func(confirmed bool) {
		if confirmed {
			g.processFiles()
		} else {
			g.currentIndex = 0
			g.updateDisplay()
		}
	}, g.window)
}

func (g *GUI) processFiles() {
	g.mutex.Lock()
	if g.isProcessing {
		g.mutex.Unlock()
		return
	}
	g.isProcessing = true
	g.mutex.Unlock()

	progress := dialog.NewProgressInfinite("Processing", "Processing files...", g.window)
	progress.Show()

	go func() {
		defer func() {
			g.mutex.Lock()
			g.isProcessing = false
			g.mutex.Unlock()
		}()

		stats := &ProcessingStats{}

		// Create a snapshot of files to avoid race conditions
		g.mutex.RLock()
		filesSnapshot := make([]FileInfo, len(g.files))
		copy(filesSnapshot, g.files)
		g.mutex.RUnlock()

		if g.dryRun {
			for _, file := range filesSnapshot {
				switch file.Action {
				case "move":
					categoryPath := g.config.Categories[file.Category].Path
					log.Printf("[DRY-RUN] Would move: %s -> %s", file.Path, categoryPath)
					stats.Moved++
				case "delete":
					log.Printf("[DRY-RUN] Would delete: %s", file.Path)
					stats.Deleted++
				case "skip":
					stats.Skipped++
				}
			}
		} else {
			var operations []Operation

			for _, file := range filesSnapshot {
				switch file.Action {
				case "move":
					categoryPath := g.config.Categories[file.Category].Path
					operations = append(operations, Operation{
						Type:   OpMove,
						Source: file.Path,
						Dest:   categoryPath,
					})
				case "delete":
					operations = append(operations, Operation{
						Type:   OpDelete,
						Source: file.Path,
					})
				case "skip":
					stats.Skipped++
				}
			}

			log.Printf("Starting to process %d operations", len(operations))

			for _, op := range operations {
				var err error
				switch op.Type {
				case OpMove:
					log.Printf("Moving %s to %s", op.Source, op.Dest)
					err = g.processor.MoveFile(op.Source, op.Dest)
					if err != nil {
						log.Printf("Failed to move file %s: %v", op.Source, err)
						stats.Errors++
					} else {
						log.Printf("Successfully moved %s", op.Source)
						stats.Moved++
						g.processor.logger.LogOperation("MOVE", op.Source, op.Dest)
					}
				case OpDelete:
					log.Printf("Deleting %s", op.Source)
					err = g.processor.DeleteFile(op.Source)
					if err != nil {
						log.Printf("Failed to delete file %s: %v", op.Source, err)
						stats.Errors++
					} else {
						log.Printf("Successfully deleted %s", op.Source)
						stats.Deleted++
						g.processor.logger.LogOperation("DELETE", op.Source, "")
					}
				}
			}

			log.Printf("Completed processing. Moved: %d, Deleted: %d, Errors: %d", stats.Moved, stats.Deleted, stats.Errors)
		}

		fyne.Do(func() {
			progress.Hide()
			g.showResults(stats)
		})
	}()
}

func (g *GUI) showResults(stats *ProcessingStats) {
	message := fmt.Sprintf("Processing Complete!\n\n"+
		"Moved: %d files\n"+
		"Deleted: %d files\n"+
		"Skipped: %d files\n"+
		"Errors: %d",
		stats.Moved, stats.Deleted, stats.Skipped, stats.Errors)

	dialog.ShowInformation("Results", message, g.window)
}

func (g *GUI) Run() {
	g.window.ShowAndRun()
}

type darkTheme struct {
	fontSize float32
}

func (t *darkTheme) Color(name fyne.ThemeColorName, variant fyne.ThemeVariant) color.Color {
	switch name {
	case theme.ColorNameBackground:
		return color.RGBA{R: 24, G: 24, B: 24, A: 255}
	case theme.ColorNameButton:
		return color.RGBA{R: 56, G: 56, B: 56, A: 255}
	case theme.ColorNameDisabledButton:
		return color.RGBA{R: 38, G: 38, B: 38, A: 255}
	case theme.ColorNamePrimary:
		return color.RGBA{R: 33, G: 150, B: 243, A: 255}
	case theme.ColorNameForeground:
		return color.RGBA{R: 255, G: 255, B: 255, A: 255}
	default:
		return theme.DefaultTheme().Color(name, variant)
	}
}

func (t *darkTheme) Font(style fyne.TextStyle) fyne.Resource {
	return theme.DefaultTheme().Font(style)
}

func (t *darkTheme) Icon(name fyne.ThemeIconName) fyne.Resource {
	return theme.DefaultTheme().Icon(name)
}

func (t *darkTheme) Size(name fyne.ThemeSizeName) float32 {
	switch name {
	case theme.SizeNameText:
		return t.fontSize
	case theme.SizeNameHeadingText:
		return t.fontSize * 1.33
	case theme.SizeNameSubHeadingText:
		return t.fontSize * 1.17
	case theme.SizeNameCaptionText:
		return t.fontSize * 0.83
	case theme.SizeNamePadding:
		return 20
	case theme.SizeNameInnerPadding:
		return 24
	case theme.SizeNameScrollBar:
		return 16
	case theme.SizeNameScrollBarSmall:
		return 8
	case theme.SizeNameSeparatorThickness:
		return 2
	case theme.SizeNameInlineIcon:
		return 28
	default:
		return theme.DefaultTheme().Size(name)
	}
}

type ProcessingStats struct {
	Moved   int
	Deleted int
	Skipped int
	Errors  int
}
