
function rand(m,n)
    setRandSeed()
    math.random(m,n); math.random(m,n); math.random(m,n)
    return math.random(m,n)
end



for t=1,100 do
	tport = tonumber("1500"..math.random(1,9))
	local portPoll = {}
	for i=1,9 do
	    if (tonumber(tport)-15000)~=i then
	        table.insert(portPoll, tonumber(i)+15000)
	    end
	end
	local ridx = math.random(1,#portPoll)
	print(tport,"===>",portPoll[ridx])
end