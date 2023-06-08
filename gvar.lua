

local a = 1
local b = {name=a,age=10} --局部变量，本文件内可用
c = {t=1,s=2} --全局变量

require 'gva2'
local ptbs = require 'lib/ptb'

function test1() --在全局G_里
	print(a)
	print(b)
end

print(d)  --nil 其他文件local变量，不可见
print(e)  --table  其他文件global变量，可见

print(_TUISONG) --nil其他文件local变量，不可见

test1()  --本文件可用
testd('fff') --其他文件函数，函数为第一等公民，可见


print('================== _G ===================')
for k,v in pairs(_G) do
	if type(v)~='function' then
		-- if type(v)~="table" then
			print(k, '====>', v, type(v))
		-- else
			--print(k, '====>')
			--ptbs:p(v)
		-- end
	end

	if type(v)=='function' then
		print(k, ':', type(v))
	end
	
end


print('================== string ===================')
ptbs:p(_G['string'])


print('================== table ===================')
ptbs:p(_G['table'])


print('================== coroutine ===================')
ptbs:p(_G['coroutine'])

-- ptbs:p(_G)


