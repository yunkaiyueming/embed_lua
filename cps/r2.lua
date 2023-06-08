function foo(a)
    print("foo", a)
    -- a[1] = 3
     os.execute('sleep 2')
    return coroutine.yield(2 * a)
end

co = coroutine.create(function ( a, b )
    -- print("co-body_01", a, b)
    -- local r = foo(a + 1)
    -- print("co-body_02", r)
    -- local r, s = coroutine.yield(a + b, a - b)
    -- print("co-body_03", r, s)
    -- return b, "end"

    print("start",a,b)
    local x,y = coroutine.yield(a + b, a - b) 
    print("yield1",x,y)

    local x2,y2 = coroutine.yield(a + b, a - b)
    print("yield2",x2,y2)

    coroutine.yield("aa","bb","cc") //yield的参数是resume的返回值

    print("end")
end)

print("---main---", coroutine.resume(co, 1, 10))  --接下来传入 coroutine.resume 的参数将被传进 coroutine 的主函数
print("---main---", coroutine.resume(co, "x1", "y1"))
print("---main---", coroutine.resume(co, "x2", "y2")) //resume 的参数是 yield的返回值

