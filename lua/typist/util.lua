local M = {}

-- unique name for namespace,augroup,etc...
M.UNIQUENAME = "TYPIST"
-- Used to match utf8 characters
M.utf8_charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

-- 随机读取文件夹下的文件
function M.GetRandomFile(folder)
	local files = {}
	-- 遍历文件夹下的文件
	for file in io.popen('ls "' .. folder .. '"'):lines() do
		table.insert(files, file)
	end
	-- 生成一个随机索引
	local randomIndex = math.random(1, #files)
	-- 返回随机选择的文件名
	return files[randomIndex]
end

function M.GetWd()
	local scriptPath = debug.getinfo(1, "S").source:sub(2)
	return scriptPath:sub(1, string.len(scriptPath) - string.len("lua/typist/init.lua")) .. "article/"
end

return M
