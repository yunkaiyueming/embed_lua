for i=10,1,-1 do
    print(i)
end

print("============")
for i=1,10,1 do
	print(i)
end

print("============")
data = {"one", "two", "three"}
for i, v in ipairs(data) do
    print(i, v)
end

print("============")
data = {aa=1,bb=2,cc=3,dd=4}
for i, v in pairs(data) do
    print(i, v)
end


function ptbp (lua_table, indent)
    if type(lua_table) ~= 'table' then 
        print '------------------ptb--------------------\n'
        print (lua_table) 
        print '------------------ptb--------------------\n'
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
                        print(formatting)
                        ptb:p(v, indent + 1)
                        print(szPrefix.."},")
                else
                        local szValue = ""
                        if type(v) == "string" then
                                szValue = string.format("%q", v)
                        else
                                szValue = tostring(v)
                        end
                        if type(k) == "number" then
                        print(szPrefix..szValue..",")
                        else
                        print(formatting..szValue..",")
                        end
                end
        end
end


local data = {a=1,b=2,c=3,d=4,e=5}
ptbp(data)


