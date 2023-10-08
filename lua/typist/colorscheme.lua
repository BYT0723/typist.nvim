local util = require("typist.util")

local M = {
	-- highlight
	NORMALTYPIST = "TypistTextNormal", -- normal
	PASSTYPIST = "TypistTextPass", -- pass
	ERRORTYPIST = "TypistTextError", -- error
}

---
--- set highlight
---
---@reutrn ns number
function M.set_highlight()
	local ns = vim.api.nvim_create_namespace(util.UNIQUENAME)
	vim.api.nvim_set_hl(ns, M.NORMALTYPIST, {
		fg = "#888888",
		bg = "#330033",
	})

	vim.api.nvim_set_hl(ns, M.PASSTYPIST, {
		fg = "#00ff00",
		bg = "#330033",
	})

	vim.api.nvim_set_hl(ns, M.ERRORTYPIST, {
		fg = "#330033",
		bg = "#ff0000",
		bold = true,
	})
	return ns
end

return M
