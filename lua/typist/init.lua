local api = vim.api

local UNIQUENAME = "TYPIST"

local NORMALTYPIST = "DiagnosticVirtualTextHint"
local ERRORTYPIST = "DiagnosticVirtualTextError"
local PASSTYPIST = "DiagnosticVirtualTextOk"

local win_conf = {
	relative = "win",
	title = "Typist",
	title_pos = "center",
	border = "double",
	row = 0,
	col = 0,
	width = 80,
	height = 30,
}

local buf, win, ns

local function open_win()
	win = api.nvim_open_win(buf, true, win_conf)
	vim.cmd("startinsert!")
end

local function set_keymap()
	vim.keymap.set("i", "<CR>", function()
		local pos = api.nvim_win_get_cursor(win)
		return pos[1] < api.nvim_buf_line_count(buf) and string.rep("<Down>", 2)
	end, { buffer = buf, expr = true })

	vim.keymap.set("i", "<Backspace>", function()
		local pos = api.nvim_win_get_cursor(win)

		if pos[2] == 0 then
			return pos[1] > 2 and string.rep("<Up>", 2)
		else
			return "<Backspace>"
		end
	end, { buffer = buf, expr = true })

	vim.keymap.set("i", "<Esc>", "", { buffer = buf })

	vim.keymap.set("i", "<C-q>", function()
		api.nvim_win_close(win, true)
		api.nvim_buf_delete(buf, { force = true })
	end, { buffer = buf })

	vim.keymap.set("i", "<C-h>", function()
		api.nvim_win_hide(win)
	end, { buffer = buf })

	vim.keymap.set("", "<C-s>", function()
		open_win()
	end, {})
end

local function updateExtmark()
	local pos = api.nvim_win_get_cursor(win)

	local row = pos[1] - 1

	local content = api.nvim_get_current_line()

	local mark = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row + 1, 0 }, { details = true })[1]

	-- if mark == nil then
	-- 	return
	-- end

	local marktxt = ""
	for _, item in ipairs(mark[4].virt_lines[1]) do
		marktxt = marktxt .. item[1]
	end

	local line = {}
	for i = 1, #marktxt do
		if i > #content then
			table.insert(line, { string.sub(marktxt, i), NORMALTYPIST })
			break
		end
		local char = string.sub(marktxt, i, i)
		if char == string.sub(content, i, i) then
			table.insert(line, { char, PASSTYPIST })
		else
			table.insert(line, { char, ERRORTYPIST })
		end
	end

	-- vim.notify(vim.inspect(line))
	-- mark[1] is the id of extmark
	api.nvim_buf_del_extmark(buf, ns, mark[1])
	api.nvim_buf_set_extmark(buf, ns, row, 0, {
		virt_lines = { line },
		virt_lines_above = true,
		sign_text = "",
	})
end

local function set_autocmd()
	local gid = api.nvim_create_augroup(UNIQUENAME, { clear = true })
	api.nvim_create_autocmd({ "TextChangedI" }, {
		group = gid,
		buffer = buf,
		callback = updateExtmark,
	})
end

local function init(filepath)
	local contents = {}
	for line in io.lines(filepath) do
		table.insert(contents, { line, NORMALTYPIST })
	end

	buf = api.nvim_create_buf(true, false)
	ns = api.nvim_create_namespace(UNIQUENAME)

	-- set space lines
	local spaces = {}
	for _ = 1, #contents * 2 + 1 do
		table.insert(spaces, "")
	end
	api.nvim_buf_set_lines(buf, 0, -1, false, spaces)

	-- set extmark
	local inc = 0
	for i, line in ipairs(contents) do
		api.nvim_buf_set_extmark(buf, ns, i + inc, 0, {
			virt_lines = { { line } },
			virt_lines_above = true,
		})
		inc = inc + 1
	end

	open_win()
	api.nvim_win_set_cursor(win, { 2, 0 })
end

local function main()
	init("/home/walter/Workspace/Github/Neovim/typist.nvim/lua/text.txt")
	set_keymap()
	set_autocmd()
end

main()
