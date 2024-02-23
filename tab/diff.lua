--检查2个表是否值有差异，有差异返回true， 相同返回false
function compareTables(table1, table2)
    -- 检查两个表的类型是否相同
    if type(table1) ~= type(table2) then
      return true
    end
  
    -- 检查两个表的长度是否相同
    if #table1 ~= #table2 then
      return true
    end
  
    -- 遍历表的键值对，比较每个值是否相等
    for k, v in pairs(table1) do
      local v2 = table2[k]
      if type(v) == "table" and type(v2) == "table" then
        -- 递归比较子表的值是否相等
        if compareTables(v, v2) then
          return true
        end
      elseif v ~= v2 then
        return true
      end
    end
  
    -- 检查表2中是否有额外的键值对
    for k, v in pairs(table2) do
      if table1[k] == nil then
        return true
      end
    end
  
    return false
end

--检查2个表是否值有差异，有差异返回true， 相同返回false
function diff(t1, t2)
    local type = type
    local pairs = pairs

    if t1 == t2 then return false; end
    if tonumber(t1) == tonumber(t2) and tostring(t1) == tostring(t2) then return false; end
    if type(t1) ~= 'table' or type(t2) ~= 'table' then return true; end

    for k, v in pairs(t1) do
        if type(v) == 'table' then
            if diff(v,t2[k]) then return true; end
        else
            if v ~= t2[k] then return true; end
        end
    end

    for k, v in pairs(t2) do
        if not t1[k] then
            return true
        end
        -- if type(v) == 'table' then  -可以去掉的优化代码
        --     if diff(v,t1[k]) then return true; end
        -- else
        --     if v ~= t1[k] then return true; end
        -- end
    end

    return false
end

-- -- 示例使用
-- local table1 = {1, 2, {3, 4}}
-- local table2 = {1, 2, {3, 4}, extra = "extra"}
-- local table3 = {1, 2, {3, 5}}
-- local table4 = {1, 2, {3, 4}}
  
--   print(compareTables(table1, table2))  -- 输出：true
--   print(compareTables(table1, table3))  -- 输出：true
--   print(compareTables(table1, table4))  -- 输出：false
    
local t1 = require('./passCardCfg')
local t2 = require('./passCardCfg2')
print(t1, t2)
local st = os.time()
print(compareTables(t1, t2))
-- print("compareTables run ", os.time()*1000-st*1000)

local st1 = os.time()
print(diff(t1, t2))
-- print("diff run ", os.time()*1000-st1*1000)
