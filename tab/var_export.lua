function dump_var(var, filename)
    local file = io.open(filename, "w")
    if file then
        file:write("return ")
        file:write(var_dump(var))
        file:close()
        print("Variable definition has been written to the file.")
    else
        print("Failed to open file for writing.")
    end
end

function var_dump(var,dept)
    dept = dept or 1
    local depttab = string.rep("    ", dept)

    if type(var) == "table" then
        local str = "{".."\n"
        local first = true
        for k, v in pairs(var) do
            if not first then
                str = str .. ", ".."\n"
            end
            first = false
            str = str ..depttab.. "[" .. var_dump(k,dept+1) .. "]=" .. var_dump(v,dept+1) 
        end
        str = str .. "\n"..string.rep("    ", dept-1).."}"
        return str
    elseif type(var) == "string" then
        return "\"" .. var .. "\""
    else
        return tostring(var)
    end
end

-- 示例使用
local data = {1, 2, 3}  -- 要输出的变量
local filename = "output.lua"  -- 目标文件路径

-- 将变量的文字面定义写入文件
dump_var(data, filename)


-- 示例使用
local passCardCfg = require('./passCardCfg')  -- 要输出的变量
local filename = "./output.lua"  -- 目标文件路径

-- 将变量的文字面定义写入文件
for code, v in ipairs(passCardCfg) do
    dump_var(v, "passCardCfg-"..code..".lua")
end

