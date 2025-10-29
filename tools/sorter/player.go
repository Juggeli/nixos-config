package main

import (
	"fmt"
	"os/exec"
)

type VideoPlayer struct {
	cmd         *exec.Cmd
	playerPath  string
	fullscreen  bool
	autoPlay    bool
	currentFile string
}

func NewVideoPlayer(playerPath string, fullscreen bool, autoPlay bool) *VideoPlayer {
	return &VideoPlayer{
		playerPath: playerPath,
		fullscreen: fullscreen,
		autoPlay:   autoPlay,
	}
}

func (vp *VideoPlayer) Play(videoPath string) error {
	if vp.cmd != nil && vp.cmd.Process != nil {
		vp.Stop()
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

	args = append(args, videoPath)

	vp.cmd = exec.Command(vp.playerPath, args...)
	vp.currentFile = videoPath

	if err := vp.cmd.Start(); err != nil {
		return fmt.Errorf("failed to start video player: %w", err)
	}

	return nil
}

func (vp *VideoPlayer) Stop() error {
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
	return vp.cmd != nil && vp.cmd.Process != nil
}

func (vp *VideoPlayer) GetCurrentFile() string {
	return vp.currentFile
}
