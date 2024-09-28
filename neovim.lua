-- Alternative configuration for neovim wrapper
--
-- This is intended for macOS, to be launched as, e.g.
--
--    open -n -W -a /Applications/WezTerm.app --args --config-file $HOME/.config/wezterm/neovim.lua
--
-- Or, if opening a particular FILE:
--
--    open -n -W -a /Applications/WezTerm.app --args --config-file $HOME/.config/wezterm/neovim.lua start --always-new-process -- /opt/homebrew/bin/nvim -c "set mouse=a" "$FILE"
--
-- This could be done, e.g., from a Shortcut, using the "Run Shell Script"
-- action as the only step. That shortcut could then be turned into a standalone
-- app ("Add to Dock")

local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

config.default_workspace = "neovim"
config.window_decorations = "TITLE | RESIZE"
config.enable_tab_bar = false

config.default_prog = { '/opt/homebrew/bin/nvim', '-c', 'set mouse=a' }

config.quit_when_all_windows_are_closed = true
config.window_padding = {
  left = 5,
  right = 5,
  top = 1,
  bottom = 1,
}


config.disable_default_key_bindings = true
config.keys = {
  { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
  { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
  { key = '-', mods = 'SUPER|SHIFT', action = act.DecreaseFontSize },
  { key = '0', mods = 'SUPER', action = act.ResetFontSize },
  { key = '0', mods = 'SUPER|SHIFT', action = act.ResetFontSize },
  { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
  { key = '=', mods = 'SUPER|SHIFT', action = act.IncreaseFontSize },
  { key = 'l', mods = 'SUPER|SHIFT|CTRL', action = act.ShowDebugOverlay },
  { key = 'h', mods = 'SUPER', action = act.HideApplication },
  { key = 'm', mods = 'SUPER', action = act.Hide },
  { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
  { key = 'c', mods = 'SUPER', action = act.SendString '"*y' },
  { key = 'a', mods = 'SUPER', action = act.SendString '\x1b\x1bggVG' },
  { key = 'q', mods = 'SUPER', action = act.SendString '\x1b\x1b:qa\n' },
  { key = 't', mods = 'SUPER', action = act.SendString '\x1b\x1b:tabnew\n' },
  { key = 'w', mods = 'SUPER', action = act.SendString '\x1b\x1b:tabclose\n' },
  { key = 's', mods = 'SUPER', action = act.SendString '\x1b\x1b:w\n' },
  { key = 'f', mods = 'SUPER', action = act.SendString '\x1b\x1b/' },
  { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' },
  { key = 'LeftArrow', mods = 'SUPER', action = act.SendString '\x1b\x1b:tabprev\n' },
  { key = 'RightArrow', mods = 'SUPER', action = act.SendString '\x1b\x1b:tabnext\n' },
  { key = '[', mods = 'SHIFT|SUPER', action = act.SendString 'x1bx1b:tabprev\n' },
  { key = ']', mods = 'SHIFT|SUPER', action = act.SendString 'x1bx1b:tabnext\n' },
  { key = '{', mods = 'SUPER', action = act.SendString 'x1bx1b:tabprev\n' },
  { key = '{', mods = 'SHIFT|SUPER', action = act.SendString 'x1bx1b:tabprev\n' },
  { key = '}', mods = 'SUPER', action = act.SendString 'x1bx1b:tabnext\n' },
  { key = '}', mods = 'SHIFT|SUPER', action = act.SendString 'x1bx1b:tabnext\n' },
}

local colors = wezterm.color.load_scheme(wezterm.home_dir .. "/.config/wezterm/colors/light.toml")
config.colors = colors

config.font = wezterm.font "JuliaMono"
config.font_size = 12
-- no ligatures
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

return config
