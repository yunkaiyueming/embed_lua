local data = {
	a = 2
}

function isTableEmpty(t)
    return t == nil or next(t) == nil
end

return data