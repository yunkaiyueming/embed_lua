
local data = os.date("*t",1522771200)
for k,v in pairs(data) do 
	print(k,v)
end

-- 2018-04-04 14:54:57 
local formateDate = data["year"].."-"..data["month"].."-"..data["day"].." "..data["hour"]..":"..data["min"]..":"..data["sec"]
print(formateDate)

2018-4-4 0:0:0