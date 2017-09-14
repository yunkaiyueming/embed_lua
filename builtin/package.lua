
-- for k,v in pairs(package.loaded) do
-- 	print(k,'===>')
-- 	for i,t in pairs(v) do
-- 		print(i,t)
-- 	end
-- end

print(package.path)
print(package.cpath)
print(package.config,type(package.config))

for k,v in pairs(package.searchers) do
	print(k,v)
end