return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#000000",
        dark_bg = "#1c1c1c",
        darker_bg = "#000000",
        lighter_bg = "#333333",

        fg = "#c1c1c1",
        dark_fg = "#919191",
        light_fg = "#cacaca",
        bright_fg = "#d1d1d1",
        muted = "#505050",

        red = "#8a9a7b",
        yellow = "#888888",
        orange = "#9ca98f",
        green = "#c1c1c1",
        cyan = "#aa9988",
        blue = "#aaaaaa",
        magenta = "#999999",
        brown = "#5e6556",

        bright_red = "#8a9a7b",
        bright_yellow = "#888888",
        bright_green = "#c1c1c1",
        bright_cyan = "#aa9988",
        bright_blue = "#aaaaaa",
        bright_magenta = "#999999",

        accent = "#8a9a7b",
        cursor = "#d1d1d1",
        foreground = "#c1c1c1",
        background = "#000000",
        selection = "#c1c1c1",
        selection_foreground = "#c1c1c1",
        selection_background = "#333333",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
