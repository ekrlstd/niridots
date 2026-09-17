 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#131314',
    base01 = '#1f1f21',
    base02 = '#2a2a2b',
    base03 = '#8f9096',
    base04 = '#c5c6cc',
    base05 = '#e4e2e3',
    base06 = '#e4e2e3',
    base07 = '#e4e2e3',
    base08 = '#ffb4ab',
    base09 = '#cfc2d6',
    base0A = '#c4c6ce',
    base0B = '#bfc7d9',
    base0C = '#cfc2d6',
    base0D = '#bfc7d9',
    base0E = '#c4c6ce',
    base0F = '#e1e2ea',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#e4e2e3',          bg = '#131314' })
  hi('TelescopeBorder',         { fg = '#8f9096',             bg = '#131314' })
  hi('TelescopePromptNormal',   { fg = '#e4e2e3',          bg = '#131314' })
  hi('TelescopePromptBorder',   { fg = '#8f9096',             bg = '#131314' })
  hi('TelescopePromptPrefix',   { fg = '#bfc7d9',             bg = '#131314' })
  hi('TelescopePromptCounter',  { fg = '#c5c6cc',  bg = '#131314' })
  hi('TelescopePromptTitle',    { fg = '#131314',             bg = '#bfc7d9' })
  hi('TelescopePreviewTitle',   { fg = '#131314',             bg = '#c4c6ce' })
  hi('TelescopeResultsTitle',   { fg = '#131314',             bg = '#cfc2d6' })
  hi('TelescopeSelection',      { fg = '#e4e2e3',          bg = '#2a2a2b' })
  hi('TelescopeSelectionCaret', { fg = '#bfc7d9',             bg = '#2a2a2b' })
  hi('TelescopeMatching',       { fg = '#bfc7d9',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
