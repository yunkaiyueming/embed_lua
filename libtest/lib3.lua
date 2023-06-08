local teacher = {}

--tb的属性为函数
function teacher.play()
	print('play.....')
end

--tb的属性=匿名函数
teacher.study = function ()
	print('study.....')
end

return teacher