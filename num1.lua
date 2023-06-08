local num = 1;
if tonumber(num) then
	print(111)
end

local num
if num and tonumber(num)>0 then
	print(111)
end

local num
if tostring(num) then
	print(1111, type(tostring(num)), tostring(num) )
end

local num = "sfdiodfs"
print(type(tonumber(num)))
if tonumber(num) and tonumber(num)>0 then
	print(111)
end