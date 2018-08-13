
-- local t1= os.date("!*t", os.time()) --格林尼治时间
-- print(t1.hour)

-- local t2= os.date("*t", os.time()) -- --格林尼治时间
-- print(t2.hour)


local gtcnow = os.date("!*t", os.time()) --格林尼治日期时间
-- for k,v in pairs(gtcnow) do
-- 	print(k,v)
-- end


local gtc = os.time(gtcnow) --日期获取时间戳
print(gtc)
-- local loc = gtc + 8 * 3600
local getdate = os.date('%Y-%m-%d %H:%M:%S', gtc)
print(getdate)


local gettime = os.time({year=2018,month=7,day=24,hour=0,min=0,sec=0})
print(gettime)
local getdate = os.date('%Y-%m-%d %H:%M:%S', gettime)
print(getdate)


print(os.time({year=2018,month=7,day=24,hour=0,min=0,sec=0}))

-- local gettime = os.time({year=2018,month=7,day=24,hour=0,min=0,sec=0}) --北京时间
-- print(gettime)


-- local gettime = os.time()
-- print(gettime)