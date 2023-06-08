package.path = "/opt/tankserver/embedded/share/lua/5.2/?.lua;" .. package.path
package.cpath = "/opt/tankserver/embedded/lib/lua/5.2/?.so;" .. package.cpath

APP_PATH = debug.getinfo(1).short_src
APP_PATH = string.sub(APP_PATH, 0, -13)
package.path = APP_PATH .. "/?.lua;" .. package.path

local ptb = require "lib.ptb"

function readFile(file1)--创建读取文件函数
    assert(file1,"file1 open failed-文件打开失败")--如果文件不存在，则提示：文件打开失败
    local fileTab = {}--创建一个局部变量表
    local line = file1:read()--读取文件中的单行内容存为另一个变量
    
    while line do--当读取一行内容为真时
        --print("get lin 获取行内容：",line)--打印读取的逐行line的内容        
        table.insert(fileTab,line)--在fileTab表末尾插入读取line内容
        line = file1:read()--读取下一行内容
        --notifyMessage(string.format("%s",line))            
    end    
    return fileTab--内容读取完毕，返回表    
end   

function get_dir_files(dir_path)
    local cmd = "cd "..dir_path.."&& ls"
    local s = io.popen(cmd)
    local fileLists = s:read("*all")
    local big_json = {}
    local start_pos = 0

    local files = {}
    while true do
        local nouse,end_pos,file_name = string.find(fileLists, "([^\n\r]+.lua)", start_pos)
        if not end_pos then
            break
        end

        local file_name = string.sub(file_name, 0, -5)
        print(file_name)
        require("api.activity2s."..file_name)
    	table.insert(files, file_name)
    end

    return files
end

local dir_path = "/opt/tankserver/game/tank-luascripts-xhc/api/activity2s"
get_dir_files(dir_path)

local rows = readFile(dir_path."/springoverviewinfo.lua")
local localVar
for k,v in pairs(localVar) do
    if string.find(activeId,'local') then
        --local name
        localVar[tostring()]
    end

end

