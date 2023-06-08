
--面向对象实现
--table的key可以是任何值(除了nil) table的v可以是任何值(除了nil)
local function create(name ,id )
	local data = {name = name ,id = id}  --data为obj.SetName,obj.GetName,obj.SetId,obj.GetId的Upvalue
	local obj = {}  --把需要隐藏的成员放在一张表里,把该表作为成员函数的upvalue。
	
	function obj.SetName(name)
		data.name = name 
	end
	
	function obj.GetName() 
		return data.name
	end
	
	function obj.SetId(id)
		data.id = id 
	end
		
	function obj.GetId() 
		return data.id
	end
	
	return obj --返回对象，其实是表
end



local t = {}
local m = {a = "and",b = "Li Lei", c = "Han Meimei"}

setmetatable(t,{__index = m})  --表{ __index=m }作为表t的元表

for k,v in pairs(t) do  --穷举表t
	print("有值吗？")
	print(k,"=>",v)
end

print("-------------")
print(t.b, t.a, t.c)


local h = {}
h.__index = m

-- setmetatable(h,{__index = m})  --表{ __index=m }作为表t的元表

for k,v in pairs(h) do  --穷举表t
	print("有值吗？")
	print(k,"=>",v)
end

print("-------------")
print(h.b, h.a, h.c)





local function add(t1,t2)
		--‘#’运算符取表长度
		assert(#t1 == #t2)
		local length = #t1
		for i = 1,length do
			t1[i] = t1[i] + t2[i]
		end
		return t1
	end


	local add = function()
	end

-- table.sort()函数对给定的table进行升序排序. comp是一个可选的参数, 此参数是一个外部函数, 可以用来自定义sort函数的排序标准.

-- 此函数应满足以下条件: 接受两个参数(依次为a, b), 并返回一个布尔型的值, 当a应该排在b前面时, 返回true, 反之返回false.


