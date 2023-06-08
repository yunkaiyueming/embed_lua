local count = 1000000

local list1 = {}
local list2 = {}
local clock = os.clock
local insert = table.insert
local remove = table.remove
local create = coroutine.create
local yield = coroutine.yield
local running = coroutine.running
local resume = coroutine.resume

local function setcb()
    insert(list1, running())
    yield()
end

local function test2()
    setcb()
end


local function test1()
    resume(create(test2))
end

local time1 = clock()--开始
for i = 1, count do
    test1()
end
local time2 = clock()--调用
while true do
    list1, list2 = list2, list1
    for i = 1, #list2 do
        resume(remove(list2))
    end
    if #list1 == 0 then
        break
    end
end
local time3 = clock()--回调完全结束

print(time2 - time1, time3 - time2)
