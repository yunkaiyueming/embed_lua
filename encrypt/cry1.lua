package.path = "E:/Lua/embed_lua/encrypt/?.lua;" .. package.path

local base64 = require('base64')

function mixAccessToken(ac,ts,cmd)
    if ac and string.len(ac)>0 then
        local s1 = string.sub(ac,1,5)
        local s2 = string.sub(ac,6,10)
        local s3 = string.sub(ac,11,string.len(ac))
       	local newAc = base64.Encrypt(s2..ts..s1..cmd..s3)
       	if string.len(newAc)>60 then
       		newAc=string.sub(newAc,10,59)
       	else
       		newAc = string.sub(newAc,2,string.len(newAc))
       	end
       	print(newAc,ts%9)
       	newAc = string.gsub(newAc,ts%9,"")
       	return newAc
    end
end


s = string.gsub("TM0NTkMDA1WlRFNVp1c2VyLmxvZ2luTTNOakExWVdFMU5XVTF",2,"")
print(s)