function do_something(i)
	print("do something", i)
	error("wrong")
end

function handle_error()
	print("receive error msg")
end

code,ret=pcall(do_something, 5)
print(code, ret)

code,ret=xpcall(do_something,handle_error, 5) --提供错误处理函数
print(code, ret)


local a = 234
local b = 4565
local map_data =  {
	host="127.0.0.1",
	port="80",
	user="root",
}


print(getmetatable(map_data))

print(rawget(getmetatable(map_data) or {}, "__" .. "add"))

-- code,ret=lua_pcall(do_something, 5)
-- print(code, ret)