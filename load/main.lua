package.path="/Users/ray/Documents/Lua/embed_lua/?.lua;"


function testRequre()
    require 'load/lib'
    require 'load/lib'
end
-- testRequre()
-- testRequre()

function testDofile()
    dofile('/Users/ray/Documents/Lua/embed_lua/load/lib.lua') --载入文件并执行代码块，对于相同的文件每次都会执行
    dofile('/Users/ray/Documents/Lua/embed_lua/load/lib.lua')
end
-- testDofile()

function testLoadfile() 
    local f = loadfile('/Users/ray/Documents/Lua/embed_lua/load/lib.lua') --载入文件但不执行代码块，对于相同的文件每次都会执行。只是编译代码，然后将编译结果作为一个函数返回
    f()
    f()
end
-- testLoadfile()

function testloadstring()  --即loadstring不涉及词法域，使用全局;
    require('load/lib')
    local f = load("show()")  --loadstring在lua 5.2之后被废弃，使用load代替，当第一个参数是string类型时，即相当于以前的loadstring，传入参数可以动态化
    f()
end
testloadstring()


print("main over....")