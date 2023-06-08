
local liba = {}

function show()
    liba.num = liba.num or 0
    liba.num= liba.num + 1
    print("show 被执行", liba.num)
end

print("requre加载，只加载一次") --载入文件并执行代码块, 对于相同的文件只执行一次,即多次require时,只会执行一次文件的代码块
show()
