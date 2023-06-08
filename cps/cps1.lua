local count = 1000000

local list1 = {}
local list2 = {}
local clock = os.clock
local insert = table.insert
local remove = table.remove

local function setcb(fn)
    insert(list1, fn)
end

local function test1()
    setcb(function()
        
    end)
end

local time1 = clock()--开始
for i = 1, count do
    test1()
end
local time2 = clock()--调用
while true do
    list1, list2 = list2, list1
    for i = 1, #list2 do
        remove(list2)()
    end
    if #list1 == 0 then
        break
    end
end
local time3 = clock()--回调完全结束

print(time2 - time1, time3 - time2)
