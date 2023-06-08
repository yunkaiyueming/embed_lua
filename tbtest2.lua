local ptb = require 'lib/ptb'

local data = {
	wifeinfo={
		exp=263425,
		glamour=1500,
		intimacy=607,
		mother=2001
	},

	adultinfo={
		aa=263425,
		bb=1500,
		cc=607,
		dd=2001
	},

	child={
		ee=263425,
		ff=1500,
		gg=607,
		hh=2001
	},
}

print("=========")
ptb:p(data.wifeinfo)

local tmpinfo = data.wifeinfo
data.wifeinfo.mother=101

print("=========")
ptb:p(data.wifeinfo)

print("===引用跟着变=====")
ptb:p(tmpinfo)


tmpinfo.exp=1
print("=========")
ptb:p(tmpinfo)

print("======引用跟着变======")
ptb:p(data.wifeinfo)

local mother = data.wifeinfo.mother
mother=20
print("=========")
ptb:p(mother)

print("===不变======")
ptb:p(data.wifeinfo)

print("============")
tmpinfo = {aa=1,bb=2,cc=3}
ptb:p(tmpinfo)
print("===整体替换不变======")
ptb:p(data.wifeinfo)
print("============")
ptb:p(data)
