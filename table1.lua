local tb1 = {"aa","bb","cc","dd","ee","ff"}
for k,v in ipairs(tb1) do
	print(k,v)
end

print("=====================")

for k,v in pairs(tb1) do
	print(k,v)
end
print("=====================")


local tb2 = {aa=1,bb=2,cc=3,dd=4,ee=5,ff=6}
for k,v in pairs(tb2) do
	print(k,v)
end

print("=====================")
local tb2 = {aa=1,bb=2,cc=3,dd=4,ee=5,ff=6}
for k,v in ipairs(tb2) do
	print(k,v)
end

