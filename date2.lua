local now = os.time()
local targetZone = 8

--获取当前日期
function getDateByTimeZone(now,format)
	local now = now or os.time()
	local format = format or "%Y-%m-%d %H:%M:%S"

	local utcdate = os.date("!*t", now)
	local utcnow = os.time(utcdate)
	local targetnow = utcnow+3600*targetZone

	return os.date(format, targetnow)
end

--获取0点的时间戳
function getTodaySt(now)
	local now = now or os.time()
	local todayst = now - ((now+targetZone*3600)%86400)
	return todayst
end

--获取当前星期几 使用通用格式时%w用0表示星期天。
function getWeekTime(now)
	local now = now or os.time()
	local week = getDateByTimeZone(now, "%w")
	if tostring(week)=="0" then --星期天
		week = 7
	end
	return tonumber(week)
end

--获取周一0点的时间戳
function getWeekStTime(now)
	local now = now or os.time()
	local week = getWeekTime(now)
	return  getTodaySt(now)-(week-1)*86400
end


local now = os.time()
print("星期：", getWeekTime(now))

local now = 1604160000
print("星期：", getWeekTime(now))

local now = 1604073600
print("星期：", getWeekTime(now))

local now = 1603987200
print("星期：", getWeekTime(now))

print("星期一时间戳：", getWeekStTime(os.time()))

