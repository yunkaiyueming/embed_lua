package.path = "/opt/tankserver/embedded/share/lua/5.2/?.lua;" .. package.path
package.cpath = "/opt/tankserver/embedded/lib/lua/5.2/?.so;" .. package.cpath

APP_PATH = debug.getinfo(1).short_src
APP_PATH = string.sub(APP_PATH, 0, -13)
package.path = APP_PATH .. "/?.lua;" .. package.path

require("lib.test")

function foreachTab(data)
   for k,v in pairs(data) do
        -- if type(v)~='function' then
                print(k,v,type(v))
        -- end
   end
end


function demo555555555() 
end


--demo444444444444444(1)


local name = "1231"
age = 12
pwd = 232432

foreachTab(_G)