package main

import (
	"fmt"
	"os/exec"
	"sync"
)

type VideoPlayer struct {
	cmd         *exec.Cmd
	playerPath  string
	fullscreen  bool
	autoPlay    bool
	currentFile string
	mutex       sync.RWMutex
}

func NewVideoPlayer(playerPath string, fullscreen bool, autoPlay bool) *VideoPlayer {
	// Validate player path for security
	if err := validatePlayerPath(playerPath); err != nil {
		// Fall back to default mpv if invalid
		playerPath = "mpv"
	}

	// Check if the player exists before using it
	if _, err := exec.LookPath(playerPath); err != nil {
		// If the specified player doesn't exist, try mpv as fallback
		if playerPath != "mpv" {
			if _, mpvErr := exec.LookPath("mpv"); mpvErr == nil {
				playerPath = "mpv"
			} else {
				// If neither the specified player nor mpv exists, we'll let the error
				// occur at runtime when trying to play a video
			}
		}
	}

	return &VideoPlayer{
		playerPath: sanitizePath(playerPath),
		fullscreen: fullscreen,
		autoPlay:   autoPlay,
	}
}

func (vp *VideoPlayer) Play(videoPath string) error {
	vp.mutex.Lock()
	defer vp.mutex.Unlock()

	// Sanitize the video path to prevent command injection
	sanitizedPath := sanitizePath(videoPath)

	// Stop any existing playback
	if vp.cmd != nil && vp.cmd.Process != nil {
		// Call stop without mutex since we already hold the lock
		vp.stopUnsafe()
	}

	args := []string{
		"--no-terminal",
		"--keep-open=no",
		"--ontop",
	}

	if vp.fullscreen {
		args = append(args, "--fullscreen")
	} else {
		args = append(args, "--geometry=50%")
	}

	args = append(args, sanitizedPath)

	vp.cmd = exec.Command(vp.playerPath, args...)
	vp.currentFile = videoPath

	if err := vp.cmd.Start(); err != nil {
		return fmt.Errorf("failed to start video player: %w", err)
	}

	return nil
}

func (vp *VideoPlayer) Stop() error {
	vp.mutex.Lock()
	defer vp.mutex.Unlock()
	return vp.stopUnsafe()
}

func (vp *VideoPlayer) stopUnsafe() error {
	if vp.cmd == nil || vp.cmd.Process == nil {
		return nil
	}

	if err := vp.cmd.Process.Kill(); err != nil {
		return fmt.Errorf("failed to stop video player: %w", err)
	}

	// Wait for process to actually terminate
	_, err := vp.cmd.Process.Wait()
	if err != nil {
		// Process.Wait() can return an error even if the process was killed successfully
		// so we log it but don't treat it as a critical failure
		fmt.Printf("Warning: error waiting for video player process to exit: %v\n", err)
	}

	vp.cmd = nil
	vp.currentFile = ""

	return nil
}

func (vp *VideoPlayer) IsPlaying() bool {
	vp.mutex.RLock()
	defer vp.mutex.RUnlock()
	return vp.cmd != nil && vp.cmd.Process != nil
}

func (vp *VideoPlayer) GetCurrentFile() string {
	vp.mutex.RLock()
	defer vp.mutex.RUnlock()
	return vp.currentFile
}
