local M = {}

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

return M
