local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux


local config = wezterm.config_builder()

config.unix_domains = {
  {
    name = 'mux',
  },
}

config.default_workspace = "default"

local launch_menu = {}

if wezterm.target_triple == 'aarch64-apple-darwin' then

  -- Apple Silicon
  config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:' .. os.getenv 'PATH',
  }
  table.insert(launch_menu, {
    label = "ZSH",
    args = { "zsh", "--login" },
  })

elseif wezterm.target_triple == 'x86_64-pc-windows-msvc' then

  -- Windows
  table.insert(launch_menu, {
    label = 'PowerShell',
    args = { 'powershell.exe', '-NoLogo' },
  })

end


-- See https://wezfurlong.org/wezterm/config/launch.html?h=launch_menu#the-launcher-menu
-- Note that we've disabled the right-click on the "new tab button"
config.launch_menu = launch_menu


config.leader = { key = 'a', mods = 'CMD', timeout_milliseconds = 5000 }

config.keys = {
  {
      mods = "LEADER",
      key = "|",
      action = act.SplitHorizontal { domain = "CurrentPaneDomain" }
  },
  {
      mods = "LEADER",
      key = "-",
      action = act.SplitVertical { domain = "CurrentPaneDomain" }
  },
  { -- open launcher
    key = 'o',
    mods = 'CMD',
    action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS'},
  },
  { -- attach to domain
    key = 'a',
    mods = 'LEADER',
    action = act.ShowLauncherArgs { flags = 'FUZZY|DOMAINS' },
  },
  { -- detach from current domain
    key = 'd',
    mods = 'LEADER',
    action = act.DetachDomain 'CurrentPaneDomain',
  },
  { -- toggle tab bar
    key = 't',
    mods = 'LEADER',
    action = act.EmitEvent 'toggle-tabbar',
  },
  { -- settings
    key = ',',
    mods = 'CMD',
    action = act.SpawnCommandInNewWindow {
      cwd = os.getenv("WEZTERM_CONFIG_DIR"),
      args = { os.getenv("SHELL"), "--login", "-c", '"$EDITOR" "$WEZTERM_CONFIG_FILE"'},
    },
  },
  { -- quick edit
    key = 'e',
    mods = 'CMD',
    action = act.SpawnCommandInNewTab {
      args = { os.getenv("SHELL"), "--login", "-c", '"$EDITOR"'},
    },
  },
  { -- ChatGPT
    key = 'g',
    mods = 'CMD',
    action = wezterm.action_callback(function(win, pane)
      local _, new_pane, _ = win:mux_window():spawn_tab {
          args = { os.getenv("SHELL"), "--login", "-c", 'nvim'},
      }
      local endTime = os.time() + 1.0
      while os.time() < endTime do
         -- sleep for 1 sec (nvim needs time to initialize)
      end
      new_pane:send_text(":GpChatNew\n")
      -- This very much depends on my configuration using https://github.com/Robitx/gp.nvim
    end),
  },
  { -- Activate copy mode (cf. `tmux`, in addition to the default ctr-shift-x)
    key = '[',
    mods = 'LEADER',
    action = act.ActivateCopyMode,
  },
  { -- Paste (like in tmux)
    key = ']',
    mods = 'LEADER',
    action = act.PasteFrom 'Clipboard',
  },
  {
    key = 'r',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Enter new name for workspace',
      action = wezterm.action_callback(
        function(window, pane, line)
          if line then
            mux.rename_workspace(
              window:mux_window():get_workspace(),  -- rename workspace
              line
            )
          end
        end
      ),
    },
  },
  {
    key = 's',
    mods = 'LEADER',
    action = act.ShowLauncherArgs { flags = 'WORKSPACES' }, -- show workspaces
  },
  {
    key = 'r',
    mods = 'CMD',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  { -- Move tab (pane) interactively
    key = 't',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, pane)

      local function get_tab_title(t)
        if t:get_title() == "" then
          local p = t:active_pane()
          return p:get_title()
        else
          return t:get_title()
        end
      end

      local choices = {}
      for _, w in ipairs(wezterm.mux.all_windows()) do
        local window_width = 0
        local window_height = 0
        local tabs = {}
        for _, t in ipairs(w:tabs()) do
            table.insert(tabs, get_tab_title(t))
            if t:get_size().rows > window_height then
                window_height = t:get_size().rows
            end
            if t:get_size().cols > window_width then
                window_width = t:get_size().cols
            end
        end
        local tab_titles = table.concat(tabs, ", ")
        table.insert(choices, { id = tostring(w:window_id()), label = "window " .. tostring(w:window_id()) .. " (" .. window_width .. "x" .. window_height .. ") with " .. tostring(#w:tabs()) .. " tabs: " .. tab_titles })
      end
      table.insert(choices, {id = "new", label = "new window"})

      window:perform_action(
        act.InputSelector {
          action = wezterm.action_callback(function(window, pane, id, label)
            if id then
              local tab_title = pane:tab():get_title()
              local wezterm_bin = wezterm.executable_dir .. "/wezterm"
              if id == "new" then
                wezterm.log_info('CMD-SHIFT-T: you selected ', label)
                local tab, _ = pane:move_to_new_window()
                tab.set_title(tab_title)
              else
                local cmd = { wezterm_bin, 'cli', 'move-pane-to-new-tab', '--pane-id', pane:pane_id(), "--window-id", id}
                wezterm.log_info('CMD-SHIFT-T: you selected ', label, "->", wezterm.shell_join_args(cmd))
                local success, stdout, stderr = wezterm.run_child_process(cmd)
                wezterm.log_info(success, stdout, stderr)
                pane:tab():set_title(tab_title)
              end
            end
          end),
          title = 'Choose target window',
          choices = choices,
          description = 'Move pane ' .. pane:pane_id() .. " (tab title '" .. get_tab_title(pane:tab()) .."') from window " .. pane:window():window_id() .. " to…",
        },
        pane
      )
    end),
  },
  {
    key = 'p',
    mods = 'CMD',
    action = act.PaneSelect {
      show_pane_ids=true,
    },
  },
  {
    key = 'p',
    mods = 'CMD|SHIFT',
    action = act.ActivateCommandPalette
  },
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = act.ActivateTabRelative(-1)
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = act.ActivateTabRelative(1)
  },
  {
    key = 'LeftArrow',
    mods = 'CMD|SHIFT',
    action = act.MoveTabRelative(-1)
  },
  {
    key = 'RightArrow',
    mods = 'CMD|SHIFT',
    action = act.MoveTabRelative(1)
  },
}

config.use_fancy_tab_bar = true
-- config.use_fancy_tab_bar = false
if config.use_fancy_tab_bar then
    config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
else
    config.window_decorations = "RESIZE"
end
config.tab_max_width = 20
config.enable_tab_bar = true

wezterm.on(
  'new-tab-button-click',
  function(window, pane, button, default_action)
    wezterm.log_info('new-tab', window, pane, button, default_action)
    if (button == "Left") and default_action then
      window:perform_action(default_action, pane)
    end
    -- Do not handle right-click. Instead, use CMD-O for a customized launcher
    return false  -- Tell WezTerm that we handled the event
  end
)

config.adjust_window_size_when_changing_font_size = false
config.quit_when_all_windows_are_closed = false

config.window_padding = {
  left = 5,
  right = 5,
  top = 1,
  bottom = 1,
}

wezterm.on('toggle-tabbar', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  if overrides.enable_tab_bar then
    overrides.enable_tab_bar = false
    overrides.window_decorations = "RESIZE"
  else
    overrides.enable_tab_bar = true
    overrides.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  end
  window:set_config_overrides(overrides)
end)


wezterm.on('update-status', function(window, pane)
  if config.enable_tab_bar then
    local right_status = ""
    local domain = pane:get_domain_name()
    if domain then
      if domain ~= "local" then
        right_status = domain .. " "
      end
    end
    local workspace = window:active_workspace()
    if workspace ~= config.default_workspace then
      right_status = right_status .. "(".. workspace .. ")" .. " "
    end
    local window_id = window:window_id()
    local pane_id_str = "." .. pane:pane_id()
    local dims = pane:get_dimensions()
    local pane_size_str = ": " .. dims.cols .. "x" .. dims.viewport_rows
    if pane:tab() then
        -- only show IDs if pane is associated with a tab. Not for, e.g., the debug pane
        right_status = right_status .. '[' .. window_id .. pane_id_str.. pane_size_str .. ']  '
    end
    if window:leader_is_active() then
      right_status = right_status .. utf8.char(0x1f388) -- balloon
    end
    window:set_right_status(wezterm.format {
      { Foreground = { Color = '#999999' } },
      { Background = { Color = '#333333' } },
      { Text = right_status  },
    })
  end
end)



local colors = wezterm.color.load_scheme(wezterm.home_dir .. "/.config/wezterm/colors/light.toml")
colors.tab_bar = {
  background = '#000000',
  -- The active tab is the one that has focus in the window
  active_tab = {
    bg_color = '#0061df',
    fg_color = '#FFFFFF',
    intensity = 'Bold', -- "Half", "Normal" or "Bold" intensity for the
    italic = false,
  },
  -- Inactive tabs are the tabs that do not have focus
  inactive_tab = {
    bg_color = '#1b1032',
    fg_color = '#FFFFFF',
    intensity = 'Half', -- "Half", "Normal" or "Bold" intensity for the
  },
  inactive_tab_hover = {
    bg_color = '#1b1032',
    fg_color = '#FFFFFF',
    italic = false,
    intensity = 'Bold',
  },
  -- The new tab button that let you create new tabs
  new_tab = {
    bg_color = '#1b1032',
    fg_color = '#AAAAAA',
    intensity = 'Bold', -- "Half", "Normal" or "Bold" intensity for the
  },
}
config.colors = colors

config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.95,
}

config.font = wezterm.font "JuliaMono"
config.font_size = 12
-- no ligatures
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
config.window_frame = {  -- tab bar font
  font = wezterm.font { family = 'Roboto', weight = 'Bold' },
  font_size = 12,
}

return config
