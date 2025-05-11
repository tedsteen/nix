-- basic sane options
local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.cursorline = true
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 300
opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true

-- keymaps
vim.g.mapleader = " "
local keymap = vim.keymap.set
keymap("n", "<leader>w", ":w<CR>", { desc = "save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "quit" })

-- optional: disable netrw (for nvim-tree, oil.nvim, etc)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1