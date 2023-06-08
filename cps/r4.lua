
function task1(co)
    print("task1...")
    coroutine.resume(co)
end

function task2(co)
    os.execute('sleep 3')
    print("task2...")
    coroutine.resume(co)
end

function task3(co)
    print("task3...")
    coroutine.resume(co)
end

function task4(co)
    print("task4...")
    coroutine.resume(co)
end


-- function all()
--     task1(task2(task3()))
--     task4()
-- end

-- all()

-- task3()
-- task2()
-- task1()
-- task4()

function async(handler,co)
    --local runn = coroutine.running()
    handler(co)
    coroutine.yield()
end

function f()
    local co = coroutine.create(
        function() print("hi coroutine start") end
    )

    async(task1, co)
    async(task2, co)
    async(task3, co)
    async(task4, co)
    coroutine.resume(co)
end

f()
