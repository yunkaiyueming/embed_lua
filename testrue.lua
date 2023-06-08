local st = 0
if st then
	print(st, not st)
end

local st = "0"
if not st then
	print(st, not st)
end

local st = true
if not st then
	print(st, not st)
end

--nil和false的条件为假
local st = false
if not st then
	print(st, not st)
end

local st = nil
if not st then
	print(st, not st)
end

