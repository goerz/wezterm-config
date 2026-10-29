-- Helpers shared between wezterm.lua and neovim.lua

local M = {}

-- Run cmd through the login shell, so it sees the same PATH and environment
-- as an interactive terminal; `exec` replaces the shell with cmd
function M.login_shell(cmd)
  return { os.getenv 'SHELL', '--login', '-c', 'exec ' .. cmd }
end

return M
