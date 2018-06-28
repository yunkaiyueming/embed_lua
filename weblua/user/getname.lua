package.path = "E:/Lua/embed_lua/c/lib/?.lua;"..package.path
package.cpath = "E:/Lua/embed_lua/c/extent/?.dll;"..package.cpath

local json=require("json")
local nptb=require("nptb")
local sha1=require("sha1")
local strings = require("strings")

ngx.say("getname.lua")
local req = ngx.req.get_uri_args()
local age = req.age
local name = req.name
local data=json.encode({age=age,name=name})
ngx.say(data)
nptb:p(data)

local sh1str = sha1.sha1("abcdefgh")
ngx.say(sh1str)

local spArr=strings.split("a_b_c", "%_")
nptb:p(spArr)

function getRedisDemo()
	local redis = require("redis")
    local config = {host='127.0.0.1',port='6379'}
    
    local rediscon = redis.connect({host = config['host'], port = config['port']})

    local data=rediscon:get("test")
    nptb:p(data)
end


local base64 = require("base64")
local encodeData = base64.Encrypt("itsgoodlucky")
nptb:p(encodeData)

local uncodeData = base64.Decrypt(encodeData)
nptb:p(uncodeData)