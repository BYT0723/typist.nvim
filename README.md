# typist.nvim

> Allows you to contact touch typing skills in Neovim

## Install

- lazy.nvim

```lua
{
    'BYT0723/typist.nvim',
    opts = {},          -- default config
    dependencies = {
      'uga-rosa/utf8.nvim',
    }
}
```

## Command

- TypistOpen

  When opening `typist.nvim` for the first time, run this command to open the window

- TypistShow

  After using `TypistOpen` to open the window, after using `<C-h>` to hide the window, you can use this command to redisplay the window

## Configuration

```lua
{
    -- Space between two lines
	paddingLine = 1,
    -- neovim window config
	win = {
		relative = "win",
		title = "Typist",
		title_pos = "center",
		border = "double",
		style = "minimal",
		row = 10.1,
		col = 10.1,
		width = 100,
		height = 30,
	},
}
```
