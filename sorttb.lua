local resData = {}

for j=1,10 do
for i=1,100 do
	table.insert(resData, i)
end

local tmpTb = {}
table.move(resData, 1, 10, 1, tmpTb)
resData = tmpTb

for k,v in pairs(resData) do
	print(k,v)
end
end


local okdata = {}
if okdata and next(okdata) then
	print(1111)
end


local okdata = {1}
if next(okdata) then
	print(222)
end