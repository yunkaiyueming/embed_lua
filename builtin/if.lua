function compare(i)
	if i<2 then
		print("i<2")
	elseif i<5 then
		print("5>i>2")
	else
		print("i>5")
	end
end

compare(3)
compare(10)


--所有的逻辑操作符把 false 和 nil 都作为假， 而其它的一切都当作真。
--只有 false 和 nil 为假
if 0 then   --条件为真
	print("sssss")
end

--取反操作 not总是返回 false 或 true 中的一个
print(not 0)  --false



--and 在第一个参数为 false 或 nil 时 返回这第一个参数； 否则，and 返回第二个参数
print(1 and 2) --2 
print(false and 2) --false


-- or 在第一个参数不为 nil 也不为 false 时， 返回这第一个参数，否则返回第二个参数
print(1 or 2) --1
print(nil or 2) --2



test ={10, 20, nil, 40}
print(#test) --4