--setmetable 元表使用，主要用来做继承和共享代码
local person = {}
function setname(name)
    person.name=name
end

function getname()
    return person.name
end

function setage(age)
    person.age = age
end

function getage()
    return person.age
end

local Person= {}
Person.new = function()
    return setmetatable({}, 
    {
        __index={  --__index包含表和函数，
        setname=setname,
        getname=getname,
        setage=setage,
        getage=getage,

        foor=3,
        },

        __newindex={}, --__newindex可以包含表和函数，当给表中不存在的元素赋值时，索引和值会设置到指定的表__newindex里

        __tostring = function(a) print("a table data tostring: "..a.getname()..a.getage().." it is person tostring") end,

        __metatable = "not your busines",

        __call = function(t, a,b,c) return a+b+c end --允许表当函数使用，常用来在表和它里面的函数之间做转发
    }
)
end

for k, v in pairs(Person) do
    print(k,v)
end

print(111, getmetatable(Person.new()))

local p1 = Person.new()
p1.setname("zs111")
p1.setage(10)
for k, v in pairs(Person) do
    print(1,k,v)
end
print(p1.getname())
print(p1.getage())
print("p1.foor=",p1.foor)
print("p1.foor2=",p1.foor2)

local p2 = Person.new()
p2.setname("zs222")
p2.setage(20)
for k, v in pairs(p1) do
    print(1,k,v)
end
print(p2.getname())
print(p2.getage())

print(p1.getname())
print(p1.getage())

print(p1==p2)

print(p1)

print(p1(1,2,3))
-- setmetatable(p1, {})