package.cpath = "/usr/local/lib/lua/5.3/?.so;" .. package.cpath
package.path = "/Users/ray/Documents/Lua/embed_lua/lib/?.lua;" .. package.path

local ptb = require 'ptb'
local pb =require"pb"

pb.loadfile "book.pb" -- 载入刚才编译的pb文件

local data = {
 	name ="ilse",
 	age =18,
 	contacts = {
 		{ name ="alice", phonenumber =12312341234 },
 		{ name ="bob", phonenumber =45645674567 }
 	}
}

local bytes =pb.encode("Person", data)
print(bytes)
print(pb.tohex(bytes))

local data2 =pb.decode("Person", bytes)
print(data2)
ptb:p(data2)