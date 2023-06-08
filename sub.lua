
local now=1574990823 --2019/11/29 9:27:3
local subtime = string.sub(now,5,10)
print(subtime) --640000
local tmptime = math.pow(10,6) - tonumber(subtime)
local newValue = 1*math.pow(10,6) + tmptime
print(newValue)




local now=1575003224 --2019/11/29 12:53:44
local subtime = string.sub(now,5,10)
print(subtime) --640000
local tmptime = math.pow(10,6) - tonumber(subtime)
local newValue = 1*math.pow(10,6) + tmptime
print(newValue)