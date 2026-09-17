require "nvchad.options"

local opt = vim.opt

-- ─── Line numbers ─────────────────────────────────────────────────────────────
-- Show absolute line number on the current line, relative elsewhere.
-- This makes jump counts (e.g. 5j, 12k) easy to read at a glance.
opt.number = true
opt.relativenumber = true
