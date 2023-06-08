--[[@Func :实现闭包
    @Desc : 当一个函数内部嵌套另一个函数定义时，内部的函数体可以访问外部的函数的局部变量，这种特征我们称作词法定界]]
function fuck()
    local i = 0
    return function()
        i = i + 1
        return i
    end
end
c1 = fuck()
print(c1())
print(c1())
print(c1())

c2 = fuck()
print(c2())
print(c2())
print(c2())
