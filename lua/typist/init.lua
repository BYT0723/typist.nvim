local api = vim.api
local config = require("typist.config")

local M = {}

require("typist.extmark")
require("typist.inner")

local conf

---
--- set command
---
local function set_command()
	local cmd = api.nvim_create_user_command
	cmd("TypistOpen", function()
		M.TypistOpen()
	end, { desc = "Open Typist Window" })
	cmd("TypistShow", function()
		M.TypistShow()
	end, { desc = "Redisplay Typist Window" })
end

---
--- Setup
---
---@param opts {}
function M.setup(opts)
	conf = config.setup(opts)
	set_command()
end

---
--- Command `TypistOpen` function
---
function M.TypistOpen()
	M.mode = ExtmarkMode(conf)
	M.mode.Init()
end

---
--- Command `TypistShow` function
---
function M.TypistShow()
	M.mode.Show()
end

return M
