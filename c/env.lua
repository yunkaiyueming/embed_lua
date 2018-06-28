package.path = "./?.lua;"..package.path
local ptb = require("lib.ptb")

function usePtbEnv()
	ptb:p(_ENV)
end


function ptbEvn()
	for k,v in pairs(_ENV) do
		print(k, type(k)," : ",v,type(v))
		if type(v)=="table" then
			for k1,v1 in pairs(v) do
				print("      ",k1, type(k1)," : ",v1,type(v1))
			end
		end
	end
end

function getDebug()
	print(debug.getinfo(1))
	ptb:p(debug.getinfo(1))

	APP_PATH = debug.getinfo(1).short_src
	print(APP_PATH)
	APP_PATH = string.sub(APP_PATH, 0, -5)
	print(APP_PATH)
end

getDebug()