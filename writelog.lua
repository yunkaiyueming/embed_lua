json = require "json.json"

function writeLog(message, fileName)
    if type(message) == 'table' then
        message = (json.encode(message) or '') .. '\r\n'
    else
        message = message .. '\r\n'
    end

    local now   = os.date('%Y-%m-%d %H:%M:%S')
    message     = now ..': '..message
    local f = io.open(fileName, "a+")
    if f then
        f:write(message)
        f:close()
    end
end



writeLog("aa", 'Reglog.txt')
writeLog({a=1,b=2,c=3}, 'Reglog.txt')
