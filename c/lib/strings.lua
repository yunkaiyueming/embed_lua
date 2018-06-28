local strings={}

function strings.split(allstr,delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( allstr, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( allstr, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( allstr, delimiter, from  )
  end
  table.insert( result, string.sub( allstr, from  ) )
  return result
end


function strings.trim(s)
  s = (string.gsub(s, "^%s*(.-)%s*$", "%1"))
  return (string.gsub(s, "[^%w]", ""))
end

return strings