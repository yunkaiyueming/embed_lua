package.path = "./?.lua;" .. package.path

local json=require("lib.json")

local mapdata={name="xhc",age=12}
local data = json.encode(mapdata)
print(data,type(data))

local arrdata={1,2,3,"4"}
local data = json.encode(arrdata)
print(data,type(data))



