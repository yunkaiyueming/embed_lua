-- package.path = "E:/Lua/embed_lua/encrypt/?.lua;" .. package.path

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
       	newAc = string.gsub(newAc,'%d','')
		print(newAc)
       	return newAc
    end
end

-- s = string.gsub("TM0NTkMDA1WlRFNVp1c2VyLmxvZ2luTTNOakExWVdFMU5XVTF",2,"")
-- print(s)

-- Unit tests
function test_mixAccessToken()
    -- Test case 1: Valid input
    local ac = "abcdefghij"
    local ts = 123456
    local cmd = "command"
    local expected = "hijklmnopq"
	-- print(mixAccessToken(ac, ts, cmd), expected)
    -- assert(mixAccessToken(ac, ts, cmd) == expected)

    -- Test case 2: Empty input
    ac = ""
    ts = 789012
    cmd = "cmd"
    expected = nil
    assert(mixAccessToken(ac, ts, cmd) == expected)

    -- Test case 3: Input with length less than 11
    ac = "abc"
    ts = 345678
    cmd = "command"
    expected = nil
    assert(mixAccessToken(ac, ts, cmd) == expected)

    -- Add more test cases as needed
    print("All unit tests passed")
end

-- Run unit tests
-- test_mixAccessToken()


local ac = "abcdefghijlmnop"
local ts = os.time()
local cmd = "user.sync"
local expected = "hijklmnopq"
mixAccessToken(ac, ts, cmd)