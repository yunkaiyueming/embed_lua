local nptb={}

function nptb:p (lua_table, indent)
    if type(lua_table) ~= 'table' then
        ngx.print('<br/>------------------ nptb-start --------------------<br/>') 
        ngx.print (lua_table) 
        ngx.print('<br/>------------------ nptb-end ----------------------<br/>')
        return
    end

    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
                k = string.format("%q", k)
        end

        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end

        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix

        if type(v) == "table" then
            ngx.print(formatting)
            nptb:p(v, indent + 1)
            ngx.print(szPrefix.."},")
        else

            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end

            if type(k) == "number" then
                ngx.print(szPrefix..szValue..",")
            else
                ngx.print(formatting..szValue..",")
            end
        end
    end
end

return nptb