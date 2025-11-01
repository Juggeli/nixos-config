package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

type ThumbnailCache struct {
	cacheDir string
}

func NewThumbnailCache(cacheDir string) (*ThumbnailCache, error) {
	expandedPath, err := expandPath(cacheDir)
	if err != nil {
		return nil, fmt.Errorf("failed to expand cache directory path: %w", err)
	}

	if err := os.MkdirAll(expandedPath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create thumbnail cache directory: %w", err)
	}

	return &ThumbnailCache{
		cacheDir: expandedPath,
	}, nil
}

func (tc *ThumbnailCache) getThumbnailPath(videoPath string) string {
	hash := sha256.Sum256([]byte(videoPath))
	filename := hex.EncodeToString(hash[:]) + ".jpg"
	return filepath.Join(tc.cacheDir, filename)
}

func (tc *ThumbnailCache) GetThumbnail(videoPath string) (string, error) {
	thumbnailPath := tc.getThumbnailPath(videoPath)

	if _, err := os.Stat(thumbnailPath); err == nil {
		return thumbnailPath, nil
	}

	if err := tc.generateThumbnail(videoPath, thumbnailPath); err != nil {
		return "", fmt.Errorf("failed to generate thumbnail: %w", err)
	}

	return thumbnailPath, nil
}

func (tc *ThumbnailCache) generateThumbnail(videoPath, thumbnailPath string) error {
	duration, err := tc.getVideoDuration(videoPath)
	if err != nil {
		return fmt.Errorf("failed to get video duration: %w", err)
	}

	midpoint := duration / 2.0
	if midpoint < 1.0 {
		midpoint = 1.0
	}

	seekTime := fmt.Sprintf("%.2f", midpoint)

	// Sanitize paths to prevent command injection
	sanitizedVideoPath := sanitizePath(videoPath)
	sanitizedThumbnailPath := sanitizePath(thumbnailPath)

	cmd := exec.Command("ffmpeg",
		"-ss", seekTime,
		"-i", sanitizedVideoPath,
		"-vframes", "1",
		"-vf", "scale=320:-1",
		"-loglevel", "error",
		"-y",
		sanitizedThumbnailPath,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpeg command failed: %w (output: %s)", err, string(output))
	}

	if _, err := os.Stat(thumbnailPath); os.IsNotExist(err) {
		return fmt.Errorf("thumbnail file was not created at %s", thumbnailPath)
	}

	return nil
}

func (tc *ThumbnailCache) getVideoDuration(videoPath string) (float64, error) {
	// Sanitize path to prevent command injection
	sanitizedVideoPath := sanitizePath(videoPath)

	cmd := exec.Command("ffprobe",
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		sanitizedVideoPath,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return 0, fmt.Errorf("ffprobe command failed: %w (output: %s)", err, string(output))
	}

	var duration float64
	_, err = fmt.Sscanf(string(output), "%f", &duration)
	if err != nil {
		return 0, fmt.Errorf("failed to parse duration: %w (output: %s)", err, string(output))
	}

	return duration, nil
}

func (tc *ThumbnailCache) Clear() error {
	entries, err := os.ReadDir(tc.cacheDir)
	if err != nil {
		return fmt.Errorf("failed to read cache directory: %w", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() && filepath.Ext(entry.Name()) == ".jpg" {
			path := filepath.Join(tc.cacheDir, entry.Name())
			if err := os.Remove(path); err != nil {
				return fmt.Errorf("failed to remove thumbnail %s: %w", entry.Name(), err)
			}
		}
	}

	return nil
}

func (tc *ThumbnailCache) Cleanup() error {
	// Remove any corrupted or incomplete thumbnail files
	entries, err := os.ReadDir(tc.cacheDir)
	if err != nil {
		return fmt.Errorf("failed to read cache directory: %w", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() && filepath.Ext(entry.Name()) == ".jpg" {
			path := filepath.Join(tc.cacheDir, entry.Name())

			// Check if file is empty (corrupted)
			info, err := os.Stat(path)
			if err != nil {
				// Remove if we can't stat the file
				os.Remove(path)
				continue
			}

			if info.Size() == 0 {
				// Remove empty files
				if err := os.Remove(path); err != nil {
					return fmt.Errorf("failed to remove corrupted thumbnail %s: %w", entry.Name(), err)
				}
			}
		}
	}

	return nil
}
