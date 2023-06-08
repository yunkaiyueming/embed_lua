--使用原表

local poslib = {}
local poslib2 = {}
function aa()
	print('aaa')
end

function bb()
	print('bbb')
end

local methods = {
	aa = aa,
	bb = bb
}

local new = function() --new是一个函数 xx.new()
	local tmp = {__index=methods}
	local s = setmetatable(poslib, tmp) --tmp是poslib的元表，访问poslib中不存在的key时，使用tmp的__index键如果__index包含一个表格，Lua会在表格中查找相应的键。
	ptb:p(s)		
	return s
end


setmetatable(poslib2, {__call= function() print('yyyyy') end }  )

return {
  new = new,
  poslib2 = poslib2
}
