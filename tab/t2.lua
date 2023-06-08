--table的点号调用 和 ：冒号调用 2中方式
local libatk={}
function libatk:getgroup()
    if not self.pkgroup then
        print("get pk group")
        self.pkgroup = {1,2,3}
    end
    return self.pkgroup
end
function libatk:add()
    self:getgroup()
    self.ok="ok"
    print("set ok field")
end
function libatk:sub()
    self:getgroup()
    self:add() --不用传参，隐藏self
    print("get ok file"..self.ok)
end
libatk.sub()


------。点号调用-----
local libatk2={}
function libatk2.add()
    print("ok")
end
function libatk2.sub()
    libatk2.add()  --没有self，要使用self得传，或使用外部变量
end
libatk2.sub()