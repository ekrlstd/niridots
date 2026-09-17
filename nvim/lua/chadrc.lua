---@type ChadrcConfig
local M = {}

-- Load the palette from Noctalia's rendered JSON.
-- `require("noctalia").palette` is ALWAYS a complete table: it is built from
-- the JSON when matugen.json exists, and falls back to a sane onedark-derived
-- palette otherwise. It never throws, so nvim can never fail to start because
-- of a missing/corrupt theme file.
local ok, noctalia = pcall(require, "noctalia")
local palette = ok and noctalia.palette or nil

-- Build base46 changed_themes. When the palette is available we theme
-- everything from it; when it is not (extreme fallback) we leave NvChad to its
-- default onedark so the UI stays usable.
if palette then
  M.base46 = {
    theme = "onedark",

    changed_themes = {
      onedark = {
        base_16 = {
          base00 = palette.base00,
          base01 = palette.base01,
          base02 = palette.base02,
          base03 = palette.base03,
          base04 = palette.base04,
          base05 = palette.base05,
          base06 = palette.base06,
          base07 = palette.base07,
          base08 = palette.base08,
          base09 = palette.base09,
          base0A = palette.base0A,
          base0B = palette.base0B,
          base0C = palette.base0C,
          base0D = palette.base0D,
          base0E = palette.base0E,
          base0F = palette.base0F,
        },

        base_30 = {
          white         = palette.white,
          darker_black  = palette.darker_black,
          black         = palette.black,
          black2        = palette.black2,

          one_bg        = palette.one_bg,
          one_bg2       = palette.one_bg2,
          one_bg3       = palette.one_bg3,

          grey          = palette.grey,
          grey_fg       = palette.grey_fg,
          grey_fg2      = palette.grey_fg2,
          light_grey    = palette.light_grey,

          red           = palette.red,
          baby_pink     = palette.baby_pink,
          pink          = palette.pink,

          line          = palette.line,

          green         = palette.green,
          vibrant_green = palette.vibrant_green,

          nord_blue     = palette.nord_blue,
          blue          = palette.blue,

          yellow        = palette.yellow,
          sun           = palette.sun,

          purple        = palette.purple,
          dark_purple   = palette.dark_purple,

          teal          = palette.teal,
          orange        = palette.orange,
          cyan          = palette.cyan,

          statusline_bg = palette.statusline_bg,
          lightbg       = palette.lightbg,

          pmenu_bg      = palette.pmenu_bg,
          folder_bg     = palette.folder_bg,
        },
      },
    },
  }
end

M.ui = {
  statusline = {
    modules = {
      mode = function()
        return ""
      end,
    },
  },

  tabufline = {
    modules = {
      buttons = function()
        return ""
      end,
    },
  },
}

return M
