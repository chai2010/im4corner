-- encoding: UTF-8
-------------------------------------------------------------------------------
-- 谷歌拼音四角号码输入扩展
--
-- 作者：ChaiShushan<chaishushan@gmail.com>
-- 项目：https://bitbucket.org/chai2010/im4corner
--       http://chai2010.bitbucket.org/im4corner.html
--       http://chaishushan.googlecode.com/hg/im4corner
-- 版权：New BSD License
-- 版本：1.0.3.201101010
--
-- 简介：四角号码输入法，例如isj1080 -> 兲
--
-------------------------------------------------------------------------------

-- 四角号码表
local im4c_table = {}
for i = 0000, 9999 do
	im4c_table[i] = {}
end
-- 汉字拼音表
local pinyin_table = {}

-- 通配符用的查找表
local im4c_ext_table = {}

-------------------------------------------------------------------------------

-- 是否合法的参数
function checkInput(args)
	-- 有效参数是2-5个
	if #args < 1 or #args > 5 then
		return false
	end

	-- 参数必须是[0-9|?]字符组成
	for i = 1, 4 do
		if i > #args then break end
		local ch = string.byte(args, i)
		if ch < string.byte("0") or ch > string.byte("9") then
			if ch ~= string.byte("?") then return false end
		end
	end
	-- 如果有第5个参数，必须是"?"
	if #args == 5 then
		local ch = string.byte(args, 5)
		if ch ~= string.byte("?") then return false end
	end

	-- 合法参数
	return true
end

-- 是否有完整角码
function hasComplete4Code(numbers)
	return #numbers >= 4
		and string.byte(numbers, 1) >= 48 and string.byte(numbers, 1) <= 57
		and string.byte(numbers, 2) >= 48 and string.byte(numbers, 2) <= 57
		and string.byte(numbers, 3) >= 48 and string.byte(numbers, 3) <= 57
		and string.byte(numbers, 4) >= 48 and string.byte(numbers, 4) <= 57
end

-- 读取参数
-- return id, show_info, show_help
function readArgs(args)
	-- ID信息（数字/字符串）
	-- 如果是完整角码，则转为数字
	if hasComplete4Code(args) then
		id = assert(tonumber(string.sub(args, 1, 4)))
	else
		-- 还有非数字的类型
		id = string.sub(args, 1, 4)
		-- 不足4字节，用“?”补充
		for i = #args+1, 4 do
			id = (id .. "?")
		end
	end

	-- 是否显示详细信息
	local show_info = false
	if #args > 4 and string.byte(args, 5) == string.byte("?") then
		show_info = true
	end

	-- 只有"?"字符时，显示帮助
	local show_help = args
	for i = 1, #args do
		if string.byte(args, i) ~= string.byte("?") then
			show_help = nil
		end
	end
    
	return id, show_info, show_help
end

-------------------------------------------------------------------------------

-- 查询四角号码表
function SearchTableBy4C(args)
	-- 提示中显示帮助
	local ret = "-- 有效格式：1080;108;108?;?080;10;10??;?0?0;... --"
	if not checkInput(args) then return ret end

	-- 读取参数
	local id, show_info, show_help = readArgs(args)
	
	-- 显示口诀
	if show_help then
		if #show_help == 1 then
			return {
				"王云五 发明四角号码，",
				"高梦旦 发明“附角”。",
				"1926年《四角号码检字法》出版，",
				"蔡元培、胡适等为序。",
			}
		elseif #show_help == 2 then
			return {
				"胡适创作歌诀：",
				"一横二垂三点捺，",
				"点下带横变零头，",
				"叉四插五方块六，",
				"七角八八小是九。",
			}
		elseif #show_help == 3 then
			return {
				"黄维荣修改版：",
				"横一垂二三点捺，",
				"叉四插五方框六；",
				"七角八八九是小，",
				"点下有横变零头。",
			}
		elseif #show_help == 4 then
			return {
				"扩展作者：",
				"ChaiShushan",
				"<chaishushan@gmail.com>",
			}
		else
			return {
				"http://chai2010.bitbucket.org/im4corner.html",
			}
		end
		
	end
	
	-- 可能查找失败（通配符）
	local words = nil
	if type(id) == "number" then
		words = im4c_table[id]
	else
		-- 间接引用查找
		words = im4c_ext_table[id]
	end
	if not words then return {} end

	-- 显示详细信息
	if show_info then
		local info_table = { }
		-- 通配符查找可能失败
		for i = 1, #words do
			-- 使用拼音信息
			local pinyin = pinyin_table[tostring(words[i])]
			if pinyin then
				table.insert(info_table, pinyin)
			else
				table.insert(info_table, tostring(words[i]))
			end
		end
		return info_table
	else
		return words
	end

	-- 不会执行
	return ret
end

-- 注册命令
-- 和base.lua的“时间”命令冲突, 需要屏蔽base.lua的sj命令
-- ime.register_command("sj", "GetTime", "输入时间", "alpha", "输入可选时间，例如12:34")
ime.register_command("sj", "SearchTableBy4C", "四角号码", "alpha", "四角号码输入法，例如isj1080[?] -> 兲")

-------------------------------------------------------------------------------

-- 生成通配符查找表
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

-------------------------------------------------------------------------------

