data = {
	host = "baidu.com",
	name = "aaaa",
	pwd=  "bb",
	1,
	2,
	3,
	4,
}

print(#data)

numData = {1,2,3,4,5,6,7}
print(table.concat(data,";")) --1;2;3;4

table.insert(numData,4,9)
for k,v in pairs(numData) do
	print(k,v)
end

print('--------move------------')
numData2 = {8,9,10}
table.move(numData,1,4,3,numData2)
for k,v in pairs(numData2) do
	print(k,v)
end