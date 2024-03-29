local function __tostring(value, indent, vmap)
    local str = ''
    indent = indent or ''
    vmap = vmap or {}
    
    --递归结束条件
    if (type(value) ~= 'table') then
        if (type(value) == 'string') then
            --字符串
            str = string.format("[[%s]]", value)
        else
            --整数
            str = tostring(value)
        end
    else
        if type(vmap) == 'table' then
            if vmap[value] then return '('..tostring(value)..')' end
            vmap[value] = true
        end
        
        local auxTable = {}     --保存元表KEY(非整数)
        local iauxTable = {}    --保存元表value
        local iiauxTable = {}   --保存数组(key为0)
        table.foreach(value, function(i, v)
            if type(i) == 'number' then
                if i == 0 then
                    table.insert(iiauxTable, i)
                else
                    table.insert(iauxTable, i)
                end
            elseif type(i) ~= 'table' then
                table.insert(auxTable, i)
            end
        end)
        table.sort(iauxTable)

        str = str..'{\n'
        local separator = ""
        local entry = "\n"
        local barray = true
        local kk,vv
        table.foreachi (iauxTable, function (i, k)
            if i == k and barray then
                entry = __tostring(value[k], indent..'  \t', vmap)
                str = str..separator..indent..'  \t'..entry
                separator = ", \n"
            else
                barray = false
                table.insert(iiauxTable, k)
            end
        end)
        table.sort(iiauxTable)
        
        table.foreachi (iiauxTable, function (i, fieldName)
            
            kk = tostring(fieldName)
            if type(fieldName) == "number" then 
                kk = '['..kk.."]"
            end 
            entry = kk .. " = " .. __tostring(value[fieldName],indent..'  \t',vmap)
            
            str = str..separator..indent..'  \t'..entry
            separator = ", \n"
        end)
        table.sort(auxTable)
        
        table.foreachi (auxTable, function (i, fieldName)

            kk = tostring(fieldName)
            if type(fieldName) == "number" then 
                kk = '['..kk.."]"
            end 
            vv = value[fieldName]
            entry = kk .. " = " .. __tostring(value[fieldName],indent..'  \t',vmap)

            str = str..separator..indent..'  \t'..entry
            separator = ", \n"
        end)
        
        str = str..'\n'..indent..'}'
    end
    
    return str
end

local ccmlog = function(m,fmt,...)
    local args = {...}
    for k,arg in ipairs(args) do
        if type(arg) == 'table' 
            or type(arg) == 'boolean' 
            or type(arg) == 'function' 
            or type(arg) == 'userdata' then
            args[k] = __tostring(arg)
        end
    end
        
    args[#args+1] = "nil"
    args[#args+1] = "nil"
    args[#args+1] = "nil"
    local str = string.format("[%s]:"..fmt.." %s", m, unpack(args))
    print(str)

    local off = 1
    local p = CCLOGWARN 
    if m == 'error' then 
        p = CCLOGERROR 
    elseif m == 'warn' then 
        p = CCLOGWARN
    end
    while off <= #str do 
        local subStr = string.sub(str, off, off+1024)
        off = off + #subStr
        --p(subStr)
    end
end

return ccmlog