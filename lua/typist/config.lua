local api = vim.api

local DEFAULT_OPTS = {
	paddingLine = 1,
	win = {
		relative = "win",
		title = "Typist",
		title_pos = "center",
		border = "double",
		style = "minimal",
		row = 0.5,
		col = 0.5,
		width = 0.4,
		height = 0.6,
	},
}

---
--- Set config
---
---@param opt {}
---@return {}
local function setup(opt)
	local conf = vim.tbl_deep_extend("force", DEFAULT_OPTS, opt or {})

	local gh = api.nvim_win_get_height(0)
	local gw = api.nvim_win_get_width(0)
	if conf.win.height <= 1 then
		conf.win.height = math.ceil(gh * conf.win.height)
	end
	if conf.win.width <= 1 then
		conf.win.width = math.ceil(gw * conf.win.width)
	end
	if conf.win.row <= 1 then
		conf.win.row = math.floor((gh - conf.win.height) * conf.win.row)
	end
	if conf.win.col <= 1 then
		conf.win.col = math.floor((gw - conf.win.width) * conf.win.col)
	end

	return conf
end

return {
	setup = setup,
}
