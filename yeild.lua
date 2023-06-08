
function writeLog(a)
	local b = a+1

	--todo some thing long
	print("sleep writeLoga")

	 -- 让出协程,传递 a1+1 值给resume函数
    coroutine.yield(b)
    -- -- 让出协程,传递 ret+1 值给resume函数
    -- return coroutine.yield(ret+1)
    -- return
end

function main()
	-- 这里创建一个协程
local co = coroutine.create(writeLog)
print("run main1")

-- 执行f 协程,  当前协程会被挂起
print(coroutine.resume(co, 1))
print("run main2")
end

main()