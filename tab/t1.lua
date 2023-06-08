
--给tab表增加函数的2中方式
local userinfo={}
userinfo.setname = function(name) --方式1
    userinfo.name=name
end
userinfo.getname = function()
    return userinfo.name
end
function userinfo.setage(age) --方式2
    userinfo.age=age
end
print("111")
userinfo.setname("zs1")
userinfo.setage(10)
print(userinfo.name, userinfo.age)
