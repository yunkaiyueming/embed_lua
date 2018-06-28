
local shopVersionData = {
    {version=1, st=1111},
    {version=2, st=1111},
    {version=3, st=1111},
    {version=4, st=8888888888},
    {version=5, st=9999999999},
}
    
local now = os.time()
for k=#shopVersionData,1,-1 do
    --检查生效数据
    local v = shopVersionData[k]
    if  v.st<now then
        table.remove(shopVersionData,k) 
    end

    if  v.st>now then
        table.remove(shopVersionData,k)
    end

    -- if v.et < now then
    --     table.remove(shopVersionData,k)
    -- end
end

for k=#shopVersionData,1,-1 do
    print(k, shopVersionData[k],version)
end
