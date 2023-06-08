function run(num)
    num = num + 1000

    error(-99) --可以在 Lua 代码中调用 error 函数来显式地抛出一个错
    return num
end


function run2(num)
    num = num + 1000

    error(-99) --可以在 Lua 代码中调用 error 函数来显式地抛出一个错
    return num
end

function errorLog(msg)
    print("writelog..."..msg)
end


--lua错误处理
function main()
    local status,num = pcall(run, "aaaaa") -- 第一个返回值是状态码（一个布尔量）， 当没有错误时，其为真
    print(status,num)

    if status then
        print("run success")
        print(num)
    else
        print("run failed")
        print(num)
        print(debug.traceback())
    end


    local status,num = xpcall(run2,errorLog, "aaaaa") --xpcall自定义错误处理函数
    print(status,num)

    if status then
        print("run success")
        print(num)
    else
        print("run failed")
        print(num)
        --print(debug.traceback())
    end
end

main()