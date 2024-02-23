
--已知年化收益率，算到期本息和
function calc(base,year,rate)
    for i = 1, year, 1 do
        base = base * (1 + rate)
        print(i,base)
    end
    return base
end
-- local total = calc(100000,20,0.036)
-- print((total/100000)-1)

--已知本息和周期，求年化收益率 a^b=N，a=N^(1/b)
function yearrate(total,year,base)
    local yearrate = (total/base)^(1/year)-1
    print(yearrate)
end

yearrate(172000,20,100000) --0.027487204779392