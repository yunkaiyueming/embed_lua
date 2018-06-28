--单行注释
--[[
lua中的table是数组+映射
]]

a = 10
b = "hello".."world"
d = nil --删除一个全局变量，只需要将变量赋值为nil。
print(a, b,d)

print(type("Hello world"))      --> string
print(type(10.4*3))             --> number
print(type(print))              --> function
print(type(true))               --> boolean
print(type({1,"hello"}))
print(#b)

local tbl = {"apple", "pear", "orange", "grape"}
for key, val in pairs(tbl) do
    print(key,val)
end
print(#tbl)


function factorial(n)
	if n==0 then
		return 1
	else
		return n*factorial(n-1)
	end
end

print(factorial(5))
newFuncName = factorial
print(newFuncName(5))


a = 5               -- 全局变量
local b = 5         -- 局部变量

function joke()
    c = 5           -- 全局变量
    local d = 6     -- 局部变量
end

joke()
print(c,d)          --> 5 nil


a, b = 10, 2*10
print(a,b)
a,b = b,a
print(a,b)


testTable={
	"v1",
	"v2",
}
testTable[3] = "v3"
testTable.k4="v4"
testTable["k5"] = "v5"
for k,v in pairs(testTable) do 
	print(k,v)
end

for k,v in ipairs(testTable) do 
	print(k,v)
end

table.sort(testTable)
for k,v in pairs(testTable) do 
	print(k,v)
end

--table元素连接
print(table.concat(testTable,", "))

--多返回值
s, e = string.find("www.runoob.com", "runoob") 
print(s,e)

--可变参数
function average(...)
   result = 0
   local arg={...}
   for i,v in ipairs(arg) do
      result = result + v
   end
   print("总共传入 " .. #arg .. " 个数")
   return result/#arg
end
print("平均值为",average(10,5,3,4,5,6))