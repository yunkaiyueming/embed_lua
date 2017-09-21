testMap = {
	"2",
	"v1",
	"v2",
	key3=v3,
	"v4",
}

testMap2 = {
	port = 8080,
	protocols = {
    echo = echo_handler
  },
  default = 22.22,
  test="v3",
}


testMap3 =  {
	host="127.0.0.1",
	port="80",
	user="root",
}

for k,v in pairs(testMap) do 
	print(k,v, type(k), type(v))
end

for k,v in pairs(testMap2) do 
	print(k,v,type(k), type(v))
end

print(testMap3["host"])
print(testMap3["protocols"])
print(testMap3["user"])

print("list no ")
print(testMap3.ddffdsafdsa)