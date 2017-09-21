local data = {
	name = 11,
	pwd =22,
	xx = "sss",
}

print(data.name)
print(data["name"])

index = "xx"
print(data.index) --访问key为index
print(data[index]) --访问key为xx