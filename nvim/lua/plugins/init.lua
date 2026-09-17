return {

  -- ─── Formatting ─────────────────────────────────────────────────────────────
  -- conform.nvim formats on BufWritePre; see lua/configs/conform.lua for the
  -- full filetype → formatter mapping.
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- ─── LSP ────────────────────────────────────────────────────────────────────
  -- nvim-lspconfig provides default server configs; see lua/configs/lspconfig.lua.
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- ─── Mason tool installer ───────────────────────────────────────────────────
  -- mason.nvim itself only provides the UI and registry.
  -- mason-tool-installer handles the actual auto-installation of anything in the
  -- Mason registry (LSP servers, formatters, linters, …).
  -- Run :MasonToolsInstall to trigger manually, or just restart Neovim.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false, -- must load on startup so run_on_start actually fires
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        -- LSP servers ─────────────────────────────────────────────────────────
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "json-lsp",
        "pyright",
        "bash-language-server",
        "marksman",

        -- Formatters ──────────────────────────────────────────────────────────
        "prettier",
        "black",
        "shfmt",
      },
      -- Install missing tools automatically on startup.
      run_on_start = false, -- DISABLED THIS FOR NIX
      auto_update = false,
    },
  },

  -- ─── Syntax highlighting ────────────────────────────────────────────────────
  -- Treesitter parsers for fast, accurate highlighting and smart indentation.
  -- Run :TSUpdate to refresh parsers after upgrading nvim-treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "typescript",
        "javascript",
        "tsx",
        "json",
        "jsonc",
        "html",
        "css",
        "python",
        "bash",
        "c",
        "cpp",
        "nix",
        "markdown",
        "markdown_inline",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- ─── Completion keybindings ─────────────────────────────────────────────────
  -- Extends NvChad's nvim-cmp defaults with these keybinds:
  --   <Tab>   → next item  (also expands / jumps LuaSnip snippets)
  --   <S-Tab> → prev item  (also jumps LuaSnip backward)
  --   <C-y>   → confirm selection
  --   <CR>    → plain newline; never confirms completion
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"
      local luasnip = require "luasnip"

      opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {

        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item { behavior = cmp.SelectBehavior.Insert }
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item { behavior = cmp.SelectBehavior.Insert }
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Confirm the highlighted (or first) item.
        ["<C-y>"] = cmp.mapping.confirm { select = true },

        -- Enter inserts a literal newline; it does not confirm completion.
        ["<CR>"] = cmp.mapping(function(fallback)
          fallback()
        end),
      })

      return opts
    end,
  },

  -- oil.nvim: browse filesystem like a buffer (used by kotlin.nvim).
  {
    "stevearc/oil.nvim",
    lazy = true,
    init = function()
      vim.g.oil_loaded = true
    end,
    opts = {},
  },

  -- ─── Git: LazyGit ───────────────────────────────────────────────────────────
  -- Opens a full-screen LazyGit TUI inside Neovim.
  -- Prerequisite: `sudo pacman -S lazygit`
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- ─── Terminal ───────────────────────────────────────────────────────────────
  -- <C-\> toggles a horizontal split terminal at the bottom.
  -- open_mapping handles all modes (normal, insert, terminal) correctly.
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = { { "<C-t>", desc = "Toggle terminal" } },
    opts = {
      shell = "fish",
      open_mapping = [[<C-t>]],
      size = 15,
      direction = "horizontal",
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      persist_size = true,
      close_on_exit = true,
    },
  },

  -- ─── File tree: 'l' to open / expand ────────────────────────────────────────
  -- Extends NvChad's nvim-tree setup: 'l' opens a file or expands a directory.
  -- All other default keymaps remain unchanged.
  {
    "nvim-tree/nvim-tree.lua",
    opts = function(_, opts)
      opts.on_attach = function(bufnr)
        local api = require "nvim-tree.api"

        -- Apply all default keymaps first so nothing is lost.
        api.config.mappings.default_on_attach(bufnr)

        -- Override 'l' → open file / expand directory.
        vim.keymap.set("n", "l", api.node.open.edit, {
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
          desc = "nvim-tree: Open / Expand",
        })
      end

      return opts
    end,
  },

  -- ─── Image viewing ──────────────────────────────────────────────────────────
  -- Renders images inline inside markdown buffers.
  --
  -- Terminal requirements (choose one):
  --   Kitty   → backend = "kitty"    (default; no extra deps)
  --   WezTerm → backend = "wezterm"
  --   Other   → backend = "ueberzugpp"
  --             + `sudo pacman -S imagemagick`
  --             + install ueberzugpp from AUR
  --
  -- build = false: skip the luarocks step (not needed for kitty / wezterm).
  {
    "3rd/image.nvim",
    build = false,
    ft = { "markdown" },
    opts = {
      -- Change to "ueberzugpp" or "wezterm" if you are not using Kitty.
      backend = "kitty",

      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },

      max_width = 100,
      max_height = 12,
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = true,
    },
  },

  -- ─── Trouble ────────────────────────────────────────────────────────────────
  -- A pretty diagnostics panel. Replaces the default quickfix / loclist.
  -- Keymaps:  <leader>xx  toggle panel   <leader>xX  buffer-only diagnostics
  --           <leader>xq  quickfix list  <leader>xl  location list
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics (Trouble)" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list (Trouble)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list (Trouble)" },
    },
    opts = { focus = true },
  },

  -- ─── Flash ──────────────────────────────────────────────────────────────────
  -- Jump anywhere on screen with 2-3 keystrokes.
  -- s  → flash jump    S  → flash treesitter (jump to AST node)
  -- r  → remote flash (in operator-pending)   R  → treesitter search
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
        mode = { "n", "x", "o" },
      },
      {
        "S",
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
        mode = { "n", "x", "o" },
      },
      {
        "r",
        function()
          require("flash").remote()
        end,
        desc = "Flash remote",
        mode = "o",
      },
      {
        "R",
        function()
          require("flash").treesitter_search()
        end,
        desc = "Flash treesitter search",
        mode = { "o", "x" },
      },
    },
  },

  -- ─── Noice ──────────────────────────────────────────────────────────────────
  -- Replaces the command line, messages, and popupmenu with a polished UI.
  -- NvChad compatibility: lsp.progress disabled (NvChad's statusline handles it).
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = {
        -- Disable features that conflict with NvChad's built-in LSP UI.
        progress = { enabled = false },
        hover = { enabled = false },
        signature = { enabled = false },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = {
        bottom_search = true, -- classic / bottom search bar
        command_palette = true, -- position cmdline + popupmenu together
        long_message_to_split = true, -- long messages go to a split
      },
    },
  },

  -- ─── Markdown rendering ─────────────────────────────────────────────────────
  -- Renders headings, code blocks, tables, checkboxes, and links inline while
  -- editing. Works in conjunction with image.nvim for embedded images.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      enabled = true,
      heading = { enabled = true },
      code = { enabled = true, style = "full" },
      bullet = { enabled = true },
      checkbox = { enabled = true },
      table = { enabled = true },
      link = { enabled = true },
    },
  },
}
