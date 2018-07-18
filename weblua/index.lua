package.path = "E:/Lua/embed_lua/c/lib/?.lua;"..package.path

package.path = "D:/openresty-1.13.6.2-win64/lualib/resty/?.lua;"..package.path


local nptb = require("nptb")
nptb:p(ngx.args)
nptb:p(ngx.var.content_type)
nptb:p(ngx.content_type)

-- 内部调用
-- res = ngx.location.capture("/weblua/user/getname")
-- nptb:p(res)


function getReVal(i) 
	return tonumber(i)+5
end

local ok, t = pcall(getReVal, 1)
if not ok then
	ngx.say("cal failed")
else
	ngx.say(t,"call success")
end

ngx.say(getReVal(1))

nptb:p(ngx.ctx)


local redis = require 'redis'
local host = "127.0.0.1"
local port = 6379

local red = redis:new()
local ok, err = red:connect(host,port)
ngx.say(ok,err)


red:set("qhx",1000)
local data = red:get("qhx")

ngx.say("=======")
ngx.say(data)
ngx.say("=======")


local mysql = require 'mysql'
local db, err = mysql:new()
local ok = db:connect({host = "127.0.0.1",
                    port = 3306,
                    database = "bi_admin",
                    user = "root",
                    password = "123456",
                    charset = "utf8",
                    max_packet_size = 1024 * 1024,})
ngx.say(ok)

local data = db:query("show tables;")
nptb:p(data)