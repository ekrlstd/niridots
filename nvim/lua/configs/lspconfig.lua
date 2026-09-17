-- Load NvChad's LSP defaults (on_attach, capabilities, etc.)
require("nvchad.configs.lspconfig").defaults()
-- ─── Language servers ─────────────────────────────────────────────────────────
-- All servers are installed automatically via Mason (see plugins/init.lua).
-- Run :Mason to open the UI, or :LspInfo to inspect active servers.
local servers = {
  "html", -- HTML
  "cssls", -- CSS / SCSS / Less
  "ts_ls", -- TypeScript & JavaScript (covers .ts .tsx .js .jsx)
  "jsonls", -- JSON & JSONC
  "tailwindcss", -- Tailwind CSS class completion and diagnostics
  "pyright", -- Python (static type analysis + hover + completion)
  "bashls", -- Bash / POSIX shell scripts
  "marksman", -- Markdown (link resolution, headings, etc.)
  "clangd", -- C / C++
  "nil_ls", -- Nix (nil language server)
}
vim.lsp.enable(servers)
-- ─── Per-server overrides ─────────────────────────────────────────────────────
-- Only override what the server's defaults don't handle well.
-- clangd: enable background indexing, clang-tidy diagnostics, and smart
-- header insertion. Reads compile_commands.json from CMake/compile_commands.
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
  },
})
-- Tailwind: extend filetypes so it activates in JSX/TSX files.
vim.lsp.config("tailwindcss", {
  filetypes = {
    "html",
    "css",
    "scss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
})
