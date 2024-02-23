-- -- 检测内存泄漏
-- function detect_memory_leak()
--     local initial_memory = collectgarbage("count")  -- 初始内存使用量

--     local function dump_memory()
--         local current_memory = collectgarbage("count")
--         local diff_memory = current_memory - initial_memory

--         print("Current Memory: " .. current_memory .. "KB, Diff: " .. diff_memory .. "KB")

--         -- 输出当前的对象数量
--         local object_count = 0
--         for k, v in pairs(_G) do
--             object_count = object_count + 1
--         end
--         print("Object Count: " .. object_count)

--         -- 输出对象的引用信息
--         local function print_references(object, indent)
--             indent = indent or 0
--             local indent_str = string.rep("  ", indent)

--             if type(object) == "table" then
--                 print(indent_str .. tostring(object))
--                 for k, v in pairs(object) do
--                     print_references(v, indent + 1)
--                 end
--             else
--                 if type(object)~="function" then
--                     print(indent_str .. tostring(object))
--                 end
--             end
--         end

--         print("Object References:")
--         print_references(_G)

--         return diff_memory
--     end

--     -- 在这里执行您的游戏逻辑和代码
--     local passCardCfg = require('./passCardCfg')  -- 要输出的变量
--     local codeCfg = passCardCfg[2]

--     -- 检测内存使用情况
--     dump_memory()
-- end

-- -- 运行内存泄漏检测
-- detect_memory_leak()

local _info = function(var)
    print(var)
end

local findedObjMap = nil   
function _G.findObject(obj, findDest)  
    if findDest == nil then  
        return false  
    end  
    if findedObjMap[findDest] ~= nil then  
        return false  
    end  
    findedObjMap[findDest] = true  
  
    local destType = type(findDest)  
    if destType == "table" then  
        if findDest == _G.CMemoryDebug then  
            return false  
        end  
        for key, value in pairs(findDest) do  
            if key == obj or value == obj then  
                _info("Finded Object")  
                return true  
            end  
            if findObject(obj, key) == true then  
                _info("table key")  
                return true  
            end  
            if findObject(obj, value) == true then  
                _info("key:["..tostring(key).."]")  
                return true  
            end  
        end  
    elseif destType == "function" then  
        local uvIndex = 1  
        while true do  
            local name, value = debug.getupvalue(findDest, uvIndex)  
            if name == nil then  
                break  
            end  
            if findObject(obj, value) == true then  
                _info("upvalue name:["..tostring(name).."]")  
                return true  
            end  
            uvIndex = uvIndex + 1  
        end  
    end  
    return false  
end  

function _G.findObjectInGlobal(obj)  
    findedObjMap = {}  
    setmetatable(findedObjMap, {__mode = "k"})  
    _G.findObject(obj, _G)  
end

APP_PATH=1
PAL=2
local jobstadsfa=1
function add()
end

local passCardCfg = require('./passCardCfg')  -- 要输出的变量
local codeCfg = passCardCfg[2]

print(_G.findObjectInGlobal(passCardCfg))

local builtinFunc = function()
    return {
        tostring	,
        ipairs	,
        pcall	,
        dofile	,
        rawget	,
        next	,
        type	,
        tonumber	,
        select	,
        load	,
        rawlen	,
        error	,
        setmetatable	,
        rawset	,
        assert	,
        xpcall	,
        collectgarbage	,
        loadfile	,
        require	,
        pairs	,
        rawequal	,
        print	,
        getmetatable	,
    }
end

local inBulitFunc = function(findv)
    for i, v in ipairs(builtinFunc()) do
        if findv==v then
            return true
        end
    end
    return false
end

for k, v in pairs(_G) do
    if not inBulitFunc(k)  then
        print('"'..k..'"',",")
    end
end

