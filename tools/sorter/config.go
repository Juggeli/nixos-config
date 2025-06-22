package main

import (
	_ "embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/mitchellh/go-homedir"
	"gopkg.in/yaml.v3"
)

//go:embed default-config.yaml
var defaultConfigYAML []byte

type CategoryConfig struct {
	Path   string `yaml:"path"`
	Hotkey string `yaml:"hotkey"`
}

type Config struct {
	BaseDir           string                    `yaml:"base_dir"`
	Categories        map[string]CategoryConfig `yaml:"categories"`
	VideoExts         []string                  `yaml:"video_extensions"`
	JunkExts          []string                  `yaml:"junk_extensions"`
	JunkVideoPatterns []string                  `yaml:"junk_video_patterns"`
	LogFile           string                    `yaml:"log_file"`
	ConfigDir         string                    `yaml:"-"`
}

func LoadDefaultConfig() (*Config, error) {
	var config Config
	if err := yaml.Unmarshal(defaultConfigYAML, &config); err != nil {
		return nil, fmt.Errorf("failed to parse default config: %w", err)
	}
	return &config, nil
}

func LoadConfig() (*Config, error) {
	homeDir, err := homedir.Dir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	configDir := filepath.Join(homeDir, ".config", "sorter")
	configPath := filepath.Join(configDir, "config.yaml")

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		if err := os.MkdirAll(configDir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create config directory: %w", err)
		}

		if err := os.WriteFile(configPath, defaultConfigYAML, 0644); err != nil {
			return nil, fmt.Errorf("failed to write default config: %w", err)
		}
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	config.ConfigDir = configDir
	return &config, nil
}

func SaveConfig(config *Config, path string) error {
	var node yaml.Node
	if err := node.Encode(config); err != nil {
		return fmt.Errorf("failed to encode config: %w", err)
	}

	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("failed to open config file: %w", err)
	}
	defer file.Close()

	encoder := yaml.NewEncoder(file)
	encoder.SetIndent(2)
	defer encoder.Close()

	if err := encoder.Encode(&node); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

func (c *Config) ExpandPaths() error {
	expandedBase, err := homedir.Expand(c.BaseDir)
	if err != nil {
		return fmt.Errorf("failed to expand base directory: %w", err)
	}
	
	if err := validatePath(expandedBase); err != nil {
		return fmt.Errorf("invalid base directory: %w", err)
	}
	c.BaseDir = expandedBase

	for key, category := range c.Categories {
		expanded, err := homedir.Expand(category.Path)
		if err != nil {
			return fmt.Errorf("failed to expand category path %s: %w", key, err)
		}
		
		if err := validatePath(expanded); err != nil {
			return fmt.Errorf("invalid category path %s: %w", key, err)
		}
		
		category.Path = expanded
		c.Categories[key] = category
	}

	return nil
}

func (c *Config) AddJunkVideoPattern(filename string) error {
	pattern := extractPattern(filename)
	
	for _, existing := range c.JunkVideoPatterns {
		if existing == pattern {
			return nil
		}
	}
	
	c.JunkVideoPatterns = append(c.JunkVideoPatterns, pattern)
	
	configPath := filepath.Join(c.ConfigDir, "config.yaml")
	return SaveConfig(c, configPath)
}

func extractPattern(filename string) string {
	name := filepath.Base(filename)
	ext := filepath.Ext(name)
	nameWithoutExt := strings.TrimSuffix(name, ext)
	
	return nameWithoutExt + "*"
}

func validatePath(path string) error {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to get absolute path: %w", err)
	}
	
	cleanPath := filepath.Clean(absPath)
	if absPath != cleanPath {
		return fmt.Errorf("path contains invalid elements: %s", path)
	}
	
	if strings.Contains(path, "..") {
		return fmt.Errorf("path contains directory traversal elements: %s", path)
	}
	
	return nil
}