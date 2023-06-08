
package.path = "/Users/ray/Documents/Lua/embed_lua/?.lua;" .. package.path
ptb = require 'lib.ptb'  --全局变量


local per = require 'lib1' --局部变量返回表

print(per:getName()) --aaa 0

print(per:getAge()) --10

print(per:getName()) -- aaa 10



print('========= 载入uinfo() ============')

require 'lib2'  --载入uinfo() 全局变量
local mUserinfo = userinfo()
mUserinfo.setName("aaa")
print(mUserinfo.getName()) --aaa

mUserinfo.setAge(20)
print(mUserinfo.getAge()) --20

ptb:p(mUserinfo)



print('========= 载入teach ============')

local teacher = require 'lib3'  --局部变量
teacher.play()
teacher.study()



print('========= 载入lib4 ============')
local poslib = require 'lib4'  --局部变量
local poslibo = poslib.new()
poslibo.aa()
poslibo.bb()

local poslib2 = poslib.poslib2	
print(poslib2()) --把table当做函数使用


print('========= _G ============')
for k,v in pairs(_G) do  --自定义载入了三个全局变量 userinfo,userinfo2,ptb
	print(k,'===>', v)
end
