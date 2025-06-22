package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

type OperationType int

const (
	OpMove OperationType = iota
	OpDelete
)

type Operation struct {
	Type   OperationType
	Source string
	Dest   string
}

type Processor struct {
	config *Config
	logger *Logger
}

func NewProcessor(config *Config) *Processor {
	return &Processor{
		config: config,
		logger: NewLogger(config),
	}
}

func (p *Processor) ProcessOperations(operations []Operation) error {
	if err := p.logger.LogOperation("SESSION_START", "", ""); err != nil {
		fmt.Printf("Warning: failed to log session start: %v\n", err)
	}

	for _, op := range operations {
		switch op.Type {
		case OpMove:
			if err := p.moveFile(op.Source, op.Dest); err != nil {
				return fmt.Errorf("failed to move file %s: %w", op.Source, err)
			}
			if err := p.logger.LogOperation("MOVE", op.Source, op.Dest); err != nil {
				fmt.Printf("Warning: failed to log move operation: %v\n", err)
			}
		case OpDelete:
			if err := p.deleteFile(op.Source); err != nil {
				return fmt.Errorf("failed to delete file %s: %w", op.Source, err)
			}
			if err := p.logger.LogOperation("DELETE", op.Source, ""); err != nil {
				fmt.Printf("Warning: failed to log delete operation: %v\n", err)
			}
		}
	}

	if err := p.cleanupJunkFiles(); err != nil {
		return fmt.Errorf("failed to cleanup junk files: %w", err)
	}

	if err := p.cleanupEmptyDirectories(); err != nil {
		return fmt.Errorf("failed to cleanup empty directories: %w", err)
	}

	if err := p.logger.LogOperation("SESSION_END", "", ""); err != nil {
		fmt.Printf("Warning: failed to log session end: %v\n", err)
	}

	return nil
}


func (p *Processor) moveFile(source, destDir string) error {
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	filename := filepath.Base(source)
	destination := filepath.Join(destDir, filename)

	if err := os.Rename(source, destination); err != nil {
		return fmt.Errorf("failed to move file: %w", err)
	}

	return nil
}

func (p *Processor) deleteFile(path string) error {
	if err := os.Remove(path); err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}
	return nil
}

func (p *Processor) cleanupJunkFiles() error {
	scanner := NewScanner(p.config)
	junkFiles, err := scanner.ScanJunkFiles()
	if err != nil {
		return err
	}

	for _, file := range junkFiles {
		if err := p.deleteFile(file); err != nil {
			return fmt.Errorf("failed to delete junk file %s: %w", file, err)
		}
		if err := p.logger.LogOperation("JUNK_DELETE", file, ""); err != nil {
			fmt.Printf("Warning: failed to log junk file deletion: %v\n", err)
		}
	}

	return nil
}

func (p *Processor) cleanupEmptyDirectories() error {
	scanner := NewScanner(p.config)
	emptyDirs, err := scanner.FindEmptyDirectories()
	if err != nil {
		return err
	}

	for _, dir := range emptyDirs {
		if err := os.Remove(dir); err != nil {
			return fmt.Errorf("failed to remove empty directory %s: %w", dir, err)
		}
		if err := p.logger.LogOperation("EMPTY_DIR_DELETE", dir, ""); err != nil {
			fmt.Printf("Warning: failed to log empty directory deletion: %v\n", err)
		}
	}

	return nil
}

func (p *Processor) PlayFile(path string) error {
	cmd := exec.Command("mpv", "--really-quiet", path)
	return cmd.Run()
}