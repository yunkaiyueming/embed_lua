

local mem1 = collectgarbage("count")

require ('./func')
require ('./game2')

getAcCrossKey()

-- local mem2 = collectgarbage("collect")

local mem2 = collectgarbage("count")
local usemem = math.floor(mem2 - mem1)
print("use meme", usemem)

local writeGdata = ""
for k,v in pairs(_G) do
    local tmp = k..", "..type(k)..", "..tostring(v)..","..type(v).."\n"
    writeGdata = writeGdata and writeGdata..tmp or tmp
end
print(writeGdata)