print(package.path)

local da = require('embed_lua/builtin/data')
print(da.a)
da.a = 3
print(da.a)

local db = require('embed_lua/builtin/data')
print(db.a)