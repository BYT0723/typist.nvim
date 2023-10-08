local api = vim.api
local util = require("typist.util")
local colors = require("typist.colorscheme")
local window = require("typist.window")

---
--- new a extmark mode typiest
---
---@param conf table
function ExtmarkMode(conf)
	local M = {}
	---
	--- statistical results
	---
	---@return {}
	function M.settle()
		local res = {}
		for i = 0, 25 do
			res[string.char(65 + i)] = { passed = 0, error = 0, count = 0 }
			res[string.char(97 + i)] = { passed = 0, error = 0, count = 0 }
		end

		local marks = api.nvim_buf_get_extmarks(api.nvim_get_current_buf(), M.ns, 0, -1, { details = true })
		for _, mark in ipairs(marks) do
			for _, char in ipairs(mark[4].virt_lines[1]) do
				local byte = string.byte(char[1])
				if (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) then
					if char[2] == colors.PASSTYPIST then
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
				report[key] =
					string.format("[%.0f%%](%d/%d)", (item.passed / item.count) * 100, item.passed, item.count)
			end
		end

		return report
	end
	---
	--- set auto command
	---
	function M.set_autocmd()
		local cb = api.nvim_win_get_buf(M.win)
		api.nvim_create_autocmd({ "TextChangedI" }, {
			group = M.augroup,
			buffer = cb,
			callback = function()
				local pos = api.nvim_win_get_cursor(M.win)

				local row = pos[1] - 1

				-- current line text
				local content = api.nvim_get_current_line()

				-- current line extmark text
				local marktxt = ""
				local mark = api.nvim_buf_get_extmarks(cb, M.ns, { row, 0 }, { row + 1, 0 }, { details = true })[1]
				for _, item in ipairs(mark[4].virt_lines[1]) do
					marktxt = marktxt .. item[1]
				end

				-- utf8 chars in extmark text
				local markChars = {}
				-- utf8 chars in content text
				local contentChars = {}

				for char in string.gmatch(marktxt, util.utf8_charpattern) do
					table.insert(markChars, char)
				end
				for char in string.gmatch(content, util.utf8_charpattern) do
					table.insert(contentChars, char)
				end

				local line = {}
				for i = 1, #markChars do
					if i > #contentChars then
						table.insert(line, { table.concat(markChars, "", i), colors.NORMALTYPIST })
						break
					end

					if markChars[i] == contentChars[i] then
						table.insert(line, { markChars[i], colors.PASSTYPIST })
					else
						table.insert(line, { markChars[i], colors.ERRORTYPIST })
					end
				end

				-- vim.notify(vim.inspect(line))
				-- mark[1] is the id of extmark
				api.nvim_buf_del_extmark(cb, M.ns, mark[1])
				api.nvim_buf_set_extmark(cb, M.ns, row, 0, {
					virt_lines = { line },
					virt_lines_above = true,
					sign_text = "",
				})
				if #contentChars >= #markChars then
					if pos[1] >= api.nvim_buf_line_count(cb) then
						local res = { rate = M.settle() }
						res.time = os.time() - M.startTime .. " second"
						vim.notify(vim.inspect(res))
						window.close_win()
						return
					end
					api.nvim_win_set_cursor(M.win, { pos[1] + 1 + conf.paddingLine, 0 })
				end
			end,
		})
	end

	---
	--- Set keymap
	---
	function M.set_keymap()
		local cb = api.nvim_win_get_buf(M.win)

		-- disable <CR> and <Esc> in buf
		vim.keymap.set("i", "<CR>", "", { buffer = cb, expr = true })
		vim.keymap.set("i", "<Esc>", "", { buffer = cb })

		-- Backspace
		vim.keymap.set("i", "<Backspace>", function()
			local pos = api.nvim_win_get_cursor(M.win)

			-- If the cursor is in the first column and not in the first row
			-- the cursor moves to the next row of the previous extmark
			if pos[2] == 0 then
				if pos[1] > 1 + conf.paddingLine then
					return string.rep("<Up>", 1 + conf.paddingLine) .. "<End><Backspace>"
				end
			else
				-- else just Backspace
				return "<Backspace>"
			end
		end, { buffer = cb, expr = true })

		-- quit window
		vim.keymap.set("i", "<C-q>", function()
			window.close_win()
		end, { buffer = cb })

		-- hide window
		vim.keymap.set("i", "<C-h>", function()
			window.close_win({ bufclose = false })
		end, { buffer = cb })
	end

	function M.Init()
		-- Initialize buf and namespace
		M.buf = api.nvim_create_buf(true, false)
		-- local ns = api.nvim_create_namespace(UNIQUENAME)
		M.ns = colors.set_highlight()

		M.augroup = api.nvim_create_augroup(util.UNIQUENAME, { clear = true })

		-- record startup time
		M.startTime = os.time()

		local filepath = util.GetWd() .. util.GetRandomFile(util.GetWd())

		-- read file and assemble extmark
		local contents = {}
		for line in io.lines(filepath) do
			table.insert(contents, { line, colors.NORMALTYPIST })
		end

		-- Fill space characters into buf
		-- Prevent error reporting when setting extmarks
		local spaces = {}
		for _ = 1, #contents * (conf.paddingLine + 1) - (conf.paddingLine - 1) do
			table.insert(spaces, "")
		end
		api.nvim_buf_set_lines(M.buf, 0, -1, false, spaces)

		-- set extmark
		local inc = 0 -- increment, to help calculate line padding
		for i, line in ipairs(contents) do
			api.nvim_buf_set_extmark(M.buf, M.ns, i + inc, 0, {
				virt_lines = { { line } },
				virt_lines_above = true,
			})
			inc = inc + conf.paddingLine
		end

		-- After buf initialization is complete, open the window
		M.win = window.open_win(M.buf, conf.win)
		-- set highlight
		api.nvim_win_set_hl_ns(M.win, M.ns)
		M.set_autocmd()
		M.set_keymap()

		-- Reposition the cursor
		api.nvim_win_set_cursor(M.win, { 2, 0 })
	end

	function M.Show()
		if api.nvim_buf_is_valid(M.buf) then
			M.win = window.open_win(M.buf, conf.win)
			-- set highlight
			api.nvim_win_set_hl_ns(M.win, M.ns)
		else
			vim.notify("No exist Typist buffer, you can :TypistOpen open a new window")
		end
	end

	return M
end

return ExtmarkMode
