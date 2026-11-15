-- ~/.config/wezterm/wezterm.lua

local wezterm = require 'wezterm'

local config = {}

config.font = wezterm.font 'AnonymicePro Nerd Font Mono'
config.font_size = 18.0

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- 'Dracula', 'Solarized Dark', 'Gruvbox dark'
config.color_scheme = 'Dracula'
config.colors = {
  tab_bar = {
    background = '#282a2e',
    active_tab = {
      bg_color = '#1e1e2e',
      fg_color = '#ffffff',
    },
    inactive_tab = {
      bg_color = '#282a2e',
      fg_color = '#a6adc8',
    },
    new_tab = {
      bg_color = '#282a2e',
      fg_color = '#a6adc8',
    },
  },
}

config.tab_max_width = 12
config.window_frame = {
  font_size = 5.0,  -- Размер шрифта именно для заголовков вкладок
}

config.window_decorations = 'NONE'
return config
