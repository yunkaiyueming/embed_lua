local newProductor

function productor()
     local i = 0
     while true do
          i = i + 1
          send(i)     -- 将生产的物品发送给消费者
     end
end

function consumer()
     while true do
          local i = receive()     -- 从生产者那里得到物品
          print(i)
     end
end

function receive()
     local status, value = coroutine.resume(newProductor, 2) --是否重启成功，返回值
     print(status,value)
     return value
end

function send(x)
     if x<10 then
          print(x, coroutine.yield(x))     -- x表示需要发送的值，值返回以后，就挂起该协同程序, 返回值=resume的参数值
     end
end

-- 启动程序
newProductor = coroutine.create(productor)
consumer()