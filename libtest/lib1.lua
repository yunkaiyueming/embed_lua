local person={sex=1} --局部变量，仅本文件可用

--使用：形式 隐藏self
function person:getName()
	return "aaa"..(self.age or 0)
end

function person:getAge()
	ptb:p(self)
	self.age= self.age or 10
	return self.age
end

return person