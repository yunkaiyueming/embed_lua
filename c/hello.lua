package.path = "./?.lua;" .. package.path

function hello()
	print("hello world lua")
end
hello()

require("api.login")
login()

for k,v in pairs(_ENV) do
	if type(v)=="function" then
		print(k,v,type(v))
	end
end

