
json = require "json.json"

local data = { 1, 2, 3, { x = 10 } }
local str = json.encode(data)
print(str)

local data = { "a", "b", "c", {d=10, e=20}}
local str = json.encode(data)
print(str)

local data = {aa=1,bb=2,cc=3,dd=4,ee=5,ff=6}
local str = json.encode(data)
print(str)


local data = {
    id = 1,
    name = "zhangsan",
    cname = "张三",
    age = nil,
    is_male = false,
    hobby = {"film", "music", "read"}
}
local str = json.encode(data)
print(str)

local data = json.decode(str)
print(data)