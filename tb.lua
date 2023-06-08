local data1={"a","b","c","d","e","f","g"}
for k,v in ipairs(data1) do
	print(k,v)
end

print('===================')
local data1={a=1,b=2,c=3,d=4,e=5,f=6,g=7}
for k,v in pairs(data1) do
	print(k,v)
end

print('===================')
local data1={["a"]=1,["b"]=2,["c"]=3,["d"]=4,["e"]=5,["f"]=6,["g"]=7}
for k,v in pairs(data1) do
	print(k,v)
end