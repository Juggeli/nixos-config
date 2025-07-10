package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type FileInfo struct {
	Path     string
	Name     string
	Size     int64
	Action   string
	Category string
}

type Scanner struct {
	config    *Config
	videoExts map[string]bool
	junkExts  map[string]bool
}

func NewScanner(config *Config) *Scanner {
	scanner := &Scanner{
		config:    config,
		videoExts: make(map[string]bool),
		junkExts:  make(map[string]bool),
	}

	for _, ext := range config.VideoExts {
		scanner.videoExts[strings.ToLower(ext)] = true
	}

	for _, ext := range config.JunkExts {
		scanner.junkExts[strings.ToLower(ext)] = true
	}

	return scanner
}

func (s *Scanner) ScanVideoFiles() ([]FileInfo, error) {
	var files []FileInfo

	err := filepath.Walk(s.config.BaseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		if s.videoExts[ext] {
			fileInfo := FileInfo{
				Path:   path,
				Name:   info.Name(),
				Size:   info.Size(),
				Action: "pending",
			}
			
			if s.IsJunkVideoFile(path) {
				fileInfo.Action = "delete"
			}
			
			files = append(files, fileInfo)
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to scan directory %s: %w", s.config.BaseDir, err)
	}

	return files, nil
}

func (s *Scanner) CalculateTotalSize(files []FileInfo) int64 {
	var totalSize int64
	for _, file := range files {
		totalSize += file.Size
	}
	return totalSize
}

func (s *Scanner) ScanJunkFiles() ([]string, error) {
	var junkFiles []string

	err := filepath.Walk(s.config.BaseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		if s.junkExts[ext] {
			junkFiles = append(junkFiles, path)
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to scan for junk files: %w", err)
	}

	return junkFiles, nil
}

func (s *Scanner) FindEmptyDirectories() ([]string, error) {
	var emptyDirs []string

	err := filepath.Walk(s.config.BaseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() {
			return nil
		}

		if path == s.config.BaseDir {
			return nil
		}

		entries, err := os.ReadDir(path)
		if err != nil {
			return err
		}

		if len(entries) == 0 {
			emptyDirs = append(emptyDirs, path)
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to scan for empty directories: %w", err)
	}

	return emptyDirs, nil
}

func FormatFileSize(size int64) string {
	const unit = 1024
	if size < unit {
		return fmt.Sprintf("%d B", size)
	}
	div, exp := int64(unit), 0
	for n := size / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(size)/float64(div), "KMGTPE"[exp])
}

func (s *Scanner) IsJunkVideoFile(filename string) bool {
	name := filepath.Base(filename)
	ext := filepath.Ext(name)
	nameWithoutExt := strings.TrimSuffix(name, ext)
	
	for _, pattern := range s.config.JunkVideoPatterns {
		if matchPattern(nameWithoutExt, pattern) {
			return true
		}
	}
	return false
}

func matchPattern(filename, pattern string) bool {
	if !strings.Contains(pattern, "*") {
		return strings.EqualFold(filename, pattern)
	}
	
	if strings.HasSuffix(pattern, "*") {
		prefix := strings.TrimSuffix(pattern, "*")
		return strings.HasPrefix(strings.ToLower(filename), strings.ToLower(prefix))
	}
	
	if strings.HasPrefix(pattern, "*") {
		suffix := strings.TrimPrefix(pattern, "*")
		return strings.HasSuffix(strings.ToLower(filename), strings.ToLower(suffix))
	}
	
	parts := strings.Split(pattern, "*")
	if len(parts) == 2 {
		return strings.HasPrefix(strings.ToLower(filename), strings.ToLower(parts[0])) &&
			strings.HasSuffix(strings.ToLower(filename), strings.ToLower(parts[1]))
	}
	
	return false
}