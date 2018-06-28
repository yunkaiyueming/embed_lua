local now = os.time()
print("now st",now)
local todaySt = now-(now%86400)
print(todaySt)

local zone = 8
local todaySt2 = now-((now+zone*3600)%86400)
print(todaySt2)


print(os.date("%c"))
print(os.date("%Y%m%d %H%m%S"))
for k,v in pairs(os.date("*t")) do
	print(k,v)
end


