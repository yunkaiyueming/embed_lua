

function getinfo(cid)
    local big = math.ceil((cid-329)/41)+15
    local middle,small
    if (cid-329)%41==0 then
        middle = 6
        small = 1
    else
        middle = math.ceil((cid-329)%41/8)
        small = (cid-329)%41 - (middle-1)*8
    end        
    local str = cid.."==>("..big.."-"..middle.."-"..small..")"
    print(str)
end


--middle 1-6
--small 1-8

getinfo(330)
getinfo(339)
getinfo(360)
getinfo(452)
getinfo(453)
getinfo(520)
getinfo(1090)
getinfo(1091)
getinfo(2090)
getinfo(3090)
getinfo(3091)
getinfo(3092)
getinfo(3093)
getinfo(3094)