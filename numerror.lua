function getUserOldZid(uid)
    
    return math.floor(uid/1000000)
    
end


local uid = 100000
print(getUserOldZid(uid))


local uid = "1111111"
print(getUserOldZid(uid))


-- local uid = "aaaa"
-- print(getUserOldZid(uid))



local uid = {a=1,b=2}
print(getUserOldZid(uid))