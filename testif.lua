

local PLATFORM = 'jp'

if PLATFORM == "jp" then
        --jpCheckMsgInfo(postdata)
        print(1111)
elseif PLATFORM == "krnew" then
    print(2222)
    krCheckMsgInfo(postdata)
elseif PLATFORM == "test" then
    --testCheckMsgInfo()
    --krCheckMsgInfo(postdata)
    --jpCheckMsgInfo(postdata)
    print(3333)
else
    allCheckMsgInfo(postdata)
    print(4444)
end