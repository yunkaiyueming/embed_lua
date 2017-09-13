local function add(a,b)
   assert(type(a) == "number", "a 不是一个数字")
   error("a is not number")
   assert(type(b) == "number", "b 不是一个数字")
   return a+b
end
add(10)