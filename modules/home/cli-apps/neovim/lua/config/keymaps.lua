-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

map("n", "<S-j>", "10j", { desc = "Scroll down" })
map("n", "<S-k>", "10k", { desc = "Scroll up" })

-- Disable horizontal scrolling
map("n", "<ScrollWheelRight>", "<Nop>")
map("n", "<ScrollWheelLeft>", "<Nop>")
map("n", "<S-ScrollWheelUp>", "<ScrollWheelRight>")
map("n", "<S-ScrollWheelDown>", "<ScrollWheelLeft>")

-- Disable replacing cliboard on change
map("n", "c", '"_c', { desc = "Change without replacing clipboard" })
map("n", "C", '"_C', { desc = "Change without replacing clipboard" })
