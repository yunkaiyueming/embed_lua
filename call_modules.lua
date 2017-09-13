-- test_module.lua 文件
-- module 模块为上文提到到 module.lua
local te_module=require("everyday/modules")
 
print(te_module.constant)
 
te_module.func3()
te_module:func4()
te_module.func4()