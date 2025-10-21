package main

import (
	"fmt"
	"io"
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

	affectedDirs := make(map[string]bool)

	for _, op := range operations {
		sourceDir := filepath.Dir(op.Source)
		affectedDirs[sourceDir] = true

		switch op.Type {
		case OpMove:
			if err := p.moveFile(op.Source, op.Dest); err != nil {
				moveErr := fmt.Errorf("failed to move file %s: %w", op.Source, err)
				fmt.Printf("ERROR: %v\n", moveErr)
				return moveErr
			}
			if err := p.logger.LogOperation("MOVE", op.Source, op.Dest); err != nil {
				fmt.Printf("Warning: failed to log move operation: %v\n", err)
			}
		case OpDelete:
			if err := p.deleteFile(op.Source); err != nil {
				deleteErr := fmt.Errorf("failed to delete file %s: %w", op.Source, err)
				fmt.Printf("ERROR: %v\n", deleteErr)
				return deleteErr
			}
			if err := p.logger.LogOperation("DELETE", op.Source, ""); err != nil {
				fmt.Printf("Warning: failed to log delete operation: %v\n", err)
			}
		}
	}

	if err := p.cleanupJunkFiles(affectedDirs); err != nil {
		cleanupErr := fmt.Errorf("failed to cleanup junk files: %w", err)
		fmt.Printf("ERROR: %v\n", cleanupErr)
		return cleanupErr
	}

	if err := p.cleanupEmptyDirectories(affectedDirs); err != nil {
		cleanupErr := fmt.Errorf("failed to cleanup empty directories: %w", err)
		fmt.Printf("ERROR: %v\n", cleanupErr)
		return cleanupErr
	}

	if err := p.logger.LogOperation("SESSION_END", "", ""); err != nil {
		fmt.Printf("Warning: failed to log session end: %v\n", err)
	}

	return nil
}


func (p *Processor) moveFile(source, destDir string) error {
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory %s: %w", destDir, err)
	}

	filename := filepath.Base(source)
	destination := filepath.Join(destDir, filename)

	if err := os.Rename(source, destination); err != nil {
		if copyErr := p.copyFile(source, destination); copyErr != nil {
			return fmt.Errorf("failed to move file from %s to %s: rename failed (%w) and copy failed (%w)", source, destination, err, copyErr)
		}
		if deleteErr := os.Remove(source); deleteErr != nil {
			return fmt.Errorf("file copied from %s to %s but failed to delete source: %w", source, destination, deleteErr)
		}
		return nil
	}

	return nil
}

func (p *Processor) copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %w", err)
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		return fmt.Errorf("failed to copy file contents: %w", err)
	}

	sourceInfo, err := os.Stat(src)
	if err != nil {
		return fmt.Errorf("failed to get source file info: %w", err)
	}

	err = os.Chmod(dst, sourceInfo.Mode())
	if err != nil {
		return fmt.Errorf("failed to set file permissions: %w", err)
	}

	return nil
}

func (p *Processor) deleteFile(path string) error {
	if err := os.Remove(path); err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}
	return nil
}

func (p *Processor) cleanupJunkFiles(affectedDirs map[string]bool) error {
	scanner := NewScanner(p.config)

	for dir := range affectedDirs {
		junkFiles, err := scanner.ScanJunkFilesInDir(dir)
		if err != nil {
			return err
		}

		for _, file := range junkFiles {
			if err := p.deleteFile(file); err != nil {
				deleteErr := fmt.Errorf("failed to delete junk file %s: %w", file, err)
				fmt.Printf("ERROR: %v\n", deleteErr)
				return deleteErr
			}
			if err := p.logger.LogOperation("JUNK_DELETE", file, ""); err != nil {
				fmt.Printf("Warning: failed to log junk file deletion: %v\n", err)
			}
		}
	}

	return nil
}

func (p *Processor) cleanupEmptyDirectories(affectedDirs map[string]bool) error {
	scanner := NewScanner(p.config)

	for dir := range affectedDirs {
		emptyDirs, err := scanner.FindEmptyDirectoriesInDir(dir)
		if err != nil {
			return err
		}

		for _, emptyDir := range emptyDirs {
			if err := os.Remove(emptyDir); err != nil {
				removeErr := fmt.Errorf("failed to remove empty directory %s: %w", emptyDir, err)
				fmt.Printf("ERROR: %v\n", removeErr)
				return removeErr
			}
			if err := p.logger.LogOperation("EMPTY_DIR_DELETE", emptyDir, ""); err != nil {
				fmt.Printf("Warning: failed to log empty directory deletion: %v\n", err)
			}
		}
	}

	return nil
}

func (p *Processor) PlayFile(path string) error {
	cmd := exec.Command("mpv", "--really-quiet", path)
	return cmd.Run()
}