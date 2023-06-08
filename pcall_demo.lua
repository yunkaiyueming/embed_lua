function run(request)
    local response = {
        data = {},
        ret = 0,        
    }

--error("-98")
   local st=""
   for k,v in pairs(st) do
      print(k,v)
   end
  -- error("-99")
   saios()
   return response
end

status,result = pcall(run, {uid=1})
print(status, type(status))
print(result, type(result))


local datas = {cmd="login", result=result}
local datastr=result
--local datastr = json.encode(datas) or ''
local getzidurl = 'http://gd-gm.leishenhuyu.com/gm/game_extrafunc/sendddgamewarn'
print(getzidurl.."?data="..datastr)
--        http.request(getzidurl.."?data="..datastr)

--for k,v in pairs(result) do
  --print(k,v)
--end
debug.traceback()
