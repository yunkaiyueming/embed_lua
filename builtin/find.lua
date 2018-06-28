function find_file_by2(file_name)
    local nouse,end_pos,value = string.find(file_name, "([a-zA-Z]_2)")

    print(nouse,end_pos,value)
    if not end_pos then return false end
    print("true")
    return true
end

find_file_by2("fdsafCfg_2.lua")
find_file_by2("a3kdf_2fdsafCfg.lua")
find_file_by2("fafa2sdCfg.lua")
