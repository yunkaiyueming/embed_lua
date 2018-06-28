local map3data = { 
	["17001000"]={    ----3K
    -- ["1"]={creatorid=1001,title="新手福利",content="亲爱的大人：\n   希望您能够喜欢这款游戏，在这里您将步步高升，权倾朝野，娶妻纳妾，坐拥天下美人，走上人生巅峰！\n\n为了让各位大人能够更快的加官进爵，臣妾在这边给大人准备了一份<font color=0x21eb39>《豪华大礼》</font>哦！\n\n关注微信公众号：<font color=0xfedb38>极品大官人</font> 即可领取。\n\n礼包内容 ：<font color=0x00ffff>魏征*1、</font><font color=0x21eb39>属性丸*1、银两*30万、士兵*30万</font>\n希望在臣妾的陪伴下大人能够玩的开心！",touch="1_1_500"},
        ["2"]={creatorid=1002,title="新官上任",content="xinshoufuli1",touch="1_1_500"},
        ["3"]={creatorid=1003,title="新手福利",content="xinshoufuli2",touch="1_1_500"},
    },
}

function printTab(data)
	if data then
		for k,v in pairs(data) do
			if type(v)=="table" then
				print(k,"\n")
				printTab(v)
			else
				print(k,v)
			end
		end
	end
end

printTab(map3data)
printTab(map3data["17001000"])



{"3":["bi_17"]}

