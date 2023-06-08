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


--获取当前星期几
function getWeekTime(now)
	local now = now or os.time()
	local week = getDateByTimeZone(now, "%w")
	print(week)
	if week==0 then --星期天
		week = 7
	end
	return week
end


--获取当前日期
local zone = 0
local loc = now + zone * 3600
local ret = os.date("%Y-%m-%d %H:%M:%S",loc) --返回机器时区的日期
print("机器日期：",ret)
local ret = os.date("%w",loc) --返回机器时区的日期
print("机器星期：",ret)

print("======= *t ======")
local timetable = os.date("*t",loc) --返回机器时区的日期
for i, v in pairs(timetable) do
      print(i, v);
end

print("======= !*t 按格林尼治时间进行格式化 ======")
local utcdate = os.date("!*t",loc)
for i, v in pairs(utcdate) do
      print(i, v);
end

print("======= 国内时区的当前日期 ======")
local utcnow = os.time(utcdate)
local targetnow = utcnow + 3600*targetZone 
local ret = os.date("%Y-%m-%d %H:%M:%S",targetnow)
print(ret)

print("======= 国内时区的当前日期 ======")
print(getDateByTimeZone(os.time()))


print("======= 国内时区的当前星期 ======")
local ret = os.date("%w",targetnow)
print(ret)

print("======= 国内时区的当前星期 ======")
local ret = getWeekTime()
print(ret)


