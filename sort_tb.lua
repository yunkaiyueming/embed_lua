local network = {"Tom","Jam","Mary"}
--升序
table.sort(network)
--降序
table.sort(network,function(a,b) return a > b end)

for k,v in ipairs(network) do
	print(k, v)
end



local network = {
	{name = "Tom" ,IP = "210.26.30.34"},
	{name = "Mary" ,IP = "210.26.30.23"},
	{name = "Jam" ,IP = "210.26.30.12"},
	{name = "hey" ,IP = "210.26.30.30"},
}

table.sort(network,function(a,b) return (a.IP < b.IP) end) --aip<b.IP时 a在前面，升序


for k,v in ipairs(network) do
	print(k, v.name, v.IP)
end
