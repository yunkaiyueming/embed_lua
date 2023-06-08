g_condition = 0

-- 检查函数
function check_condition()
    if g_condition == 0 then
        print('Check Failed.')
        return false
    else
        print('Check OK.')
        return true
    end
    return false
end

-- 我们的具体某个操作operate，分成三步走，每一步打印信息提示
function operate()
    if ( not check_condition() ) then
        return
    end
    print('operating...1')
    local par = coroutine.yield("op1")
    print("yield",par)
 
    if ( not check_condition() ) then
        return
    end
    print('operating...2')
    par = coroutine.yield("op2")
    print("yield2",par)
 
    if ( not check_condition() ) then
        return
    end
    print('operating...3')
    return 'finished'
end
 
-- 以下模拟主逻辑用于测试
co = coroutine.create(operate)
 
print('Test 1: Normal procedure')
g_condition = 1

count = 1
while true do
    count = count+1
    status, value = coroutine.resume(co, count)
    print('coroutine:',status, value)
    if not status or value=='finished' then
        break
    end
end


-- print('---------------------------')
-- print('Test 2: The environment changes in the procedure ')
-- g_condition = 1
-- co = coroutine.create(operate)
-- g_condition = 1
-- status, value = coroutine.resume(co, 'hahaha')
-- print('coroutine:',status, value)
-- g_condition = 0
-- status, value = coroutine.resume(co, 'hahaha')
-- print('coroutine:',status, value)
 
-- status, value = coroutine.resume(co, 'hahaha')
-- print('coroutine:',status, value)



