-- =============================================================================
-- noctalia.lua  --  Single source of truth for theme colors in Neovim.
--
-- This module is the replacement for the old `matugen.lua` generated file.
--
-- Noctalia no longer writes a `.lua` file into `~/config/nvim/lua/matugen.lua`
-- (the old v4 flow that made `require("matugen")` throw and break startup).
-- Instead Noctalia renders a **JSON file** (see `~/config/nvim/matugen.json`,
-- templated from `~/config/nvim/matugen-template.json`) every time the
-- wallpaper / color scheme changes.
--
-- This module:
--   * reads that JSON file defensively (never crashes on a missing/corrupt file),
--   * exposes a full palette (base16 + base30 semantics + accent colors) that
--     chadrc.lua uses to theme ALL of NvChad's UI (statusline, tabufline,
--     nvim-tree ...) AND that we apply directly to plugin/runtime highlight
--     groups here,
--   * falls back to a sane onedark-derived palette if the JSON is absent,
--   * hot-reloads on `SIGUSR1` (what Noctalia's `post_hook` sends) and on
--     `FocusGained` / `VimResume`, and
--   * is indexed so other modules can pull the current palette.
--
-- NOTE: keep this module side-effect free at require-time EXCEPT for building
-- the palette. All nvim_set_hl calls happen in `apply()`.
-- =============================================================================

local M = {}

-- Paths. Expand `~` ourselves because Lua/dofile does not do shell expansion.
local home = vim.fn.expand("~")
local CONFIG_DIR = vim.fn.stdpath("config") -- ~/.config/nvim
local JSON_PATH = CONFIG_DIR .. "/matugen.json"
local TEMPLATE_PATH = CONFIG_DIR .. "/matugen-template.json"

-- -----------------------------------------------------------------------------
-- Default token map (used whenever the JSON is missing/corrupt so nvim ALWAYS
-- comes up with a usable theme instead of erroring). These are a neutral
-- onedark-ish set that still produce a complete, readable UI. We keep these as
-- the same M3 token keys the JSON uses, then run them through `build_palette`
-- so the fallback palette has the exact same shape as the real one.
-- -----------------------------------------------------------------------------
local DEFAULT = {
  surface                = "#282c34",
  surface_container      = "#31353d",
  surface_container_high = "#393f4a",
  surface_container_lowest = "#21252b",
  on_surface             = "#abb2bf",
  on_surface_variant     = "#565c64",
  on_background          = "#c8ccd4",
  outline                = "#545862",
  primary                = "#61afef",
  secondary              = "#e5c07b",
  tertiary               = "#d19a66",
  error                  = "#e06c75",
  error_container        = "#be5046",
  primary_fixed_dim      = "#61afef",
  secondary_fixed_dim    = "#c678dd",
  tertiary_fixed_dim     = "#56b6c2",
}

-- -----------------------------------------------------------------------------
-- Internal helpers
-- -----------------------------------------------------------------------------

-- Accepts "#rrggbb" OR "rrggbb" and returns "#rrggbb", or nil if invalid.
local function normalize_hex(value)
  if type(value) ~= "string" then
    return nil
  end

  local v = value:gsub("%s", "")

  if v:match("^#%x%x%x%x%x%x$") then
    return v
  end

  if v:match("^%x%x%x%x%x%x$") then
    return "#" .. v
  end

  return nil
end

-- -----------------------------------------------------------------------------
-- Palette construction
-- -----------------------------------------------------------------------------
-- Builds the full palette table from the Mar-me/M3 JSON token map.
-- Falls back to DEFAULT for any missing/invalid entry so a partial JSON still
-- yields a complete theme.
-- -----------------------------------------------------------------------------

---@param tokens table<string,string> raw string->string JSON token map
---@return table palette
local function build_palette(tokens)
  local hex = function(key, fallback)
    local h = normalize_hex(tokens[key])
    return (h ~= nil) and h or (fallback or DEFAULT[key])
  end

  local p = {}

  -- ---- base16 ----
  p.base00 = hex("surface")
  p.base01 = hex("surface_container")
  p.base02 = hex("surface_container_high")
  p.base03 = hex("outline")
  p.base04 = hex("on_surface_variant")
  p.base05 = hex("on_surface")
  p.base06 = hex("on_background")
  p.base07 = hex("on_background")
  p.base08 = hex("error")
  p.base09 = hex("tertiary")
  p.base0A = hex("secondary")
  p.base0B = hex("primary")
  p.base0C = hex("tertiary_fixed_dim")
  p.base0D = hex("primary_fixed_dim")
  p.base0E = hex("secondary_fixed_dim")
  p.base0F = hex("error_container")

  -- ---- named accents (convenience for syntax groups) ----
  p.bg        = p.base00
  p.fg        = p.base05
  p.comment   = p.base03
  p.dim       = p.base04
  p.red       = p.base08
  p.orange    = p.base09
  p.yellow    = p.base0A
  p.green     = p.base0B
  p.cyan      = p.base0C
  p.blue      = p.base0D
  p.purple    = p.base0E
  p.brown     = p.base0F
  p.selection = p.base02
  p.border    = p.base03
  p.menu_bg   = p.base01

  -- The file tree stays at the terminal/surface color (p.bg) — never darker.
  -- To tell the panes apart we make the FOCUSED code editor LIGHTER instead.
  p.editor_bg = p.base01                            -- lighter than surface

  -- Non-current (background) windows sit AT the surface/terminal color (p.bg),
  -- matching the file tree, so only the focused editor appears lighter.
  p.nc_bg = p.bg

  -- ---- base30 (NvChad statusline / tabufline / nvim-tree) ----
  -- We deliberately keep a surface ramp here: NvChad relies on these slots
  -- being DIFFERENT lightnesses to show hierarchy (active vs inactive tabs,
  -- cursor line, folder names). Using one flat surface everywhere made the
  -- selected tab / hovered tree item indistinguishable from the background.
  --
  -- NOTE: darker_black stays at the editor surface (base00), NOT a darker
  -- "deepest" tone. darker_black is shared by the file tree, floats, popups,
  -- telescope and the statusline, and mapping it darker darkened the whole UI.
  -- The hover/tab distinction comes from one_bg2/one_bg being lighter, not
  -- from making darker_black darker.

  p.white         = p.fg
  p.darker_black  = p.base00                        -- file tree / floats / popups
  p.black         = p.base00                        -- editor bg
  p.black2        = p.base00                        -- inactive tab bg / tabline
  p.one_bg        = p.base01                        -- active tab / statusline bar
  p.one_bg2       = p.base02                        -- hover / cursorline
  p.one_bg3       = p.base02
  p.grey          = p.base03
  p.grey_fg       = p.base04
  p.grey_fg2      = p.base04
  p.light_grey    = p.base04
  p.red           = p.base08
  p.baby_pink     = p.base08
  p.pink          = p.base09
  p.line          = p.base03                        -- separators (visible-ish)
  p.green         = p.base0B
  p.vibrant_green = p.base0B
  p.nord_blue     = p.base0D
  p.blue          = p.base0D
  p.yellow        = p.base0A
  p.sun           = p.base0A
  p.purple        = p.base0E
  p.dark_purple   = p.base0E
  p.teal          = p.base0C
  p.orange        = p.base09
  p.cyan          = p.base0C
  p.statusline_bg = p.base00
  p.lightbg       = p.base01
  p.pmenu_bg      = p.base01
  -- Folder names must be readable against the dark tree, so use a bright
  -- accent (the M3 "primary" tone) rather than a dark surface.
  p.folder_bg     = p.base0B

  return p
end

-- -----------------------------------------------------------------------------
-- JSON reading
-- -----------------------------------------------------------------------------

-- Returns the raw palette file contents, or nil if unreadable. Used by the
-- change watcher to cheaply detect when the rendered palette differs.
local function read_raw_palette()
  local fh = io.open(JSON_PATH, "r")
  if not fh then
    return nil
  end
  local content = fh:read("*a")
  fh:close()
  return content
end

local function read_palette()
  -- Read the raw file contents.
  local fh, err = io.open(JSON_PATH, "r")
  if not fh then
    return build_palette(DEFAULT), "no palette file (" .. JSON_PATH .. "): " .. tostring(err)
  end

  local content = fh:read("*a")
  fh:close()

  if not content or content:find("%S") == nil then
    return build_palette(DEFAULT), "palette file is empty"
  end

  -- Decode JSON; vim.json is available on nvim 0.10+.
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return build_palette(DEFAULT), "palette JSON is invalid: " .. tostring(decoded)
  end

  return build_palette(decoded), nil
end

-- -----------------------------------------------------------------------------
-- Public API
-- -----------------------------------------------------------------------------

-- The current palette (built at require time, refreshed on reload).
M.palette = read_palette()

-- Raw JSON content that the current palette was built from. The watcher uses
-- this to tell when the palette changed on disk (wallpaper switch, etc.).
M._applied_content = nil

-- Returns a fresh palette after re-reading the JSON on disk.
function M.reload()
  local new_palette, err = read_palette()
  M.palette = new_palette
  M.last_error = err
  M._applied_content = read_raw_palette()
  return new_palette, err
end

-- Applies runtime/plugin highlight groups from the current palette.
-- These sit ON TOP of NvChad's base46 cache (which chadrc.lua already points
-- at the same palette via base_16/base_30), so everything stays consistent.
function M.apply()
  local c = M.palette

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Core editor surfaces
  -- The editor stays at the background/surface color whether focused or not,
  -- so focusing the file tree never lightens the code editor. Active vs
  -- inactive is shown by the tabufline instead.
  hi("Normal",          { fg = c.fg, bg = c.bg })
  hi("NormalNC",        { fg = c.fg, bg = c.bg })
  hi("NormalFloat",     { fg = c.fg, bg = c.bg })
  hi("FloatBorder",     { fg = c.border, bg = c.bg })
  hi("FloatTitle",      { fg = c.fg, bg = c.bg })
  hi("SignColumn",      { fg = c.dim, bg = c.bg })
  hi("ColorColumn",     { bg = c.one_bg })
  hi("CursorLine",      { bg = c.one_bg })
  hi("CursorLineNr",    { fg = c.fg, bg = c.one_bg, bold = true })
  hi("CursorColumn",    { bg = c.one_bg })
  hi("EndOfBuffer",     { fg = c.dim })
  hi("Conceal",         { fg = c.dim, bg = c.bg })
  hi("LineNr",          { fg = c.dim, bg = c.bg })
  hi("WinSeparator",    { fg = c.line })

  -- Selection / search
  hi("Visual",          { bg = c.selection })
  hi("VisualNOS",       { bg = c.selection })
  hi("Search",          { fg = c.bg, bg = c.yellow })
  hi("IncSearch",       { fg = c.bg, bg = c.orange })
  hi("Substitute",      { fg = c.bg, bg = c.yellow })
  hi("MatchParen",      { bg = c.selection })

  -- Messages / status
  hi("ModeMsg",         { fg = c.green })
  hi("MoreMsg",         { fg = c.green })
  hi("Question",        { fg = c.blue })
  hi("WarningMsg",      { fg = c.orange })
  hi("ErrorMsg",        { fg = c.red, bg = c.bg })
  hi("Title",           { fg = c.blue })

  -- Popup menu (completion)
  hi("Pmenu",           { fg = c.fg, bg = c.menu_bg })
  hi("PmenuSel",        { fg = c.bg, bg = c.blue })
  hi("PmenuSbar",       { bg = c.selection })
  hi("PmenuThumb",      { bg = c.grey })

  -- Tabs (native, in case tabufline isn't active on some buffer)
  hi("TabLine",         { fg = c.dim, bg = c.bg })
  hi("TabLineFill",     { bg = c.bg })
  hi("TabLineSel",      { fg = c.green, bg = c.one_bg })

  -- NvChad file tree (nvim-tree): the tree background stays at the same color
  -- as the terminal/editor surface (c.bg) — never darker. The hovered row is
  -- clearly lighter so you can see where the cursor is.
  hi("NvimTreeCursorLine",  { bg = c.one_bg2 })
  hi("NvimTreeNormal",      { bg = c.bg })
  hi("NvimTreeNormalNC",    { bg = c.bg })
  hi("NvimTreeWinSeparator",{ fg = c.bg, bg = c.bg })

  -- NvChad tabufline: ACTIVE tab is darker (bg/surface) while inactive tabs
  -- are lighter (editor_bg), so the active buffer is a dark pillar surrounded
  -- by lighter inactive ones.
  hi("TbBufOn",         { fg = c.white, bg = c.bg })
  hi("TbBufOnModified", { fg = c.green, bg = c.bg })
  hi("TbBufOnClose",    { fg = c.red, bg = c.bg })
  hi("TbBufOff",        { fg = c.light_grey, bg = c.editor_bg })
  hi("TbBufOffModified",{ fg = c.red, bg = c.editor_bg })
  hi("TbBufOffClose",   { fg = c.light_grey, bg = c.editor_bg })
  hi("TbFill",          { bg = c.editor_bg })
  hi("Tabline",         { bg = c.editor_bg })
  hi("TbTabOn",         { fg = c.red, bg = c.bg })
  hi("TbTabOff",        { fg = c.white, bg = c.editor_bg })

  -- Syntax (base16-linked, matches NvChad's treesitter integration)
  hi("Comment",         { fg = c.comment, italic = true })
  hi("Constant",        { fg = c.orange })
  hi("String",          { fg = c.green })
  hi("Character",       { fg = c.green })
  hi("Number",          { fg = c.orange })
  hi("Float",           { fg = c.orange })
  hi("Boolean",         { fg = c.orange })
  hi("Identifier",      { fg = c.red })
  hi("Function",        { fg = c.blue })
  hi("Statement",       { fg = c.red })
  hi("Conditional",     { fg = c.purple })
  hi("Repeat",          { fg = c.yellow })
  hi("Label",           { fg = c.yellow })
  hi("Operator",        { fg = c.purple })
  hi("Keyword",         { fg = c.purple })
  hi("Exception",       { fg = c.red })
  hi("PreProc",         { fg = c.yellow })
  hi("Include",         { fg = c.blue })
  hi("Define",          { fg = c.purple })
  hi("Macro",           { fg = c.red })
  hi("Type",            { fg = c.yellow })
  hi("StorageClass",    { fg = c.yellow })
  hi("Structure",       { fg = c.purple })
  hi("Typedef",         { fg = c.yellow })
  hi("Special",         { fg = c.cyan })
  hi("SpecialChar",     { fg = c.brown })
  hi("Tag",             { fg = c.yellow })
  hi("Delimiter",       { fg = c.brown })
  hi("SpecialComment",  { fg = c.comment })
  hi("Todo",            { fg = c.yellow, bg = c.one_bg })
  hi("Underlined",      { fg = c.red, underline = true })
  hi("Error",           { fg = c.red, bg = c.bg })
  hi("Debug",           { fg = c.red })

  -- Fold / columns
  hi("Folded",          { fg = c.comment, bg = c.one_bg })
  hi("FoldColumn",      { fg = c.cyan, bg = c.bg })

  -- Diff
  hi("DiffAdd",         { fg = c.green, bg = c.one_bg })
  hi("DiffChange",      { fg = c.blue, bg = c.one_bg })
  hi("DiffDelete",      { fg = c.red, bg = c.one_bg })
  hi("DiffText",        { fg = c.yellow, bg = c.selection })

  -- Diagnostics
  hi("DiagnosticError", { fg = c.red })
  hi("DiagnosticWarn",  { fg = c.yellow })
  hi("DiagnosticInfo",  { fg = c.blue })
  hi("DiagnosticHint",  { fg = c.cyan })

  -- Treesitter: link the modern @groups to our base16-grounded groups so we
  -- don't have to enumerate every single one. Fall back to sensible links.
  local ts_link = {
    ["@comment"]    = "Comment",
    ["@string"]     = "String",
    ["@string.escape"] = "SpecialChar",
    ["@character"]  = "Character",
    ["@number"]     = "Number",
    ["@float"]      = "Float",
    ["@boolean"]    = "Boolean",
    ["@constant"]   = "Constant",
    ["@constant.builtin"] = "Constant",
    ["@constant.macro"]   = "Constant",
    ["@namespace"]  = "Identifier",
    ["@symbol"]     = "Special",
    ["@function"]   = "Function",
    ["@function.builtin"] = "Function",
    ["@function.macro"]   = "Macro",
    ["@method"]     = "Function",
    ["@method.call"]= "Function",
    ["@constructor"]= "Special",
    ["@keyword"]    = "Keyword",
    ["@keyword.function"] = "Keyword",
    ["@keyword.return"]   = "Keyword",
    ["@keyword.operator"] = "Operator",
    ["@keyword.conditional"] = "Conditional",
    ["@keyword.repeat"]   = "Repeat",
    ["@keyword.storage"]  = "StorageClass",
    ["@conditional"]= "Conditional",
    ["@repeat"]     = "Repeat",
    ["@label"]      = "Label",
    ["@include"]    = "Include",
    ["@preproc"]    = "PreProc",
    ["@define"]     = "Define",
    ["@operator"]   = "Operator",
    ["@type"]       = "Type",
    ["@type.builtin"] = "Type",
    ["@type.definition"] = "Typedef",
    ["@attribute"]  = "PreProc",
    ["@property"]   = "Identifier",
    ["@field"]      = "Identifier",
    ["@variable"]   = "Identifier",
    ["@variable.builtin"] = "Identifier",
    ["@parameter"]  = "Identifier",
    ["@punctuation"]= "Delimiter",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"]   = "Delimiter",
    ["@punctuation.special"]   = "Special",
    ["@tag"]        = "Tag",
    ["@tag.attribute"] = "Type",
    ["@tag.delimiter"] = "PreProc",
    ["@error"]      = "Error",
    ["@comment.error"] = "Error",
    ["@comment.warning"] = "WarningMsg",
    ["@comment.note"]   = "SpecialComment",
    ["@comment.todo"]   = "Todo",

    -- text / markup
    ["@text"]             = "Normal",
    ["@text.title"]       = "Title",
    ["@text.strong"]      = { bold = true },
    ["@text.emphasis"]    = { italic = true },
    ["@text.underline"]   = { underline = true },
    ["@text.strike"]      = { strikethrough = true },
    ["@text.literal"]     = "Constant",
    ["@text.uri"]         = { fg = c.blue, underline = true },
    ["@string.special.url"] = { fg = c.blue, underline = true },
    ["@text.reference"]   = "Identifier",
    ["@text.diff.add"]    = "DiffAdd",
    ["@text.diff.delete"] = "DiffDelete",
    ["@markup.heading"]   = "Title",
    ["@markup.strong"]    = { bold = true },
    ["@markup.italic"]    = { italic = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.link"]      = "Identifier",
    ["@markup.link.url"]  = { fg = c.blue, underline = true },
    ["@markup.link.label"]= "SpecialChar",
    ["@markup.raw"]       = "Comment",
    ["@markup.list"]      = "Delimiter",
    ["@markup.quote"]     = "Comment",
  }

  for group, target in pairs(ts_link) do
    if type(target) == "table" then
      hi(group, target)
    else
      vim.api.nvim_set_hl(0, group, { link = target })
    end
  end

  -- Inlay hints
  hi("LspInlayHint",    { fg = c.comment })
  hi("LspInlayHintSig", { fg = c.comment })
end

-- Lightweight palette change watcher. Every 3s re-reads the tiny JSON and, if
-- it differs from what was last applied, runs a full apply_reload(). This
-- covers wallpaper changes even when the SIGUSR1 post_hook is missed (e.g. the
-- daemon couldn't reach nvim). The file is ~500 bytes, so this is cheap.
local watcher_started = false
function M._start_watcher()
  if watcher_started then
    return
  end
  watcher_started = true
  local timer = vim.uv.new_timer()
  M._watcher = timer
  timer:start(3000, 3000, vim.schedule_wrap(function()
    if M._applied_content ~= read_raw_palette() then
      M.apply_reload()
    end
  end))
end

-- Idempotently (de)register the signal + autocmd handlers. We keep handles
-- global so `setup()` can be called repeatedly without stacking callbacks.
local function ensure_handlers()
  if M._installed then
    return
  end
  M._installed = true

  -- SIGUSR1 is what Noctalia's post_hook (`pkill -SIGUSR1 nvim`) sends.
  -- We clear the relevant caches so the fresh JSON is picked up, then
  -- recompile base46 (statusline / tabufline / tree) and re-apply syntax.
  local signal = vim.uv.new_signal()
  M._signal = signal
  signal:start("sigusr1", vim.schedule_wrap(function()
    M.apply_reload()
  end))

  -- If the JSON appears/changes while focused (e.g. first run), refresh too.
  M._focus_autocmd = vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
    callback = function()
      vim.schedule(function()
        M.apply_reload()
      end)
    end,
  })

  -- Plugins (treesitter, nvim-tree, tabufline, noice, …) lazily re-apply
  -- their OWN highlight groups after we do, clobbering our overrides as soon
  -- as new buffers/windows open. Re-assert our groups whenever a buffer enters
  -- or a colorscheme is (re)applied so our colors always win. These fire often
  -- but are cheap (a handful of nvim_set_hl calls) and idempotent. We defer so
  -- our re-apply runs AFTER any plugin handlers for the same event.
  M._reapply_autocmds = vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWinEnter", "BufAdd", "ColorScheme", "FileType" },
    {
      callback = function()
        if M.palette then
          vim.defer_fn(M.apply, 10)
        end
      end,
    }
  )

  -- After Lazy / plugins finish loading, run the FULL reload so the base46
  -- cache (tabufline / tree / statusline colors) is compiled from the current
  -- palette — this guarantees nvim opens with the latest theme even if the
  -- JSON was written while nvim was closed.
  M._verylazy_autocmd = vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      vim.defer_fn(M.apply_reload, 100)
    end,
  })

  -- Fallback that makes reload work even if the SIGUSR1 post_hook never
  -- reaches nvim: watch matugen.json for changes and reload on the spot.
  M._start_watcher()
end

-- Re-read the JSON, repoint NvChad's base46 at the new palette, recompile the
-- UI cache and re-apply syntax groups. Safe to call at any time.
function M.apply_reload()
  local _, err = M.reload()

  -- Drop the cached chadrc / nvconfig so base46 recompiles against the fresh
  -- palette. NOTE: we must NOT clear noctalia's own package.loaded entry —
  -- other modules (and this one) keep a reference to the same module table.
  pcall(function()
    package.loaded["chadrc"] = nil
    package.loaded["nvconfig"] = nil
  end)

  pcall(function()
    require("base46").load_all_highlights()
  end)

  M.apply()

  if err then
    vim.notify(
      "Noctalia theme: " .. err
        .. ". Using fallback palette until matugen.json is rendered.",
      vim.log.levels.WARN
    )
  end
end

-- Setup entrypoint. Safe to call more than once.
function M.setup()
  M.reload()
  ensure_handlers()
  vim.schedule(function()
    M.apply()
  end)
end

return M
