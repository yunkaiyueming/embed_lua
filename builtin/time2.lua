local gtcdate = os.date("!*t")
for k,v in pairs(os.date("!*t")) do
	print(k,v)
end

print(os.date("%c"))

local format = '%Y%m%d %H%m%S'
local zone = 8
print(os.date(format,os.time()))
print(os.date(format,os.time(gtcdate)+8*3600))