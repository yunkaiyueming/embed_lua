function getChatEncrypt( st1,uid1,zid1 )
    st1 = tostring(st1)
    uid1 = tonumber(uid1)
    zid1 = tonumber(zid1)
    local b1=math.floor(math.floor(tonumber(string.sub(st1,8))*4.1415))%3
    local b2=math.floor(tonumber(string.sub(st1,7))%7)
    local b3=math.floor(tonumber(string.sub(st1,6))%6)
    local b4=math.floor((uid1*3.1415)%9)
    local b5=math.floor(uid1%3)
    local b6=math.floor(uid1%4)
    local b7=math.floor((zid1*5.57))
    local b8=math.floor((zid1*7.78))
    local b9=math.floor((zid1*8.35))
    return ((b4*b1*b7+st1*3)..(b5*b2*b8+st1*4)..(5*b3*b6*b9))
end

local ts = 1578846823
local uid1=4000155
local zid=1
print(getChatEncrypt(ts, uid1, zid))

local ts = 1564502600
local uid1=4000156
local zid=1
print(getChatEncrypt(ts, uid1, zid))

local ts = 1564502500
local uid1=4000157
local zid=1
print(getChatEncrypt(ts, uid1, zid))
