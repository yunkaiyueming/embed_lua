a = 1
b = 1.2
c = "string"
local d = {
	name="aaaa"
}

print(_ENV,type(_ENV))

for k,v in pairs(_ENV) do
	print(k,type(k), v,type(v))
end

print(_VERSION)

print("============================================")
for k,v in pairs(_G) do
	print(k,v)
end

print("============================================")
print(LUA_CPATH)
print(LUA_PATH)
