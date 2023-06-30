local M = {}

local config = require("typist.config")
local api = vim.api

local UNIQUENAME = "TYPIST"

local NORMALTYPIST = "TypistTextNormal"
local PASSTYPIST = "TypistTextPass"
local ERRORTYPIST = "TypistTextError"

local utf8_charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

local conf, buf, ns, win

local startTime

local function open_win()
	win = api.nvim_open_win(buf, true, conf.win)
	api.nvim_win_set_hl_ns(win, ns)
	vim.cmd("startinsert!")
end

local function close_win(opt)
	opt = opt or { bufclose = true }
	if opt.bufclose then
		api.nvim_win_close(win, true)
		api.nvim_buf_delete(buf, { force = true })
	else
		api.nvim_win_hide(win)
	end

	if vim.fn.mode() == "i" then
		vim.cmd("stopinsert!")
	end
end

local function settle()
	local res = {}
	for i = 0, 25 do
		res[string.char(65 + i)] = { passed = 0, error = 0, count = 0 }
		res[string.char(97 + i)] = { passed = 0, error = 0, count = 0 }
	end

	local marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
	for _, mark in ipairs(marks) do
		for _, char in ipairs(mark[4].virt_lines[1]) do
			local byte = string.byte(char[1])
			if (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) then
				if char[2] == PASSTYPIST then
					res[char[1]].passed = res[char[1]].passed + 1
				else
					res[char[1]].error = res[char[1]].error + 1
				end
				res[char[1]].count = res[char[1]].count + 1
			end
		end
	end

	local report = {}

	for key, item in pairs(res) do
		if item.count > 0 then
			report[key] = item.passed / item.count
		end
	end

	return report
end

local function Init(filepath)
	-- Initialize buf and namespace
	buf = api.nvim_create_buf(true, false)
	ns = api.nvim_create_namespace(UNIQUENAME)

	startTime = os.time()

	local contents = {}
	for line in io.lines(filepath) do
		table.insert(contents, { line, NORMALTYPIST })
	end

	local spaces = {}
	for _ = 1, #contents * (conf.paddingLine + 1) - (conf.paddingLine - 1) do
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
		inc = inc + conf.paddingLine
	end

	open_win()
	api.nvim_win_set_cursor(win, { 2, 0 })
end

local function set_command()
	local cmd = api.nvim_create_user_command
	cmd("TypistOpen", function()
		M.TypistOpen()
	end, {})
	cmd("TypistShow", function()
		M.TypistShow()
	end, {})
end

-- set space lines
local function set_highlight()
	api.nvim_set_hl(ns, NORMALTYPIST, {
		fg = "#888888",
		bg = "#330033",
	})

	api.nvim_set_hl(ns, PASSTYPIST, {
		fg = "#00ff00",
		bg = "#330033",
	})

	api.nvim_set_hl(ns, ERRORTYPIST, {
		fg = "#330033",
		bg = "#ff0000",
		bold = true,
	})
end

local function set_autocmd()
	local gid = api.nvim_create_augroup(UNIQUENAME, { clear = true })
	api.nvim_create_autocmd({ "TextChangedI" }, {
		group = gid,
		buffer = buf,
		callback = function()
			local pos = api.nvim_win_get_cursor(win)

			local row = pos[1] - 1

			-- current line text
			local content = api.nvim_get_current_line()

			-- current line extmark text
			local marktxt = ""
			local mark = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row + 1, 0 }, { details = true })[1]
			for _, item in ipairs(mark[4].virt_lines[1]) do
				marktxt = marktxt .. item[1]
			end

			-- utf8 chars in extmark text
			local markChars = {}
			-- utf8 chars in content text
			local contentChars = {}

			for char in string.gmatch(marktxt, utf8_charpattern) do
				table.insert(markChars, char)
			end
			for char in string.gmatch(content, utf8_charpattern) do
				table.insert(contentChars, char)
			end

			local line = {}
			for i = 1, #markChars do
				if i > #contentChars then
					table.insert(line, { table.concat(markChars, "", i), NORMALTYPIST })
					break
				end

				if markChars[i] == contentChars[i] then
					table.insert(line, { markChars[i], PASSTYPIST })
				else
					table.insert(line, { markChars[i], ERRORTYPIST })
				end
			end

			-- vim.notify(vim.inspect(line))
			-- mark[1] is the id of extmark
			api.nvim_buf_del_extmark(buf, ns, mark[1])
			api.nvim_buf_set_extmark(buf, ns, row, 0, {
				virt_lines = { line },
				virt_lines_above = true,
				sign_text = "",
			})
			if #contentChars >= #markChars then
				if pos[1] >= api.nvim_buf_line_count(buf) then
					local res = { rate = settle() }
					close_win()
					res.time = os.time() - startTime

					vim.notify(vim.inspect(res))
					return
				end
				api.nvim_win_set_cursor(win, { pos[1] + 1 + conf.paddingLine, 0 })
			end
		end,
	})
end

local function set_keymap()
	vim.keymap.set("i", "<CR>", function() end, { buffer = buf, expr = true })

	vim.keymap.set("i", "<Backspace>", function()
		local pos = api.nvim_win_get_cursor(win)

		if pos[2] == 0 then
			if pos[1] > 1 + conf.paddingLine then
				return string.rep("<Up>", 1 + conf.paddingLine) .. "<End><Backspace>"
			end
		else
			return "<Backspace>"
		end
	end, { buffer = buf, expr = true })

	vim.keymap.set("i", "<Esc>", "", { buffer = buf })

	vim.keymap.set("i", "<C-q>", function()
		close_win()
	end, { buffer = buf })

	vim.keymap.set("i", "<C-h>", function()
		close_win({ bufclose = false })
	end, { buffer = buf })
end

function M.setup(opts)
	conf = config.setup(opts)
	set_command()
end

function M.TypistOpen()
	Init("/home/walter/Workspace/Github/Neovim/typist.nvim/lua/text.txt")
	set_highlight()
	set_keymap()
	set_autocmd()
end

function M.TypistShow()
	if not buf then
		vim.notify("No exist Typist buffer")
		return
	end
	open_win()
end

return M
