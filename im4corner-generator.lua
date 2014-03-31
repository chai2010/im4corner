-- encoding: UTF-8
-------------------------------------------------------------------------------
-- im4corner.lua脚本生成器
--
-- 作者：ChaiShushan<chaishushan@gmail.com>
-- 项目：http://chaishushan.googlecode.com/hg/im4corner
--       https://bitbucket.org/chai2010/im4corner
-- 版权：New BSD License
--
-------------------------------------------------------------------------------

-- 初始化四角号码表
im4c_table = {}
im4c_table_size = 0
for i = 0000, 9999 do
	im4c_table[i] = {}
end

-- 设置四角号码表
-- udapte(2011.07.18)
-- http://vimim-data.googlecode.com/svn-history/trunk/data/vimim.4corner.txt
io.input("vimim.4corner.txt")
-- 从文件读入号码表
for line in io.lines() do
	local words = nil
	-- 每行以空格拆分
	for w in string.gmatch(line, "%S+") do
		if words == nil then
			if #w ~= 4 then break end
			local index = assert(tonumber(w))
			words = im4c_table[index]
		else
			table.insert(words, w)
			im4c_table_size = (im4c_table_size+1)
		end
	end
end

-------------------------------------------------------------------------------

-- 初始化汉字拼音表
pinyin_table = {}
pinyin_table_size = 0

-- 从文件读入拼音表
function readPinyinTable(filename)
	io.input(tostring(filename))

	for line in io.lines() do
		local pinyin = nil
		-- 每行以空格拆分
		for w in string.gmatch(line, "%S+") do
			if pinyin == nil then
				pinyin = w
			else
				-- 有多音字
				if pinyin_table[w] == nil then
					pinyin_table[w] = { pinyin }
					pinyin_table_size = (pinyin_table_size+1)
				else
					table.insert(pinyin_table[w], pinyin)
					pinyin_table_size = (pinyin_table_size+1)
				end
			end
		end
	end
end

-- 设置汉字拼音表
-- http://vimim-data.googlecode.com/svn-history/r128/trunk/data/pinyin1234.txt
-- http://vimim-data.googlecode.com/svn-history/r128/trunk/data/vimim.pinyin.txt
-- 目前还有4千多个汉字没有拼音

readPinyinTable("pinyin1234.txt")
--readPinyinTable("vimim.pinyin.txt")

---[[
-- 去掉重复的拼音
-- 规则： 一个拼音是另一个拼音的前缀
-- bug: 呵 a, a1, a2, a3, a4, he1, ke1

for key in pairs(pinyin_table) do
	local chs = pinyin_table[key]
	local len = #chs

	i = 1
	while i <= len do
		local is_prefix = false
		for j = 1,len do
			if j ~= i then
				local a, b = string.find(tostring(chs[j]), tostring(chs[i]))
				if a == 1 then
					is_prefix = true
				end
			end
		end
		-- 删除重复的拼音
		if is_prefix then
			table.remove(chs, i)
			i = (i-1)
			len = (len-1)
		end
		i = (i+1)
	end
end
--]]

-------------------------------------------------------------------------------
-- 生成im4corner.lua脚本

-- 设置输出文件
io.output("im4corner.lua")

-- 输出扩展脚本（基于im4corner-base.lua）
io.input("im4corner-base.lua")
io.write(io.read("*all"))

-- 输出四角号码表
io.write(string.format("-- 汉字四角号码表(共%d个)\n\n", im4c_table_size))
io.write([[
do
	local a = im4c_table
]])
for i = 0000, 9999 do
	-- 空表不输出
	local chs = im4c_table[i]
	if chs and #chs > 0 then
		io.write(string.format("\ta[%04d]={", (i)))
		for j = 1, #chs do
			if j < #chs then
				io.write("\"" .. chs[j] .. "\",")
			else
				io.write("\"" .. chs[j] .. "\"")
			end
			if (j%10) == 0 and j < #chs then
				io.write("\n\t\t")
			end
		end
		io.write("}\n")
	end
end
io.write([[
end

-------------------------------------------------------------------------------
]])

-- 输出汉字拼音表

-- 只输出四角号码中有的字符
local pinyin_output_size = 0
for i = 0000, 9999 do
	-- 空表不输出
	local chs = im4c_table[i]
	if chs and #chs > 0 then
		for j = 1, #chs do
			if pinyin_table[chs[j]] then
				pinyin_output_size = (pinyin_output_size+1)
			end
		end
	end
end

-- 有效拼音数目
io.write(string.format("-- 汉字拼音表共%d个汉字，", pinyin_output_size))
io.write(string.format("缺少拼音汉字%d个(见pinyin-lost.txt)\n\n",
	(im4c_table_size-pinyin_output_size)))
io.write([[
do
	local b = pinyin_table
]])

-- 保存缺少拼音的字
local pinyin_lost_table = {}

-- 输出有效拼音
for i = 0000, 9999 do
	-- 空表不输出
	local chs = im4c_table[i]
	if chs and #chs > 0 then
		for j = 1, #chs do
			if pinyin_table[chs[j]] then
				-- pinyin_table["天"] = "天[1080, tian1]"
				local str_pinyin = string.format("%s [%04d", tostring(chs[j]), i)
				-- 连接拼音为一个字符串
				for k = 1, #pinyin_table[chs[j]] do
					str_pinyin = (str_pinyin .. ", " .. pinyin_table[chs[j]][k])
				end
				str_pinyin = (str_pinyin .. "]")

				io.write(string.format("\tb[\"%s\"]=\"%s\"\n",
					tostring(chs[j]), str_pinyin))
			else
				-- 缺少拼音
				local str_pinyin = string.format("%s [%04d]", tostring(chs[j]), i)
				io.write(string.format("\tb[\"%s\"]=\"%s\"\n", tostring(chs[j]), str_pinyin))
				
				table.insert(pinyin_lost_table, tostring(chs[j]))
			end
		end
	end
end
io.write([[
end

-------------------------------------------------------------------------------

]])

-- 初始化通配符查找表
local im4c_ext_table = {}

-- 函数需要在基本表初始化之后执行
function generateIm4cExtTable()
	for i = 0000, 9999 do
		-- 只处理有汉字的类型
		if im4c_table[i] then
			-- 解析每个角码编号
			local x1, x2, x3, x4 = string.byte(string.format("%04d", i), 1, 4)
			-- 生成通配符位置组合
			local keys = {
				-- 1个通配符
				string.format("%s%c%c%c", "?", x2 , x3 , x4 ),
				string.format("%c%s%c%c", x1 , "?", x3 , x4 ),
				string.format("%c%c%s%c", x1 , x2 , "?", x4 ),
				string.format("%c%c%c%s", x1 , x2 , x3 , "?"),
				-- 2个通配符
				string.format("%s%s%c%c", "?", "?", x3 , x4 ),
				string.format("%s%c%s%c", "?", x2 , "?", x4 ),
				string.format("%s%c%c%s", "?", x2 , x3 , "?"),
				string.format("%c%s%s%c", x1 , "?", "?", x4 ),
				string.format("%c%s%c%s", x1 , "?", x3 , "?"),
				string.format("%c%c%s%s", x1 , x2 , "?", "?"),
			}
			-- 保存汉字到对应的通配符选择中
			for j = 1, #(im4c_table[i]) do
				for k = 1, #keys do
					if im4c_ext_table[keys[k]] then
						table.insert(im4c_ext_table[keys[k]], im4c_table[i][j])	
					else
						im4c_ext_table[keys[k]] = { im4c_table[i][j] }
					end
				end
			end
		end
	end
end

-- 生成通配符表格
-- 文件太长，脚本无法加载
--[[
generateIm4cExtTable()

-- 输出表格
io.write("-- 初始化通配符表\n")
for key in pairs(im4c_ext_table) do
	-- 空表不输出
	local chs = im4c_ext_table[key]
	if chs and #chs > 0 then
		io.write(string.format("im4c_ext_table[\"%s\"] = { ", (key)))
		for j = 1, #chs do
			io.write("\"" .. chs[j] .. "\", ")
			if (j%40) == 0 and j < #chs then
				io.write("\n\t")
			end
		end
		io.write("}\n")
	end
end
io.write("\n")
--]]

io.write("-- 初始化通配符表\n")
io.write("generateIm4cExtTable()\n")

io.write([[

-------------------------------------------------------------------------------

]])

--[-[
-- 输出缺少的函数表
io.output("pinyin-lost.txt")

io.write(string.format("-- 缺少拼音的汉字(共%d个)\n", #pinyin_lost_table))
io.write("-- 每行40个\n")

for i = 1, #pinyin_lost_table do
	if ((i-1)%40) == 0 then
		io.write("\n-- ")
	end
	io.write(tostring(pinyin_lost_table[i]), " ")
end
io.write("\n\n\n")
--]]

-------------------------------------------------------------------------------


