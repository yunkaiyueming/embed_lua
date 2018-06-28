package.path = "E:/Lua/embed_lua/c/lib/?.lua;"..package.path

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
	ngx.say(t)
end

