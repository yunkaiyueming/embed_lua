local a="aaaa"
if a==0 then
	print("a==0 ok")
else
	print("a==0 false")
end

if a==22 then
	print("a==22 ok")
else
	print("a==22 false")
end

if a=="" then
	print("a=='' ok")
else
	print("a=='' false")
end

if a==true then
	print("a==true ok")
else
	print("a==true false")
end

if a=="stringval" then
	print("a==string ok")
else
	print("a==string false")
end

if a=={name='dfssf'} then
	print("a==table ok")
else
	print("a==table false")
end

b={name=21222,age="ssss"}
if b["namexxxxx"]>="sfsafdsaaaaa" then
	print("a==a[name] ok")
else
	print("a==a[name] false")
end
