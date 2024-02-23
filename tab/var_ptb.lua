
function var_dump(var,dept)
    dept = dept or 1
    local depttab = string.rep("    ", dept)

    if type(var) == "table" then
        print("{".."\n")
        local first = true
        for k, v in pairs(var) do
            if not first then
                print(", ".."\n")
            end
            first = false
            print(depttab.. "[")
            var_dump(k,dept+1)
            print("]=")
            var_dump(v,dept+1) 
            -- str = str ..depttab.. "[" .. var_dump(k,dept+1) .. "]=" .. var_dump(v,dept+1) 
        end
        print("\n"..string.rep("    ", dept-1).."}")
    elseif type(var) == "string" then
        print("\"" .. var .. "\"")
    else
        print(tostring(var))
    end
end


local passCardCfg = require('./passCardCfg')  -- 要输出的变量
var_dump(passCardCfg[2])


