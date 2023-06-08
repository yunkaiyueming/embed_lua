
local d = 2  --本文件可用
e = {name=a,age=10} --全局变量
w = 1

local _TUISONG = {}

function testd(f)  --函数在全局_G里
	h = 'hhhhh' --全局变量

	print(d)
	print(e)
	print(f)
end