local M = {}

---
--- open window
---
---@param buf integer
---@param opt table
---@return integer
function M.open_win(buf, opt)
	-- open window by buf
	local win = vim.api.nvim_open_win(buf, true, opt)
	-- enter insert mode
	vim.cmd("startinsert!")

	return win
end

---
--- close the window
---
---@param opt  nil | { bufclose:boolean }
function M.close_win(opt)
	opt = opt or { bufclose = true }
	local cw = vim.api.nvim_get_current_win()
	if opt.bufclose then
		-- if close window with close buf
		local cb = vim.api.nvim_get_current_buf()
		vim.api.nvim_win_close(cw, true)
		vim.api.nvim_buf_delete(cb, { force = true })
	else
		-- else just hide window
		vim.api.nvim_win_hide(cw)
	end

	if vim.fn.mode() == "i" then
		vim.cmd("stopinsert!")
	end
end

return M
