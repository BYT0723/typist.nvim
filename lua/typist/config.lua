local DEFAULT_OPTS = {
	paddingLine = 1,
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

local function setup(conf)
	return vim.tbl_deep_extend("force", DEFAULT_OPTS, conf or {})
end

return {
	setup = setup,
}
