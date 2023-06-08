function trimAll(s)
    if s then
        return (string.gsub(s, "%s*(.-)%s*", "%1"))
    end
end

local str = 'bbbsssbbbb\r'
print(str)
local str = trimAll(str)
print(str)
print("111")