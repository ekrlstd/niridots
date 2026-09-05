-- conform.nvim — format on save
-- Formatters must be installed; Mason installs them automatically (see plugins/init.lua).
-- Run :ConformInfo to see which formatter is active for the current buffer.

local options = {
  -- Map each filetype to an ordered list of formatters (first available wins).
  formatters_by_ft = {
    lua = { "stylua" },

    -- Web / JavaScript ecosystem — prettier handles all of these.
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    markdown = { "prettier" },

    -- Python
    python = { "black" },

    -- Shell
    bash = { "shfmt" },
    sh = { "shfmt" },

    -- C / C++ (reads .clang-format; falls back to LLVM style)
    c = { "clang-format" },
    cpp = { "clang-format" },
    objc = { "clang-format" },
    objcpp = { "clang-format" },

    -- Nix (NixOS official formatter — 2-space indent)
    nix = { "nixpkgs-fmt" },
  },

  -- Format automatically when saving. 500 ms is generous enough for large files.
  -- lsp_fallback: if no formatter is registered for this ft, ask the LSP instead.
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
}

return options
