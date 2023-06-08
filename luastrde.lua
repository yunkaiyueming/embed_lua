 local pattern = "^A-Za-z0-9%-%._~"
 local pt = string.gsub("中","[" .. pattern .. "]",function(c) return string.format("%%%02X",string.byte(c)) end)
print(pt)
