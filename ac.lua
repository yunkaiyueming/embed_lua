function mixAccessToken(ac,ts,cmd)
    if ac and string.len(ac)>0 then
        local s1 = string.sub(ac,1,5)
        local s2 = string.sub(ac,6,10)
        local s3 = string.sub(ac,11,string.len(ac))

        local base64 = require "lib.base64"
        local newAc = base64.Encrypt(s2..ts..s1..cmd..s3)
        if string.len(newAc)>60 then
            newAc=string.sub(newAc,10,59)
        else
            newAc = string.sub(newAc,2,string.len(newAc))
        end
        newAc = string.gsub(newAc,ts%9,"")
        return newAc
    end
end

function getUserOldZid(uid)
    return math.floor(uid/1000000)
end

function createAccessToken(uid,loginTs,isSet)
    uid = uid or 0
    if not loginTs then
        loginTs = getClientTs()
    end

    local oldzid = getUserOldZid(uid)
    --local secretkey = getConfig("baseCfg.SECRETKEY")   
    local secretkey = "111" 

    local baseString = uid .. "_" .. secretkey .. "_" .. loginTs .. "_" ..oldzid
    local sha1 = require "lib.sha1"
    local base64 = require "lib.base64"

    local token = sha1(baseString)
    token = base64.Encrypt(token)
    -- if PLATFORM=="test" or PLATFORM=="cn_wx" then
    --     token = mixAccessToken(token,getClientTs(),getCmd())
    -- end

    return token, loginTs
end

local ac = "222=="
local ts = 1566998027
print(ts%9)

--print(mixAccessToken(ac, ts, "user.login"))

local getClientTs = 1566998027

local ac = createAccessToken(386019695,1566998028)
mixtoken = mixAccessToken(ac,getClientTs,"user.login")


print(ac)
print(mixtoken)



