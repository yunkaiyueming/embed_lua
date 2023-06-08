package.cpath = "/usr/local/lib/lua/5.3/?.so;" .. package.cpath
package.path = "/Users/ray/Documents/Lua/embed_lua/lib/?.lua;" .. package.path

local ptb = require 'ptb'
local pb =require"pb"

pb.loadfile "model.pb" -- 载入刚才编译的pb文件

-- local data = {
-- 	aa = {"1","2","3"},

-- 	uid=1000495,
-- 	name="张三",
-- 	vipexp=13,
-- 	gold=2131231,
-- 	food=32322,
-- 	mygname="天下帮",
-- 	charm=12313,
-- 	info={wid='1',wname='我妻'}
-- }

local userinfomodel = {
	uid=1000495,
	name="张三",
	vipexp=13,
	gold=2131231,
	food=32322,
	mygname="天下帮",
	charm=12313,
	info={wid='1',wname='我妻'}
}
local response = {
	models={userinfo=pb.encode("UserinfoModel", userinfomodel)},
	uid = 1000405,
	rnum = 22;
	logints=1239003423;
  	data = {pk="1",merank="2"}
}



local bytes =pb.encode("Response", response)
print(bytes)
print(pb.tohex(bytes))

local data2 =pb.decode("Response", bytes)
print(data2)
ptb:p(data2)

local uinfodata = pb.decode("UserinfoModel", data2.models.userinfo)
print(uinfodata)
ptb:p(uinfodata)








