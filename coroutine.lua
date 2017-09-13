co = coroutine.create(
    function(i)
        print(i);
    end
)
 
coroutine.resume(co, 1)   -- 1
print(coroutine.status(co))  -- dead
 
print("----------")
 
co = coroutine.wrap(
    function(i)
        print(i);
    end
)
 
co(1)
print("----------")
 
co2 = coroutine.create(
    function()
        for i=1,10 do
            if i == 3 then
                print(i,coroutine.status(co2))  --running
                print(i, coroutine.running()) --thread:XXXXXX
            end
            coroutine.yield()
        end
    end
)
 
--重启
coroutine.resume(co2) --1
coroutine.resume(co2) --2
coroutine.resume(co2) --3
 
print(coroutine.status(co2))   -- suspended
print(coroutine.running())
print(coroutine.status(co2))   -- suspended
print("----------")


for i=1,10 do 
    print(i,coroutine.resume(co2))
end