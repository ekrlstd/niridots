-- Load NvChad's built-in mappings first, then add / override below.
require "nvchad.mappings"

local map = vim.keymap.set

-- ─── General ──────────────────────────────────────────────────────────────────
-- map("n", ";", ":", { desc = "CMD: enter command mode" })
map("i", "jk", "<ESC>", { desc = "Quick escape from insert mode" })

-- ─── File tree ────────────────────────────────────────────────────────────────
-- Remove NvChad's default <C-n> toggle; <leader>e is our replacement.
-- pcall guards against the case where NvChad hasn't set it in a given context.
pcall(vim.keymap.del, "n", "<C-n>")
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- ─── Buffer navigation ────────────────────────────────────────────────────────
-- Shift-L / Shift-H mirror the Vim hjkl direction for left/right buffer tabs.
map("n", "<S-h>", "<cmd>bprev<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- ─── Terminal ─────────────────────────────────────────────────────────────
-- Escape terminal mode with Esc, then move to the editor window with standard window nav.
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- ─── LSP (general) ─────────────────────────────────────────────────────────
-- Code actions (auto-import, quick fixes, etc.) — IntelliJ Alt+Enter equivalent.
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: code action" })
map("x", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: code action (range)" })
-- Rename symbol across the project.
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "LSP: rename symbol" })

-- ─── Git ──────────────────────────────────────────────────────────────────────
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })
