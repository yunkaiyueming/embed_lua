--os包操作
for k,v in pairs(os) do
	print(k,v)
end

print("-------------")
print(os.clock())
print(os.date())
print(os.time())
os.exit()
print("end")

