package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/mitchellh/go-homedir"
)

type Logger struct {
	logFile string
}

func NewLogger(config *Config) *Logger {
	return &Logger{
		logFile: config.LogFile,
	}
}

func (l *Logger) LogOperation(operation, source, destination string) error {

	logPath, err := homedir.Expand(l.logFile)
	if err != nil {
		return fmt.Errorf("failed to expand log file path: %w", err)
	}

	logDir := filepath.Dir(logPath)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return fmt.Errorf("failed to create log directory: %w", err)
	}

	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	var logEntry string

	switch operation {
	case "MOVE":
		logEntry = fmt.Sprintf("[%s] MOVE: %s -> %s\n", timestamp, source, destination)
	case "DELETE":
		logEntry = fmt.Sprintf("[%s] DELETE: %s\n", timestamp, source)
	case "JUNK_DELETE":
		logEntry = fmt.Sprintf("[%s] JUNK_DELETE: %s\n", timestamp, source)
	case "EMPTY_DIR_DELETE":
		logEntry = fmt.Sprintf("[%s] EMPTY_DIR_DELETE: %s\n", timestamp, source)
	case "SESSION_START":
		logEntry = fmt.Sprintf("[%s] ===== SESSION START =====\n", timestamp)
	case "SESSION_END":
		logEntry = fmt.Sprintf("[%s] ===== SESSION END =====\n", timestamp)
	default:
		logEntry = fmt.Sprintf("[%s] %s: %s\n", timestamp, operation, source)
	}

	_, err = file.WriteString(logEntry)
	if err != nil {
		return fmt.Errorf("failed to write to log file: %w", err)
	}

	return nil
}


func (l *Logger) LogJunkPatternAdded(filename, pattern string) error {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	
	logPath, err := homedir.Expand(l.logFile)
	if err != nil {
		return fmt.Errorf("failed to expand log file path: %w", err)
	}

	logDir := filepath.Dir(logPath)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return fmt.Errorf("failed to create log directory: %w", err)
	}

	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	logEntry := fmt.Sprintf("[%s] JUNK_PATTERN_ADDED: %s (pattern: %s)\n", timestamp, filename, pattern)
	_, err = file.WriteString(logEntry)
	if err != nil {
		return fmt.Errorf("failed to write to log file: %w", err)
	}

	return nil
}