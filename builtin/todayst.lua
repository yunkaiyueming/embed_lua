function getTodaySt(now,zonenum)  
    local zone = zonenum or 0
    now = now or os.time()
    local ts = now-((now+zone*3600)%86400)
    return ts
end

os = os.time()
print(getTodaySt(os,8))
print(getTodaySt(os,9))