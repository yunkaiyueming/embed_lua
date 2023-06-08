
--用function的方式模拟类

function userinfo()
	local umodel = {
		name = "",
		age = 0,
	}

	umodel.sex=1 --也是其属性

	function umodel.setName(v)
		umodel.name=v
	end

	function umodel.getName()
		return umodel.name
	end

	umodel.setAge = function(v)
		umodel.age = v
	end

	umodel.getAge = function()
		return umodel.age
	end

	return umodel
end


function userinfo2()
	local self = {
		name = "",
		age = 0,
	}

	self.sex=1

	function self.setName(v)
		self.name=v
	end

	function self.getName()
		return self.name
	end

	return self
end
