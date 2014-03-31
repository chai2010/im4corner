all:
	lua im4corner-generator.lua
	t2t main.t2t
	
debug:
	lua im4corner-generator.lua
	GooglePinyinApiConsole.exe im4corner.lua

install:
	lua im4corner-generator.lua
	copy im4corner.lua "C:\Documents and Settings\All Users\Application Data\Google\Google Pinyin 3\Extensions"
