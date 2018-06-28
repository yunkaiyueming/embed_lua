package.path = "E:/Lua/embed_lua/c/lib/?.lua;"..package.path

local nptb = require("nptb")

ngx.say("<p>say:hello, world lua</p>")
ngx.print("<p>print:hello, world lua</p>")



local arg = ngx.req.get_uri_args()
for k,v in pairs(arg) do
   ngx.say("[GET ] key:", k, " v:", v)
end

ngx.req.read_body() -- 解析 body 参数之前一定要先读取 body
local arg = ngx.req.get_post_args()
for k,v in pairs(arg) do
   ngx.say("[POST] key:", k, " v:", v)
end

local data = ngx.req.get_body_data()
ngx.say("boday ", data)


for k,v in pairs(ngx.var) do
	ngx.say(k,type(v))
end

ngx.say("<br/>")

local headers = ngx.req.get_headers()
nptb:p(headers)


nptb:p({name="xxx",age=123,info={age=123,tew=11,te=544,item={aa={dfasffdsaf,12313,12321,345,76,1231}}}})
