
local socket = require("socket")

for i=1,10000 do
	local start_time = socket.gettime()
	local end_time= socket.gettime()
	local use_time = (end_time - start_time )*1000
	print("used time: "..use_time .."ms \n")
end


