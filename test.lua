

local ccmlog = require 'lib/ptable'

--打印测试
reserved =  { [100] = { 300, 400}, 200, { 300, 500}, abc = "abc",[0] = {1,2,3,"abc"}}

ccmlog("d","d",reserved)