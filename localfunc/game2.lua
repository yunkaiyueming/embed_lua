--[[
游戏内相关逻辑方法 跟游戏逻辑密切相关
]]
function userGetUid(username)
    local db = getDbo()
    local result
    if type(username) == 'number' then
        result = db:getRow("select uid from userinfo where uid=:uname", { uname = username })
    else
        result = db:getRow("select uid from userinfo where username=:uname", { uname = username })
    end
    if type(result) == 'table' and result['uid'] then
        return tonumber(result['uid'])
    end
    return 0
end

function userGetUidByName(name)
    local db = getDbo()
    local result = db:getRow("select uid from userinfo where name=:name", { name = name })
    if type(result) == 'table' and result['uid'] then
        return tonumber(result['uid'])
    end
    return 0
end

-- function userCreateUid()
--     local maxUidKey = "z" .. _GAMEVARS['zoneid'] .. "_maxuid"
--     local redis = getRedis()
--     local uid = tonumber(redis:incr(maxUidKey)) or 0

--     local minuid = _GAMEVARS['zoneid'] * 10000000

--     if uid > minuid then
--         return uid
--     else
--         local db = getDbo()
--         local result = db:getRow("select max(uid) as uid from userinfo")
--         if result then
--             local maxUid = tonumber(result.uid) or 0
--             if maxUid < minuid then
--                 maxUid = minuid
--             end
--             redis:set(maxUidKey, maxUid)
--             uid = tonumber(redis:incr(maxUidKey))
--             return uid
--         end
--     end
--     return 0
-- end

function userLogin(uid)
    local db = getDbo()
    local result = db:getRow("select uid from userinfo where uid=:uid", { uid = uid })

    if result then
        return tonumber(result.uid) or -1
    else
        return 0
    end
end

function getModelInfo(modelname, uid)
    if modelname and uid then
        -- local returnmodelinfo = {}
        local uobjs = getUserObjs(uid, true)
        local tmpModel = uobjs.getModel(modelname)
        local data = tmpModel.toArray(true)
        return data
    end
end

function sendMsgModel(returnmodel, uid)
    local tuisong = { ret = 0, msg = "Success", cmd = "admin.update", data = { model = {} } }
    if next(returnmodel) then
        local uobjs = getUserObjs(uid, true)
        if uobjs then
            for k, v in pairs(returnmodel) do
                local pos = string.split(v, "%.")
                --                ptb:p(pos)
                local tmpModel = uobjs.getModel(pos[1])
                local data = tmpModel.toArray(true)
                for i = 2, #pos do
                    data = data[pos[i]]
                end
                table.insert(tuisong.data.model, { key = v, value = data })
            end
        end
    end
    pushMsg(uid, tuisong)
end

--获取奖励倍数字符串
function getRateRewards(rewards, rate)
    local newRewards = ""
    local rewards_table = string.split(rewards, "%|")
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        local newRewardNum = rewardNum * rate
        if newRewards ~= "" then
            newRewards = newRewards .. "|" .. rewardType .. "_" .. rewardId .. "_" .. newRewardNum
        else
            newRewards = rewardType .. "_" .. rewardId .. "_" .. newRewardNum
        end
    end
    return newRewards
end

--增加奖励物品
function funAddRewards(uid, rewards, targetId, extra)
    --大类定义
    --1 钻石/元宝  2 黄金/银两  3 粮食  4 士兵 5 经验/政绩  6 道具 7 门客属性 
    --8门客 9红颜亲密度 10红颜 11称号 12红颜魅力 13 红颜经验值 14 门客书籍经验  
    --15  门客技能经验 16增加红颜服饰 17人望 18-人望废弃- 19门客皮肤 20同舟共济-令旗(仅前端) 21翠玉生辉-积分道具(仅前端) 22圣诞节-积分道具(仅前端) 25双11-代金券(仅前端)
    --26  前端使用夺帝号角  27 在放灯活动中被使用  28-99 使用时需与前端沟通
    --31 红颜表情  32 门客觉醒  33宴会积分 
    --36门客历练值  37繁荣度(封地) 38税金(封地)  39石料(封地)  
    --40奖励为聊天表情  51增加马粮  52增加战马  53增加经营NPC  54增加新经营建筑皮肤 55传记奖励
    --56 玩家背景 57聊天字色
    --60红颜学识 61民望  62案卷经验 63办案经验 64镇民 65升堂次数
    --66文玩 67文玩经验 68文玩探险按时间计算的指定奖励 69 功勋
    --100英雄护符 101帮会经验(仅前端)  102个人贡献  103红颜才艺值 104红颜共浴场景 105府邸场景
    --106 聊天头像   107 聊天气泡
    --108 统一活动中间产物（不进背包，之后类型统一，以id区分）  109 帮会财富 
    --110 战马PVP 商店代币 111资质书类型id增加等级
    --120 活动中限时的道具
    --112 升级单门客资质书等级 113升级所有门客资质书等级 114拜访商店代币  115战马资历
    --201大富翁-积分道具(仅前端)
    --301骑士团箱子 302骑士团金币  303骑士团钻石  304骑士团主角经验 305骑士团宝箱 306骑士团仕途经验 351骑士团战马 352骑士团称号
    --401 雕像
    --1000阶段门客条件
    --1006-1024（前端用）2001擂台攻击次数
    --3001特殊资质书经验
    local uid = tonumber(uid)
    if uid <= 0 or not rewards then
        return false
    end
    local load_model = {}
    local newrewards
    local rewards_table = string.split(rewards, "%|")
    local finalFlag = true
    local warnFlag = true
    local uobjs = getUserObjs(uid)
    for k, v in ipairs(rewards_table) do
        local addFlag = false
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        
        local realadd = v --真实添加的奖励
        local changeReward
        if rewardType == 1 then
            -- 奖励为钻石/元宝
            local mUserinfo = uobjs.getModel('userinfo')
            addFlag = mUserinfo.addGem(rewardNum)
            regReturnModel({"userinfo"})
        elseif rewardType == 2 then
            -- 奖励为黄金/银两
            local mUserinfo = uobjs.getModel('userinfo')
            addFlag = mUserinfo.addGold(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 3 then
            -- 奖励为粮食
            local mUserinfo = uobjs.getModel('userinfo')
            addFlag = mUserinfo.addFood(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 4 then
            -- 奖励为士兵
            local mUserinfo = uobjs.getModel('userinfo')
            addFlag = mUserinfo.addSoldier(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 5 then
            -- 奖励为政绩
            local mUserinfo = uobjs.getModel('userinfo')
            addFlag = mUserinfo.addExp(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 6 then
            --奖励为道具
            local mItem = uobjs.getModel('item')
            addFlag = mItem.addItem(rewardId, rewardNum)
            regReturnModel({"item"})
        elseif rewardType==7 then
            --增加门客属性
            local mServant = uobjs.getModel('servant')
            rewardId = tonumber(rewardId)
            if rewardId<=5 then
                --放到门客模块里做
                -- if rewardId == 5 then
                --     rewardId = rand(1,4)
                -- end
                -- realadd = "7_"..rewardId.."_"..rewardNum
                addFlag,realadd = mServant.addItemAttr(targetId,rewardId,rewardNum)
                regReturnModel({"servant"})
            end
        elseif rewardType==8 then
             --增加门客
            local mServant = uobjs.getModel('servant')
            local servantId = tostring(rewardId)
            --重复门客替换
            addFlag,changeReward = mServant.addServant(servantId)
            regReturnModel({"servant"})
        elseif rewardType==9 then
            --增加红颜亲密度
            local mWife = uobjs.getModel('wife')
            local wifeId = tostring(targetId)
            addFlag = mWife.addIntimacy(wifeId,rewardNum)
            regReturnModel({"wife"})
        elseif rewardType==10 then
            --增加红颜
            local mWife = uobjs.getModel('wife')
            local wifeId = tostring(rewardId)
            --重复红颜替换
            addFlag,changeReward = mWife.addWife(wifeId)
            regReturnModel({"wife","servant"})
        elseif rewardType == 11 then
            --奖励为称号
            local mItem = uobjs.getModel('item')
            local st = tonumber(targetId) --指定称号开始时间
            addFlag,changeReward = mItem.addTitle(rewardId,st)
            regReturnModel({"item"})
        elseif rewardType == 12 then
            --增加红颜魅力
            local mWife = uobjs.getModel('wife')
            local wifeId = tostring(targetId)
            addFlag = mWife.addGlamour(wifeId, rewardNum)
            regReturnModel({"wife"})
        elseif rewardType == 13 then
            --增加红颜技能经验
            local mWife = uobjs.getModel('wife')
            local wifeId = tostring(targetId)
            addFlag = mWife.addExp(wifeId, rewardNum)
            regReturnModel({"wife"})
        elseif rewardType == 14 then
             --增加门客书籍经验
            local mServant = uobjs.getModel('servant')
            local servantId = tostring(targetId)
            addFlag = mServant.addAbilityExp(servantId,rewardNum)
            regReturnModel({"servant"})
            warnFlag = false
        elseif rewardType == 15 then
             --增加门客技能经验
            local mServant = uobjs.getModel('servant')
            local servantId = tostring(targetId)
            addFlag = mServant.addSkillExp(servantId,rewardNum)
            regReturnModel({"servant"})
        elseif rewardType == 16 then
            --增加红颜服饰
            local mWifeskin = uobjs.getModel('wifeskin')
            local figure = tonumber(targetId)
            addFlag,changeReward = mWifeskin.addWifeskin(rewardId,figure)
            regReturnModel({"wifeskin"})
        elseif rewardType == 17 then
            --增加人望
            local mPrestige = uobjs.getModel('prestige')
            addFlag=mPrestige.addPem(rewardNum)
            regReturnModel({"prestige"})
        elseif rewardType == 18 then
            --增加人望废弃--
        elseif rewardType == 19 then
            --增加门客服饰
            local abilityId = extra and tonumber(extra['abilityId'])
            local mServant = uobjs.getModel('servant')
            addFlag,changeReward = mServant.addServantskin(rewardId, abilityId)
            regReturnModel({"servant"})
        elseif rewardType == 31 then
            --增加红颜表情
            local mWife = uobjs.getModel('wife')
            local emojiid = tostring(rewardId)
            addFlag,changeReward = mWife.getWifeEmoji(emojiid)
            regReturnModel({"wife"})
        elseif rewardType == 32 then
            --增加红颜表情
            local mServant = uobjs.getModel('servant')
            addFlag,changeReward = mServant.addServantAwake(rewardId)
            regReturnModel({"servant"})
        elseif rewardType == 33 then
            --增加宴会积分
            local mDinner = uobjs.getModel('dinner')
            addFlag= mDinner.addDinnerScore(rewardNum)
            regReturnModel({"dinner"})
        elseif rewardType == 36 then
            --增加门客历练值
            local mServant = uobjs.getModel('servant')
            local servantId = tostring(targetId)
            addFlag = mServant.addTrainExp(servantId,rewardNum)
            regReturnModel({"servant"})
        elseif rewardType == 37 then
            -- 增加繁荣度
            local mFief = uobjs.getModel('fief')
            addFlag = mFief.addProsperity(rewardNum)
            regReturnModel({ "fief" })
        elseif rewardType == 38 then
            -- 奖励为税金
            local mFief = uobjs.getModel('fief')
            addFlag = mFief.addResource(1,rewardNum)
            regReturnModel({ "fief" })
        elseif rewardType == 39 then
            -- 奖励为石料
            local mFief = uobjs.getModel('fief')
            addFlag = mFief.addResource(2,rewardNum)
            regReturnModel({ "fief" })
        elseif rewardType == 40 then
            --奖励为聊天表情
            local mItem = uobjs.getModel('item')
            addFlag,changeReward = mItem.addChatEmoji(rewardId)
            regReturnModel({"item"})
        elseif rewardType == 51 then
            --增加马粮
            local mWarHores = uobjs.getModel('warhorse')
            addFlag = mWarHores.addHorseFood(rewardNum)
        elseif rewardType == 52 then
            --增加战马
            local mWarHores = uobjs.getModel('warhorse')
            addFlag,changeReward = mWarHores.addWarHorse(rewardId)
            regReturnModel({"warhorse"})
        elseif rewardType == 53 then
            --增加经营NPC
            local mManagenpc = uobjs.getModel('managenpc')
            addFlag,changeReward = mManagenpc.addManageNpc(rewardId)
            regReturnModel({"managenpc"})
        elseif rewardType == 54 then
            --增加新经营建筑皮肤
            local mManagenew = uobjs.getModel('managenew')
            addFlag,changeReward = mManagenew.addBuildScene(rewardId)
            regReturnModel({"managenew"})
        elseif rewardType == 55 then
            --传记奖励
            local mBiography = uobjs.getModel('biography')
            addFlag = mBiography.addBiography(rewardId)
            regReturnModel({ "biography" })
        elseif rewardType == 56 then
            --奖励为背景
            local mItem = uobjs.getModel('item')
            local st = tonumber(targetId) --指定背景开始时间
            addFlag,changeReward = mItem.addBackground(rewardId,st)
            regReturnModel({"item"})
        elseif rewardType == 57 then
            --奖励为聊天字色
            local mItem = uobjs.getModel('item')
            addFlag,changeReward = mItem.addChatColor(rewardId)
            regReturnModel({"item"})
        elseif rewardType == 60 then
            --红颜学识
            local mWife = uobjs.getModel('wife')
            local callWifeId = tostring(targetId)
            addFlag = mWife.addKnowExp(callWifeId,rewardNum)
            regReturnModel({ "yamen"})
        elseif rewardType == 61 then
            --民望奖励
            local mYamen = uobjs.getModel('yamen')
            addFlag = mYamen.addPrestige(rewardNum)
            regReturnModel({ "yamen"})
        elseif rewardType == 62 then
            --案卷经验奖励
            local mYamen = uobjs.getModel('yamen')
            addFlag = mYamen.addFileExp(rewardId,rewardNum)
            regReturnModel({ "yamen"})
        elseif rewardType == 63 then
            --办案经验奖励
            local mYamen = uobjs.getModel('yamen')
            addFlag = mYamen.addExp(rewardNum)
            regReturnModel({ "yamen"})
        elseif rewardType == 64 then
            --镇民奖励
            local mYamen = uobjs.getModel('yamen')
            addFlag = mYamen.addPeople(rewardId)
            regReturnModel({ "yamen"})
        elseif rewardType == 65 then
            --升堂次数奖励
            local mYamen = uobjs.getModel('yamen')
            addFlag = mYamen.addCourtNum(rewardNum)
            regReturnModel({ "yamen"})
            warnFlag = false
        elseif rewardType == 66 then
            -- 解锁文玩
            local mCurios = uobjs.getModel('curios')
            addFlag,changeReward = mCurios.addCurios(rewardId)
            regReturnModel({ "curios" })
        elseif rewardType == 67 then
            -- 文玩经验
            local mCurios = uobjs.getModel('curios')
            addFlag = mCurios.addAbilityExp(tostring(targetId),rewardNum)
            regReturnModel({ "curios" })
        elseif rewardType == 68 then
            -- 文玩挂机奖励
            local mCuriosadventure = uobjs.getModel('curiosadventure')
            addFlag,changeReward = mCuriosadventure.useAfkItem(tostring(rewardId),rewardNum)
            regReturnModel({ "curiosadventure" })
        elseif rewardType == 69 then
            -- 功勋奖励
            local mOneManWar = uobjs.getModel('onemanwar')
            addFlag = mOneManWar.addScore(rewardNum)
            regReturnModel({ "onemanwar" })
        elseif rewardType == 100 then
            --增加英雄护符
            local mAmulet = uobjs.getModel('amulet')
            addFlag = mAmulet.addAmulet(rewardId, rewardNum)
            regReturnModel({"amulet"})
        elseif rewardType == 103 then
            --增加红颜才艺值
            local mWife = uobjs.getModel('wife')
            local wifeId = tostring(targetId)
            addFlag = mWife.addArtistry(wifeId, rewardNum)
            regReturnModel({"wife"})
        elseif rewardType == 102 then
            --增加个人贡献
            local mUserinfo = uobjs.getModel('userinfo')
            local allianceId = mUserinfo.mygid
            if allianceId<=0 then
                --我已经被退出军团
                addFlag = false
            else
                local mMyalliance = uobjs.getModel('myalliance')
                addFlag = mMyalliance.addTctv(rewardNum)
            end
        elseif rewardType == 104 then
            --增加红颜共浴场景
            local mWife = uobjs.getModel('wife')
            local sceneId = tostring(rewardId)
            addFlag,changeReward = mWife.addWifeSceneBySceneId(sceneId)
            regReturnModel({"wife"})
        elseif rewardType == 105 then
            --增加府邸场景
            local mOtherinfo = uobjs.getModel('otherinfo')
            local sceneId = tostring(rewardId)
            addFlag,changeReward = mOtherinfo.addSceneById(sceneId)
            regReturnModel({"otherinfo"})
        elseif rewardType == 106 then
            --奖励为聊天头像
            local mItem = uobjs.getModel('item')
            addFlag,changeReward = mItem.addChatHead(rewardId)
            regReturnModel({"item"})
        elseif rewardType == 107 then
            --奖励为聊天气泡
            local mItem = uobjs.getModel('item')
            addFlag,changeReward = mItem.addChatFrame(rewardId)
            regReturnModel({"item"})
        elseif rewardType == 108 then
            --道具
            local mActivity = uobjs.getModel('activity')
            local acInfo = mActivity.info[targetId]
            addFlag = false
            if acInfo then
                local activitylib = require "lib/activitylib"
                local newItemInfo = activitylib:addAcItem(acInfo.item, v, rewardNum, uid)
                if newItemInfo then
                    addFlag = true
                    acInfo.item = newItemInfo
                    regReturnModel({"activity"})
                end
            end
        elseif rewardType == 110 then
            --战马PVP 商店代币
            local mWarhorserace = uobjs.getModel('warhorserace')
            addFlag = mWarhorserace.addItem(rewardId,rewardNum)
            regReturnModel({"warhorserace"})
        elseif rewardType == 112 then
            -- 升级单门客资质书等级
            local mServant = uobjs.getModel('servant')
            local servantId = tostring(targetId)
            local atype = tonumber(rewardId)
            local uplv = tonumber(rewardNum)
            local upRetData = {}
            upRetData[servantId] = {}
            addFlag,upRetData[servantId] = mServant.upServantBookAbility(servantId,atype,nil,uplv)
            load_model.change = load_model.change or {}
            table.insert(load_model.change,upRetData)
            regReturnModel({"servant"})
        elseif rewardType == 113 then
            --升级所有门客资质书等级
            local extraData = extra or nil
            local atype = tonumber(rewardId)
            local uplv = tonumber(rewardNum)
            local mServant = uobjs.getModel('servant')
            local upRetData = {}
            addFlag,upRetData = mServant.upAllServantBookAbilityLv(atype,uplv,extraData)

            load_model.change = load_model.change or {}
            table.insert(load_model.change,upRetData)
            regReturnModel({"servant"})
        elseif rewardType == 114 then
            --拜访 商店代币
            local mVisit = uobjs.getModel('visit')
            addFlag = mVisit.addItem(rewardId,rewardNum)
            regReturnModel({"visit"})
        elseif rewardType == 115 then
            --战马 资历
            local horseId = tostring(targetId)
            local mWarhorse = uobjs.getModel('warhorse')
            addFlag = mWarhorse.addHorseSeniority(horseId,rewardNum)
            regReturnModel({"warhorse"})
        elseif rewardType == 120 then
            --活动限时道具
            local mActivity = uobjs.getModel('activity')
            local acInfo = mActivity.info[targetId]
            addFlag = false
            if acInfo then
                local code = acInfo.code
                local aid = acInfo.aid
                local actCfg = getConfig(aid .. "Cfg", "activecfg")[code]
                local spItemCfg = actCfg.spItemTime[rewardId]
                local activitylib = require "lib/activitylib"
                local newItemInfo = activitylib:addAcTimeItem(acInfo.timeitem, v, rewardNum, uid, spItemCfg.lastTime)
                if newItemInfo then
                    addFlag = true
                    acInfo.timeitem = newItemInfo
                    regReturnModel({"activity"})
                end
            end
        elseif rewardType == 3001 then
            --3001特殊资质书经验
            local mAbilitytask = uobjs.getModel('abilitytask')
            addFlag = mAbilitytask.addBookExp(rewardId,rewardNum)
            regReturnModel({"abilitytask"})
        elseif rewardType == 301 then
            --骑士团装备
            local crazylib = require("lib/crazylib")
            local equip = crazylib:getEquipById(rewardId)
            local mCrazybox = uobjs.getModel('crazybox')
            addFlag = mCrazybox.pushEquip(equip)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 302 then
            --骑士团金币
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            addFlag = mCrazyplayer.addGold(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 303 then
            --骑士团钻石
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            addFlag = mCrazyplayer.addCGem(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 304 then
            --骑士团主角经验
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            addFlag = mCrazyplayer.addExp(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 305 then
            --骑士团宝箱
            local mCrazybox = uobjs.getModel('crazybox')
            addFlag = mCrazybox.addBoxNum(rewardNum)
            regReturnModel({"crazybox"})
        elseif rewardType == 306 then
            --骑士团仕途经验
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            addFlag = mCrazyplayer.addServantBookExp(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 351 then
            --骑士团战马
            local mCrazyequip = uobjs.getModel("crazyequip")
            addFlag = mCrazyequip.addHorse(rewardId)
            regReturnModel({"crazyequip"})
        elseif rewardType == 352 then
            --骑士团称号
            local mCrazyplayer = uobjs.getModel("crazyplayer")
            addFlag = mCrazyplayer.addTitle(rewardId)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 401 then
            --奖励为雕像
            local mItem = uobjs.getModel('item')
            local st = tonumber(targetId) --指定称号开始时间
            addFlag = mItem.addStatue(rewardId,st)
            regReturnModel({"item"})
        elseif rewardType == 71 then
            --奖励为天赋点
            local mServantatk = uobjs.getModel('servantatk')
            addFlag = mServantatk.addPoint(rewardId,rewardNum)
            regReturnModel({"servantatk"})
        end

        if changeReward and changeReward~="" then realadd=changeReward end
        newrewards = newrewards and newrewards.."|"..realadd or realadd

        --一旦有一个奖励添加失败直接跳出
        if not addFlag then
            finalFlag = addFlag
            break
        end
    end

    if not finalFlag and warnFlag then
        warn:sendMail('addRewardsFailed', {uid=uid,rewards=rewards,params=getParams() or {},targetId=targetId,msg=rewards.." 奖励添加失败"})
    end
    return finalFlag, load_model, newrewards
end

--使用物品
function funUseRewards(uid, rewards, eflag)
    --大类定义
    --1 钻石/元宝  2 黄金/银两  3 粮食  4 士兵 5 经验/政绩  6 道具 7 门客属性 
    --8门客 9红颜亲密度 10红颜 11称号 12红颜魅力 13 红颜经验值 14 门客书籍经验  
    --15  门客技能经验 16增加红颜服饰 17人望 18-人望废弃- 19门客皮肤 20同舟共济-令旗(仅前端) 21翠玉生辉-积分道具(仅前端) 22圣诞节-积分道具(仅前端) 25双11-代金券(仅前端)
    --26  前端未使用  27 在放灯活动中被使用  28-99 使用时需与前端沟通
    --38 税金(封地)  39 石料(封地)
    --62案卷经验 63办案经验 69 功勋
    --100英雄护符 101帮会经验(仅前端)  102个人贡献  103红颜才艺值 104红颜共浴场景 105府邸场景
    --106 聊天头像   107 聊天气泡
    --108 统一活动中间产物（不进背包，之后类型统一，以id区分）
    --109 帮会财富 以玩家当前帮会为准
    --110 战马PVP 商店代币  114 拜访商店代币
    --120 活动中的限时道具
    --201大富翁-积分道具(仅前端)
    --301骑士团箱子 302骑士团金币  303骑士团钻石  304骑士团主角经验 305骑士团宝箱 306骑士团仕途经验
    --1006-1024（前端用）2001擂台攻击次数
    local uid = tonumber(uid)
    if uid <= 0 or not rewards then
        return false
    end
    local rewards_table = string.split(rewards, "%|")
    local useFlag = false
    local uobjs = getUserObjs(uid)
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        if rewardType == 1 then
            --钻石/元宝
            local mUserinfo = uobjs.getModel('userinfo')
            useFlag = mUserinfo.useGem(rewardNum)
            regReturnModel({"userinfo"})
        elseif rewardType == 2 then
            --黄金/银两
            local mUserinfo = uobjs.getModel('userinfo')
            useFlag = mUserinfo.useGold(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 3 then
            --粮食
            local mUserinfo = uobjs.getModel('userinfo')
            useFlag = mUserinfo.useFood(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 4 then
            --士兵
            local mUserinfo = uobjs.getModel('userinfo')
            useFlag = mUserinfo.useSoldier(rewardNum)
            regReturnModel({ "userinfo" })
        elseif rewardType == 6 then
            --道具
            local mItem = uobjs.getModel('item')
            useFlag = mItem.useItem(rewardId, rewardNum)
            regReturnModel({"item"})
        elseif rewardType == 38 then
            --税金
            local mFief = uobjs.getModel('fief')
            useFlag = mFief.useResource(1,rewardNum)
            regReturnModel({ "fief" })
        elseif rewardType == 39 then
            --石料
            local mFief = uobjs.getModel('fief')
            useFlag = mFief.useResource(2,rewardNum)
            regReturnModel({ "fief" })
        elseif rewardType == 62 then
            --案卷经验
            local mYamen = uobjs.getModel('yamen')
            useFlag = mYamen.useFileExp(rewardId,rewardNum)
            regReturnModel({ "yamen" })
        elseif rewardType == 63 then
            --办案经验
            local mYamen = uobjs.getModel('yamen')
            useFlag = mYamen.useExp(rewardNum)
            regReturnModel({ "yamen" })
        elseif rewardType == 69 then
            -- 功勋奖励
            local mOneManWar = uobjs.getModel('onemanwar')
            useFlag = mOneManWar.useScore(rewardNum)
            regReturnModel({ "onemanwar" })
        elseif rewardType == 108 then
            --活动道具
            local mActivity = uobjs.getModel('activity')
            local acInfo = mActivity.info[eflag]
            local newItemInfo = {}
            local activitylib = require "lib/activitylib"
            useFlag,newItemInfo = activitylib:useAcItem(acInfo.item, v, rewardNum, uid)
            if useFlag then
                acInfo.item = newItemInfo
            end
            regReturnModel({"activity"})
        elseif rewardType == 109 then
            --eflag  帮会ID  需在消耗前  验证玩家帮会职务是否可以消耗帮会财富
            local aobjs = getallianceObjs(eflag)
            local mAlliance = aobjs.getModel('alliance')
            useFlag = mAlliance.useWealth(rewardNum)
        elseif rewardType == 110 then
            --战马PVP 商店代币
            local mWarhorserace = uobjs.getModel('warhorserace')
            useFlag = mWarhorserace.useItem(rewardId,rewardNum)
            regReturnModel({"warhorserace"})
        elseif rewardType == 114 then
            --拜访 商店代币
            local mVisit = uobjs.getModel('visit')
            useFlag = mVisit.useItem(rewardId,rewardNum)
            regReturnModel({"visit"})
        elseif rewardType == 115 then
            --战马 资历
            local horseId = tostring(eflag)
            local mWarhorse = uobjs.getModel('warhorse')
            useFlag = mWarhorse.useHorseSeniority(horseId,rewardNum)
            regReturnModel({"warhorse"})
        elseif rewardType == 120 then
            --活动道具
            local mActivity = uobjs.getModel('activity')
            local acInfo = mActivity.info[eflag]
            local newItemInfo = {}
            local activitylib = require "lib/activitylib"
            useFlag,newItemInfo = activitylib:useAcTimeItem(acInfo.timeitem, v, rewardNum, uid)
            if useFlag then
                acInfo.timeitem = newItemInfo
            end
            regReturnModel({"activity"})
        elseif rewardType == 302 then
            --302骑士团金币
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            useFlag = mCrazyplayer.useGold(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 303 then
            --303骑士团钻石
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            useFlag = mCrazyplayer.useCGem(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 306 then
            --骑士团仕途经验
            local mCrazyplayer = uobjs.getModel('crazyplayer')
            useFlag = mCrazyplayer.cutServantBookExp(rewardNum)
            regReturnModel({"crazyplayer"})
        elseif rewardType == 3001 then
            --3001特殊资质书经验
            local mAbilitytask = uobjs.getModel('abilitytask')
            useFlag = mAbilitytask.useBookExp(rewardId,rewardNum)
            regReturnModel({"abilitytask"})
        elseif rewardType == 71 then
            --奖励为天赋点
            local mServantatk = uobjs.getModel('servantatk')
            useFlag = mServantatk.usePoint(rewardId,rewardNum)
            regReturnModel({"servantatk"})
        else
            --其他不支持，报错
            useFlag = false
        end
        if not useFlag then
            break
        end
    end

    -- if not useFlag then
    --     warn:sendMail('useRewardsFailed', {uid=uid,rewards=rewards,eflag=eflag,msg=rewards.." 使用失败"})
    -- end
    return useFlag
end

--合并奖励
function mergeRewards(rewards)
    if rewards == '' then
        return rewards
    end
    local gift_table = string.split(rewards, "%|")

    local tmp_table = {}
    local result = ""
    for k, v in pairs(gift_table) do
        local gift_v = string.split(v, "%_")
        local giftType = tonumber(gift_v[1])
        local giftId = tostring(gift_v[2]) or '0'
        local giftNum = tonumber(gift_v[3])
        if tmp_table[giftType .. "_" .. giftId] == nil then
            tmp_table[giftType .. "_" .. giftId] = giftNum
        else
            tmp_table[giftType .. "_" .. giftId] = tmp_table[giftType .. "_" .. giftId] + giftNum
        end
    end
    for k, v in pairs(tmp_table) do
        local gift_str = string.split(k, "%_")
        local tmp_v = gift_str[1] .. "_" .. gift_str[2] .. "_" .. v
        if result == "" then
            result = tmp_v
        else
            result = result .. "|" .. tmp_v
        end
    end

    return result
end

--缓存用户常用基础信息
function getCacheUserInfo(uid)
    local redis = getRedis()
    local key = "z"..getZoneId()..".cacheUserInfo."..uid
    local cacheData = redis:get(key)
    if not cacheData then
        cacheData = {}
    else
        cacheData = json.decode(cacheData)
    end

    if not next(cacheData) then
        local uobjs = getUserObjs(uid, true)
        local mUserinfo = uobjs.getModel('userinfo')
        local mGameinfo = uobjs.getModel('gameinfo')
        cacheData['name'] = mUserinfo.name
        cacheData['vip'] = mUserinfo.vip
        cacheData['level'] = mUserinfo.level
        cacheData['pic'] = mUserinfo.pic
        cacheData['title'] = mUserinfo.title
        cacheData['titlelv'] = mUserinfo.titlelv
        cacheData['ptitle'] = mUserinfo.ptitle
        cacheData['mygid'] = mUserinfo.mygid
        cacheData['mygname'] = tostring(mUserinfo.mygname)
        cacheData['pid'] = mGameinfo.pid
        cacheData['plat'] = mGameinfo.plat
        cacheData['deviceid'] = mGameinfo.deviceid
        cacheData['regdt'] = mGameinfo.regdt
        cacheData['ip'] = mGameinfo.ip
        cacheData['logindt'] = mGameinfo.logindt
        cacheData['lastpic'] = mGameinfo.info.lastpic
        redis:setex(key,864000,json.encode(cacheData))
    end
    return cacheData
end

--删除用户常用基础信息
function delCacheUserInfo(uid)
    local redis = getRedis()
    local key = "z"..getZoneId()..".cacheUserInfo."..uid
    redis:del(key)
    delCommonCacheUserInfo(uid)
    return true
end

--缓存帮会常用基础信息
function getCacheAllianceInfo(id)
    local redis = getRedis()
    local key = "z" .. getZoneId() .. ".cacheAllianceInfo." .. id
    local cacheData = redis:get(key)
    if not cacheData then
        cacheData = {}
    else
        cacheData = json.decode(cacheData)
    end

    if not next(cacheData) then
        local aobjs = getallianceObjs(tonumber(id), true)
        local mAlliance = aobjs.getModel('alliance')
        cacheData['creator'] = mAlliance.creator
        cacheData['creatorname'] = mAlliance.creatorname
        cacheData['name'] = mAlliance.name
        cacheData['level'] = mAlliance.level
        redis:setex(key, 864000, json.encode(cacheData))
    end
    return cacheData
end

--删除帮会常用基础信息
function delCacheAllianceInfo(id)
    local redis = getRedis()
    local key = "z" .. getZoneId() .. ".cacheAllianceInfo." .. id
    redis:del(key)
    delCommonCacheAllianceInfo(id)
    return true
end

--公共缓存-缓存用户常用基础信息
function getCommonCacheUserInfo(uid)
    local redis = getCommonRedis()
    local key = "common.cacheUserInfo."..uid
    local cacheData = redis:get(key)
    if not cacheData then
        cacheData = {}
    else
        cacheData = json.decode(cacheData)
    end

    if not next(cacheData) then
        local db = getDbo(getUserTrueZid(uid))
        local mUserinfo = db:getRow("select name,vip,level,pic,title,titlelv,ptitle,mygid,mygname from userinfo where uid="..uid)
        local mGameinfo = db:getRow("select info from gameinfo where uid="..uid)
        local gameLastPic
        if mGameinfo and mGameinfo.info then
            mGameinfo.info = json.decode(mGameinfo.info)
            gameLastPic = mGameinfo.info.lastpic
        end
        
        cacheData['name'] = mUserinfo.name
        cacheData['vip'] = mUserinfo.vip
        cacheData['level'] = mUserinfo.level
        cacheData['pic'] = mUserinfo.pic
        cacheData['title'] = mUserinfo.title
        cacheData['titlelv'] = mUserinfo.titlelv
        cacheData['ptitle'] = json.decode(mUserinfo.ptitle) or mUserinfo.ptitle
        cacheData['mygid'] = mUserinfo.mygid
        cacheData['mygname'] = mUserinfo.mygname
        cacheData['lastpic'] = gameLastPic
        redis:setex(key,864000,json.encode(cacheData))
    end
    return cacheData
end

--公共缓存-删除用户在公共缓存的常用基础信息
function delCommonCacheUserInfo(uid)
    local redis = getCommonRedis()
    local key = "common.cacheUserInfo."..uid
    redis:del(key)
    return true
end

--公共缓存-缓存帮会常用基础信息
function getCommonCacheAllianceInfo(id,zid)
    local redis = getCommonRedis()
    local key = "common.cacheAllianceInfo."..id
    local cacheData = redis:get(key)
    if not cacheData then
        cacheData = {}
    else
        cacheData = json.decode(cacheData)
    end

    if not next(cacheData) then
        local db = getDbo(tonumber(zid))
        local mAlliance = db:getRow("select name,creator,creatorname,level from alliance where id="..id)
        cacheData['creator'] = mAlliance.creator
        cacheData['creatorname'] = mAlliance.creatorname
        cacheData['name'] = mAlliance.name
        cacheData['level'] = mAlliance.level
        redis:setex(key,864000,json.encode(cacheData))
    end
    return cacheData
end

--公共缓存-删除帮会在公共缓存的常用基础信息
function delCommonCacheAllianceInfo(id)
    local redis = getCommonRedis()
    local key = "common.cacheAllianceInfo."..id
    redis:del(key)
    return true
end

--一次寻访
function onePlaySearch(uid)
    local uobjs = getUserObjs(uid)
    local mUserinfo = uobjs.getModel('userinfo')
    local mSearch = uobjs.getModel('search')

    --自动补充运势
    mSearch.autoSetLucky()

    --过滤可以寻访人物
    local filterKeys = {}
    local searchCfg = getConfig('searchCfg')
    local wifeCfg = getConfig('wifeCfg')
    local switchData = getSwitchData()

    for k,v in pairs(searchCfg['personList']) do
        if v["type"] ==2 then --红颜
            local wifeid = v.wifeId
            local wifeswitchname = "wifeName_"..wifeid
            if switchData[wifeswitchname] or wifeCfg[wifeid]["state"] == 1 then
                if not v["value"] or v["value"]==0 then --直接检测有没有红颜
                    local mWife = uobjs.getModel('wife')
                    if mWife.info[wifeid] then
                        table.insert(filterKeys, k)
                    end
                else
                    if v.needTime and v.needTime>0 then --检测是否到时间
                        local mGameinfo = uobjs.getModel('gameinfo')
                        if os.time()-tonumber(mGameinfo.regdt)>=v.needTime then
                            table.insert(filterKeys, k)
                        end
                    else
                        table.insert(filterKeys, k)
                    end
                end
            end
        else --物资
            table.insert(filterKeys, k)
        end
    end

    --确定运势档位
    local luckyListCfg = getConfig('searchBaseCfg')
    local last = -1
    local nowLucky = mSearch.lucky.num
    local luckyKey
    for k,v in ipairs(luckyListCfg.luckyList) do
        if nowLucky<=tonumber(v.value) and nowLucky>last then
            luckyKey = k
            break
        else
            last = tonumber(v.value)
        end
    end

    --设置权重
    local personLuckyList = {}
    for _,personId in pairs(filterKeys) do
        personLuckyList[personId] = luckyListCfg["luckyList"][luckyKey][tostring(personId)]
    end

    --获取随机人物
    local randKey = getKeyByRnd(personLuckyList)
    local searchTwoFun = isSwitchTrue(uid,"openNewSearch")
    -- print(searchTwoFun,uid,"openNewSearch")
    --开启2.0后指定的次数获得指定的ID奖励，不用随机
    if searchTwoFun then
        local nextPnum = mSearch.tinfo.snum and mSearch.tinfo.snum+1 or 1
        if luckyListCfg.specialId then
            for _, value in ipairs(luckyListCfg.specialId) do
                local specialNum = value[1]
                local specifiedId = value[2]
                if nextPnum == specialNum and not mSearch.tinfo.flag[tostring(specialNum)] then
                    randKey = specifiedId
                    mSearch.tinfo.flag[tostring(specialNum)] = 1
                    break
                end
            end
        end
    end
    if not randKey then
        writeLog(json.encode(personLuckyList), 'randKey') 
        return false
    end

    --获取奖励
    local addFlag = false
    local personListCfg = searchCfg['personList']
    local reward = ""
    if tonumber(personListCfg[randKey]["type"])==1 then
        local attrType = personListCfg[randKey]["reward"]
        local rate = personListCfg[randKey]["ratioList"][tonumber(luckyKey)]
        local num = formula:getAddHomeBuffSearchByType(uid, attrType, rate)
        local base = personListCfg[randKey]["base"][tonumber(luckyKey)]

        if tonumber(attrType)==2 then --银两
            if num>0 then
                num = num+base
                addFlag = mUserinfo.addGold(num)
            elseif num<0 then
                local unum = math.min(mUserinfo.gold, math.abs(num))
                addFlag = mUserinfo.useGold(unum)
            else
                addFlag = true
            end
        elseif tonumber(attrType)==3 then --粮食
            if num>0 then
                num = num+base
                addFlag = mUserinfo.addFood(num)
            elseif num<0 then
                local unum = math.min(mUserinfo.food, math.abs(num))
                addFlag = mUserinfo.useFood(unum)
            else
                addFlag = true
            end
        elseif tonumber(attrType)==4 then --士兵
            if num>0 then
                num = num+base
                addFlag = mUserinfo.addSoldier(num)
            elseif num<0 then
                local unum = math.min(mUserinfo.soldier, math.abs(num))
                addFlag = mUserinfo.useSoldier(unum)
            else
                addFlag = true
            end
        end

        --1 钻石/元宝  2 黄金/银两  3 粮食  4 士兵 5 经验/政绩  6 道具 7 门客属性 8门客 9亲密度
        reward = tonumber(attrType).."_0_"..tostring(num)
        regReturnModel({"userinfo"})
    elseif tonumber(personListCfg[randKey]["type"])==2 then
        local mWife = uobjs.getModel('wife')
        local wifeId = personListCfg[randKey]["wifeId"]
        
        --增加进度
        addFlag = mSearch.addProgress(randKey, 1)
        
        --获取红颜
        if not mWife.info[wifeId] and mSearch.getProgress(randKey) >= personListCfg[randKey]['value'] then
            mWife.addWife(wifeId)
            regReturnModel({"servant"})
        end
        
        --增加亲密度
        if mWife.info[wifeId] and mSearch.getProgress(randKey) ~= personListCfg[randKey]['value'] then
            addFlag = mWife.addIntimacy(wifeId) 
            reward = "9_0_1"
            regReturnModel({"wife"})
        end
        
        addFlag = true
    end

    if not addFlag then
        personLuckyList.addFlagerr = reward
        writeLog(json.encode(personLuckyList), 'randKey') 
        return false
    end
    local extreward
    --开启寻访2.0后配置有追加奖励字段的需要给玩家追加奖励
    if searchTwoFun then
        -- print("is run tinfo reset")
        if personListCfg[randKey].itemReward then
            local giveId = rand(1,#(personListCfg[randKey].itemReward))
            local itemR = personListCfg[randKey].itemReward[giveId]
            addFlag = funAddRewards(uid, itemR)
            if not addFlag then
                personLuckyList.extraaddFlagerr = itemR
                writeLog(json.encode(personLuckyList), 'randKey') 
                return false
            end
            extreward = itemR
        end
        mSearch.addPlayNum(1)
    end

    --使用体力
    local useFlag = mSearch.useStrength()
    --减少运势
    mSearch.useLucky(2)

    --自动补充运势
    mSearch.autoSetLucky()

    if useFlag then
        regReturnModel({"search"})
        return randKey,reward,extreward
    end
    personLuckyList.strengthnum=mSearch.strength.num
    writeLog(json.encode(personLuckyList), 'randKey') 
    return false
end

--一次随机政务
function onpPlayAffair(uid)
    --设置权重
    local affairCfg = getConfig('affairCfg')
    local affairLucky = {}
    for k,v in pairs(affairCfg['affairList']) do
        affairLucky[k] = v["weight"]
    end

    --获取随机政务id
    local randKey = getKeyByRnd(affairLucky)
    if not randKey then
        return false
    end

    return randKey
end

--增加任务进程
function addGameTask(uid, taskType, num, need)
    local uobjs = getUserObjs(uid)
    local mMaintask = uobjs.getModel('maintask')
    local mDailytask = uobjs.getModel('dailytask')
    local flag = mMaintask.addTaskNum(taskType, num, need)
    --每日任务处理
    mDailytask.addDailyTaskNum(taskType,num)
    --增加成就进程
    local mAchievement = uobjs.getModel('achievement')
    mAchievement.addAchievement(taskType,num)
    local mOtherinfo = uobjs.getModel('otherinfo')
    --新七日签到
    if isSwitchTrue(uid,'openLoginWeek') then
        mOtherinfo.addLoginWeekData(taskType,num)
    end
    --新版七日任务
    if isSwitchTrue(uid,'openNewLoginWeek2022') then
        mOtherinfo.addNewLoginWeekData(taskType,num)
    end
    --更新关卡进度的接口太多所以在任务进度统计中更新关卡进度
    if taskType == "30105" and isSwitchTrue(uid,"openManageNew") then
        local mManagenew = uobjs.getModel('managenew')
        mManagenew.checkAnswer("upchallengelv",num)
    end
    --战马特训
    local typearr = {"30111","30112","30113","30114","30115"}
    if isSwitchTrue(uid,"openWarHorse") and table.contains(typearr,taskType) then
        local mWarhorsetrain = uobjs.getModel('warhorsetrain')
        mWarhorsetrain.addTaskData(taskType,num)
    end

    local mGodtask = uobjs.getModel('godtask')
    mGodtask.addTinfoNum(taskType,num,need)

    return flag
end

--滚动公告，跑马灯入队
function pushMsgToRollQueue(uid,need,msg,st,dtype,origin)
    local needFlag = false
    local needs = {}
    local lampInfoCfg = getConfig('lampInfoCfg')
    dtype = tostring(dtype)
    local item

    local name = ""
    local title = ""
    local pic = ""
    local level = ""
    local ntid = ""
    if uid>0 then
        local userinfo = getCacheUserInfo(uid)
        name = userinfo.name
        title = userinfo.title
        pic = userinfo.pic
        level = userinfo.level
        if userinfo.ptitle and userinfo.ptitle.ntid then
            ntid = userinfo.ptitle.ntid
        end
    end

    local sortId = lampInfoCfg[tostring(dtype)]['sortId']
    if not sortId then
        return false
    end

    if dtype=="1" then
        needs = lampInfoCfg[dtype]['wifeId']
        item = {uid=uid, name=name, msg=msg, st=st, dtype=1, need=need, sortId=tonumber(sortId), sexflag=msg}
    elseif dtype=="2" then
        needs = lampInfoCfg[dtype]['servantId']
    elseif dtype=="3" then  --势力值单独判断
        needs = lampInfoCfg[dtype]['needPower']
        for _,v in ipairs(needs) do
            if tonumber(origin)<tonumber(v) and tonumber(need)>=tonumber(v) then
                need = tonumber(v) --更改势力值
                needFlag = true
                break
            end
        end
        if not needFlag then
            return false
        end
    elseif tostring(dtype)=="4" then
        needs = lampInfoCfg[dtype]['needVip']
    elseif tostring(dtype)=="5" then
        needs = lampInfoCfg[dtype]['needLv']
    elseif tostring(dtype)=="6" then --皇帝登录
        needFlag = true
        item = {uid=uid,st=st,dtype=6,sortId=tonumber(sortId),info={"name_"..name} }
    elseif tostring(dtype)=="8" then --国策
        needFlag = true
        item = {uid=uid,st=st,dtype=8,sortId=tonumber(sortId),info={"name_"..name,"spid_"..need,"spdetail_"..need}}
    elseif tostring(dtype)=="9" then --政令
        needFlag = true
        item = {uid=uid,st=st,dtype=9,sortId=tonumber(sortId),info={"name_"..name,"gdid_"..msg,"gddetail_"..msg} }
    elseif tostring(dtype)=="10" then --国策
        needFlag = true
        item = {uid=uid,st=st,dtype=10,sortId=tonumber(sortId),info={"name_"..name,"spid_"..need,"spdetail_"..need}}
    elseif tostring(dtype)=="7" then --分封
        needFlag = true
        item = {uid=uid,st=st,dtype=7,sortId=tonumber(sortId),info={"name_"..name,"position_"..need}}
    elseif tostring(dtype)=="99" then --豪华盛宴
        needFlag = true
        local showData = {"name_"..name,"opttype_"..need,"endtime_"..msg,"title_"..title,"pic_"..pic,"ntid_"..ntid,"level_"..level}
        item = {uid=uid,st=st,dtype=99,sortId=tonumber(sortId),info=showData}
        --开宴信息发送至聊天
        sendMessageToChat(uid,2,item)
    elseif dtype=="11" then
        --称号获得
        needs = lampInfoCfg[dtype]['titleId']
        item = {uid=msg.uid, name=msg.name, aname=msg.aname, zid=msg.zid, rank=1, st=st, dtype=11, need=need, sortId=tonumber(sortId)}
    elseif dtype=="12" then
        --战马活动获得战马
        needFlag = true
        item = {uid=uid, name=name, st=st, dtype=12, need=need, sortId=tonumber(sortId)}
    else
        needFlag = true
    end

    --非势力值/系统公告需要比较是否相同
    if not needFlag then
        for _,v in ipairs(needs) do
            if tostring(v)== tostring(need) then
                needFlag = true
                break
            end
        end
    end

    if not needFlag then
        return false
    end

    local rollQueueKey = "z" ..getZoneId() .. ".roll"
    local redis = getRedis()
    local data = redis:get(rollQueueKey)
    local info = json.decode(data) or {}
    local now = os.time()

    if not item then
        item = {uid=uid, name = name,msg = msg,st = st,dtype = dtype,need = need,sortId = tonumber(sortId)}
    end

    local insertFlag = false
    if info then
        for i=#info,1,-1 do
            local v = info[i]
            --去掉10分钟前的数据
            local sTime = 10*60
            if v.dtype == 99 then
                sTime = 30*60
            end
            if now - tonumber(v.st) >= sTime then
                table.remove(info, i)
            else
                local dsortId = tonumber(lampInfoCfg[tostring(v.dtype)]['sortId'])
                if tonumber(sortId)>=dsortId then
                    table.insert(info, i+1, item)
                    insertFlag = true
                    break
                end
            end
        end
    end

    --放在首位
    if not insertFlag then
        table.insert(info,1,item)
    end
    local data = json.encode(info)
    redis:set(rollQueueKey, data)
    return true
end

--滚动公告，跑马灯获取
function getMsgInRollQueue(uid)
    local redis = getRedis()
    local userRollVisitKey = "z" .. getZoneId() .. "."..uid..".rollvisit"
    local visitTime = redis:get(userRollVisitKey) or 0

    local rollQueueKey = "z" .. getZoneId() .. ".roll"
    local data = redis:get(rollQueueKey)
    local info = json.decode(data) or {}

    local item = {}
    local upFlag = false
    local now = os.time()
    for k,v in ipairs(info) do
        --10分钟内数据
        local sTime = 10*60
        if v.dtype == 99 then
            sTime = 30*60
        end
        if now - tonumber(v.st)< sTime then
            if v.dtype == 99 then
                table.insert(item, v)
                upFlag = true
            else
                if tonumber(v.st)<=tonumber(now) and tonumber(v.st)>tonumber(visitTime) then
                    table.insert(item, v)
                    upFlag = true
                end
            end
        end
    end

    if upFlag then
        redis:setex(userRollVisitKey,30*60,now)
    end
    return item
end

--设置跨服称号
function setCrossTitle(titleId,userid,zid,aname,sign,st,et)
    local preUserId
    local crosstitle = "z" .. getZoneId() .. ".crosstitle"
    local redis = getRedis()
    local palaceData = redis:get(crosstitle)
    local titleCfg = getConfig("titleCfg")
    if not palaceData then
        local data = getBakData(crosstitle)
        if data then
            palaceData = json.decode(data)
        else 
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isCross == 1 and v.titleType then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        for k,v in pairs(titleCfg) do
            if not palaceData[k] and v.isCross == 1 and v.titleType then
                palaceData[k] = {}
            end
        end
    end

    --防重
    if palaceData[titleId] and tonumber(palaceData[titleId].uid)==tonumber(userid) and palaceData[titleId].st and os.time()-tonumber(palaceData[titleId].st)<86400 then
        writeLog({uid=userid,titleId=titleId,type="crosstitle",cmd=getCmd(),myuid=getMyuid()}, "crossTitleRepWrong")
        return false
    end

    if palaceData[titleId] and palaceData[titleId].uid and userid ~= palaceData[titleId].uid then
        preUserId = palaceData[titleId].uid
        -- preZid = palaceData[titleId].zid
    end

    if not palaceData[titleId].rank then
        palaceData[titleId].rank = {}
    end
    if sign then
        if not palaceData[titleId].uid or palaceData[titleId].uid~=userid then
            return false
        end
        palaceData[titleId].sign = sign
    else
        palaceData[titleId].sign = ""
        palaceData[titleId].uid = userid
        palaceData[titleId].zid = zid
        palaceData[titleId].st = st or os.time()
        if not et and titleCfg[titleId].lastTime then
            et = palaceData[titleId].st + titleCfg[titleId].lastTime
        end
        palaceData[titleId].et = et
        table.insert(palaceData[titleId].rank,1,{userid,aname,st or os.time(),zid,et})
        if #palaceData[titleId].rank >100 then
            table.remove(palaceData[titleId].rank,100)
        end
    end
    local dataStr = json.encode(palaceData)
    --记录到缓存
    redis:set(crosstitle, dataStr)
    --记录数据入库
    recordBakData(crosstitle,dataStr)
    return true,preUserId
end

--同时设置多个跨服称号
function setMoreCrossTitle(titleData)
    local crosstitle = "z" .. getZoneId() .. ".crosstitle"
    local redis = getRedis()
    local titleCfg = getConfig("titleCfg")
    local palaceData = redis:get(crosstitle)
    if not palaceData then
        local data = getBakData(crosstitle)
        if data then
            palaceData = json.decode(data)
        else
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isCross == 1 and v.titleType then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        for k,v in pairs(titleCfg) do
            if not palaceData[k] and v.isCross == 1 and v.titleType then
                palaceData[k] = {}
            end
        end
    end

    local now = os.time()
    for _, tInfo in pairs(titleData) do
        local titleId = tostring(tInfo.titleId)
        if palaceData[titleId] then
            palaceData[titleId].rank = palaceData[titleId].rank or {}
            --进行防重处理
            if titleCfg[titleId].isOnly == 1 then --只可一人获得称号
                if palaceData[titleId] and tonumber(palaceData[titleId].uid)==tonumber(tInfo.uid) and palaceData[titleId].st and os.time()-tonumber(palaceData[titleId].st)<86400 then
                    writeLog({uid=tInfo.uid,titleId=titleId,type="crosstitle",cmd=getCmd(),myuid=getMyuid()}, "crossTitleRepWrong")
                    return false
                end
            elseif titleCfg[titleId].isOnly == 0 then --可多人同时获得称号
                for _, uInfo in pairs(palaceData[titleId].rank) do
                    --(开始时间相同)&(结束时间相同)&(uid相同)
                    if (not tonumber(uInfo[3]) or tonumber(uInfo[3]) == tonumber(tInfo.st)) and (not tonumber(uInfo[5]) or tonumber(uInfo[5]) == tonumber(tInfo.et)) and tonumber(uInfo[1]) == tonumber(tInfo.uid) then
                        writeLog({uid=tInfo.uid,titleId=titleId,type="crosstitle",cmd=getCmd(),myuid=getMyuid()}, "crossTitleRepWrong")
                        return false
                    end
                end
            end
            palaceData[titleId].sign = ""
            palaceData[titleId].uid = tInfo.uid
            palaceData[titleId].zid = tInfo.zid
            palaceData[titleId].st = tInfo.st or now
            palaceData[titleId].et = tInfo.et
            table.insert(palaceData[titleId].rank,1,{tInfo.uid,"",tInfo.st or now,tInfo.zid,tInfo.et})
        end
	end

    local dataStr = json.encode(palaceData)
    redis:set(crosstitle, dataStr)
    recordBakData(crosstitle,dataStr)
    return true
end

--清理皇宫称号
function clearCrossKingTitle()
    local crosstitle = "z" .. getZoneId() .. ".crosstitle"
    local redis = getRedis()
    local palaceData = redis:get(crosstitle)
    if not palaceData then
        local data = getBakData(crosstitle)
        if data then
            palaceData = json.decode(data)
        end
    else
        palaceData = json.decode(palaceData)
    end

    local preuid
    if palaceData and palaceData["3201"] and palaceData["3201"].uid then
        preuid = tonumber(palaceData["3201"].uid)
        palaceData["3201"].uid=0
        palaceData["3201"].zid=0
        palaceData["3201"].sign=""

        local dataStr = json.encode(palaceData)
        redis:set(crosstitle, dataStr)
        --记录数据入库
        recordBakData(crosstitle,dataStr)
        return true,preuid
    end
end

--获取当前皇帝信息
function getCrossKingTitle()
    -- local returnData = {}
    local crosstitle = "z" .. getZoneId() .. ".crosstitle"
    local redis = getRedis()
    local palaceData = redis:get(crosstitle)
    if not palaceData then
        local data = getBakData(crosstitle)
        if data then
            palaceData = json.decode(data)
        end
    else
        palaceData = json.decode(palaceData)
    end

    local kinguid=0
    local kingst=0
    if palaceData and palaceData["3201"] and palaceData["3201"].uid and palaceData["3201"].st then
        kinguid = tonumber(palaceData["3201"].uid)
        kingst = tonumber(palaceData["3201"].st)
    end

    return kinguid,kingst
end

--更新区服称号
function setOtherTitle(titleId,userid)
    local othertitle = "z" .. getZoneId() .. ".othertitle"
    local redis = getRedis()
    local palaceData = redis:get(othertitle)
    if not palaceData then
        local data = getBakData(othertitle)
        if data then
            palaceData = json.decode(data)
        else 
            palaceData = {}
        end
    else
        palaceData = json.decode(palaceData)
    end

    if not palaceData[titleId] then
        palaceData[titleId] = {}
    end
    if not table.contains(palaceData[titleId],userid) then
        table.insert(palaceData[titleId],userid)
    end

    local dataStr = json.encode(palaceData)
    --记录到缓存
    redis:set(othertitle, dataStr)
    --记录数据入库
    recordBakData(othertitle,dataStr)
    return true
end

--更新区服唯一称号
function setOnlyTitle(titleId,userid,sign)
    local preUserId
    local onlytitle = "z" .. getZoneId() .. ".onlytitle"
    local redis = getRedis()
    local palaceData = redis:get(onlytitle)
    if not palaceData then
        local data = getBakData(onlytitle)
        if data then
            palaceData = json.decode(data)
        else 
            local titleCfg = getConfig("titleCfg")
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    --{uid = 0,sign = "",rank={}}
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        local titleCfg = getConfig("titleCfg")
        for k,v in pairs(titleCfg) do
            if not palaceData[k] and v.isOnly == 1 and v.isCross == 0 then
                palaceData[k] = {}
            end
        end
    end

    --防重
    if not palaceData[titleId].st then
        palaceData[titleId].st = 0
    end
    if palaceData[titleId] and tonumber(palaceData[titleId].uid)==tonumber(userid) and os.time()-tonumber(palaceData[titleId].st)<86400 then
        writeLog({uid=userid,titleId=titleId,type="onlytitle",zid=getZoneId(),myuid=getMyuid(),cmd=getCmd()}, "onlyTitleRepWrong")
        return false
    end

    if palaceData[titleId] and palaceData[titleId].uid and userid ~= palaceData[titleId].uid then
        preUserId = palaceData[titleId].uid
    end

    if not palaceData[titleId].rank then
        palaceData[titleId].rank = {}
    end
    if sign then
        if not palaceData[titleId] or not palaceData[titleId].uid or palaceData[titleId].uid~=userid then
            return false
        end
        palaceData[titleId].sign = sign
    else
        local userCache = getCacheUserInfo(tonumber(userid))

        palaceData[titleId].sign = ""
        palaceData[titleId].uid = userid
        palaceData[titleId].st = os.time()
        table.insert(palaceData[titleId].rank,1,{userid,userCache.name,os.time()})
        if #palaceData[titleId].rank >100 then
            table.remove(palaceData[titleId].rank,101)
        end
    end
    local dataStr = json.encode(palaceData)
    --记录到缓存
    redis:set(onlytitle, dataStr)
    --记录数据入库
    recordBakData(onlytitle,dataStr)
    return true,preUserId
end

--获取皇宫信息
function getPalaceData()
    local returnData = {}
    local onlytitle = "z" .. getZoneId() .. ".onlytitle"
    local redis = getRedis()
    local palaceData = redis:get(onlytitle)
    if not palaceData then
        local data = getBakData(onlytitle)
        if data then
            redis:set(onlytitle, data)
            palaceData = json.decode(data)
        else 
            local titleCfg = getConfig("titleCfg")
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    --{uid = 0,sign = "",rank={}}
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        local titleCfg = getConfig("titleCfg")
        for k,v in pairs(titleCfg) do
            if not palaceData[k] and v.isOnly == 1 and v.isCross == 0 then
                palaceData[k] = {}
            end
        end
    end

    local onlytsignkey = "z"..getZoneId()..".onlytitle.sign"
    local signData = redis:get(onlytsignkey) or "{}"
    signData = json.decode(signData) or {}

    for title,data in pairs(palaceData) do
        returnData[title] = copyTable(data)
        if data.uid then
            local uid = tonumber(data.uid)
            local uobjs = getUserObjs(uid,true)
            local mUserinfo = uobjs.getModel('userinfo')
            local mGameinfo = uobjs.getModel('gameinfo')
            local mItem = uobjs.getModel('item')
            returnData[title].vip = mUserinfo.vip
            returnData[title].pic = mUserinfo.pic
            returnData[title].name = mUserinfo.name
            returnData[title].level = mUserinfo.level
            returnData[title].titlelv = mItem.tupinfo[tostring(title)] and mItem.tupinfo[tostring(title)].tlv or 0
            returnData[title].lastpic = mGameinfo.info.lastpic
            
            if signData[title] and signData[title].uid and signData[title].uid==data.uid then
                returnData[title].sign = signData[title].sign
            end
        end
    end
    return returnData
end

--获取皇宫当前称号
function getCurrentPalaceData()
    local returnData = {}
    local onlytitle = "z" .. getZoneId() .. ".onlytitle"
    local redis = getRedis()
    local palaceData = redis:get(onlytitle)
    if not palaceData then
        local data = getBakData(onlytitle)
        if data then
            redis:set(onlytitle, data)
            palaceData = json.decode(data)
        else 
            local titleCfg = getConfig("titleCfg")
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
    end
    for k, v in pairs(palaceData) do
        if v.uid then
            returnData[k] = v.uid
        end
    end

    local crosstitle = "z" .. getZoneId() .. ".crosstitle"
    local palaceData = redis:get(crosstitle)
    if not palaceData then
        local data = getBakData(crosstitle)
        if data then
            redis:set(crosstitle, data)
            palaceData = json.decode(data)
        else 
            local titleCfg = getConfig("titleCfg")
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isCross == 1 and v.titleType then
                    --{uid = 0,sign = "",rank={}}
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
    end
    for k, v in pairs(palaceData) do
        if v.uid then
            returnData[k] = v.uid
        end
    end
    return returnData
end

--记录数据入库
function recordBakData(key,dataStr)
    local backData = {
        id = key,
        info = dataStr,
        updated_at = os.time()
    }

    local db = getDbo()
    local ret = db:replace('backdata',backData)
    if ret and ret > 0 then
        return true
    end

    return false
end

--记录数据入库(指定服)
function recordBakDataByZid(key,dataStr,zid)
    local zid = zid or getZoneId()
    local backData = {
        id = key,
        info = dataStr,
        updated_at = os.time()
    }

    local db = getDbo(zid)
    local ret = db:replace('backdata',backData)

    if ret and ret > 0 then
        return true
    end

    return false
end

--获取数据库数据
function getBakData(key,zid)
    local zid = zid or getZoneId()
    local db = getDbo(zid)
    local result = db:getRow("select info from backdata where id='"..key.."';")
    if result and result["info"] then
        return result["info"]
    else
        return false
    end
end

--宴会模块是否解锁
function dinnerIsUnlock(uid)
    local userCache = getCacheUserInfo(tonumber(uid))
    local dinnerCfg = getDinnerCfgFunc()
    if tonumber(userCache.level) >= tonumber(dinnerCfg['needLv']) then
        return true
    end

    return false
end

--宴会积分兑换道具随机列表
function dinnerRandItems(randNum,uid)
    local uobjs = getUserObjs(uid)
    local mDinner = uobjs.getModel('dinner')
    local dayBuyInfo = mDinner.other_info.day_buyinfo or {}
    
    local randItems = {}
    local dinnerCfg = getDinnerCfgFunc()
    local dinnerShopCfg = dinnerCfg['shop']
    local daylimitpostionCfg = copyTable(dinnerCfg['daylimitpostion'])
    
    local dayopenfunpostion = dinnerCfg.dayopenfunpostion or {}
    for funKey,openShop in pairs(dayopenfunpostion) do
        if not isSwitchTrue(uid,funKey) then
            for _,shopId in ipairs(openShop) do
                if daylimitpostionCfg[shopId] then
                    daylimitpostionCfg[shopId] = nil
                end
            end
        end
    end
    
    local allianceWarCfg = getConfig('allianceWarCfg')
    local itemList = allianceWarCfg.itemList
    
    -- 添加跨服的商品取出
    local zid = getZoneId()
    local crossflag = getDinnerCrossSwitch(zid)
    if crossflag then
        dinnerShopCfg = dinnerCfg['servershop']
    end
    
    local randKeys = {}
    for k,v in pairs(dinnerShopCfg) do
        -- 此处需要过滤今天不能再出现的道具
        if dayBuyInfo[k] and daylimitpostionCfg[k] and dayBuyInfo[k] >= daylimitpostionCfg[k] then
        else
            randKeys[tostring(k)] = tonumber(v.weight)
        end
        if not true then
            for _,num in pairs(itemList) do
                local item = "6_"..num.item.."_1"
                if v.content == item and randKeys[tostring(k)] then
                    randKeys[tostring(k)] = nil
                end
            end
        end
    end

    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
        randKeys[key] = nil
    end
    return randItems
end

--酒楼可看到的宴会席位信息
function getDinnerCanView(sZid,eZid)
    local z1 = sZid or 0
    local z2 = eZid or 0
    local selectZid = z1
    if z2 ~= 0 then
        selectZid = z1.."_"..z2
    end
    local viewKey = "z" .. selectZid .. ".dinnerview"
    local redis = getRedis()
    local data = redis:get(viewKey)
    if data then
        return json.decode(data)
    end
    return false
end

--酒楼设置看到的宴会席位信息
function setDinnerCanView(uid,data,sZid,eZid)
    local z1 = sZid or 0
    local z2 = eZid or 0
    local selectZid = z1
    if z2 ~= 0 then
        selectZid = z1.."_"..z2
    end
    local viewKey = "z" .. selectZid .. ".dinnerview"
    local redis = getRedis()
    redis:set(viewKey, json.encode(data))
end

--设置冲榜活动排行榜数据(rankName最后一段应为开始时间，否则应传extrast)
function setRankActive(uid,rankName,value,extrast)
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local now = os.time()
    local tmpst
    if extrast and extrast > 0 then
        tmpst = tonumber(extrast)
    else
        local keyarr = string.split(rankName,"%.")
        tmpst = tonumber(keyarr[#keyarr])
    end
    local subtime
    if tmpst and tmpst > 0 then
        subtime = (now-tmpst) % (math.pow(10,6))
    else
        subtime = string.sub(now,5,10)
    end
    local tmptime = math.pow(10,6) - tonumber(subtime)
    local newValue = value*math.pow(10,6) + tmptime
    redis:zadd(key,newValue,uid)
    redis:expire(key,30*86400)
end

--关卡冲榜初始化
function checkChallengeRank(rankName)
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local num = redis:zcard(key)
    if num ==0 then
        local now = os.time()
        local keyarr = string.split(rankName,"%.")
        local tmpst = tonumber(keyarr[#keyarr])
        local subtime = (now-tmpst) % (math.pow(10,6))
        local tmptime = math.pow(10,6) - tonumber(subtime)
        local db = getDbo()
        local result = db:getAllRows("select uid,cid from challenge where cid>0 order by cid desc limit 300")
        if result and #result>0 then
            for _,info in ipairs(result) do
                local auid = tonumber(info["uid"])
                local value = tonumber(info["cid"])
                local newValue = value*math.pow(10,6) + tmptime
                redis:zadd(key,newValue,auid)
            end
        end
    end
end

--获取排行榜和我的排名信息
function getRankActive(uid,rankName,num,startIndex)
    local endIndex
    if not startIndex or startIndex < 1 then
        startIndex = 0
    else
        startIndex = startIndex - 1
    end
    if not num then
        endIndex = 199
    else
        endIndex = startIndex + num - 1
    end
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local activeRank = redis:zrevrange(key,startIndex,endIndex)
    local rankArr = {}
    for k,ruid in ipairs(activeRank) do
        local aUserinfo = getCacheUserInfo(tonumber(ruid))
        local tmpvalue = redis:zscore(key,ruid)
        local ruidscore = math.floor(tmpvalue / math.pow(10,6))
        local rankUserData = {uid=ruid,value=ruidscore,name=aUserinfo.name,title=aUserinfo.title,pic = aUserinfo.pic,ptitle=aUserinfo.ptitle,lastpic=aUserinfo.lastpic}
        if k == 1 then
            rankUserData.ptitle = aUserinfo.ptitle
        end
        table.insert(rankArr,rankUserData)
    end
    --我的排名
    local rank = redis:zrevrank(key,uid)
    local myrank
    local myrankArr = {}
    if rank then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,uid)
        local aUserinfo = getCacheUserInfo(tonumber(uid))
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {uid=uid,value=myscore,myrank=myrank,title=aUserinfo.title,ptitle=aUserinfo.ptitle,pic = aUserinfo.pic,lastpic=aUserinfo.lastpic}
    end

    return rankArr,myrankArr
end

--获取我的排名
function getMyRankActive(uid,rankName,isdetail)
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local rank = redis:zrevrank(key,uid)
    
    local myrank
    local myrankArr = {}
    if rank then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,uid)
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {uid=uid,value=myscore,myrank=myrank}
        
        if isdetail then
            local aUserinfo = getCacheUserInfo(tonumber(uid))
            myrankArr.title = aUserinfo.title
            myrankArr.ptitle = aUserinfo.ptitle
            myrankArr.pic = aUserinfo.pic
            myrankArr.lastpic = aUserinfo.lastpic
        end
    end

    return myrankArr
end

--获取军团排名奖励
function getAlliRankActive(id,rankName,num)
    local endIndex
    if not num then
        endIndex = 199
    else
        endIndex = num -1
    end
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local activeRank = redis:zrevrange(key,0,endIndex)
    local rankArr = {}
    for k,allianceId in ipairs(activeRank) do
        local mAlliance = getCacheAllianceInfo(allianceId)
        local tmpvalue = redis:zscore(key,allianceId)
        local ruidscore = math.floor(tmpvalue / math.pow(10,6))
        table.insert(rankArr,{id=tonumber(allianceId),value=ruidscore,name=mAlliance.name})
    end
    
    --我的排名
    local myrank
    local myrankArr = {}
    local rank = redis:zrevrank(key,id)
    if rank and id>0 then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,id)
        local aAlliance = getCacheAllianceInfo(id)
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {uid=id,value=myscore,myrank=myrank,name=aAlliance.name}
    end

    return rankArr,myrankArr
end

--获取我的帮会排名
function getMyAlliRankActive(id,rankName,isdetail)
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local myrank
    local myrankArr = {}
    local rank = redis:zrevrank(key,id)
    if rank and id>0 then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,id)
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {aid=id,value=myscore,myrank=myrank}
        
        if isdetail then
            local aAlliance = getCacheAllianceInfo(id)
            myrankArr.name=aAlliance.name
        end
    end

    return myrankArr
end

-- 记录帮会类活动排行榜的个人涨幅
function setPersonalIncrease(perkey, uid, v)
    local key = perkey .. ".new"
    local redis = getRedis()
    redis:zincrby(key, v, uid)
    redis:expire(key, 864000)
end

-- zadd记录帮会类活动排行榜的个人涨幅
function zaddPersonalIncrease(perkey, uid, v)
    local key = perkey .. ".new"
    local redis = getRedis()
    redis:zadd(key, v, uid)
    redis:expire(key, 864000)
end

-- 从帮会类活动排行榜的个人涨幅中移除某人数据
function rmFromPersonalIncrease(perkey, uid, remflag)
    local key = perkey .. ".new"
    local redis = getRedis()
    local score = redis:zscore(key, uid)
    if remflag then
        redis:zrem(key, uid)
        redis:expire(key, 864000)
    end
    return tonumber(score) or 0
end

-- 获取帮会类活动排行榜的个人涨幅
function getPersonalIncrease(perkey, uid, allianceId)
    local key = perkey .. ".new"
    local redis = getRedis()
    local rankData = redis:zrevrange(key, 0, -1, "withscores")
    local myalliRank = {}
    for _, v in pairs(rankData) do
        local auid = tonumber(v[1])
        -- local aUserinfo = getCacheUserInfo(auid)
        local auobjs = getUserObjs(tonumber(auid), true)
        local aUserinfo = auobjs.getModel('userinfo')
        if not aUserinfo.mygid then
            delCacheUserInfo(auid)
            aUserinfo = getCacheUserInfo(auid)
        end
        local aflag = false
        if aUserinfo.mygid ~= allianceId then
            aflag = true
        end
        local showrank = true
        if aflag then
            showrank = false
            redis:zrem(key, auid)
            redis:expire(key, 864000)
        end
        if showrank then
            table.insert(myalliRank, { tonumber(auid), tonumber(v[2]), aUserinfo.name, aflag })
        end
    end

    local allirank = {}
    local alliRankList = {}
    for k, v in ipairs(myalliRank) do
        table.insert(alliRankList, { uid = tonumber(v[1]), value = v[2], name = v[3], eflag = v[4] })
        if uid == tonumber(v[1]) then
            allirank.myrank = { uid = tonumber(v[1]), value = v[2], myrank = k, name = v[3] }
        end
    end
    allirank.rankList = alliRankList

    return allirank
end

--成就统计
function addAchievementStat(uid,taskType)
    local userCache = getCacheUserInfo(uid)
    local regdt = tonumber(userCache.regdt)
    local today = getWeeTs(regdt)
    local redis  = getRedis()
    local key = "z"..getZoneId().."."..today..".achievementStat"
    local achievementArr = redis:get(key)
    if achievementArr then
        achievementArr = json.decode(achievementArr)
    else
        achievementArr = {}
    end
    if not achievementArr[taskType] then
        achievementArr[taskType] = 0
    end
    achievementArr[taskType] = achievementArr[taskType] + 1
    redis:setex(key, 86400*5, json.encode(achievementArr))
end

--关卡统计
function addChallengeStat(uid,challengeId)
    local userCache = getCacheUserInfo(uid)
    local regdt = tonumber(userCache.regdt)
    local today = getWeeTs(regdt)
    local redis  = getRedis()
    local key = "z"..getZoneId().."."..today..".challengeStat"
    local challendeArr = redis:get(key)
    if challendeArr then
        challendeArr = json.decode(challendeArr)
    else
        challendeArr = {}
    end
    if not challendeArr[challengeId] then
        challendeArr[challengeId] = 0
    end
    challendeArr[challengeId] = challendeArr[challengeId] + 1
    redis:set(key,json.encode(challendeArr))

    --7477记录指定关卡通关时间
    if PLATFORM=="cn_7477mg" then
        local statChangeIDs = {
            ["42"]=1,["205"]=1,["410"]=1,["820"]=1,["1640"]=1,["2460"]=1,["3690"]=1,["4920"]=1,["6150"]=1,["7380"]=1,["10250"]=1
        }
        if challengeId and statChangeIDs[tostring(challengeId-1)] then
            local changeStat7477key = "z"..getZoneId().."."..uid..".challengeStat7477"
            local redis = getRedis()
            local changeStat7477Info = {}
            local changeStat7477Json = redis:get(changeStat7477key)
            if not changeStat7477Json then
                local data = getBakData(changeStat7477key)
                if data then
                    redis:set(changeStat7477key, data)
                    changeStat7477Info = json.decode(data)
                end
            else
                changeStat7477Info = json.decode(changeStat7477Json)
            end
            changeStat7477Info[tostring(challengeId-1)] = os.time()
            local changeStat7477InfoStr = json.encode(changeStat7477Info)
            redis:set(changeStat7477key, changeStat7477InfoStr)
            recordBakData(changeStat7477key, changeStat7477InfoStr)
        end
    end
end

--翰林/练武场模块是否解锁
function studyatkIsUnlock(uid)
    local studyAtkBaseCfg = getConfig("studyAtkBaseCfg")
    local userCache = getCacheUserInfo(tonumber(uid))
    if tonumber(userCache.level) >= tonumber(studyAtkBaseCfg['needLv']) then
        return true
    end

    return false
end

--翰林/练武场模块额外功能是否解锁
function studyatkIsUnlock2(uid)
    local studyAtkBaseCfg = getConfig("studyAtkBaseCfg")
    local userCache = getCacheUserInfo(tonumber(uid))
    if tonumber(userCache.level) >= tonumber(studyAtkBaseCfg['needLv2']) then
        return 1
    end

    return nil
end

function addTaskStat(uid,taskId)
    local now = os.time()
    local today = getWeeTs(now)
    local redis  = getRedis()
    local key = "z"..getZoneId().."."..today.."_taskstat"
    local taskArr = redis:get(key)
    if taskArr then
        taskArr = json.decode(taskArr)
    else
        taskArr = {}
    end
    if not taskArr[taskId] then
        taskArr[taskId] = 0
    end
    taskArr[taskId] = taskArr[taskId] + 1
    redis:set(key,json.encode(taskArr))
    redis:expire(key,172800)
end

--任务统计分渠道
function addTaskStatByChannel(uid,taskId,channelId)
    local channelId = tostring(channelId)
    local now = os.time()
    local today = getWeeTs(now)
    local redis  = getRedis()
    local key = "z"..getZoneId().."."..today.."_taskstatbychannel"
    local taskArr = redis:get(key)
    if taskArr then
        taskArr = json.decode(taskArr)
    else
        taskArr = {}
    end
    if not taskArr[channelId] then
        taskArr[channelId] = {}
    end
    if not taskArr[channelId][taskId] then
        taskArr[channelId][taskId] = 0
    end
    taskArr[channelId][taskId] = taskArr[channelId][taskId] + 1
    redis:set(key,json.encode(taskArr))
    redis:expire(key,172800)
end

--检测是否出现天赐鸿福
function checkLuckyAppear(uid,ltype)
    local uobjs = getUserObjs(uid,true)
    --开启封地4.0之后需要在关卡X之后才能生效
    if isSwitchTrue(uid,"openFiefTo4") then
        local gameProject = getConfig("gameProjectCfg")
        local needChallenge4 = gameProject.needChallenge4
        local mChallenge = uobjs.getModel('challenge')
        if mChallenge.cid <= needChallenge4 then
            return false
        end
    end
    local mUserinfo = uobjs.getModel('userinfo')
    local mOtherinfo = uobjs.getModel('otherinfo')
    local dailyLuckCfg = getConfig("dailyLuckCfg")
    local vipCfg = getConfig("vipCfg")
    local godextranum = mOtherinfo.getLuckyAdd() or 0
    local maxLuckyNum = vipCfg[tostring(mUserinfo.vip)].dailyLuckNum + godextranum
    local useLuckNum = mOtherinfo.lucky[ltype] or 0
    local flag = false
    if maxLuckyNum>useLuckNum then
        local rate = dailyLuckCfg[ltype][1]
        local v = dailyLuckCfg[ltype][2]
        if rand(1,100) <= rate*100 then
            mOtherinfo.lucky[ltype] = useLuckNum + 1
            return v
        end
    end
    return flag
end

--获取世界boss基本信息
function getDailyBoss2Info()
    local redis = getRedis()
    local key = "z"..getZoneId()..".DailyBoss2Info"
    local DailyBoss2Info = redis:get(key)

    if not DailyBoss2Info then
        DailyBoss2Info = getBakData(key)
    end

    if not DailyBoss2Info then
        local now = os.time()
        local today = getWeeTs(now)
        local dailyBossCfg = getConfig("dailyBossCfg")
        local initHp = dailyBossCfg.boss2.iniHp
        local iniScore = dailyBossCfg.boss2.iniScore
        DailyBoss2Info ={ hp = initHp,score = iniScore,time = today,success = false}
        redis:set(key,json.encode(DailyBoss2Info))
        return DailyBoss2Info
    else
        return DailyBoss2Info and json.decode(DailyBoss2Info)
    end
end

--获取boss副本开始时间
function getDailyBossTime()
    local dailyBossCfg = getConfig("dailyBossCfg")
    local boss1Time = copyTable(dailyBossCfg.boss1Time)
    local boss2Time = copyTable(dailyBossCfg.boss2Time)
    if PLATFORM == "test" or getZoneId()==1000 then
        local redis = getRedis()
        local key = "z"..getZoneId()..".DailyBossTime"
        local dailyBossTime = redis:get(key)
        if dailyBossTime then
            dailyBossTime = json.decode(dailyBossTime)
            boss1Time = {dailyBossTime[1],dailyBossTime[2]}
            boss2Time = {dailyBossTime[3],dailyBossTime[4]}
        end
    end
    return boss1Time,boss2Time
end

--获取boss副本期号
function getDailyBossVersion()
    local now = os.time()
    local today = getWeeTs(now)
    local bossType = 1
    -- local HpRate
    local startFlag = false
    local version = today
    local boss2StartTime
    local boss1Time,boss2Time = getDailyBossTime()
    if now>=boss1Time[1]*3600+today and now<=boss1Time[2]*3600+today then
        startFlag = true
    elseif now>=boss2Time[1]*3600+today and now<=boss2Time[2]*3600+today then
        startFlag = true
    end
    
    if now>boss1Time[2]*3600+today then
        bossType = 2
        version = boss1Time[2]*3600+today
        boss2StartTime = boss2Time[1]*3600+today
    end
    return version,bossType,startFlag,boss2StartTime
end

--获取当前期号Boss血量
function getDailyBoss2Hp()
    local now = os.time()
    local today = getWeeTs(now)
    local redis = getRedis()
    local key = "z"..getZoneId()..".DailyBossHp."..today
    local ret = redis:get(key)
    local DailyBossHp
    if not ret then
        local dailyBossCfg = getConfig("dailyBossCfg")
        local bossInfo = getDailyBoss2Info()
        if bossInfo.time < today then
            if bossInfo.success then
                local killAddHp = 0
                local killAddScore = 0
                if bossInfo.lasttime then
                    if bossInfo.lasttime <= 180 then
                        killAddHp = math.floor(bossInfo.hp*1)
                        killAddScore = math.floor(killAddHp*dailyBossCfg.boss2.killAddScore/dailyBossCfg.boss2.killAddHp)
                    elseif bossInfo.lasttime <= 300 then
                        killAddHp = math.floor(math.max(bossInfo.hp*0.57,killAddHp))
                        killAddScore = math.floor(killAddHp*dailyBossCfg.boss2.killAddScore/dailyBossCfg.boss2.killAddHp)
                    elseif bossInfo.lasttime <= 600 then
                        killAddHp = math.floor(math.max(bossInfo.hp*0.26,killAddHp))
                        killAddScore = math.floor(killAddHp*dailyBossCfg.boss2.killAddScore/dailyBossCfg.boss2.killAddHp)
                    end
                end
                bossInfo.hp = bossInfo.hp + killAddHp
                bossInfo.score = bossInfo.score + killAddScore
            else

                local runReduceHp = (bossInfo.hp*0.06)
                local runReduceScore = math.floor(runReduceHp*dailyBossCfg.boss2.runReduceScore/dailyBossCfg.boss2.runReduceHp)
                bossInfo.hp = math.floor(bossInfo.hp - runReduceHp)
                if bossInfo.hp < dailyBossCfg.boss2.iniHp then
                    bossInfo.hp = dailyBossCfg.boss2.iniHp
                end
                bossInfo.score = math.floor(bossInfo.score - runReduceScore)
                if bossInfo.score < dailyBossCfg.boss2.iniScore then
                    bossInfo.score = dailyBossCfg.boss2.iniScore
                end
            end
            bossInfo.time = today
            bossInfo.success = false
            bossInfo.lasttime = nil
            local basekey = "z"..getZoneId()..".DailyBoss2Info"
            redis:set(basekey,json.encode(bossInfo))
            recordBakData(basekey,json.encode(bossInfo))
        end
        
        DailyBossHp = bossInfo.hp
        redis:set(key,DailyBossHp)
        redis:expire(key,432000)
        return DailyBossHp,bossInfo.hp
    else
        local bossInfo = getDailyBoss2Info()
        DailyBossHp = tonumber(ret) or 0
        return DailyBossHp,bossInfo.hp --返回：战斗实时血量,当日总血量
    end
end

--获取Boss击杀信息
function getBossKillData()
    local returnData = {}
    local key = "z" .. getZoneId() .. ".BosskillData"
    local redis = getRedis()
    local BosskillData = redis:get(key)
    if not BosskillData then
        local data = getBakData(key)
        if data then
            redis:set(key, data)
            BosskillData = json.decode(data)
        else 
            BosskillData = {}
        end
    else
        BosskillData = json.decode(BosskillData)
    end
    for k,data in ipairs(BosskillData) do
        returnData[k] = {}
        if data[1] then
            local uid = tonumber(data[1])
            returnData[k].uid = uid
            local userCache = getCacheUserInfo(uid)
            returnData[k].name = userCache["name"]
            returnData[k].level = userCache["level"]
            returnData[k].time = tonumber(data[2])
        end
        if k>100 then
            break
        end
    end
    return returnData
end

--获取最后击杀者的名称
function getBossKillName()
    -- local returnData = {}
    local key = "z" .. getZoneId() .. ".BosskillData"
    local redis = getRedis()
    local BosskillData = redis:get(key)
    if not BosskillData then
        local data = getBakData(key)
        if data then
            redis:set(key, data)
            BosskillData = json.decode(data)
        else 
            BosskillData = {}
        end
    else
        BosskillData = json.decode(BosskillData)
    end
    if BosskillData[1] and BosskillData[1][1] then
        local uid = tonumber(BosskillData[1][1])
        local userCache = getCacheUserInfo(uid)
        return userCache["name"]
    end
    return ""
end

--记录Boss击杀信息
function addBossKillData(uid)
    -- local returnData = {}
    local key = "z" .. getZoneId() .. ".BosskillData"
    local redis = getRedis()
    local BosskillData = redis:get(key)
    if not BosskillData then
        local data = getBakData(key)
        if data then
            BosskillData = json.decode(data)
        else 
            BosskillData = {}
        end
    else
        BosskillData = json.decode(BosskillData)
    end
    table.insert(BosskillData,1,{uid,os.time()})
    local dataStr = json.encode(BosskillData)
    redis:set(key, dataStr)
    recordBakData(key,dataStr)
end

--获取公共信息
function getLogInfo(key,ltype)
    --ltype 1副本log  2 军团副本log
    local returnData = {}
    local redis = getRedis()
    local logData = redis:get(key)
    if not logData then
        local data = getBakData(key)
        if data then
            redis:setex(key, 86400*10, data)
            logData = json.decode(data)
        else 
            logData = {}
        end
    else
        logData = json.decode(logData)
    end
    for k,data in ipairs(logData) do
        returnData[k] = {}
        if data[1] then
            local uid = tonumber(data[1])
            local uobjs = getUserObjs(uid,true)
            local mUserinfo = uobjs.getModel('userinfo')
            returnData[k].uid = uid
            --returnData[k].title = mUserinfo.title
            --returnData[k].ptitle = mUserinfo.ptitle
            returnData[k].name = mUserinfo.name
            --returnData[k].level = mUserinfo.level
            returnData[k].time = tonumber(data[2])
            if ltype == 1 then
                returnData[k].rewards = tostring(data[3])
                returnData[k].bossLv = data[4] or mUserinfo.level
            elseif ltype == 2 then
                returnData[k].title = mUserinfo.title
                returnData[k].ptitle = mUserinfo.ptitle
                returnData[k].level = mUserinfo.level
                
                returnData[k].dps = tonumber(data[3])
                returnData[k].servantId = tostring(data[4])
            end

        end
    end
    return returnData
end

--记录公共信息
function addLogInfo(key,info,num, isindb)
    num = num or 100
    local redis = getRedis()
    local logData = redis:get(key)
    if not logData then
        local data = getBakData(key)
        if data then
            logData = json.decode(data)
        else 
            logData = {}
        end
    else
        logData = json.decode(logData)
    end
    table.insert(logData,1,info)
    if #logData >= num then
        table.remove(logData,#logData)
    end
    local dataStr = json.encode(logData)
    redis:setex(key, 86400*15, dataStr)
    
    if isindb==nil or isindb then
        recordBakData(key,dataStr)
    end
end

--设置活动版本时间
function addActivityVersion(version,st,et)
    local key = "z" .. getZoneId() .. ".shopVersionData"
    local redis = getRedis()
    local shopVersionData = redis:get(key)
    if not shopVersionData then
        local data = getBakData(key)
        if data then
            shopVersionData = json.decode(data)
        else
            shopVersionData = {}
        end
    else
        shopVersionData = json.decode(shopVersionData)
    end
    local now = os.time()
    local flag = true
    for k=#shopVersionData,1,-1 do
        --检查生效数据
        local v = shopVersionData[k]
        if st<now and v.version==version and v.st<now then
            table.remove(shopVersionData,k) 
        end
        if st>now and v.version==version and v.st>now then
            table.remove(shopVersionData,k)
        end
        if v.et < now then
            table.remove(shopVersionData,k)
        end
    end
    if flag then
        if now > st and now < et then
            shopVersionData = {}
        end
        table.insert(shopVersionData,{version=version, st=st, et=et })
        local dataStr = json.encode(shopVersionData)
        redis:set(key, dataStr)
        recordBakData(key,dataStr)
    end
end

--获取活动版本配置设置信息   
function getActivityVersion()
    local activityVersion = {version=0, sortid = 0, st=nil, et=nil }
    local shopVArr = getConfig("shopActivityVerCfg") -- ["rankActive-1"]={shopid=商店ID,sortid=权重},
    
    local sysActive = require "lib.active"
    --拉取正在进行活动（不包括前置时间）
    local actives = sysActive:getRealNoExpiredActive()
    local now = os.time()
    for ak,actInfo in pairs(actives) do
        if shopVArr[ak] and shopVArr[ak].shopid then
            local et = actInfo.et-86400
            if now < et then
                if shopVArr[ak].sortid > activityVersion.sortid then
                    activityVersion.active = ak
                    activityVersion.sortid = shopVArr[ak].sortid
                    activityVersion.version = shopVArr[ak].shopid
                    activityVersion.st = actInfo.st
                    activityVersion.et = et
                end
                --break
            end
        end
    end

    return activityVersion
end

--征伐随机兵力
function randConquestSoldier(cid)
    local conquestCfg = getConfig('conquestCfg')
    local max = conquestCfg[tostring(cid)].soldierUp
    local min = conquestCfg[tostring(cid)].soldierLow
    local soldier = rand(min, max)
    local atk = math.ceil(soldier/10)
    return soldier,atk
end

--征伐随机奖励
function randConquestReward(uid, cid)
    local conquestCfg = getConfig('conquestCfg')
    cid = tostring(cid)
    local uobjs = getUserObjs(uid,true)

    local rewards = {}
    for num=1,5,1 do
        local rewardNum = "reward"..tostring(num)
        local randRewards = {}
        if conquestCfg[tostring(cid)][rewardNum] then
            for _,v in ipairs(conquestCfg[tostring(cid)][rewardNum]) do
                randRewards[v[1]] = v[2]
            end
            local rkey = getKeyByRnd(randRewards)

            --红颜魅力
            if num==1 and conquestCfg[cid].reward1Ratio and conquestCfg[cid].reward1 then
                -- local reward1Ratio = conquestCfg[cid].reward1Ratio
                local reward1 = rkey
                local mWife = uobjs.getModel('wife')
                local randWifes = {}
                for k,_ in pairs(mWife.info) do
                    table.insert(randWifes, k)
                end
                local randKey = rand(1, #randWifes)
                local wifeid = randWifes[randKey]

                --返前端新的奖励格式:12_红颜id_num
                local reward_arr = string.split(reward1, "%_")
                reward1 = "12_"..tostring(wifeid).."_"..tostring(reward_arr[3])
                rkey = reward1
            end

            --门客技能经验/书籍经验
            if num==2 and conquestCfg[cid].reward2Ratio and conquestCfg[cid].reward2 then
                -- local reward2Ratio = conquestCfg[cid].reward2Ratio
                local reward2 = rkey
                local mServant = uobjs.getModel('servant')
                local randServant = {}
                for k,_ in pairs(mServant.info) do
                    table.insert(randServant, k)
                end
                local randKey = rand(1, #randServant)
                local servantid = randServant[randKey]

                --返回前端新的奖励格式
                local reward2Arr = string.split(reward2, "%_")
                reward2 = tostring(reward2Arr[1]).."_"..tostring(servantid).."_"..tostring(reward2Arr[3])
                rkey = reward2
            end

            table.insert(rewards,rkey)
        end
    end

    return rewards
end

--根据区服获取指定商城配置
function getshopNewCfgFunc()
    --本地使用14做间隔;更新时替换为正式区服 正式间隔区服为652
    local replaceZid = 652 --14
    local shopNewCfg=getConfig('shopNewCfg')
    --微信平台 区服大于指定服时,使用另一份配置
    if PLATFORM == "cn_wx" and getZoneId() > replaceZid then
        shopNewCfg = getConfig('shopNew2Cfg')
    end
    return shopNewCfg
end

--根据区服获取指定通商配置
function getTradeCfgFunc()
    local replaceZid = 652
    local tradeCfg = getConfig('tradeCfg')
    --微信平台 区服大于指定服时,使用另一份配置
    if PLATFORM == "cn_wx" and getZoneId() > replaceZid then
        tradeCfg = getConfig('trade2Cfg')
    end
    return tradeCfg
end

--根据区服获取指定通商配置
function getDinnerCfgFunc()
    local replaceZid = 652
    local dinnerCfg = getConfig('dinnerCfg')
    --微信平台 区服大于指定服时,使用另一份配置
    if PLATFORM == "cn_wx" and getZoneId() > replaceZid then
        dinnerCfg = getConfig('dinner2Cfg')
    end
    return dinnerCfg
end

--通商随机奖励
function randTradeReward(cid)
    local tradeCfg = getTradeCfgFunc()
    cid = tostring(cid)

    local rewards = {}
    for num=1,6,1 do
        local rewardNum = "reward"..tostring(num)
        local randRewards = {}
        if tradeCfg[tostring(cid)][rewardNum] then
            for _,v in ipairs(tradeCfg[tostring(cid)][rewardNum]) do
                randRewards[v[1]] = v[2]
            end
            local rkey = getKeyByRnd(randRewards)

            table.insert(rewards,rkey)
        end
    end

    return rewards
end

--推送社交消息通知: 1擂台仇人 2练武场驱赶
function pushSocialMsg(mUid, friendUid, dtype)
    friendUid = tonumber(friendUid)
    if friendUid>0 then
        local uobjs = getUserObjs(friendUid,true)
        local mGameinfo = uobjs.getModel('gameinfo')
        if mGameinfo.pid then
            local pid_arr = string.split(mGameinfo.pid, "%_")
            local openid = pid_arr[2]
            local content = {frd=openid, type=dtype}
            regPushMsg(mUid, "gamebarmsg", content)
        end
    end
end

--检测平台
function checkPlatForm(dtype)
    local compareCond = {
        checkviplimit = {'test',"cn_wx","cn_37wx","cn_7477mg","cn_wb","wg_sea","wg_eur","cn_newwd"},
    }

    local comparePlat = compareCond[dtype]
    if comparePlat then
        if table.contains(comparePlat, PLATFORM) then
            return true
        end
    end

    return false
end

function fixPlatformRechargeCfg(platName,plat,reqplat)
    local baseCfg = getConfig('baseCfg')
    local nowPlatform = baseCfg.APPPLATFORM

    local rechargeCfg = copyTable(getConfig("rechargeCfg"))
    local orderCfg = getConfig('orderCfg')
    if plat and orderCfg[plat] then
        for gid,orderid in pairs(orderCfg[plat]) do
            if rechargeCfg[gid] then
                rechargeCfg[gid].orderid = orderid
            end
        end
    elseif platName and orderCfg[platName] then 
        for gid,v in pairs(rechargeCfg) do
            local forgid = v.sameGid or gid --映射同价钱多档位
            if orderCfg[platName][forgid] then
                v.orderid = orderCfg[platName][forgid]
            end
        end
    elseif orderCfg[nowPlatform] then
        for gid,orderid in pairs(orderCfg[nowPlatform]) do
            if rechargeCfg[gid] then
                rechargeCfg[gid].orderid = orderid
            end
        end
    end

    --韩国处理
    if nowPlatform=="kr" or nowPlatform=="krnew" then
        if tonumber(plat) == 1003018001 then --krnew ios
            for k,v in pairs(rechargeCfg) do
                v.cost = v.iosCostK2
                v.gemCost = v.iosGemCost
                v.firstGet = v.iosFirstGet
            end
        else
            for k,v in pairs(rechargeCfg) do
                v.cost = v.costK2
            end
        end
    end

    if nowPlatform=="jp" then
        if tonumber(plat) == 1003002006 then--日本mobo处理
            for k,v in pairs(rechargeCfg) do
                if v.costMobo then
                    v.cost = v.costMobo
                end
            end
        elseif tonumber(plat) == 1003002001 then --jp ios
            for k,v in pairs(rechargeCfg) do
                v.cost = v.iosCost
                v.gemCost = v.iosGemCost
                v.firstGet = v.iosFirstGet
            end
        end
    end

    --cn_mm
    if tonumber(plat) == 1003011002 then
        rechargeCfg = copyTable(getConfig("extraRechargeCfg"))
    end

    local chargeArr = {"test","cn_wb"}
    if not table.contains(chargeArr,nowPlatform) then
        rechargeCfg["g12"] = nil 
        rechargeCfg["g13"] = nil 
    end
    return rechargeCfg
end

function checkPunishCode(uid,flag)
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local now = os.time()
    local extend = 86400
    if flag then
        extend = 0
    end
    for k,v in pairs(mActivity.info) do
        if v.aid == "punish" then
            local endtime = v.et - extend
            if now<endtime and now>v.st and v.code~=2 then --code不为2时替换 2变为基础版
                return v.code
            end
        end 
    end
    return false
end

--替换奖励
function replacePunishRewards(rewards,code)
    local punishCfg = getConfig("punishCfg","activecfg")
    local changeReward = punishCfg[code].changeReward
    local rewards_table = string.split(rewards, "%|")
    local newrewads = ""
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        if newrewads == "" then
        else
            newrewads = newrewads.."|"
        end

        if rewardType == 6 and changeReward[rewardId] then
            newrewads = newrewads..rewardType.."_"..changeReward[rewardId].."_"..rewardNum
        else
            newrewads = newrewads..v
        end
    end
    return newrewads
end

function checkRescueCode(uid,flag)
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local now = os.time()
    local extend = 86400
    if flag then
        extend = 0
    end
    for k,v in pairs(mActivity.info) do
        if v.aid == "rescue" then
            local endtime = v.et - extend
            if now<endtime and now>v.st then --code不为2时替换 2变为基础版
                return v.code
            end
        end 
    end
    return false
end

--替换奖励
function replaceRescueRewards(rewards,code)
    local rescueCfg = getConfig("rescueCfg","activecfg")
    local changeReward = rescueCfg[code].changeReward
    local rewards_table = string.split(rewards, "%|")
    local newrewads = ""
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        if newrewads == "" then
        else
            newrewads = newrewads.."|"
        end

        if rewardType == 6 and changeReward[rewardId] then
            newrewads = newrewads..rewardType.."_"..changeReward[rewardId].."_"..rewardNum
        else
            newrewads = newrewads..v
        end
    end
    return newrewads
end

--替换奖励
function replaceSpecialRewards(rewards,befReward,repRerard)
    local rewards_table = string.split(rewards, "%|")
    local newrewads = ""
    for k, v in ipairs(rewards_table) do
        if newrewads == "" then
        else
            newrewads = newrewads.."|"
        end

        if befReward == v then
            newrewads = newrewads..repRerard
        else
            newrewads = newrewads..v
        end
    end
    return newrewads
end

--得到定时开关
function getTimerSwitch(uid,plat)
    local key = "z" .. getZoneId() .. ".theTimerSwitch"
    local redis = getRedis()
    local switchData = redis:get(key)
    if not switchData then
        local data = getBakData(key) or "{}"
        if data then
            redis:setex(key, 86400, data)
            switchData = json.decode(data)
        end
    else
        switchData = json.decode(switchData)
    end

    return switchData
end

--删除定时开关
function delTimerSwitch(switchkey,weekkey)
    local key = "z" .. getZoneId() .. ".theTimerSwitch"
    local switchData = getTimerSwitch()
    if not switchData or not switchData[switchkey] or not switchData[switchkey][weekkey] then
        return false
    end
    switchData[switchkey][weekkey] = nil
    if table.length(switchData[switchkey]) <= 0 then
        switchData[switchkey] = nil
    end

    local redis = getRedis()
    redis:set(key,json.encode(switchData))
    recordBakData(key,json.encode(switchData))

    return true
end

function isSwitchTrue(uid,switchKey)
    switchKey = tostring(switchKey)
    local switchData=getSwitchData(uid)
    if switchData[switchKey] and switchData[switchKey]==1 then
        return true
    end

    return false
end

--获取功能开关-公共缓存
function getSwitchData(uid,plat)
    local tmpdata = getGameSwitch()
    if tmpdata and next(tmpdata) then
        return tmpdata
    end
    local key = "z" .. getZoneId() .. ".gameSwitch"
    local redis = getCommonRedis()
    local switchData = redis:get(key)
    if not switchData then
        local data = getBakData(key)
        if data then
            redis:set(key, data)
            switchData = json.decode(data)
        end
    else
        switchData = json.decode(switchData)
    end

    if not switchData then
        switchData = {}
    end

    --定时开关
    local timerswitch = getTimerSwitch() or {}
    local now = os.time()
    local weektime = getWeekTime(now)
    for sid,sinfo in pairs(timerswitch) do
        local wkey = "weekday" .. weektime
        local tinfo = sinfo[wkey]
        if tinfo then
            local addtime = getWeeTs(now)
            local dst = tonumber(tinfo.st) or 0
            local det = tonumber(tinfo.et) or 90000
            local st = addtime + dst
            local et = addtime + det
            if now <= et and now >= st then
                switchData[sid] = 1
            else
                switchData[sid] = nil
            end
        end
    end

    setGameSwitch(switchData)
    return switchData
end

--封号列表
function getLockUidList()
    local redis = getRedis()
    local key = "z"..getZoneId()..".lockUidArr"
    local lockData = redis:get(key)
    if not lockData then
        lockData = {}
    else
        lockData = json.decode(lockData)
    end
    return lockData
end

--封号列表
function getLockPidList()
    local redis = getRedis()
    local key = "z"..getZoneId()..".lockPidArr"
    local lockData = redis:get(key)
    if not lockData then
        lockData = {}
    else
        lockData = json.decode(lockData)
    end
    return lockData
end

--同时在线的uid列表
function getOnlineUidList()
    local redis = getRedis()
    local key = "z"..getZoneId()..".onlineuids"
    local lockData = redis:get(key)
    if not lockData then
        lockData = {}
    else
        lockData = json.decode(lockData)
    end
    return lockData
end

function getChatBlockSortList(list)
    local listSortFunc = function(a,b)
        if a[4]==b[4] then
            if a[3]==b[3] then
                return false
            else
                return a[3]>b[3]
            end
        else
            return a[4]>b[4]
        end
    end

    local sortlist={}
    local mzid = getZoneId()
    for _,v in ipairs(list) do
        local zid = getUserTrueZid(v)
        if zid == mzid then
            local uobjs = getUserObjs(v,true)
            local mUserinfo = uobjs.getModel('userinfo')
            table.insert(sortlist,{mUserinfo.uid,mUserinfo.olt,mUserinfo.level,mUserinfo.power,mUserinfo.name,mUserinfo.pic,mUserinfo.mygname,mUserinfo.ptitle,zid})
        else
            local cmdName = "inviteadminapi.getuinfo"
            local responseData = getCrossinfoApi(v,zid,cmdName,{})
            if responseData and responseData.data.uinfo then
                local udata = responseData.data.uinfo
                table.insert(sortlist,{udata.uid,udata.olt,udata.level,udata.power,udata.name,udata.pic,udata.mygname,json.decode(udata.ptitle) or udata.ptitle,zid})
            end
        end
    end

    table.sort(sortlist, listSortFunc)
    return sortlist
end

--增加跨服记录
function setCrossRecord(rewards,uid,zidArr,extra,st)
    local rewards_table = string.split(rewards, "%|")
    local titleCfg = getConfig('titleCfg')
    local zid = getZoneId()
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        if rewardType == 11 and titleCfg[rewardId].isTitle == 1 then
            if titleCfg[rewardId].isCross == 1 then

                local uobjs = getUserObjs(uid,true)
                local mUserinfo = uobjs.getModel('userinfo')
                if (PLATFORM == "cn_37wx" or PLATFORM == "cn_7477mg") and titleCfg[rewardId].lastTime and st then
                    local et = st+titleCfg[rewardId].lastTime
                    setCrossTitle(rewardId,uid,getZoneId(),mUserinfo.name,nil,st,et) --记录跨服称号
                else
                    setCrossTitle(rewardId,uid,getZoneId(),mUserinfo.name) --记录跨服称号
                end
                
                --增加额外消息(加入本服聊天与跑马灯)
                if extra and extra.spectype then
                    --本服聊天
                    if extra.allianceId then
                        local aobjs = getallianceObjs(tonumber(extra.allianceId),true)
                        local mAlliance = aobjs.getModel('alliance')
                        extra.aname = mAlliance.name
                    end
                    extra.name = mUserinfo.name
                    extra.pic = mUserinfo.pic
                    extra.title = mUserinfo.title
                    extra.level = mUserinfo.level
                    extra.zid = zid
                    extra.uid = uid
                    sendMessageToChat(0,1,{spectype=extra.spectype,uid=uid,level=extra.level,title=extra.title,pic=extra.pic,zid=extra.zid,aname=extra.aname,name=extra.name,rank=1,titleId=rewardId,act=extra.act})
                    if extra.spectype == 1 then
                        --跑马灯
                        pushMsgToRollQueue(uid,rewardId,{uid=extra.uid,zid=extra.zid,aname=extra.aname,name=extra.name},os.time(),"11")
                    end
                end

                if zidArr and type(zidArr)=="table" and next(zidArr) and table.length(zidArr)>0 then
                    for _,uzid in pairs(zidArr) do
                        if uzid and tonumber(uzid)~=tonumber(zid) then
                            --增加额外消息(加入本服聊天与跑马灯)
                            local cmdName = "inviteadminapi.settitle"
                            getCrossinfoApi(uzid*100000+1,uzid,cmdName,{titleId= rewardId,auid =uid,azid = zid,aname = mUserinfo.name,extra=extra,acst=st})
                        end
                    end
                end
            end
        end
    end
end

--发送聊天信息到本服及跨服
function sendMsgToZidArr(extra,zidArr)
    sendMessageToChat(0,1,extra)
    if zidArr and type(zidArr)=="table" and next(zidArr) and table.length(zidArr)>0 then
        for _,uzid in pairs(zidArr) do
            if uzid and tonumber(uzid)~=tonumber(getZoneId()) then
                --发送消息至其他服的聊天
                local cmdName = "inviteadminapi.settitle"
                getCrossinfoApi(uzid*100000+1,uzid,cmdName,{azid = getZoneId(),auid = extra.uid,aname = extra.aname,extra=extra})
            end
        end
    end
end

--聊天等级
function getchatLevel()
    local key = "z"..getZoneId()..".chatLevel"
    local redis = getRedis()
    local chatData = redis:get(key)
    if not chatData then
        chatData = {}
        local chatSqlData = getBakData(key)
        if chatSqlData then
            chatData = json.decode(chatSqlData)
            redis:set(key,json.encode(chatData))
        end
    else
        chatData = json.decode(chatData)
    end
    if next(chatData) then
        return chatData["chatlevel"]
    end
    if getZoneId() ~= 1999 then
        local db2000 = getDbo(2000)
        local otherkey = "z2000.chatLevel"
        local result = db2000:getRow("select * from backdata where id='"..otherkey.."';")
        if result and result["info"] then
            local chatData = json.decode(result["info"])
            return chatData["chatlevel"]
        end
    end
    return false
end

--ios官品限制
function getioslvlimit(channel)
    local db = getDbo(2000)
    local key= "ioslvlimitbychannel"

    local result = db:getRow("select * from backdata where id='"..key.."';")
    if result and result["info"] then
        local datainfo = {}
        datainfo = json.decode(result["info"])
        if datainfo[tostring(channel)] then
            return tonumber(datainfo[tostring(channel)])
        elseif datainfo["generalchannel"] then
            return tonumber(datainfo["generalchannel"])
        end
    end

    local redis = getRedis()
    local lvlimitkey= "z"..getZoneId()..".ioslvlimit"
    local lvlimitinfo = redis:get(lvlimitkey)
    local lvinfo
    if lvlimitinfo then
        lvinfo = json.decode(lvlimitinfo)
    else
        local lvlimitdata = getBakData(lvlimitkey)
        if lvlimitdata then
            lvinfo = json.decode(lvlimitdata)
            redis:set(lvlimitkey, json.encode(lvinfo))
        end
    end
    if lvinfo and lvinfo.lvlimit then
        return tonumber(lvinfo.lvlimit)
    end
end

--自己的头像框
function getMePhotoTitle(uid)
    uid = tonumber(uid)
    local uobjs = getUserObjs(uid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    if mUserinfo.ptitle and tonumber(mUserinfo.ptitle.ptid) and tonumber(mUserinfo.ptitle.ptid)>0 then
        return mUserinfo.ptitle
    end
    return ''
end

function getshareText(plat)
    local config = getConfig('config')
    local http = require("socket.http")
    local zid = getZoneId()
    local getzidUrl =  config['z'..zid].tankglobalUrl.."?t=getsharetext&channel="..plat
    local sharetext = http.request(getzidUrl)
    if sharetext then
        return sharetext
    end
    return false
end

function getZoneFirstUid(zid)
    return tonumber(zid)*1000000+1
end

--皇帝跑马灯
function emperosLoginRollQueue(uid,lasttime)
    local now = os.time()
    if now-lasttime>10*60 then
    --if now-lasttime>60 then
        pushMsgToRollQueue(uid,'','',now,6,'')
    end
end

--设置皇帝
function setPromoteKing(uid,version,et,acet)
    if uid<=0 or version<=0 then
        return false
    end

    local promoteKing
    local key = "z" .. getZoneId() .. ".beTheKing"
    local redis = getRedis()
    local promoteKingJson = redis:get(key)
    if not promoteKingJson then
        local data = getBakData(key)
        if data then
            redis:set(key, data)
            promoteKing = json.decode(data)
        end
    else
        promoteKing = json.decode(promoteKingJson)
    end

    if not promoteKing then
        promoteKing = {rank = {}}
    end

    promoteKing.version = version
    promoteKing.king = uid
    promoteKing.sign = ""
    promoteKing.et = et

    local uobjs = getUserObjs(uid)
    local mUserinfo = uobjs.getModel('userinfo')

    local length = #promoteKing.rank
    if length>0 then
        if tonumber(promoteKing.rank[length][1])==uid and tonumber(promoteKing.rank[length][5])==version then
        else
            table.insert(promoteKing.rank,{uid,mUserinfo.name,os.time(),0,version})
        end
    else
        table.insert(promoteKing.rank,{uid,mUserinfo.name,os.time(),0,version})
    end

    local kingData = json.encode(promoteKing)
    redis:set(key,kingData)
    recordBakData(key,kingData)

    --称号/头像框
    local mItem = uobjs.getModel('item')
    mItem.tinfo["3201"] = 2
    mItem.tinfo["4006"] = 2
    for k,v in pairs(mItem.tinfo) do
        if v==2 and k~="3201" and k~="4006" then
            mItem.tinfo[k] = 1
        end
    end

    mUserinfo.title = "3201"
    mItem.tupinfo["3201"] = mItem.tupinfo["3201"] or {}
    mItem.tupinfo["3201"].tnum = mItem.tupinfo["3201"].tnum or 0
    mItem.tupinfo["3201"].tnum = mItem.tupinfo["3201"].tnum + 1
    local titleCfg = getConfig('titleCfg')
    local tlvarr = titleCfg["3201"].emperorLvUpNeed
    for lv,neednum in ipairs(tlvarr) do
        if mItem.tupinfo["3201"].tnum >= neednum then
            mItem.tupinfo["3201"].tlv = lv
        else
            break
        end
    end
    if PLATFORM == "cn_37wx" and acet and titleCfg["3201"].lastTime then
        local now = os.time()
        if mItem.tupinfo["3201"] and mItem.tupinfo["3201"].et and mItem.tupinfo["3201"].et > now then
            --当传入指定开始时间,不进行结束时间追加,而是直接更新结束时间
            local updateEt = (acet or mItem.tupinfo["3201"].et) + titleCfg["3201"].lastTime
            if updateEt>mItem.tupinfo["3201"].et then
                mItem.tupinfo["3201"].et = updateEt
            end
        else
            mItem.tupinfo["3201"].st = acet
            mItem.tupinfo["3201"].et = acet+titleCfg["3201"].lastTime
        end
    end
    mUserinfo.titlelv = mItem.getNewTitleLvNum("3201")
    mUserinfo.ptitle = mUserinfo.ptitle or {}
    mUserinfo.ptitle.ptid = "4006"

    delCacheUserInfo(uid)
    regReturnModel({"userinfo","item"})
end

function gmSetPromoteKing(uid,version,et)
    setPromoteKing(uid,version,et)
end

--去掉人望奖励
function removePrestigeRewards(rewards)
    local rewards_table = string.split(rewards, "%|")
    local newrewads
    for k,v in ipairs(rewards_table) do
        local v_arr = string.split(v, "%_")
        local vtype = tonumber(v_arr[1])
        if vtype==17 then
        else
            if not newrewads then
                newrewads = v
            else
                newrewads = newrewads.."|"..v
            end
        end
    end
    return newrewads
end

function addsharedot(type,dot)
    if dot == "a" then
        dot = "wife_"..dot
    elseif dot == "b" then
        dot = "child_"..dot
    end
    local now = os.time()
    local date = getWeeTs(now)

    local redis = getRedis()
    local key = "z"..getZoneId()..".sharetext_data."..date
    local sharedata_stat = redis:get(key)
    if not sharedata_stat then
        sharedata_stat = {}
    else
        sharedata_stat = json.decode(sharedata_stat)
    end
    if not sharedata_stat[dot] then
        sharedata_stat[dot] = {}
    end
    if not sharedata_stat[dot][type] then
        sharedata_stat[dot][type] = 0
    end
    sharedata_stat[dot][type] = sharedata_stat[dot][type] + 1
    sharedata_stat = json.encode(sharedata_stat)
    redis:set(key,sharedata_stat)
end

function md5_old(str)
    local cmd = "echo -n '"..str.."'|md5sum|cut -d ' ' -f1"
    local s = io.popen(cmd)
    return s:read("*all")
end

function md5(str)
    local md5 = require 'lib/md5'
    return md5.sumhexa(str)
end

--商城特惠礼包统计
function recordShopSpecialStats(uid,version,itemid,itemnum)
    local zid = getZoneId()
    if zid >= 998 then
        return
    end

    if version and tonumber(version)>0 then
        itemid = tostring(version).."-"..itemid
    end

    local todayst = getWeeTs(os.time())
    local http = require("socket.http")
    local config = getConfig('config')

    local url = config['z1'].tankglobalUrl
    if url then
        local getstateUrl =  url.."setshoppurchase?uid="..uid.."&zid="..zid.."&itemid="..itemid.."&itemnum="..itemnum.."&todayst="..todayst
        http.request(getstateUrl)
    end
end

--临时修复玩家名字带空格
function tmpFixTabName(uid)
    local uobjs = getUserObjs(uid)
    local mUserinfo = uobjs.getModel('userinfo')
    local mGameinfo = uobjs.getModel('gameinfo')
    if match(mUserinfo.name) then
        local okName = trimAll(mUserinfo.name)

        local zid = getZoneId()
        local db = getDbo(zid)
        local result = db:getRow("select uid from userinfo where name = :name",{name=okName}) or {}
        if result and type(result)=='table' and result.uid and tonumber(result.uid)>0 then
            local rnum = rand(1,100)
            okName = okName..rnum
        end

        mUserinfo.name = okName
        if not mGameinfo.info['virenameauto'] then
            local rewards = "6_1901_1|6_1020_5|6_1030_5"
            local mails = require "lib.mails"
            local systeminfo = {touch=rewards, title=''}
            local id = mails:addData(uid,'',1,systeminfo)
            local mMymail = uobjs.getModel('mymail')
            mMymail.receiveSystemMail(0,id,'',999,rewards,{mt=54,pa={}},os.time())
            mGameinfo.info['virenameauto'] = true
        end
    end
end

--获取用户zid
function getUserZid(uid)
    return tonumber(math.floor(uid/1000000))
end

--展示中大奖信息
function showLotteryWinInfo(actVersion)
    local redis = getRedis()
    local lotterWinInfoKey = "z"..getZoneId().."."..actVersion..".winfo"
    local winInfo = redis:get(lotterWinInfoKey)
    winInfo = json.decode(winInfo) or {}
    return winInfo
end

--展示抽到特殊道具信息
function showLotteryCrewardInfo(actVersion)
    local redis = getRedis()
    local lotterPInfoKey = "z"..getZoneId().."."..actVersion..".pinfo"
    local pInfo = redis:get(lotterPInfoKey)
    pInfo = json.decode(pInfo) or {}
    return pInfo
end

--显示当前奖池金额
function showLotteryTotalGem(actVersion,code)
    local redis = getRedis()
    local lotteryTotalGemKey  = "z"..getZoneId().."."..actVersion..".totalgem"
    local totalGem = redis:get(lotteryTotalGemKey)
    if not totalGem then
        local lotteryCfg = getConfig("lotteryCfg","activecfg")
        local initGem = lotteryCfg[code].initialPrize
        redis:set(lotteryTotalGemKey,initGem)
        return initGem
    end
    return totalGem
end

function checkUserBan(uid)
    local uobjs = getUserObjs(tonumber(uid))
    local mGameinfo = uobjs.getModel('gameinfo')
    local mUserinfo = uobjs.getModel('userinfo')

    if tonumber(mGameinfo.ban)>0 and mUserinfo.buyg==0 then
        local banflag=1
        local mChild = uobjs.getModel('child')
        if tonumber(mGameinfo.ban)==1 and mChild.info and next(mChild.info) then
            for _,v in pairs(mChild.info) do
                if v.exp>0 or v.lv>=2 then
                    banflag = 0
                    break
                end
            end
        elseif tonumber(mGameinfo.ban)==2 then
            banflag = 1
        end

        if banflag==1 then
            local redis = getRedis()
            local loginkey = "z"..getZoneId()..".login."..uid
            redis:del(loginkey)

            return true
        end
    end
    return false
end

function setUserBan(uid)
    local uobjs = getUserObjs(tonumber(uid),true)
    local mGameinfo = uobjs.getModel('gameinfo')
    mGameinfo.ban=1
end

function checkWxSign(uid,pid,prefix,rsdk_login_time,rsdk_sign)
    local wxPrivateKey = "9E4376F408771AE3687C1ED5668DDA4C"
    if PLATFORM=="cn_37wx" then
        wxPrivateKey = "X7PAEBDTIUSLSHH0OTB7ZS7AB8FSEMZD"
    end

    local localsign = md5(string.sub(pid,string.len(prefix)+1)..rsdk_login_time..wxPrivateKey)
    if localsign and localsign==rsdk_sign then
        return true
    end

    local redis = getRedis()
    local loginkey = "z"..getZoneId()..".login."..uid
    redis:del(loginkey)
    return false
end

--获取平台区服
function getPlatAllZids()
    local zids = {}
    local http = require("socket.http")
    http.TIMEOUT= 0.5
    local zoneid = getZoneId()
    local config = getConfig('config')
    local getzidsurl = config['z'..zoneid].tankglobalUrl.."getallzids"
    --http://192.168.8.82/tank-global/index.php/getallzids
    local zonerets = http.request(getzidsurl)
    if zonerets then
        local list = json.decode(zonerets)
        for _,info in ipairs(list.serverlist) do
            local iflag=true
            if tonumber(info.zoneid)==2000 then --2000服
                iflag=false
            elseif PLATFORM == 'wg_sea' or PLATFORM == 'wg_eur' then
                local tzid = tonumber(info.zoneid)
                if tzid<900 and (tzid<490 or (tzid>500 and tzid<890)) and info.enable and tonumber(info.enable)==0 then --未开新服
                    iflag=false
                end
            else
                if tonumber(info.zoneid)<900 and info.enable and tonumber(info.enable)==0 then --未开新服
                    iflag=false
                end
            end

            if iflag then
                table.insert(zids,tonumber(info.zoneid))
            end
        end
    end
    return zids
end

--获取跨服信息
function getCrossSwitch(mzid)
    local crossSwitchFlag = false
    local zid = getZoneId()
    if mzid then
        zid=mzid
    end

    local config = getConfig('config')
    if not config["z2000"] then
        warn:sendMail("noCrossServerDb",{message = "no database gt_2000"})
        return crossSwitchFlag
    end

    local key = "crosslist"
    local startZid,endZid
    
    local redkey = "z"..getZoneId().."."..key
    local redis = getRedis()
    local crosslistData = redis:get(redkey)
    if crosslistData then
        crosslistData = json.decode(crosslistData)
    else
        crosslistData = {}
        local db = getDbo(2000)
        local result = db:getRow("select * from bkcross where id='"..key.."';")
        if result and result["info"] then
            crosslistData = json.decode(result["info"])
            redis:set(redkey,json.encode(crosslistData))
        end
    end
    if crosslistData and next(crosslistData) then
        for _,v in ipairs(crosslistData) do
            if zid>=v[1] and zid<=v[2] then
                crossSwitchFlag = true
                startZid = v[1]
                endZid = v[2]
                break
            end
        end
    end
    
    return crossSwitchFlag,startZid,endZid
end

function trimAll(s)
    if s then
        return (string.gsub(s, "%s*(.-)%s*", "%1"))
    end
end

--wx检测函数
function wxCheckMsgInfo(adata)
    adata["useWechat"] = true
    adata["autoSwitchToCloud"] = true
    adata["useCloud"] = false
    local postData
    for k,v in pairs(adata) do
        if postData then
            postData = postData .. "&" .. k .. "=" .. tostring(v)
        else
            postData = "" .. k .. "=" .. tostring(v)
        end
    end

    local http = require("socket.http")
    http.TIMEOUT = 3
    local signurl = "http://sapi.hortorgames.com/sensitive/v2/msg"
    local tmp  = http.request(signurl, postData)
    local res = json.decode(tmp)
    return res
end

--活动基础统计
function addActivityStat(uid,atype,v)
    if true then return true end
end

--获取微信昵称屏蔽
function getWxBlackName()
    local db = getDbo(1)
    local key = "wxblackname"
    local result = db:getRow("select * from backdata where id='"..key.."'")
    if result and result["info"] then
        return result["info"]
    else
        return false
    end
end

--合服维护公告
function checkMergezoneNotice(uid,language,plat)
    local zid = getZoneId()
    local mkey= "z"..zid..".mergezonenotice"
    uid = tostring(uid)
    local mninfo
    local db = getDbo()
    local resinfo = db:getRow("select * from backdata where id='"..mkey.."';")
    if resinfo and next(resinfo) then
        mninfo = json.decode(resinfo.info)
    end
    if mninfo then
        local thetime = os.time()
        local thest = mninfo.st or 0
        local theet = mninfo.et or (thetime+10000)
        local channelIdTb = mninfo.channel or {}
        if tonumber(thetime) >= tonumber(thest) and tonumber(thetime) <= tonumber(theet) then
            local blocklistflag = 1
            local wlstr = mninfo.whitelist
            if wlstr then
                local whitelist = string.split(wlstr, "%,")
                for k,v in pairs(whitelist) do
                    if v == uid then
                        blocklistflag = nil
                        break
                    end
                end
            end
            if channelIdTb and next(channelIdTb) then
                if not table.contains(channelIdTb,tostring(plat)) then
                    blocklistflag = nil
                end
            end
            if blocklistflag then
                -- local titleinfo = mninfo.title
                -- local contentinfo = mninfo.content
                -- if type(titleinfo) == "table" and type(contentinfo) == "table" then
                --     language = language or "cn"
                --     if titleinfo[language] and contentinfo[language] then
                --         local title = titleinfo[language]
                --         local content = contentinfo[language]
                --         return true,title,content
                --     end
                -- end
                return true,mninfo.title,mninfo.content
            end
        end
    end
    return false
end

--脱衣的vip等级
function getstripLevel()
    local key = "z"..getZoneId()..".striplevel"
    local redis = getRedis()
    local stripData = redis:get(key)
    if stripData then
        stripData = json.decode(stripData)
    else
        stripData = {}
        local stripSqlData = getBakData(key)
        if stripSqlData then
            stripData = json.decode(stripSqlData)
            redis:set(key,json.encode(stripData))
        end
    end
    if stripData and next(stripData) then
        return stripData["striplevel"]
    end
    return false
end

--string奖励转换为tab
function RewardString2tab(rewards)
    if rewards == '' then
        return {}
    end
    local gift_table = string.split(rewards, "%|")

    local tmp_table = {}
    -- local result = ""
    for k, v in pairs(gift_table) do
        local gift_v = string.split(v, "%_")
        local giftType = tonumber(gift_v[1])
        local giftId = tostring(gift_v[2]) or '0'
        local giftNum = tonumber(gift_v[3])
        if tmp_table[giftType .. "_" .. giftId] == nil then
            tmp_table[giftType .. "_" .. giftId] = giftNum
        else
            tmp_table[giftType .. "_" .. giftId] = tmp_table[giftType .. "_" .. giftId] + giftNum
        end
    end
    
    return tmp_table
end

--将字符串转换为table
function getTableLampByString(rewards)
    local rewards = tostring(rewards)
    if rewards == '' or rewards == 'nil' then
        return false
    end
    local tmp_table = string.split(rewards, "%|")

    local result = {}
    for k,sinfo in pairs(tmp_table) do
        local tmp_arr = string.split(sinfo, "%_")
        if tmp_arr[1] and tmp_arr[2] then
            local tmpkey = tmp_arr[1] .. tmp_arr[2]
            result[tmpkey] = sinfo
        end
    end
    
    return result
end

--将信息转换为table
function getTableLampByTable(rewards)
    if not (rewards and next(rewards)) then
        return false
    end

    local result = {}
    for k,v in pairs(rewards) do
        local sinfo = tostring(k)
        local tmp_arr = string.split(sinfo, "%_")
        if tmp_arr[1] and tmp_arr[2] then
            local tmpkey = tmp_arr[1] .. tmp_arr[2]
            result[tmpkey] = sinfo
        end
    end
    
    return result
end

--检测重复物品
function checkTableReward(checklamparr,targetlamparr)
    if not (checklamparr and next(checklamparr) and targetlamparr and next(targetlamparr)) then
        return false
    end

    for k,v in pairs(targetlamparr) do
        local skey = tostring(k)
        if checklamparr[skey] then
            return targetlamparr[skey]
        end
    end
    
    return false
end

--获得排行数组中我的排行
function getRankFromTable(rankarr,uid)
    if not (rankarr and next(rankarr) and uid) then
        return 0
    end

    for rid,rankinfo in ipairs(rankarr) do
        local ranknum = tonumber(rid)
        if rankinfo.uid == tonumber(uid) then
            return ranknum
        end
    end
    
    return 0
end

--筑阁祭天随机奖励
function buildingWorshipRandItems(randNum,code)
    local randItems = {}
    local buildingWorshipCfg = getConfig("buildingWorshipCfg","activecfg")
    local lotteryPoolCfg = buildingWorshipCfg[code].lotteryPool
    local lotteryCriticalRate = buildingWorshipCfg[code].lotteryCriticalRate
    local lotteryCriticalEffect = buildingWorshipCfg[code].lotteryCriticalEffect
    
    local randKeys = {}
    for i,v in ipairs(lotteryPoolCfg) do
        randKeys[tostring(i)] = tonumber(v[2])
    end
    local isLuck = false
    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
        --本次是否暴击
        local rankNum = math.random(1, 100)
        --是否发生了暴击
        if tonumber(lotteryCriticalRate)*100 >= rankNum then
            --发生暴击时 当前奖励再给暴击效果次
            isLuck = true
            for i=1,lotteryCriticalEffect do
                table.insert(randItems, key)
            end
        end
    end
    local rewards = ""
    for _,rewardId in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. lotteryPoolCfg[tonumber(rewardId)][1]
    end
    
    return isLuck,mergeRewards(rewards)
end

--获取宴会跨服信息
function getDinnerCrossSwitch(mzid)
    local crossSwitchFlag = false
    local zid = getZoneId()
    if mzid then
        zid=mzid
    end

    local config = getConfig('config')
    if not config["z2000"] then
        warn:sendMail("noCrossServerDb",{message = "no database gt_2000"})
        return crossSwitchFlag
    end

    local key = "crossdinnerlist"
    local startZid,endZid
    
    local redkey = "z"..getZoneId().."."..key
    local redis = getRedis()
    local crosslistData = redis:get(redkey)
    if crosslistData then
        crosslistData = json.decode(crosslistData)
    else
        crosslistData = {}
        local db = getDbo(2000)
        local result = db:getRow("select * from bkcross where id='"..key.."';")
        if result and result["info"] then
            crosslistData = json.decode(result["info"])
            redis:set(redkey,json.encode(crosslistData))
        end
    end
    if crosslistData and next(crosslistData) then
        for _,v in ipairs(crosslistData) do
            if zid>=v[1] and zid<=v[2] then
                crossSwitchFlag = true
                startZid = v[1]
                endZid = v[2]
                break
            end
        end
    end
    
    return crossSwitchFlag,startZid,endZid
end

--多区服pk检测
function checkCrossMoreZonePk(aid,code,mzid,version)
    local pkflag = true
    aid = tostring(aid)
    code = tonumber(code)
    mzid = tonumber(mzid)

    --跨服多区服活动
    local crossMoreZoneAids = {
        ["crossServerAtkRace"] = "crossatkracezids",
        ["crossServerIntimacy"] = "crossimacyzids",
        ["crossServerPower"] = "crosspowerzids",
    }

    if aid ~= "nil" and code and mzid and crossMoreZoneAids[aid] and version then
        local crossCfg = getConfig(aid.."Cfg","activecfg")[code]
        if crossCfg and crossCfg.crossServerType then
            local ctype = math.floor(crossCfg.crossServerType / 10)
            if ctype == 2 then
                pkflag = false
                local pkkey = crossMoreZoneAids[aid]
                --local mzid = getZoneId()
                local db2000 = getDbo(2000)
                local pkret = db2000:getRow("select * from bkcross where id=:key",{key=pkkey})
                if pkret then
                    local pkinfos = json.decode(pkret.info)
                    for _,pkinfo in ipairs(pkinfos) do
                        local zidgroups = pkinfo.zids
                        if pkinfo.st == version and not pkflag then
                            for _,zidgroup in ipairs(zidgroups) do
                                if table.contains(zidgroup,mzid) and #zidgroup > 2 then
                                    pkflag = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return pkflag
end

--检测跨服活动前置活动
function checkCrossPreActivity(aid,version,zid)
    local preflag = true
    aid = tostring(aid)

    --跨服多区服活动
    local crosspreAids = {
        ["crossServerAtkRace"] = 16, --跨服擂台
        ["crossServerIntimacy"] = 15, --跨服亲密
        ["crossServerPower"] = 11, --跨服权势
        ["crossServerHegemony"] = 1, --群雄逐鹿
        ["wifeBattlePromotion"] = 1, --风云群芳
        ["crossServerHorsePower"] = 1, --跨服战马权势
        ["crossCityAllianceBattle"] = 1,  --跨服连城斗阵
        ["battleGround"] = 1, --跨服风云擂台
        ["crossServerWipeBoss"] = 2, --跨服征讨可汗
        ["crossCaptureCityNew"] = 1, --跨服攻城掠地(新)
        ["crossServerHorseRace"] = 1, --跨服战马PVP
        ["conquerMainLand"] = 1, --定军中原

        ["crossHorseFight"] = 1, --跨服斗马冲榜
        ["crossGroupAbility"] = 1, --乱世争雄
        ["cloudHorseFight"] = 1, --风云赛马大会
        ["crossYamenPower"] = 1, --跨服衙门民望冲榜
        ["crossCuriosPower"] = 1, --跨服文玩属性冲榜
        ["crossCuriosFight"] = 1, --跨服文玩PVP冲榜

        ["crossServerWifeBattle"] = 122, --跨服群芳
        ["crossServerAbility"] = 115, --跨服资质
        ["crossCityBattle"] = 1, --雄霸天下
    }
    local extraTimeCfg = getConfig("extraTimeCfg")
    local warmupTimeCfg = getConfig("warmupTimeCfg")

    local crosstype = tonumber(crosspreAids[aid])
    local sysActive = require("lib.active")
    if aid ~= "nil" and crosstype and version then
        preflag = false
        if aid == "crossServerWipeBoss" then
            local actives = sysActive:getWipeBossActive(zid)
            if actives and next(actives) then
                for _,info in ipairs(actives) do
                    local et = tonumber(info.time_end)-86400
                    local rcode = tonumber(info.code)
                    if info.aid == 'wipeBoss' and version == et then
                        local wipeBossCfg = getConfig("wipeBossCfg","activecfg")[rcode]
                        if wipeBossCfg.crossServerPass == 1 and wipeBossCfg.crossServerPassNum then
                            preflag = true
                            break
                        end
                    end
                end
            end
        elseif aid == "crossCaptureCityNew" then--攻城掠地
            local actives = sysActive:getCaptureCityActive(zid)
            if actives and next(actives) then
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)
                    if info.aid == 'captureCity' and version == et then
                        local captureCityCfg = getConfig("captureCityCfg","activecfg")[rcode]
                        if captureCityCfg.crossServerPass==1 and captureCityCfg.crossServerType==1001 then
                            preflag = true
                            break
                        end
                    end
                end
            end
            if not preflag then
                actives = sysActive:getEnRollRankActive(zid)
                if actives and next(actives) then
                    for _,info in ipairs(actives) do
                        local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                        local et = tonumber(info.time_end)-86400*extraTime
                        local rcode = tonumber(info.code)
                        if info.aid == 'enrollRankActive' and version == et then
                            local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")
                            if enrollRankActiveCfg[rcode].qualifyType == 1 and enrollRankActiveCfg[rcode].crossActivityMap == "crossCaptureCityNew" then
                                preflag = true
                                break
                            end
                        end
                    end
                end
            end
        elseif aid == "crossCityAllianceBattle" then--连城斗阵
            local actives = sysActive:getAllEnRollActive(zid)
            if actives and next(actives) then
                local rankActiveCfg = getConfig("rankActiveCfg","activecfg")
                local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local warmupTime = warmupTimeCfg[info.aid] and warmupTimeCfg[info.aid].warmupTime or 0

                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)
                    if info.aid == 'rankActive' and version == et then
                        local atype = rankActiveCfg[rcode].type
                        if rankActiveCfg[rcode].isCross==2 and (atype==12 or atype==13 or atype==14 or atype==4) then
                            preflag = true
                            break
                        end
                    end

                    local realet = getWeeTs(et) + 86400
                    local realst = version + warmupTime * 3600
                    if info.aid == 'enrollRankActive' and realet == realst then
                        if enrollRankActiveCfg[rcode].qualifyType == 2 and enrollRankActiveCfg[rcode].crossActivityMap == "crossCityAllianceBattle"  then
                            preflag = true
                            break
                        end
                    end
                end
            end
        elseif aid == "crossServerHorsePower" then--跨服战马冲榜
            local actives = sysActive:getAllEnRollActive(zid)
            if actives and next(actives) then
                local rankActiveCfg = getConfig("rankActiveCfg","activecfg")
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)
                    if info.aid == 'rankActive' and version == et then
                        if rankActiveCfg[rcode].isCross==1 and tonumber(rankActiveCfg[rcode].crossServerType) == 127 then
                            preflag = true
                            break
                        end
                    end

                    if info.aid == 'enrollRankActive' and version == et then
                        local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")
                        if enrollRankActiveCfg[rcode].qualifyType == 1 and enrollRankActiveCfg[rcode].crossActivityMap == "crossServerHorsePower"  then
                            preflag = true
                            break
                        end
                    end
                end
            end
        elseif aid == "crossServerHorseRace" then--跨服战马PVP
            local actives = sysActive:getAllEnRollActive(zid)
            if actives and next(actives) then
                local rankActiveCfg = getConfig("rankActiveCfg","activecfg")
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)
                    if info.aid == 'rankActive' and version == et then
                        if rankActiveCfg[rcode].isCross==1 and tonumber(rankActiveCfg[rcode].crossServerType) == 128 then
                            preflag = true
                            break
                        end
                    end
                    if info.aid == 'enrollRankActive' and version == et then
                        local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")
                        if enrollRankActiveCfg[rcode].qualifyType == 1 and enrollRankActiveCfg[rcode].crossActivityMap == "crossServerHorseRace"  then
                            preflag = true
                            break
                        end
                    end
                end
            end
        elseif aid == "wifeBattlePromotion" then--风云群芳
            local actives = sysActive:getAllEnRollActive(zid)
            if actives and next(actives) then
                local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local warmupTime = warmupTimeCfg[info.aid] and warmupTimeCfg[info.aid].warmupTime or 0

                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)

                    local realet = getWeeTs(et) + 86400
                    local realst = version + warmupTime * 3600
                    if info.aid == 'enrollRankActive' and realet == realst then
                        if enrollRankActiveCfg[rcode].qualifyType == 2 and enrollRankActiveCfg[rcode].crossActivityMap == "wifeBattlePromotion"  then
                            preflag = true
                            break
                        end
                    end
                end
            end
        elseif aid == "crossServerHegemony" then--群雄逐鹿
            local actives = sysActive:getAllianceQualifyActive(zid)
            if actives and next(actives) then
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local et = tonumber(info.time_end)-86400*extraTime
                    if info.aid == 'crossAllianceQualify' and version == et then
                        preflag = true
                        break
                    end
                end
            end
        elseif aid == "conquerMainLand" then--定军中原
            local actives = sysActive:getRankCrossActiveNew(zid)
            if actives and next(actives) then
                local rankActiveCfg = getConfig("rankActiveCfg","activecfg")
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)
                    if info.aid == 'rankActive' and version == et then
                        if rankActiveCfg[rcode].isCross==1 and rankActiveCfg[rcode].crossServerType=="125" then --产出通行证
                            preflag = true
                            break
                        end
                    end
                end
            end
            if not preflag then
                actives = sysActive:getEnRollRankActive(zid)
                if actives and next(actives) then
                    local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")
                    for _,info in ipairs(actives) do
                        local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                        local et = tonumber(info.time_end)-86400*extraTime
                        local rcode = tonumber(info.code)
                        if info.aid == 'enrollRankActive' and version == et then
                            if enrollRankActiveCfg[rcode].qualifyType == 1 and enrollRankActiveCfg[rcode].crossActivityMap == "conquerMainLand" then --产出通行证
                                preflag = true
                                break
                            end
                        end
                    end
                end
            end
        elseif aid == "crossCityBattle" then--雄霸天下
            local actives = sysActive:getServerHegemonyActive(zid)
            if actives and next(actives) then
                local crossServerHegemonyCfg = getConfig("crossServerHegemonyCfg","activecfg")
                for _,info in ipairs(actives) do
                    local extraTime = extraTimeCfg[info.aid] and extraTimeCfg[info.aid].extraTime or 0
                    local et = tonumber(info.time_end)-86400*extraTime
                    local rcode = tonumber(info.code)
                    if info.aid == 'crossServerHegemony' and version == et then
                        if crossServerHegemonyCfg[rcode].qualifications then
                            preflag = true
                            break
                        end
                    end
                end
            end
        else
            local actives = sysActive:getRankCrossActive(zid)
            if actives and next(actives) then
                for _,info in ipairs(actives) do
                    local et = tonumber(info.time_end)-86400
                    local rcode = tonumber(info.code)

                    if info.aid == 'rankActive' and version == et then
                        local rankActiveCfg = getConfig("rankActiveCfg","activecfg")[rcode]
                        local ranktype = rankActiveCfg.isCross .. rankActiveCfg.type
                        ranktype = tonumber(ranktype)
                        if aid == "battleGround" then
                            if table.contains({24,212,213,214},ranktype) then
                                preflag = true
                                break
                            end
                        else
                            if ranktype == crosstype then
                                preflag = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    --增加报名活动检测
    if not preflag then
        local actives = sysActive:getRankCrossEnrollActive(zid)
        if actives and next(actives) then
            for _,info in ipairs(actives) do
                local et = tonumber(info.time_end)-86400
                local rcode = tonumber(info.code)

                if info.aid == 'enrollRankActive' and version == et then
                    local enrollRankActiveCfg = getConfig("enrollRankActiveCfg","activecfg")[rcode]
                    local crossActivityMap = enrollRankActiveCfg.crossActivityMap
                    if aid == crossActivityMap then
                        preflag = true
                        break
                    end
                end
            end
        end
    end
    
    return preflag
end

-- 校验活动领奖的帮主
function checkAllianceCreatorInActivity(allianceId,uid,activeId,st)
    local key = "z"..getZoneId()..".checkAllianceCreatorInActivity."..allianceId.."."..activeId.."."..st
    local redis = getRedis()
    local result = redis:get(key)
    if not result then
        result = tostring(uid)
        redis:set(key,result)
        redis:expire(key,86400*30)
        return true
    else
        if tostring(uid) == result then
            return true
        else
            return false
        end
    end
end

-- 校验活动聊天只发送一次
function checkChatMsgInActivity(uid,acst,titleid)
    local key = "z"..getZoneId()..".checkChatMsgInActivity."..acst.."."..titleid.."."..uid
    local redis = getRedis()
    if redis:exists(key) then
        return true
    else
        redis:setex(key,86400*10,1)
        return false
    end
end

-- 红莲勇士活动继承血量检测
function checkRedLotusWarrior(uid, activeId, code)
    local redLotusWarriorCfg = getConfig("redLotusWarriorCfg", "activecfg")[code]

    local uobjs = getUserObjs(uid)
    local mServant = uobjs.getModel('servant')
    local servantId = tostring(redLotusWarriorCfg.sevantID)
    local skinId = tostring(redLotusWarriorCfg.zhentianSkinId)
    if mServant.info[servantId] and mServant.info[servantId].skin and mServant.info[servantId].skin[skinId] then
        --有皮肤则消除活动
        return true
    else
        --boss血量扣除
        local mItem = uobjs.getModel('item')
        local ItemId = tostring(redLotusWarriorCfg.helmetItemID)
        local pnum = tonumber(mItem.info[ItemId]) or 0
        return false,pnum
    end
end

-- 红莲勇士活动攻击
function attackRedLotusWarrior(uid, activeId, code, anum)
    local anum = tonumber(anum)
    if not anum or anum <= 0 then
        return false
    end

    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local redLotusWarriorCfg = getConfig("redLotusWarriorCfg", "activecfg")[code]
    local chiplimit = tonumber(redLotusWarriorCfg.helmetItemNum)
    local singlenum = tonumber(redLotusWarriorCfg.helmetRwardNum)
    -- local oncereward = redLotusWarriorCfg.helmetItem
    local helmetreward = "6_" .. redLotusWarriorCfg.helmetItemID
    local rewards,generalrewards
    local realnum,critnum = 0,0

    --随机暴击
    local rangeLoop = redLotusWarriorCfg.attackloop --暴击区间上限
    local rangelimit = redLotusWarriorCfg.criticaltime --区间内必暴击次数
    local critAdd = redLotusWarriorCfg.criticaldamageAdd --暴击增益
    local singlecritnum = critAdd * singlenum
    for i=1,anum do
        if actinfo.attacknum > 0 and actinfo.chipnum < chiplimit then
            local randreward = getKeyByArrRnd(redLotusWarriorCfg.trophyPool)
            actinfo.attacknum = actinfo.attacknum - 1
            actinfo.thenum = actinfo.thenum + 1
            actinfo.chipnum = actinfo.chipnum + 1
            actinfo.usenum = actinfo.usenum + 1
            realnum = realnum + 1
            if not generalrewards then
                generalrewards = randreward
            else
                generalrewards = generalrewards .. "|" .. randreward
            end

            if (actinfo.chipnum+singlecritnum) <= chiplimit then
                actinfo.rangenum = (actinfo.rangenum % rangeLoop) + 1
                if actinfo.rangenum == 1 then
                    actinfo.rangeflag = 0
                elseif (((rangeLoop - actinfo.rangenum) <= (rangelimit - actinfo.rangeflag)) or (rand(1,rangeLoop) <= actinfo.rangenum)) and actinfo.rangeflag < rangelimit then
                    actinfo.rangeflag = actinfo.rangeflag + 1
                    realnum = realnum + singlecritnum
                    critnum = critnum + 1
                    actinfo.thenum = actinfo.thenum + singlecritnum
                    actinfo.chipnum = actinfo.chipnum + singlecritnum
                    for j=1,critAdd do
                        generalrewards = generalrewards .. "|" .. randreward
                    end
                end
            end
        else
            break
        end
    end

    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end
    if realnum > 0 then
        rewards = helmetreward .. "_" .. realnum .. "|" .. generalrewards
    else
        rewards = generalrewards
    end
    return realnum,critnum,rewards,generalrewards
end

-- 搜查奸臣活动继承血量检测
function checkRansackTraitor(uid, activeId, code)
    local ransackTraitorCfg = getConfig("ransackTraitorCfg", "activecfg")[code]

    local uobjs = getUserObjs(uid)
    local mServant = uobjs.getModel('servant')
    local servantId = tostring(ransackTraitorCfg.TraitorId)
    local skinId = tostring(ransackTraitorCfg.TraitorSkinId)
    if mServant.info[servantId] and mServant.info[servantId].skin and mServant.info[servantId].skin[skinId] then
        --有皮肤则消除活动
        return true
    else
        --boss血量扣除
        local mItem = uobjs.getModel('item')
        local ItemId = tostring(ransackTraitorCfg.RansackItemID)
        local pnum = tonumber(mItem.info[ItemId]) or 0
        return false,pnum
    end
end

-- 搜查奸臣活动单次搜查
function singleAttackRansackTraitor(uid, activeId, code, anum)
    local anum = tonumber(anum)
    if not anum or anum <= 0 then
        return false
    end

    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local ransackTraitorCfg = getConfig("ransackTraitorCfg", "activecfg")[code]
    local ransacklimit = tonumber(ransackTraitorCfg.RansackItemNum)
    local rtreward = "6_" .. ransackTraitorCfg.RansackItemID
    local rewards,generalrewards
    local getransack,resflag = 0,false

    for i=1,anum do
        if actinfo.attacknum > 0 and actinfo.chipnum < ransacklimit then
            --获得随机奖励
            local randreward = getKeyByArrRnd(ransackTraitorCfg.RansackPool)
            actinfo.singlenum = actinfo.singlenum + 1
            actinfo.attacknum = actinfo.attacknum - 1
            if not generalrewards then
                generalrewards = randreward
            else
                generalrewards = generalrewards .. "|" .. randreward
            end

            --随机获得证物
            local upperlimit,lowerlimit,ransackflag = 0,0,false
            for round,rlimit in ipairs(ransackTraitorCfg.Range) do
                if actinfo.singlechipnum < round then
                    upperlimit = rlimit
                    if actinfo.singlenum >= rand(lowerlimit,upperlimit) then
                        ransackflag = true
                    end
                    break
                else
                    lowerlimit = rlimit+1
                end
            end

            --增加证物
            if ransackflag and actinfo.chipnum < ransacklimit then
                actinfo.chipnum = actinfo.chipnum + 1
                getransack = getransack + 1
                actinfo.singlechipnum = actinfo.singlechipnum + 1
            end
            resflag = true
        else
            break
        end
    end

    -- if rewards then
    --     rewards = mergeRewards(rewards)
    -- end
    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end
    if getransack > 0 then
        rewards = rtreward .. "_" .. getransack .. "|" .. generalrewards
    else
        rewards = generalrewards
    end
    return resflag,rewards,getransack,generalrewards
end

-- 搜查奸臣活动十连搜查
function tenAttackRansackTraitor(uid, activeId, code)
    local anum = 10
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local ransackTraitorCfg = getConfig("ransackTraitorCfg", "activecfg")[code]
    local ransacklimit = tonumber(ransackTraitorCfg.RansackItemNum)
    local rewards

    --增加证物
    if actinfo.attacknum >= anum and actinfo.chipnum < ransacklimit then
        local addchipnum = tonumber(ransackTraitorCfg.RansackRewardNum)
        actinfo.chipnum = actinfo.chipnum + addchipnum
        rewards = ransackTraitorCfg.RansackItem
    else
        return false
    end

    actinfo.tennum = actinfo.tennum + anum
    actinfo.attacknum = actinfo.attacknum - anum

    local generalrewards
    for i=1,anum do
        --获得随机奖励
        local randreward = getKeyByArrRnd(ransackTraitorCfg.RansackPool)
        if generalrewards then
            generalrewards = generalrewards .. "|" .. randreward
        else
            generalrewards = randreward
        end
    end

    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end
    rewards = rewards .. "|" .. generalrewards

    return true,rewards
end

--增加联盟经验冲榜活动
function addAlliactiveV(uid,allianceId,addExp)
    if uid and uid>0 and allianceId and allianceId>0 and addExp>0 then
        local now = os.time()
        local uobjs = getUserObjs(tonumber(uid),true)
        local aobjs = getallianceObjs(allianceId)
        local mActivity = uobjs.getModel('activity')
--        local activeArr = {"rankActive-4","rankActive-15","rankActive-43","rankActive-50","rankActive-104","rankActive-108","rankActive-1001"}
        for activeId,info in pairs(mActivity.info) do
            if info.aid=="rankActive" and info.atype and tonumber(info.atype)==4 and info.st<now and now<mActivity.info[activeId].et-86400 then
                local mAlliactive = aobjs.getModel('alliactive')
                local akey = activeId.."."..mActivity.info[activeId].st
                mAlliactive.addActiveData(akey,addExp,uid,mActivity.info[activeId].atype)
            end
        end
    end
end

--删除登录时间验签
function delAcLoginTs(uid)
    local redis = getRedis()
    local loginkey = "z"..getZoneId()..".login."..uid
    redis:del(loginkey)
end

--携美同游随机奖励
function springOutingRandItems(randNum,code)
    local randItems = {}
    local springOutingCfg = getConfig("springOutingCfg","activecfg")
    local lotteryPoolCfg = springOutingCfg[code].lotteryPool
    
    
    local randKeys = {}
    for i,v in ipairs(lotteryPoolCfg) do
        randKeys[tostring(i)] = tonumber(v[2])
    end

    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
        
    end
    local rewards = ""
    for _,rewardId in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. lotteryPoolCfg[tonumber(rewardId)][1]
    end
    
    return mergeRewards(rewards)
end

--范蠡活动随机奖励
function fanliRandItems(randNum,code)
    local randItems = {}
    local fanliReviewCfg = getConfig("fanliReviewCfg","activecfg")
    local ReviewPoolCfg = fanliReviewCfg[code].ReviewPool
    
    
    local randKeys = {}
    for i,v in ipairs(ReviewPoolCfg) do
        randKeys[tostring(i)] = tonumber(v[2])
    end

    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
        
    end
    local rewards = ""
    for _,rewardId in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. ReviewPoolCfg[tonumber(rewardId)][1]
    end
    
    return mergeRewards(rewards)
end

--携美同游活动邮件 检测空奖励
function checksSpringOutingMail(mailInfo)
    local checkMt = "67_1"
    local dleteMail = {}
    for k,v in ipairs(mailInfo) do
        if v.extra and v.extra.mt == checkMt and v.touch and v.touch == "" then
            dleteMail[tostring(v.mid)] = 1
        end
    end
    local needHaveMail = {}
    
    for k,v in ipairs(mailInfo) do
        if not dleteMail[tostring(v.mid)] then
            table.insert(needHaveMail,v)
        end
    end
    
    return needHaveMail
end

--翻牌活动 根据牌的类型取 对应的配置
function getCardCfgBytype(code,ct,uid,addNum)
    local nowAddNum = 0
    if addNum then
        nowAddNum = addNum
    end
    local flipCardCfg = getConfig("flipCardCfg","activecfg")[code]
    local lotteryNum = 0
    local randRewardCfg = nil
    if ct == 1 then
        lotteryNum = flipCardCfg.goldenCardValue
        randRewardCfg = flipCardCfg.goldenPool
    elseif ct == 2 then
        lotteryNum = flipCardCfg.silveryCardValue
        randRewardCfg = flipCardCfg.silveryPool
    elseif ct == 3 then
        lotteryNum = flipCardCfg.copperyCardValue
        randRewardCfg = flipCardCfg.copperyPool
    end
    --这里处理  是否把英雄碎片放进奖励池
    --如果已经小于了必给的次数  则奖池里只能有 碎片
    local sendChip = false
    if uid and flipCardCfg.drawloop then
        local uobjs = getUserObjs(uid)
        local mActivity = uobjs.getModel('activity')
        local acInfo = mActivity.info["flipCard-"..code]
        local acLotteryinfo =  acInfo.lotteryinfo
        
        local drawloop = flipCardCfg.drawloop--抽奖循环长度
        local drawChipTime = flipCardCfg.drawChipTime--抽奖奖励门客碎片次数
        local chipID = flipCardCfg.chipID--碎片ID
        local servantId = flipCardCfg.servantID--兑换门客ID
        local chipTotalNum = flipCardCfg.chipTotalNum--碎片最大数量（兑换数量）
        
        --检测自己有没有这个门客
        local mServant = uobjs.getModel('servant')
        local isHave = false
        if mServant.info[tostring(servantId)] then
            isHave = true
        end
        --检测当前身上有几个碎片
        local mItem = uobjs.getModel('item')
        local itemNum = 0
        if mItem.info[tostring(chipID)] then
            itemNum = mItem.info[tostring(chipID)]
        end
        local CanSendChip = true
        if isHave or itemNum+nowAddNum >= chipTotalNum then
            CanSendChip = false
        end
        
        if CanSendChip and acLotteryinfo.drawnum < drawChipTime and itemNum+nowAddNum < chipTotalNum then
            
            --当前回合 剩下的次数都需要中奖碎片
            if drawloop - acLotteryinfo.drawloopindex <= drawChipTime-acLotteryinfo.drawnum then
                sendChip = true
            elseif rand(1,drawloop - acLotteryinfo.drawloopindex) <= drawChipTime-acLotteryinfo.drawnum then
                sendChip = true
            end
            if sendChip then
                --碎片奖励
                acLotteryinfo.drawnum = acLotteryinfo.drawnum + 1
                --这里覆盖了奖池  只有一个碎片奖励
                randRewardCfg = {{flipCardCfg.chipReward,1,0,0}}
            end
        end
        
        acLotteryinfo.drawloopindex = acLotteryinfo.drawloopindex + 1
        if acLotteryinfo.drawloopindex >= drawloop then
            acLotteryinfo.drawloopindex = 0
            acLotteryinfo.drawnum = 0
        end
    end
    
    return lotteryNum,randRewardCfg,sendChip
end

--计算活动天数
function getDaysbytime(activest)
    local now = os.time()
    local st = getWeeTs(tonumber(activest))
    local diffday = math.ceil((now-st)/24/3600)
    
    return diffday
end

--计算活动天数(正确)
function getNewDaysbytime(activest)
    local now = os.time()
    local st = getWeeTs(tonumber(activest))
    local diffday = math.ceil((now-st+1)/24/3600)
    return diffday
end

--[[
    *计算天数
    *参数:
        st , --起始时间
        time , --目标时间(可不传，默认为现在)
    *返回: diffday 指定时间的相对天数
]]
function getTheDaysbytime(st,time)
    local thetime = tonumber(time) or os.time()
    local st = getWeeTs(tonumber(st))
    local diffday = math.ceil((thetime-st+1)/24/3600)
    
    return diffday
end

-- 红颜皮肤碎片修复计划
function checkWifeSkinPass(uid, code)
    local wifeSkinInheritCfg = getConfig("wifeSkinInheritCfg", "activecfg")[code]
    local uobjs = getUserObjs(uid,true)
    local ItemId = tostring(wifeSkinInheritCfg.wifeSkinInheritItemID)
    
    --现有道具的数量
    local mItem = uobjs.getModel('item')
    local attackmiss = mItem.info[ItemId] or 0
    local sumlimit = tonumber(wifeSkinInheritCfg.wifeSkinInheritItemNum) or 0
    if attackmiss > sumlimit then
        attackmiss = sumlimit
    end
    return true,attackmiss
end
--红颜皮肤活动随机奖励
function wifeSkinRandItems(randNum,code)
    local randItems = {}
    local wifeSkinInheritCfg = getConfig("wifeSkinInheritCfg","activecfg")
    local FirePoollCfg = wifeSkinInheritCfg[code].FirePool
    
    local randKeys = {}
    for i,v in ipairs(FirePoollCfg) do
        randKeys[tostring(i)] = tonumber(v[2])
    end

    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
        
    end
    local rewards = ""
    for _,rewardId in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. FirePoollCfg[tonumber(rewardId)][1]
    end
    
    return mergeRewards(rewards)
end

--检测玩吧是否可领取奖励
function checkwbgiftreward(uid,giftid,lastlogin)
    local wanbaGiftCfg = getConfig("wanbaGiftCfg")
    local rewards = wanbaGiftCfg[tostring(giftid)]["reward"]

    local uobjs = getUserObjs(tonumber(uid))
    local mOtherinfo = uobjs.getModel('otherinfo')
    mOtherinfo.init()
    local checkGiftFlag = mOtherinfo.chackWbGiftRoward(giftid,lastlogin)
    local addFlag
    if checkGiftFlag then
        addFlag = funAddRewards(uid, rewards)
    end
    return addFlag or checkGiftFlag,rewards
end

--获取实名认证&防沉迷功能  0未操作 1游客 2未成年 3成年
function getRealNameForDrink(pid,uid)
    local config = getConfig('config')
    local http = require("socket.http")
    local zid = getZoneId()
    local getzidUrl =  config['z'..zid].tankglobalUrl.."getidcardinfo?pid="..pid
    local cardinfo = http.request(getzidUrl)
    if cardinfo then
        cardinfo = json.decode(cardinfo) or {}
        return cardinfo
    end
end

--荷塘月色随机奖励
function moonlightRandItems(randNum,code)
    local randItems = {}
    local moonlightCfg = getConfig("moonlightCfg","activecfg")
    local lotteryPoolCfg = moonlightCfg[code].drawItem2
    
    local randKeys = {}
    for k,v in pairs(lotteryPoolCfg) do
        randKeys[tostring(k)] = tonumber(v.proportion)
    end
    
    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
    end
    
    local addScore = 0
    local rewards = ""
    for _,rewardId in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. "6_"..rewardId.."_1"
        local scoreNum = lotteryPoolCfg[tostring(rewardId)].score
        addScore = addScore + scoreNum
    end
    
    return addScore,rewards
end

--跨服pk检测
function checkCrossPkLack(aid,mzid,version)
    local pkflag = true
    aid = tostring(aid)
    mzid = tonumber(mzid)

    --需检测的跨服活动
    local checkCrossCrossAids = {
        ["crossServantPower"] = "crossservantpowerpkzids",
        ["treasureFairActive"] = "treasurefairzids",
        ["treasureFairGem"] = "treasurefairgemzids",
        ["newWeaponHouse"] = "newWeaponHouseZids",
        ["orchard"] = "orchardpkzids"
    }

    if aid ~= "nil" and mzid and checkCrossCrossAids[aid] and version then
        pkflag = false
        local pkkey = checkCrossCrossAids[aid]
        --local mzid = getZoneId()
        local db2000 = getDbo(2000)
        local pkret = db2000:getRow("select * from bkcross where id=:key",{key=pkkey})
        if pkret then
            local pkinfos = json.decode(pkret.info)
            for _,pkinfo in ipairs(pkinfos) do
                local zidgroups = pkinfo.zids
                if pkinfo.st == version and not pkflag then
                    for _,zidgroup in ipairs(zidgroups) do
                        if table.contains(zidgroup,mzid) then
                            pkflag = true
                            break
                        end
                    end
                end
            end
        end
    end
    
    return pkflag
end

--随机门客
function randshareservant(uid)
    local uobjs = getUserObjs(uid)
    local mServant = uobjs.getModel('servant')

    local ruleServants = {}
    for sid,info in pairs(mServant.info) do
        local tmpret = {
            sid = sid,
            attr = mServant.getServantAttr(sid,5)
        }
        table.insert(ruleServants,tmpret)
    end

    local snum = table.length(ruleServants)
    if snum == 0 then
        return false
    end

    table.sort(ruleServants,function(a,b) return a.attr>b.attr end)

    --随机前3-前6
    local uplimit = snum
    local lowlimit = 1
    if snum >= 3 then
        lowlimit = 3
    end
    if snum >= 6 then
        uplimit = 6
    end

    local randnum = rand(lowlimit,uplimit)

    return ruleServants[randnum].sid
end

--检测是否有才情活动加成
function checkWifeAddByAct(uid)
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local rankactarr,wifeatkarr = {},{}
    for akey,ainfo in pairs(mActivity.info) do
        if ainfo.aid == "wifeBattleRank" then
            table.insert(wifeatkarr,akey)
        elseif ainfo.aid == "rankActive" and ainfo.atype == 22 then
            table.insert(rankactarr,akey)
        end
    end

    local now = os.time()
    for i,winfo in ipairs(wifeatkarr) do
        if mActivity.info[winfo].st <= now and (mActivity.info[winfo].et-86400) >= now then
            for j,rinfo in ipairs(rankactarr) do
                if mActivity.info[winfo].st == mActivity.info[rinfo].st and mActivity.info[winfo].et == mActivity.info[rinfo].et then
                    return mActivity.info[winfo].code
                end
            end
        end
    end

    return false
end

--得到才情活动加成
function getWifeAddByAct(uid,acode)
    local code = tonumber(acode)
    if not code then
        return false
    end
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local key = "wifeBattleRank-" .. code
    local resarr,sum
    if mActivity.info[key] then
        resarr = {}
        sum = 0
        for wid,winfo in pairs(mActivity.info[key].wifeadd_arr) do
            resarr[wid] = winfo
            sum = sum + tonumber(winfo)
        end
    end
    return resarr,sum
end

--风云擂台持续时间检测
function checkBattleGroudTime(code,st,et)
    local battleGroundCfg = getConfig("battleGroundCfg","activecfg")[code]
    local lastingday = tonumber(battleGroundCfg.lastingDay) or 3
    local acttimes = getWeeTs(et) - getWeeTs(st)
    local actdays = math.floor(acttimes/86400) + 1
    if actdays < lastingday then
        return false
    end
    
    return true
end

--群芳会冲榜活动检测是否开启群芳会
function checkWifeBattleOpen(code)
    local rankActiveCfg = getConfig("rankActiveCfg","activecfg")[code]
    if rankActiveCfg.type == 22 then
        require('lib/wifeatk')
        local wifeBattleCfg = getConfig('wifeBattleCfg')
        local uidnum = getWifeatkRankTotalNum()
        if not uidnum or uidnum < wifeBattleCfg.unlock_player then
            return false
        end
    end
    
    return true
end

--欢心夏日随机奖励
function seasideGameRandItems(randNum,code)
    local randItems = {}
    local seasideGameCfg = getConfig("seasideGameCfg","activecfg")
    local lotteryPoolCfg = seasideGameCfg[code].drawItem2
    
    local randKeys = {}
    for k,v in pairs(lotteryPoolCfg) do
        randKeys[tostring(k)] = tonumber(v.proportion)
    end
    
    for i=1,randNum,1 do
        local key = getKeyByRnd(randKeys)
        if not key then
            return false
        end
        table.insert(randItems, key)
    end
    
    local addScore = 0
    local rewards = ""
    for _,rewardId in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. "6_"..rewardId.."_1"
        local scoreNum = lotteryPoolCfg[tostring(rewardId)].score
        addScore = addScore + scoreNum
    end
    
    return addScore,rewards
end

--欢心夏日随机奖励
function seasideGameRandItems2(rankData,code)
    local seasideGameCfg = getConfig("seasideGameCfg","activecfg")
    local lotteryPoolCfg = seasideGameCfg[code].drawItem1
    local randKeys = {}
    for k,v in pairs(lotteryPoolCfg) do
        if v.proportion then
            local isNum = rankData[tostring(k)] or 0
            if isNum < v.limitNum then
                randKeys[tostring(k)] = tonumber(v.proportion)
            end
        end
    end
    local rewardId = getKeyByRnd(randKeys)
    return rewardId
end

--tab转换为string奖励
function tabToRewardstr(rewardarr,addnum)
    addnum = tonumber(addnum)
    if not rewardarr or not next(rewardarr) or not addnum or addnum < 1 then
        return 
    end
    local rewards
    for k,v in pairs(rewardarr) do
        local tmpnum = v * addnum
        local tmp_reward = k .. "_" .. tmpnum
        if rewards then
            rewards = rewards .. "|" .. tmp_reward
        else
            rewards = tmp_reward
        end
    end
    
    return rewards
end

--合并两个table
function mergeTwoTable(adata,odata)
    local res = {}
    for i,v in ipairs(adata) do
        table.insert(res,v)
    end
    for i,v in ipairs(odata) do
        table.insert(res,v)
    end
    return res
end

-- key有相同的情况
function newMergeTable(dest, src)
    if not next(dest) then
        return src
    end
    if not next(src) then
        return dest
    end
    local res = dest
    for k, v in pairs(src) do
        res[k] = res[k] or 0
        res[k] = res[k] + v
    end
    return res
end

-- 搜查奸臣周年庆-单次搜查
function singleRstSpSearch(uid, activeId, code, anum)
    local anum = tonumber(anum)
    if not anum or anum <= 0 then
        return false
    end

    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local ransackTraitorSPCfg = getConfig("ransackTraitorSPCfg", "activecfg")[code]
    local limitnum = tonumber(ransackTraitorSPCfg.RansackItemNum)

    local generalrewards,ransrewards
    local ranstotalnum = 0
    local ranstotalinfo = {}
    
    for i=1,anum do
        if actinfo.cannum>0 then
            --必得奖励
            local randreward = getKeyByArrRnd(ransackTraitorSPCfg.RansackPool)
            actinfo.singlenum = actinfo.singlenum + 1
            actinfo.cannum = actinfo.cannum - 1
            if not generalrewards then
                generalrewards = randreward
            else
                generalrewards = generalrewards .. "|" .. randreward
            end

            --随机获得证物
            local upperlimit,lowerlimit,ransackflag = 0,0,false
            for round,rlimit in ipairs(ransackTraitorSPCfg.Range) do
                if actinfo.singlechipnum<round then
                    upperlimit = rlimit
                    if actinfo.singlenum >= rand(lowerlimit,upperlimit) then
                        ransackflag = true
                    end
                    break
                else
                    lowerlimit = rlimit+1
                end
            end

            --证物池子
            local pool={}
            for k,pinfo in ipairs(ransackTraitorSPCfg.oneRansackItem) do
                local pinfoArr = string.split(pinfo[1],"%_")
                local ranid = tostring(pinfoArr[2])
                local weight = pinfo[2]
                if actinfo.ackinfo.info[tostring(ranid)] and actinfo.ackinfo.info[tostring(ranid)]>=limitnum then
                else
                    pool[ranid] = weight
                end
            end

            --增加证物
            if ransackflag and pool then
                local ranid = getKeyByRnd(pool)
                if ranid then
                    actinfo.ackinfo.info[tostring(ranid)] = actinfo.ackinfo.info[tostring(ranid)]+1
                    ranstotalnum = ranstotalnum + 1
                    actinfo.singlechipnum = actinfo.singlechipnum + 1

                    if not ransrewards then
                        ransrewards = "6_"..ranid.."_1"
                    else
                        ransrewards = ransrewards.."|".."6_"..ranid.."_1"
                    end

                    ranstotalinfo[tostring(ranid)] = ranstotalinfo[tostring(ranid)] or 0
                    ranstotalinfo[tostring(ranid)] = ranstotalinfo[tostring(ranid)]+1
                end
            end
        else
            return false
        end
    end

    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end

    return true,generalrewards,ranstotalnum,ransrewards,ranstotalinfo
end

-- 搜查奸臣周年庆-十连搜查
function tenRstSpSearch(uid, activeId, code)
    local anum = 10
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local ransackTraitorSPCfg = getConfig("ransackTraitorSPCfg", "activecfg")[code]
    local limitnum = tonumber(ransackTraitorSPCfg.RansackItemNum)
    local ransrewards

    if actinfo.cannum>=anum then
        actinfo.cannum = actinfo.cannum - anum
    else
        return false
    end
    
    --证物池子
    local pool={}
    for k,pinfo in ipairs(ransackTraitorSPCfg.tenRansackItem) do
        local pinfoArr = string.split(pinfo[1],"%_")
        local ranid = tostring(pinfoArr[2])
        local weight = pinfo[2]
        if actinfo.ackinfo.info[tostring(ranid)] and actinfo.ackinfo.info[tostring(ranid)]>=limitnum then
        else
            pool[ranid] = weight
        end
    end

    --增加证物
    if pool then
        local ranid = getKeyByRnd(pool)
        if ranid then
            actinfo.ackinfo.info[tostring(ranid)] = actinfo.ackinfo.info[tostring(ranid)]+1
            ransrewards = "6_"..ranid.."_1"
        end
    end

    local generalrewards
    for i=1,anum do
        --获得必得奖励
        local randreward = getKeyByArrRnd(ransackTraitorSPCfg.RansackPool)
        if generalrewards then
            generalrewards = generalrewards .. "|" .. randreward
        else
            generalrewards = randreward
        end
    end

    local rewards
    if generalrewards then
        rewards = mergeRewards(generalrewards)
    end
    if ransrewards then
        rewards = rewards.."|"..ransrewards
    end

    return true,rewards
end

--奸臣皮肤周年庆-初始继承罪证
function checkRstSpInit(uid, aid, code)
    local ransackTraitorSPCfg = getConfig("ransackTraitorSPCfg", "activecfg")[code]
    local servantSkinCfg = getConfig('servantSkinCfg')
    
    local uobjs = getUserObjs(uid)
    local mServant = uobjs.getModel('servant')
    local mItem = uobjs.getModel('item')
    local shops = ransackTraitorSPCfg.exchangeShop
    local initinfo = {}
    local showflag = 0
    for _,shopinfo in ipairs(shops) do
        local skinId = tostring(shopinfo.skinID)
        local sanid =  tostring(shopinfo.itemID)
        local servantId = servantSkinCfg[tostring(skinId)].servantId
        local limit = ransackTraitorSPCfg.RansackItemNum
        if mServant.info[servantId] and mServant.info[servantId].skin and mServant.info[servantId].skin[skinId] then
            initinfo[tostring(sanid)]=limit
        else
            showflag = 1 --要展示
            local pnum = tonumber(mItem.info[sanid]) or 0
            initinfo[tostring(sanid)]=pnum
        end
    end

    return showflag,initinfo
end

--显示当前奖池金额
function showArcadeTotalGem(actVersion,code)
    local redis = getRedis()
    local lotteryTotalGemKey  = "z"..getZoneId().."."..actVersion..".totalgem"
    local totalGem = redis:get(lotteryTotalGemKey)
    if not totalGem then
        local arcadeCfg = getConfig("arcadeCfg","activecfg")
        local initGem = arcadeCfg[code].initialPrize
        redis:set(lotteryTotalGemKey,initGem)
        redis:expire(lotteryTotalGemKey,86400*10)
        return initGem
    end
    return totalGem
end

--得到排行榜真实涨幅值
function getRankTrueValue(value)
    local num = tonumber(value)
    local truescore = math.floor(num / math.pow(10,6))
    return truescore
end

--得到奖池抽奖随机奖励
function getPoolLotteryRewards(pool,num)
    num = tonumber(num) or 0
    if not pool or num < 1 then
        return false
    end
    local rewards
    for i=1,num do
        local randReward = getKeyByArrRnd(pool)
        if rewards then
            rewards = rewards.."|"..randReward
        else
            rewards = randReward
        end
    end

    if rewards then
        rewards = mergeRewards(rewards)
    end
    return rewards
end

--夜观天象周年庆-初始继承罪证
function checkStaZerInit(uid, aid, code)
    local stargazerCfg = getConfig("stargazerCfg", "activecfg")[code]
    local servantSkinCfg = getConfig('servantSkinCfg')
    
    local uobjs = getUserObjs(uid)
    local mServant = uobjs.getModel('servant')
    local mItem = uobjs.getModel('item')
    local shops = stargazerCfg.exchangeShop
    local initinfo = {}
    local showflag = 0
    for _,shopinfo in ipairs(shops) do
        local skinId = tostring(shopinfo.skinID)
        local sanid =  tostring(shopinfo.itemID)
        local servantId = servantSkinCfg[tostring(skinId)].servantId
        local limit = stargazerCfg.RansackItemNum
        if mServant.info[servantId] and mServant.info[servantId].skin and mServant.info[servantId].skin[skinId] then
            initinfo[tostring(sanid)]=limit
        else
            showflag = 1 --要展示
            local pnum = tonumber(mItem.info[sanid]) or 0
            initinfo[tostring(sanid)]=pnum
        end
    end

    return showflag,initinfo
end

-- 夜观天象周年庆-单次搜查
function singleStaZerSearch(uid, activeId, code, anum)
    local anum = tonumber(anum)
    if not anum or anum <= 0 then
        return false
    end

    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local stargazerCfg = getConfig("stargazerCfg", "activecfg")[code]
    local limitnum = tonumber(stargazerCfg.RansackItemNum)

    local generalrewards,ransrewards
    local ranstotalnum = 0
    local ranstotalinfo = {}
    
    for i=1,anum do
        if actinfo.cannum>0 then
            --必得奖励
            local randreward = getKeyByArrRnd(stargazerCfg.RansackPool)
            actinfo.singlenum = actinfo.singlenum + 1
            actinfo.cannum = actinfo.cannum - 1
            if not generalrewards then
                generalrewards = randreward
            else
                generalrewards = generalrewards .. "|" .. randreward
            end

            --随机获得证物
            local upperlimit,lowerlimit,ransackflag = 0,0,false
            for round,rlimit in ipairs(stargazerCfg.Range) do
                if actinfo.singlechipnum<round then
                    upperlimit = rlimit
                    if actinfo.singlenum >= rand(lowerlimit,upperlimit) then
                        ransackflag = true
                    end
                    break
                else
                    lowerlimit = rlimit+1
                end
            end

            --证物池子
            local pool={}
            for k,pinfo in ipairs(stargazerCfg.oneRansackItem) do
                local pinfoArr = string.split(pinfo[1],"%_")
                local ranid = tostring(pinfoArr[2])
                local weight = pinfo[2]
                if actinfo.ackinfo.info[tostring(ranid)] and actinfo.ackinfo.info[tostring(ranid)]>=limitnum then
                else
                    pool[ranid] = weight
                end
            end

            --增加证物
            if ransackflag and pool then
                local ranid = getKeyByRnd(pool)
                if ranid then
                    actinfo.ackinfo.info[tostring(ranid)] = actinfo.ackinfo.info[tostring(ranid)]+1
                    ranstotalnum = ranstotalnum + 1
                    actinfo.singlechipnum = actinfo.singlechipnum + 1

                    if not ransrewards then
                        ransrewards = "6_"..ranid.."_1"
                    else
                        ransrewards = ransrewards.."|".."6_"..ranid.."_1"
                    end

                    ranstotalinfo[tostring(ranid)] = ranstotalinfo[tostring(ranid)] or 0
                    ranstotalinfo[tostring(ranid)] = ranstotalinfo[tostring(ranid)]+1
                end
            end
        else
            return false
        end
    end

    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end

    return true,generalrewards,ranstotalnum,ransrewards,ranstotalinfo
end

-- 夜观天象周年庆-十连搜查
function tenStaZerSearch(uid, activeId, code)
    local anum = 10
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local stargazerCfg = getConfig("stargazerCfg", "activecfg")[code]
    local limitnum = tonumber(stargazerCfg.RansackItemNum)
    local ransrewards

    if actinfo.cannum>=anum then
        actinfo.cannum = actinfo.cannum - anum
    else
        return false
    end
    
    --证物池子
    local pool={}
    for k,pinfo in ipairs(stargazerCfg.tenRansackItem) do
        local pinfoArr = string.split(pinfo[1],"%_")
        local ranid = tostring(pinfoArr[2])
        local weight = pinfo[2]
        if actinfo.ackinfo.info[tostring(ranid)] and actinfo.ackinfo.info[tostring(ranid)]>=limitnum then
        else
            pool[ranid] = weight
        end
    end

    --增加证物
    if pool then
        local ranid = getKeyByRnd(pool)
        if ranid then
            actinfo.ackinfo.info[tostring(ranid)] = actinfo.ackinfo.info[tostring(ranid)]+1
            ransrewards = "6_"..ranid.."_1"
        end
    end

    local generalrewards
    for i=1,anum do
        --获得必得奖励
        local randreward = getKeyByArrRnd(stargazerCfg.RansackPool)
        if generalrewards then
            generalrewards = generalrewards .. "|" .. randreward
        else
            generalrewards = randreward
        end
    end

    local rewards
    if generalrewards then
        rewards = mergeRewards(generalrewards)
    end
    if ransrewards then
        rewards = rewards.."|"..ransrewards
    end

    return true,rewards
end

-- 夜观天象单人版活动单次搜查
function singleAttackStargazerSingle(uid, activeId, code, anum)
    local anum = tonumber(anum)
    if not anum or anum <= 0 then
        return false
    end

    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local stargazerSingleCfg = getConfig("stargazerSingleCfg", "activecfg")[code]
    local ransacklimit = tonumber(stargazerSingleCfg.RansackItemNum)
    local rtreward = "6_" .. stargazerSingleCfg.RansackItemID
    local rewards,generalrewards
    local getransack,resflag = 0,false

    for i=1,anum do
        if actinfo.attacknum > 0 and actinfo.chipnum < ransacklimit then
            --获得随机奖励
            local randreward = getKeyByArrRnd(stargazerSingleCfg.RansackPool)
            actinfo.singlenum = actinfo.singlenum + 1
            actinfo.attacknum = actinfo.attacknum - 1
            if not generalrewards then
                generalrewards = randreward
            else
                generalrewards = generalrewards .. "|" .. randreward
            end

            --随机获得证物
            local upperlimit,lowerlimit,ransackflag = 0,0,false
            for round,rlimit in ipairs(stargazerSingleCfg.Range) do
                if actinfo.singlechipnum < round then
                    upperlimit = rlimit
                    if actinfo.singlenum >= rand(lowerlimit,upperlimit) then
                        ransackflag = true
                    end
                    break
                else
                    lowerlimit = rlimit+1
                end
            end

            --增加证物
            if ransackflag and actinfo.chipnum < ransacklimit then
                actinfo.chipnum = actinfo.chipnum + 1
                getransack = getransack + 1
                actinfo.singlechipnum = actinfo.singlechipnum + 1
            end
            resflag = true
        else
            break
        end
    end

    -- if rewards then
    --     rewards = mergeRewards(rewards)
    -- end
    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end
    if getransack > 0 then
        rewards = rtreward .. "_" .. getransack .. "|" .. generalrewards
    else
        rewards = generalrewards
    end
    return resflag,rewards,getransack,generalrewards
end

-- 夜观天象单人版活动十连搜查
function tenAttackStargazerSingle(uid, activeId, code)
    local anum = 10
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local stargazerSingleCfg = getConfig("stargazerSingleCfg", "activecfg")[code]
    local ransacklimit = tonumber(stargazerSingleCfg.RansackItemNum)
    local rewards

    --增加证物
    if actinfo.attacknum >= anum and actinfo.chipnum < ransacklimit then
        local addchipnum = tonumber(stargazerSingleCfg.RansackRewardNum)
        actinfo.chipnum = actinfo.chipnum + addchipnum
        rewards = stargazerSingleCfg.RansackItem
    else
        return false
    end

    actinfo.tennum = actinfo.tennum + anum
    actinfo.attacknum = actinfo.attacknum - anum

    local generalrewards
    for i=1,anum do
        --获得随机奖励
        local randreward = getKeyByArrRnd(stargazerSingleCfg.RansackPool)
        if generalrewards then
            generalrewards = generalrewards .. "|" .. randreward
        else
            generalrewards = randreward
        end
    end

    if generalrewards then
        generalrewards = mergeRewards(generalrewards)
    end
    rewards = rewards .. "|" .. generalrewards

    return true,rewards
end

-- 夜观天象单人版活动继承血量检测
function checkStargazerSingle(uid, activeId, code)
    local stargazerSingleCfg = getConfig("stargazerSingleCfg", "activecfg")[code]

    local uobjs = getUserObjs(uid)
    local mServant = uobjs.getModel('servant')
    local servantId = tostring(stargazerSingleCfg.TraitorId)
    local skinId = tostring(stargazerSingleCfg.TraitorSkinId)
    if mServant.info[servantId] and mServant.info[servantId].skin and mServant.info[servantId].skin[skinId] then
        --有皮肤则消除活动
        return true
    else
        --boss血量扣除
        local mItem = uobjs.getModel('item')
        local ItemId = tostring(stargazerSingleCfg.RansackItemID)
        local pnum = tonumber(mItem.info[ItemId]) or 0
        return false,pnum
    end
end

--每日充值补充活动的奖励获取
function getRewardByDailyChargeExtraId(uid,rkey,stTime,etTime)
    local activeId = "dailyChargeExtra"
    local addRewards = ""
    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local dailyChargeExtraCfg = getConfig("dailyChargeExtraCfg","activecfg")
    -- local now = os.time()
    for k,v in pairs(mActivity.info) do
        if v.aid == activeId then
            if v.st==stTime and v.et <= etTime then
                local code = v.code
                if dailyChargeExtraCfg[code][tostring(rkey)] then
                    if addRewards ~= "" then
                        addRewards = addRewards .."|"
                    end
                    addRewards = addRewards..dailyChargeExtraCfg[code][tostring(rkey)].reward
                end
            end
        end
    end
        
    return addRewards
end

--狂欢之夜攻击
function carnivalNightAttacks(num,code,flag)
    local randItems = {}
    local carnivalNightCfg
    if flag then
        carnivalNightCfg = getConfig("carnivalNight2Cfg","activecfg")
    else
        carnivalNightCfg = getConfig("carnivalNightCfg","activecfg")
    end
    local CriticalRate = carnivalNightCfg[code].CriticalRate
    local CriticalEffect = carnivalNightCfg[code].CriticalEffect
    local baseReward = carnivalNightCfg[code].reward
    if not baseReward then
        return false
    end
    
    local isLuck = false
    for i=1,num,1 do
        table.insert(randItems, baseReward)
        --本次是否暴击
        local rankNum = math.random(1, 100)
        --是否发生了暴击
        if tonumber(CriticalRate)*100 >= rankNum then
            --发生暴击时 当前奖励再给暴击效果次
            isLuck = true
            for i=1,CriticalEffect do
                table.insert(randItems, baseReward)
            end
        end
    end
    local rewards = ""
    for _,addreward in ipairs(randItems) do
        if rewards ~= "" then
            rewards = rewards .. "|"
        end
        rewards = rewards .. addreward
    end
    
    return isLuck,mergeRewards(rewards)
end

--一次寻访-前几次寻访必出红颜
function onePlaySearchByControlKey(uid,NowSearchNum)
    local uobjs = getUserObjs(uid)
    local mSearch = uobjs.getModel('search')
    local mWife = uobjs.getModel('wife')

    --自动补充运势
    mSearch.autoSetLucky()
    
    local luckyListCfg = getConfig('searchBaseCfg')
    local searchCfg = getConfig('searchCfg')
    --设置权重
    local personLuckyList = luckyListCfg.searchList[NowSearchNum]

    --获取随机人物
    local randKey = getKeyByRnd(personLuckyList)
    if not randKey then
        writeLog(json.encode(personLuckyList), 'randKey') 
        return false
    end

    --获取奖励
    local addFlag = false
    local reward = ""
    local personListCfg = searchCfg['personList']
    local wifeId = personListCfg[randKey]["wifeId"]
    
    --增加进度
    addFlag = mSearch.addProgress(randKey, 1)
    
    --获取红颜
    if not mWife.info[wifeId] and mSearch.getProgress(randKey) >= personListCfg[randKey]['value'] then
        mWife.addWife(wifeId)
        regReturnModel({"servant"})
    end
    
    --增加亲密度
    if mWife.info[wifeId] and mSearch.getProgress(randKey) ~= personListCfg[randKey]['value'] then
        addFlag = mWife.addIntimacy(wifeId) 
        reward = "9_0_1"
        regReturnModel({"wife"})
    end

    if not addFlag then
        return false
    end

    --使用体力
    local useFlag = mSearch.useStrength()
    --减少运势
    mSearch.useLucky(2)

    --自动补充运势
    mSearch.autoSetLucky()
    
    if useFlag then
        regReturnModel({"search"})
        return randKey,reward
    end
    return false
end

--日本检测函数
function jpCheckMsgInfo(adata)
    local now = os.time()
    local uid = tonumber(adata.actor_id)
    local uobjs = getUserObjs(uid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    local mGameinfo = uobjs.getModel('gameinfo')

    --adata.dsid = getZoneId()
    adata.uid = mGameinfo.pid
    adata.user_ip = mGameinfo.ip
    adata.actor_name = mUserinfo.name
    if adata.type == 1 then
        adata.type_channel_id = 1
    elseif adata.type == 2 then
        adata.type_channel_id = mUserinfo.mygid
    elseif adata.type == 5 then
        adata.type_channel_id = 2
    elseif adata.type == 8 then
        adata.type_channel_id = 3
    end
    adata.gid = 50002
    adata.platid = '6'
    adata.time = now

    local cmdParams = {uid=uid, cmd=getCmd() ,params=adata, cron_type="jpchat"}
    local setFlag = setGameCron(cmdParams, 2)
    if not setFlag then
        writeLog({uid=uid,cron="jpchat",now=os.time(),cmd=getCmd()}, "setChatCronWrong")
    end
end

--韩国检测函数
function krCheckMsgInfo(adata)
    local now = os.time()
    local uid = tonumber(adata.actor_id)
    local uobjs = getUserObjs(uid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    local mGameinfo = uobjs.getModel('gameinfo')

    adata.dsid = getZoneId()
    adata.uid = mGameinfo.pid
    adata.user_ip = mGameinfo.ip
    adata.actor_name = mUserinfo.name
    if adata.type == 1 then
        adata.type_channel_id = 1
    elseif adata.type == 2 then
        adata.type_channel_id = mUserinfo.mygid
    elseif adata.type == 5 then
        adata.type_channel_id = 2
    elseif adata.type == 8 then
        adata.type_channel_id = 3
    end
    adata.gid = 60163
    adata.platid = '7'
    adata.time = now

    local key = "global_2sd47Udu3234adsdf60163"
    local signstr = key..adata.uid..adata.gid..adata.dsid..now..adata.type
    adata.sign = string.lower(md5(signstr))

    local postData
    local URL = require "lib.url"
    for k,v in pairs(adata) do
        local tmpvalue = URL:url_escape(tostring(v))
        if postData then
            postData = postData .. "&" .. k .. "=" .. tmpvalue
        else
            postData = "" .. k .. "=" .. tmpvalue
        end
    end

    local http = require("socket.http")
    http.TIMEOUT = 1
    local signurl = "http://cmapi.37games.com/Content/_requestContent"
    local tmp  = http.request(signurl, postData)
    local res = json.decode(tmp)
    return res
end

--普遍检测函数
function allCheckMsgInfo(adata)
    local key
    if PLATFORM == "jp" then
        key = "jp_yhjyfsf@#37games50002"
        adata.gid = 50002
        adata.platid = '6'
    elseif PLATFORM == "krnew" then
        key = "global_2sd47Udu3234adsdf60163"
        adata.gid = 60163
        adata.platid = '7'
    elseif PLATFORM == "wg_sea" or PLATFORM == "wg_eur" then
        key = "global_yhjyfsf@#sfdsf60181"
        adata.gid = 60181
        adata.platid = '7'
    else
        return false
    end

    local now = os.time()
    local uid = tonumber(adata.actor_id)
    local uobjs = getUserObjs(uid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    local mGameinfo = uobjs.getModel('gameinfo')

    adata.dsid = getZoneId()
    adata.uid = mGameinfo.pid
    adata.user_ip = mGameinfo.ip
    adata.actor_name = mUserinfo.name
    if adata.type == 1 then
        adata.type_channel_id = 1
    elseif adata.type == 2 then
        adata.type_channel_id = mUserinfo.mygid
    elseif adata.type == 5 then
        adata.type_channel_id = 2
    elseif adata.type == 8 then
        adata.type_channel_id = 3
    end
    adata.time = now

    local signstr = key..adata.uid..adata.gid..adata.dsid..now..adata.type
    adata.sign = string.lower(md5(signstr))

    local postData
    local URL = require "lib.url"
    for k,v in pairs(adata) do
        local tmpvalue = URL:url_escape(tostring(v))
        if postData then
            postData = postData .. "&" .. k .. "=" .. tmpvalue
        else
            postData = "" .. k .. "=" .. tmpvalue
        end
    end

    local http = require("socket.http")
    http.TIMEOUT = 1
    local signurl = "http://cmapi.37games.com/Content/_requestContent"
    local tmp  = http.request(signurl, postData)
    local res = json.decode(tmp)
    return res
end

-- 情人节红颜衣装活动继承检测
function checkValentine(uid, activeId, code)
    local valentineCfg = getConfig("valentineCfg", "activecfg")[code]

    local uobjs = getUserObjs(uid)
    --血量扣除
    local mItem = uobjs.getModel('item')
    local ItemId = tostring(valentineCfg.wifeSkinInheritItemID)
    local pnum = tonumber(mItem.info[ItemId]) or 0
    local pos = 0
    if pnum > 0 then
        for i,v in ipairs(valentineCfg.progress) do
            if pnum >= v.needNum and i > pos then
                pos = i
            end
        end
    end
    return pnum,pos
end

-- 计算格式化年月后的月份差值
function calmonthnum(prenum, lastnum)
    local prenum = tonumber(prenum)
    local lastnum = tonumber(lastnum)
    if not prenum or prenum < 200001 or not lastnum or lastnum < 200001 then
        return false
    end
    local preyear = math.floor(prenum/100)
    local lastyear = math.floor(lastnum/100)
    local premonth = prenum % 100
    local lastmonth = lastnum % 100
    local monthnum = (preyear - lastyear) * 12 + premonth - lastmonth
    return monthnum
end

--计算门客资质等级上限 extra{sid,abid} 有资质id算本资质书id
function calmaxabilitylv(uid,clv,extra)
    uid = tonumber(uid)
    local scrollroomCfg = getConfig("scrollroomCfg")
    local servantBaseCfg = getConfig("servantBaseCfg")
    local mlv = servantBaseCfg.servantLvList[tostring(clv)].abilityLv
    local uplv = 0

    local uobjs = getUserObjs(uid)
    local mOtherinfo = uobjs.getModel('otherinfo')

    --藏书阁上限
    if (PLATFORM=="krnew" or PLATFORM=="wg_sea") and isSwitchTrue(uid,"openScrollRoom") then
        mOtherinfo.info.scrollroom = mOtherinfo.info.scrollroom or {}
        local tmplv = mOtherinfo.info.scrollroom.lv
        if tmplv and tmplv > 0 then
            local roominfo = scrollroomCfg.poolList
            if roominfo[tmplv] then
                mlv = math.max(roominfo[tmplv].abilityLvLimit,mlv)
            end
        end
    end
    --丹药资质增加
    if extra and extra.sid and extra.abid then
        uplv = mOtherinfo.getItemAbilityUp(extra.sid, extra.abid)
    end

    return mlv+uplv
end

------------------------------------------------灯火元宵随机地图2 开始---------------------------------------------
function lineMapNum(code,scenenum)
    local discorveryCfg = getConfig("discorveryCfg","activecfg")[code]
    local maxSceneNum = discorveryCfg.floorNum
    local floorCfg = discorveryCfg.floor
    if scenenum > maxSceneNum or not discorveryCfg['floor'..scenenum] or not floorCfg[scenenum] then
        return false
    end
    local rewardPoolCfg = discorveryCfg['floor'..scenenum]
    --都有哪些奖励
    local reward_arr = {}
    for i,indexPool in ipairs(rewardPoolCfg) do
        local pool={}
        for k,pinfo in ipairs(indexPool) do
            pool[k] = pinfo.weight
        end
        --增加证物
        if pool and next(pool) then
            local ranid = getKeyByRnd(pool)
            if ranid then
                reward_arr[tostring(i)] = ranid
            end
        end
    end
    
    local specialmap = {}
    
    local floorNum = floorCfg[scenenum]['obstacleNum']
    local haveKeyMap = {}
    local lastId = 1
    if floorNum > 0 then
        local nowRandNum = 1
        local randKeyMap = {}
        haveKeyMap = {["1"] = 0}
        local baseRand = 10
        local randAddCost = 1
        while nowRandNum + floorNum < 25 do
            baseRand = baseRand + randAddCost
            local canGoArr = getMapIDround(haveKeyMap,lastId)
            for i,v in ipairs(canGoArr) do
                randKeyMap[tostring(v)] = baseRand
            end
            local ranid = getKeyByRnd(randKeyMap)
            if not ranid then
                return false
            end
            haveKeyMap[tostring(ranid)] = 1
            lastId = tonumber(ranid)
            randKeyMap[tostring(ranid)] = nil
            nowRandNum = nowRandNum + 1
        end
        
        for i=1,25 do
            if not haveKeyMap[tostring(i)] then
                specialmap[tostring(i)] = 99
            end
        end
    else
        local nextMapArr = {}
        for i=2,25 do
            if i ~= 2 and i ~= 6 then
                nextMapArr[tostring(i)] = 1
            end
            haveKeyMap[tostring(i)] = 1
        end
        lastId = getKeyByRnd(nextMapArr)
    end
    haveKeyMap[tostring(lastId)] = 0
    specialmap[tostring(lastId)] = 100--这个地块是穿越门
    for k,v in pairs(reward_arr) do
        local ranid = getKeyByRnd(haveKeyMap)
        specialmap[tostring(ranid)] = tonumber(k)
        haveKeyMap[tostring(ranid)] = nil
    end
    return true,reward_arr,specialmap
end

--获取四周的格子
function getMapIDround(mapArr,mapid)
    --[[
        1   2   3   4   5
        6   7   8   9   10
        11  12  13  14  15
        16  17  18  19  20
        21  22  23  24  25
    ]]
    local nowIdInfo = getMapIdInfo(mapid)
    local leftInfo = getMapIdInfo(mapid - 1)
    local rightInfo = getMapIdInfo(mapid + 1)
    local upInfo = getMapIdInfo(mapid - 5)
    local downInfo = getMapIdInfo(mapid + 5)
    local canGoTb = {}
    --只要同行或同列  并且 还在随机库里 是空白格子 及不被堵死
    if leftInfo[2] > 0 and leftInfo[2] == nowIdInfo[2] and not mapArr[tostring(leftInfo[1])] then
        table.insert(canGoTb,leftInfo[1])
    end
    if rightInfo[2] > 0 and rightInfo[2] == nowIdInfo[2] and not mapArr[tostring(rightInfo[1])] then
        table.insert(canGoTb,rightInfo[1])
    end
    if upInfo[3] > 0 and upInfo[3] == nowIdInfo[3] and not mapArr[tostring(upInfo[1])] then
        table.insert(canGoTb,upInfo[1])
    end
    if downInfo[3] > 0 and downInfo[3] == nowIdInfo[3] and not mapArr[tostring(downInfo[1])] then
        table.insert(canGoTb,downInfo[1])
    end
    return canGoTb
end

--获取当前id的行列
function getMapIdInfo(mId)
    if mId <= 0 or mId > 25 then
        return {mId,-1,-1}
    end
    local lineNum = math.ceil(mId/5)
    local rowNum = mId - (math.floor(mId/5)*5)
    
    return {mId,lineNum,rowNum}
end
------------------------------------------------灯火元宵随机地图2 结束---------------------------------------------

-- 缓存进度假数据
function makingratefakedata(key, days, limitnum, usenum)
    local redis = getRedis()
    local tmpnum = redis:get(key)
    tmpnum = tonumber(tmpnum) or 0
    local accnum = (days-1) * limitnum
    if days > 0 and tmpnum < accnum then
        local lowest = (days-2) * limitnum
        if lowest > 0 and tmpnum < lowest then
            redis:setex(key,864000,lowest)
            --tmpnum = lowest
        else
            local tmpadd = math.floor(limitnum / 1000)
            usenum = usenum + tmpadd
        end
    end
    if usenum > 0 then
        redis:incrby(key,usenum)
        redis:expire(key,864000)
    end
    return redis:get(key)
end

--雄霸天下增加跨服称号
---@param titleList table 称号奖励列表 {["11_titleID_1"]={{uid=玩家uid,zid=区服},...}}
---@param balanceTime number 结算时间
---@param zidgroup table 区服列表 {zid1,zid2..}
---@param group number pk组ID
---@param version number 活动版本(开始时间)
function setCrossCityBattleTitle(titleList,balanceTime,zidgroup,group,version)
    local titleCfg = getConfig('titleCfg')
    local zid,st = getZoneId(),tonumber(balanceTime)
    local tData = {}
    --设置本服
    for rewards, uidList in pairs(titleList) do
        local reward_v = string.split(rewards, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        if rewardType == 11 and titleCfg[rewardId] and titleCfg[rewardId].isTitle == 1 then
            if titleCfg[rewardId].isCross == 1 then
                local et = st+titleCfg[rewardId].lastTime
                for _, uinfo in pairs(uidList) do
                    --记录跨服称号(雄霸天下称号不是唯一称号,同一称号可能有多人)
                    -- setCrossTitle(rewardId,uinfo.uid,uinfo.zid,"",nil,st,et) 
                    table.insert(tData, {
                        titleId = rewardId, uid = uinfo.uid, zid = uinfo.zid, st = st, et = et
                    })
                end
            end
        end
    end

    --所有称号一次设置
    setMoreCrossTitle(tData)

    local balanceKey = "crosscitybattle.balancePalaceTitle-"..group.."."..version
    --设置结算标记
    local commonRedis = getCommonRedis()
    commonRedis:hset(balanceKey,tostring(zid),1)
    commonRedis:expire(balanceKey, 86400*10)

    --同步跨服
    if zidgroup and type(zidgroup)=="table" and next(zidgroup) and table.length(zidgroup)>0 then
        for _,uzid in pairs(zidgroup) do
            if tonumber(uzid)~=tonumber(zid) then
                --同步称号数据
                local cmdName = "crosscitybattleadminapi.synctitle"
                getCrossinfoApi(tonumber(uzid)*100000+1,tonumber(uzid),cmdName,{tData= tData,group = group,version = version})
            end
        end
    end
end

--增加跨服记录
function setCrossHegemonyTitle(rewards,uid,bmst,zidArr,sendTime)
    local rewards_table = string.split(rewards, "%|")
    local titleCfg = getConfig('titleCfg')
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        if rewardType == 11 and tonumber(rewardId) == 3501 then
            local etTime = 1
            if (PLATFORM == "cn_37wx" or PLATFORM == "cn_7477mg") and titleCfg['3501'].lastTime then
                etTime = sendTime + titleCfg['3501'].lastTime
            end
            
            setHegemonyTitle(uid,bmst,etTime) --记录跨服称号

            if zidArr and type(zidArr)=="table" and next(zidArr) and table.length(zidArr)>0 then
                for _,uzid in pairs(zidArr) do
                    if uzid and tonumber(uzid)~=tonumber(getZoneId()) then
                        local cmdName = "achegemonyadminapi.settitle"
                        getCrossinfoApi(uzid*100000+1,uzid,cmdName,{auid =uid,bmst = bmst,ettime=etTime})
                    end
                end
            end
            break
        end
    end
end

--设置神威将军
function setHegemonyTitle(uid,version,etTime)
    if uid<=0 or version<=0 then
        return false
    end

    local acHegemony
    local key = "z" .. getZoneId() .. ".acHegemony"
    local redis = getRedis()
    local acHegemonyJson = redis:get(key)
    if not acHegemonyJson then
        local data = getBakData(key)
        if data then
            redis:set(key, data)
            acHegemony = json.decode(data)
        end
    else
        acHegemony = json.decode(acHegemonyJson)
    end

    if not acHegemony then
        acHegemony = {}
        acHegemony.rank = {}
        acHegemony.version = 0
    end
    
    if version > acHegemony.version then
        if (PLATFORM == "cn_37wx" or PLATFORM == "cn_7477mg") and etTime and etTime > 1 then
            acHegemony.version = version
        else
            acHegemony = {}
            acHegemony.rank = {}
            acHegemony.version = version
        end
    end

    if not acHegemony.rank then
        acHegemony.rank = {}
    end
    if not acHegemony.rank[tostring(uid)] then
        acHegemony.rank[tostring(uid)] = 1
        if (PLATFORM == "cn_37wx" or PLATFORM == "cn_7477mg") and etTime and etTime > 1 then
            acHegemony.rank[tostring(uid)] = etTime
        end
        redis:set(key,json.encode(acHegemony))
        recordBakData(key,json.encode(acHegemony))
    end
end

--获取神威将军
function getHegemonyTitle()
    local acHegemony
    local key = "z" .. getZoneId() .. ".acHegemony"
    local redis = getRedis()
    local acHegemonyJson = redis:get(key)
    if not acHegemonyJson then
        local data = getBakData(key)
        if data then
            redis:set(key, data)
            acHegemony = json.decode(data)
        end
    else
        acHegemony = json.decode(acHegemonyJson)
    end

    if not acHegemony then
        acHegemony = {rank = {}}
    end
    if PLATFORM == "cn_37wx" or PLATFORM == "cn_7477mg" then
        local now = os.time()
        local newRank = {}
        for uid, et in pairs(acHegemony.rank) do
            if et == 1 or et > now then
                newRank[tostring(uid)] = et
            end
        end
        acHegemony.rank = newRank
    end
    return acHegemony
end

--转换坐标为数
function transCoordToNum(x,y,wth)
    if not x or not y or not wth then
        return false
    end
    local pos = y*(wth+2)+x
    
    return pos
end

--转换数为坐标
function transNumToCoord(pos,wth)
    if not pos or not wth then
        return false
    end
    local y = math.floor(pos/(wth+2))
    local x = pos % (wth+2)
    
    return x,y
end

--转换配置地图数组
function transConfigMap(cinfo,width)
    if not cinfo or not next(cinfo) or not width then
        return false
    end

    local res = {}
    for _,v in pairs(cinfo) do
        local x,y = v.coordinate[2],v.coordinate[1]
        local pos = transCoordToNum(x,y,width)
        table.insert(res,pos)
    end
    
    return res
end

--生成随机图案数组
function getRandPicArr(pnum,tnum)
    if not pnum or not tnum or pnum > tnum then
        return false
    end

    local randarr = {}
    for i=1,tnum do
        table.insert(randarr,i)
    end
    local res = {}
    for i=1,pnum do
        local len = #randarr
        local tmp = rand(1,len)
        table.insert(res,randarr[tmp])
        table.remove(randarr,tmp)
    end
    
    return res
end

--获取连连看地图信息
function getLinkMapInfo(marr,parr,rnum)
    if not marr or not next(marr) or not parr or not next(parr) or not rnum then
        return false
    end
    local mlen = #marr
    local plen = #parr
    local arr = {}
    local count = 1
    for i=1,mlen,2 do
        local pos = tostring(marr[i])
        local tmp = count % plen + 1
        arr[pos] = parr[tmp]
        pos = tostring(marr[i+1])
        arr[pos] = parr[tmp]
        count = count + 1
    end

    --随机交换
    for i=1,rnum do
        local r1 = rand(1,mlen)
        local r2 = rand(1,mlen)
        local pos1 = tostring(marr[r1])
        local pos2 = tostring(marr[r2])
        local tmp = arr[pos1]
        arr[pos1] = arr[pos2]
        arr[pos2] = tmp
    end
    
    return arr
end

--获取指定位置可消图数组
function getTheLinkPos(marr,p1,len,wth)
    if not marr or not next(marr) or not p1 or not len or not wth then
        return false
    end
    local resarr = {} --可消除数组
    local blankarr = {} --目前中转数组
    local tmparr = {} --下层中转数组
    local rearr = {} --访问过数组

    local function checkMapPosition(px,py)
        local pos = transCoordToNum(px,py,wth)
        local spos = tostring(pos)
        if marr[spos] then
            resarr[spos] = 1
            return true
        end
        if rearr[spos] then
            return false
        end
        rearr[spos] = 1
        tmparr[spos] = 1
        return false
    end

    --按广度优先搜索获取指定位置的可消除数组
    local function getLinkPosByBFS(x,y)
        --向左
        for i=x-1,0,-1 do
            if checkMapPosition(i,y) then
                break
            end
        end
        --向右
        for i=x+1,wth+1 do
            if checkMapPosition(i,y) then
                break
            end
        end
        --向上
        for i=y-1,0,-1 do
            if checkMapPosition(x,i) then
                break
            end
        end
        --向下
        for i=y+1,len+1 do
            if checkMapPosition(x,i) then
                break
            end
        end

        return
    end
    
    blankarr[tostring(p1)] = 1
    --3层搜索(0弯，1弯，2弯)
    for sid=1,3 do
        for k,_ in pairs(blankarr) do
            local cx,cy = transNumToCoord(tonumber(k),wth)
            getLinkPosByBFS(cx,cy)
        end
        blankarr = tmparr
        tmparr = {}
    end

    return resarr
end

--生成有免费可消图地图
function getFreeTheLinkMap(marr,fnum,len,wth)
    if not marr or not next(marr) or not fnum or fnum < 1 or not len or not wth then
        return false
    end
    local tmparr = {} --随机数组

    for p,pv in pairs(marr) do
        table.insert(tmparr,p)
    end

    local function findtable(tarr, tnum)
        for i,v in ipairs(tarr) do
            if v == tnum then
                return i
            end
        end
        return false
    end
    
    for i=1,fnum do
        if #tmparr < 2 then
            return false
        end
        if #tmparr == 2 then
            return marr
        end
        local pnum = rand(1,#tmparr)
        local pos = tmparr[pnum]
        table.remove(tmparr,pnum)
        local parr = getTheLinkPos(marr,tonumber(pos),len,wth)
        if not parr or not next(parr) then
            return false
        end
        local tmpflag
        for k,_ in pairs(parr) do
            if k ~= pos and marr[pos] == marr[k] then
                tmpflag = nil
                local di = findtable(tmparr, k)
                table.remove(tmparr,di)
                break
            elseif k ~= pos then
                tmpflag = k
            end
        end
        if tmpflag then
            local di = findtable(tmparr, tmpflag)
            table.remove(tmparr,di)
            for tp,tv in pairs(marr) do
                if tp ~= pos and tv == marr[pos] then
                    local tmp = marr[tmpflag]
                    marr[tmpflag] = marr[tp]
                    marr[tp] = tmp
                    break
                end
            end
        end
    end

    return marr
end

function getKeyTitleData(key)
    local redis = getRedis()
    local palaceData = redis:get(key)
    if not palaceData then
        local data = getBakData(key)
        if data then
            palaceData = json.decode(data)
        end
    else
        palaceData = json.decode(palaceData)
    end

    return palaceData
end

--清理特殊称号
function clearAllSpecialTitle(uid)
    local crosstitle = "z" .. getZoneId() .. ".crosstitle"
    local crossData = getKeyTitleData(crosstitle)
    local redis = getRedis()

    if crossData and next(crossData) then
        local flag = false
        for tid,v in pairs(crossData) do
            local tmpuid = tonumber(v.uid)
            if tmpuid == uid then
                v.uid = nil
                v.zid = nil
                v.sign = nil
                flag = true
            end
        end

        if flag then
            local dataStr = json.encode(crossData)
            redis:set(crosstitle, dataStr)
            --记录数据入库
            recordBakData(crosstitle,dataStr)
        end
    end

    local onlytitle = "z" .. getZoneId() .. ".onlytitle"
    local onlyData = getKeyTitleData(onlytitle)

    if onlyData and next(onlyData) then
        local flag = false
        for tid,v in pairs(onlyData) do
            local tmpuid = tonumber(v.uid)
            if tmpuid == uid then
                v.uid = nil
                v.zid = nil
                v.sign = nil
                flag = true
            end
        end

        if flag then
            local dataStr = json.encode(onlyData)
            redis:set(onlytitle, dataStr)
            --记录数据入库
            recordBakData(onlytitle,dataStr)
        end
    end
end

--武田活动判断是否已有红颜了
function checkXinxuanInit(uid, aid, code)
    local xinxuanCfg = getConfig("xinxuanCfg", "activecfg")[code]
    local wifeID = tostring(xinxuanCfg.wifeID)
    local servantID = tostring(xinxuanCfg.servantID)
    
    local uobjs = getUserObjs(uid)
    local mWife = uobjs.getModel('wife')
    local mServant = uobjs.getModel('servant')
    
    local showflag = 1
    if mWife.info[wifeID] and mServant.info[servantID] then
        showflag = 0
    end

    return showflag
end

--购买府邸活动判断是否已有场景
function checkBuyHouseInit(uid, aid, code)
    local buyHouseCfg = getConfig("buyHouseCfg", "activecfg")[code]
    local homeSenceId = tostring(buyHouseCfg.homeSenceId)

    local uobjs = getUserObjs(uid)
    local mOtherinfo = uobjs.getModel('otherinfo')
    local sceneInfo = mOtherinfo.info.sceneinfo
    local showflag = 1
    if sceneInfo and sceneInfo.idinfo and sceneInfo.idinfo[homeSenceId] then
        showflag = 0
    end

    return showflag
end

--随机请求端口
function randCrossApiSerPort(tozid,cmd)
    local serverCfg = getConfig("config")
    local fzid = getZoneId()
    local fuid = getMyuid()
    local fhost = serverCfg["z"..fzid]['server']['host'] or ""
    local fport = serverCfg["z"..fzid]['server']['port'] or 0

    local loginHostUidKey = "z"..fzid..".loginhostUid."..fuid
    local redis = getRedis()
    local sdata = redis:get(loginHostUidKey)
    if sdata and sdata~="" then
        sdata = json.decode(sdata)
        fhost =  sdata[1]
        fport = sdata[2]
    else
        --writeLog({fuid=fuid,fzid=fzid,loginHostUidKey=loginHostUidKey,tozid=tozid,cmd=cmd}, 'badServerPortLog')
    end

    local thost = serverCfg["z"..tozid]['server']['host']
    local tport = serverCfg["z"..tozid]['server']['port']
    if fhost==thost and tonumber(fport)==tonumber(tport) then
        local portPoll = {}
        for i=1,9 do
            if (tonumber(tport)-15000)~=i then
                table.insert(portPoll, tonumber(i)+15000)
            end
        end
        local ridx = rand(1,#portPoll)
        --writeLog({fzid=fzid,fhost=fhost,fport=fport,tzid=tozid,thost=thost,tport=portPoll[ridx],cmd=cmd}, 'randServerPortLog')
        return portPoll[ridx]
    end

    return tonumber(tport)
end

--得到真实奖池(去除不合格道具)
function getRealPoolArr(uid, pool)
    uid = tonumber(uid)
    if not uid or not pool or not next(pool) then
        return false
    end
    local uobjs = getUserObjs(uid)
    local mItem = uobjs.getModel('item')
    local poolarr = {}
    for _,str in pairs(pool) do
        local rewards = str[1]
        local rewards_table = string.split(rewards, "%|")
        local addFlag = true
        for k, v in pairs(rewards_table) do
            local reward_v = string.split(v, "%_")
            local rewardType = tonumber(reward_v[1])
            local rewardId = tostring(reward_v[2])
            local rewardNum = tonumber(reward_v[3])
            if rewardType == 6 and mItem.checkSpecialItemNum(rewardId,rewardNum) then
                addFlag = false
                break
            end
        end
        if str[2]>0 and addFlag then
            table.insert(poolarr,str)
        end
    end

    return poolarr
end

--获取内府门客能力值
function getOfficeServantAnum(total)
    total = tonumber(total)
    if not total or total < 0 then
        return false
    end
    local homeOfficeCfg = getConfig("homeOfficeCfg")
    local abilityExchange = homeOfficeCfg.abilityExchange
    local anum = 0
    for _,v in pairs(abilityExchange) do
        if total >= v.servantPower and v.ability > anum then
            anum = v.ability
        end
    end
    return anum
end

--搜索内府名称
function getUidByOfficeName(name)
    local db = getDbo()
    local result = db:getRow("select uid from homeoffice where name=:name", { name = name })
    if type(result) == 'table' and result['uid'] then
        return tonumber(result['uid'])
    end
    return 0
end

--获取擂台战斗力额外buff
function getAllAtkAttackBuff(uid)
    uid = tonumber(uid)
    if not uid then
        return false
    end
    local uobjs = getUserObjs(uid,true)
    local mHomeoffice = uobjs.getModel('homeoffice')
    local buff = 0
    --内府buff
    buff = buff + mHomeoffice.getAtkAttackBuffData()
    return buff
end

--获取美人绘卷地图信息
function getTurnMapInfo(mlen,parr,rnum)
    mlen = tonumber(mlen)
    if not mlen or not parr or not next(parr) or not rnum then
        return false
    end
    local plen = #parr
    local arr = {}
    local count = 1
    for i=1,mlen,2 do
        local tmp = count % plen + 1
        arr[i] = parr[tmp]
        arr[i+1] = parr[tmp]
        count = count + 1
    end

    --随机交换
    for i=1,rnum do
        local r1 = rand(1,mlen)
        local r2 = rand(1,mlen)
        local tmp = arr[r1]
        arr[r1] = arr[r2]
        arr[r2] = tmp
    end
    
    return arr
end

-- 美人花活动攻击
function beautyFlowerLottery(uid, activeId, code, anum)
    local anum = tonumber(anum)
    if not anum or anum <= 0 then
        return false
    end

    local uobjs = getUserObjs(uid)
    local mActivity = uobjs.getModel('activity')
    local actinfo = mActivity.info[activeId]
    local beautyFlowerCfg = getConfig("beautyFlowerCfg", "activecfg")[code]
    local oncereward = beautyFlowerCfg.poolMust[1][1]
    local rewards,generalrewards

    --获取抽奖池(如果玩家未选定，取默认奖池)
    local lotteryinfo = beautyFlowerCfg.poolDefault
    if actinfo.lotteryinfo and next(actinfo.lotteryinfo) then
        lotteryinfo = {}
        for i=1,beautyFlowerCfg.poolNum do
            for idx=1,beautyFlowerCfg["poolPos"..i] do
                local j = actinfo.lotteryinfo[i][idx] + 1
                table.insert(lotteryinfo,beautyFlowerCfg["pool"..i][j])
            end
        end
        -- table.insert(lotteryinfo,beautyFlowerCfg["poolMust"][1])
    end

    actinfo.totalnum = actinfo.totalnum or 0
    local drawloop = beautyFlowerCfg.drawloop --区间上限
    --超出设定碎片数取新循环长度
    if beautyFlowerCfg.newChipInterval and actinfo.totalnum >= beautyFlowerCfg.newChipInterval[1] then
        drawloop = beautyFlowerCfg.newChipInterval[2]
    end
    local drawChipTime = beautyFlowerCfg.drawChipTime --区间内获得次数
    for i=1,anum do
        if actinfo.lotterynum > 0 then
            actinfo.lotterynum = actinfo.lotterynum - 1
            actinfo.usenum = actinfo.usenum + 1
            --是否获得碎片
            local getFlag = false
            if actinfo.drawnum <= drawChipTime then
                actinfo.loopidx = (actinfo.loopidx % drawloop) + 1
                if actinfo.loopidx == 1 then
                    actinfo.drawnum = 0
                elseif (((drawloop - actinfo.loopidx) <= (drawChipTime - actinfo.drawnum)) or (rand(1,drawloop) <= actinfo.loopidx)) and actinfo.drawnum < drawChipTime then
                    actinfo.totalnum = actinfo.totalnum + 1
                    actinfo.drawnum = actinfo.drawnum + 1
                    getFlag = true
                end
            end
            if getFlag then
                generalrewards = oncereward
            else
                generalrewards = getKeyByArrRnd(lotteryinfo)
            end
            if rewards then
                rewards = rewards .. "|" .. generalrewards
            else
                rewards = generalrewards
            end
        else
            break
        end
    end

    return rewards
end

--检查奖励中的红颜皮肤是否能获得
function checkWifeskinRewards(uid, rewards)
    --16增加红颜服饰 
    local uid = tonumber(uid)
    if uid <= 0 or not rewards then
        return false
    end
    local rewards_table = string.split(rewards, "%|")
    local uobjs = getUserObjs(uid,true)
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        -- local rewardNum = tonumber(reward_v[3])
        if rewardType == 16 then
            --增加红颜服饰
            local mWife = uobjs.getModel('wife')
            local wifeSkinCfg = getConfig("wifeSkinCfg")
            local wifeId = wifeSkinCfg[rewardId].wifeId
            if not mWife.info[wifeId] then
                return true
            end
        end
    end

    return false
end

--确认gm权限
function checkGmQuanxian()
    if sysDebug() then return true end
    
    if PLATFORM == "test" then
        local ipArr = {
            "192.168.8.83",
        }
        local myip = getMyIp()
        if myip and table.contains(ipArr,myip) then
            return true
        end
    else
        local ipArr = {
            "192.168.8.83",
            "134.175.219.33",
            "150.109.53.61",
        }
        local myip = getMyIp()
        if myip and table.contains(ipArr,myip) then
            return true
        end
    end

    writeLog({uid=getMyuid(),cmd=getCmd(),myip=getMyIp(),plat=PLATFORM,now=os.time()}, 'checkGmQuanxianWrong') 
    return false
end

--gm调用ip限制
function gmLimitForIp(plat)
    local ipArr = {}
    if plat == "test" then
        ipArr = {
            "192.168.8.83",
        }
    else
        ipArr = {
            "192.168.8.83",
            --"134.175.219.33",
        }
    end
    local myip = getMyIp()
    if myip and table.contains(ipArr,myip) then
        return true
    end
    return false
end

--返回快照信息
function returnUsershotData(uid,ruid)
    local uobjs = getUserObjs(ruid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    local mGameinfo = uobjs.getModel('gameinfo')
    local mChallenge = uobjs.getModel('challenge')
    local mWife = uobjs.getModel('wife')
    local mChild = uobjs.getModel('child')
    local mAdult = uobjs.getModel('adult')
    local mItem = uobjs.getModel('item')
    local mDinner = uobjs.getModel('dinner')
    local mMyalliance = uobjs.getModel('myalliance')
    local mPrestige = uobjs.getModel('prestige')
    local mOtherinfo = uobjs.getModel('otherinfo')
    local mCrossDinner = uobjs.getModel('crossdinner')
    local mBiography = uobjs.getModel('biography')
    local resdata = {}

    resdata.bio = mBiography.info
    resdata.godbless = mOtherinfo.info.godbless
    resdata.ruid = ruid
    resdata.pic = mUserinfo.pic
    resdata.name = mUserinfo.name
    resdata.vip =  mUserinfo.vip
    resdata.hideVip = mOtherinfo.info.hideVip
    resdata.level = mUserinfo.level
    resdata.exp = mUserinfo.exp
    resdata.atk = mUserinfo.atk
    resdata.inte = mUserinfo.inte
    resdata.politics = mUserinfo.politics
    resdata.charm = mUserinfo.charm
    resdata.power = mUserinfo.power
    resdata.title = mUserinfo.title
    resdata.titlelv = mUserinfo.titlelv
    resdata.ptitle = mUserinfo.ptitle
    resdata.gmFlag = mGameinfo.info.gmFlag

    resdata.gname = mUserinfo.mygname
    resdata.po = mMyalliance.po

    resdata.childnum =  table.length(mChild.info) + table.length(mAdult.info) + table.length(mAdult.minfo)
    resdata.wifenum = table.length(mWife.info)
    resdata.imacy = mWife.total_imacy
    resdata.cid = mChallenge.cid
    resdata.pem = mPrestige.pem
    --【v1.1增加历史头像返回】
    resdata.lastpic = mGameinfo.info['lastpic']

    if uid~=ruid then
        local uobjs = getUserObjs(uid,true)
        local mFriend = uobjs.getModel('friend')
        local friendflag = -1
        if mFriend.info[tostring(ruid)] then
            friendflag=1
        elseif mFriend.apply[tostring(ruid)] then
            friendflag=0
        end

        resdata.friendflag = friendflag
    end

    if mDinner.end_time>0 and not mDinner.isFinish() then --有宴会且未结束
        resdata.ishavedinner = 1
    else
        resdata.ishavedinner = 0
    end
    

    if mCrossDinner.end_time>0 and not mCrossDinner.haveCanJoinDinner() then --有群英宴会且未结束
        resdata.ishavecrossdinner = 1
    else
        resdata.ishavecrossdinner = 0
    end

    local titleinfo = mItem.tinfo or {}
    resdata.titleinfo = titleinfo
    local tupinfo = mItem.tupinfo or {}
    resdata.tupinfo = tupinfo

    return resdata
end

--更新区服唯一聊天头像
function setOnlyChatHead(chatheadId,userid,sign)
    local preUserId
    -- local returnData = {}
    local onlychathead = "z" .. getZoneId() .. ".onlychathead"
    local redis = getRedis()
    local palaceData = redis:get(onlychathead)
    if not palaceData then
        local data = getBakData(onlychathead)
        if data then
            palaceData = json.decode(data)
        else 
            local chatHeadCfg = getConfig("chatHeadCfg")
            palaceData = {}
            for k,v in pairs(chatHeadCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    --{uid = 0,sign = "",rank={}}
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        local chatHeadCfg = getConfig("chatHeadCfg")
        for k,v in pairs(chatHeadCfg) do
            if not palaceData[k] and v.isOnly == 1 and v.isCross == 0 then
                palaceData[k] = {}
            end
        end
    end

    --防重
    if not palaceData[chatheadId] then
        palaceData[chatheadId] = {}
    end
    if not palaceData[chatheadId].st then
        palaceData[chatheadId].st = 0
    end
    if palaceData[chatheadId] and tonumber(palaceData[chatheadId].uid)==tonumber(userid) and os.time()-tonumber(palaceData[chatheadId].st)<86400 then
        writeLog({uid=userid,chatheadId=chatheadId,type="onlychathead"}, "onlyChatHeadRepWrong")
        return false
    end

    if palaceData[chatheadId] and palaceData[chatheadId].uid and userid ~= palaceData[chatheadId].uid then
        preUserId = palaceData[chatheadId].uid
    end

    if not palaceData[chatheadId].rank then
        palaceData[chatheadId].rank = {}
    end
    if sign then
        if not palaceData[chatheadId] or not palaceData[chatheadId].uid or palaceData[chatheadId].uid~=userid then
            return false
        end
        palaceData[chatheadId].sign = sign
    else
        -- local uobjs = getUserObjs(userid,true)
        -- local mUserinfo = uobjs.getModel('userinfo')
        local userCache = getCacheUserInfo(tonumber(userid))

        palaceData[chatheadId].sign = ""
        palaceData[chatheadId].uid = userid
        palaceData[chatheadId].st = os.time()
        table.insert(palaceData[chatheadId].rank,1,{userid,userCache.name,os.time()})
        if #palaceData[chatheadId].rank >100 then
            table.remove(palaceData[chatheadId].rank,101)
        end
    end
    local dataStr = json.encode(palaceData)
    --记录到缓存
    redis:set(onlychathead, dataStr)
    --记录数据入库
    recordBakData(onlychathead,dataStr)
    return true,preUserId
end

--获取聊天当前全服唯一头像
function getOnlyChatHeadData()
    local returnData = {}
    local onlychathead = "z" .. getZoneId() .. ".onlychathead"
    local redis = getRedis()
    local palaceData = redis:get(onlychathead)
    if not palaceData then
        local data = getBakData(onlychathead)
        if data then
            redis:set(onlychathead, data)
            palaceData = json.decode(data)
        else 
            local chatHeadCfg = getConfig("chatHeadCfg")
            palaceData = {}
            for k,v in pairs(chatHeadCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
    end
    for k, v in pairs(palaceData) do
        if v.uid then
            returnData[k] = v.uid
        end
    end
    return returnData
end

--更新区服唯一聊天气泡
function setOnlyChatFrame(chatframeId,userid,sign)
    local preUserId
    -- local returnData = {}
    local onlychatframe = "z" .. getZoneId() .. ".onlychatframe"
    local redis = getRedis()
    local palaceData = redis:get(onlychatframe)
    if not palaceData then
        local data = getBakData(onlychatframe)
        if data then
            palaceData = json.decode(data)
        else 
            local chatFrameCfg = getConfig("chatFrameCfg")
            palaceData = {}
            for k,v in pairs(chatFrameCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    --{uid = 0,sign = "",rank={}}
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        local chatFrameCfg = getConfig("chatFrameCfg")
        for k,v in pairs(chatFrameCfg) do
            if not palaceData[k] and v.isOnly == 1 and v.isCross == 0 then
                palaceData[k] = {}
            end
        end
    end

    --防重
    if not palaceData[chatframeId] then
        palaceData[chatframeId] = {}
    end
    if not palaceData[chatframeId].st then
        palaceData[chatframeId].st = 0
    end
    if palaceData[chatframeId] and tonumber(palaceData[chatframeId].uid)==tonumber(userid) and os.time()-tonumber(palaceData[chatframeId].st)<86400 then
        writeLog({uid=userid,chatframeId=chatframeId,type="onlychatframe"}, "onlyChatFrameRepWrong")
        return false
    end

    if palaceData[chatframeId] and palaceData[chatframeId].uid and userid ~= palaceData[chatframeId].uid then
        preUserId = palaceData[chatframeId].uid
    end

    if not palaceData[chatframeId].rank then
        palaceData[chatframeId].rank = {}
    end
    if sign then
        if not palaceData[chatframeId] or not palaceData[chatframeId].uid or palaceData[chatframeId].uid~=userid then
            return false
        end
        palaceData[chatframeId].sign = sign
    else
        -- local uobjs = getUserObjs(userid,true)
        -- local mUserinfo = uobjs.getModel('userinfo')
        local userCache = getCacheUserInfo(tonumber(userid))

        palaceData[chatframeId].sign = ""
        palaceData[chatframeId].uid = userid
        palaceData[chatframeId].st = os.time()
        table.insert(palaceData[chatframeId].rank,1,{userid,userCache.name,os.time()})
        if #palaceData[chatframeId].rank >100 then
            table.remove(palaceData[chatframeId].rank,101)
        end
    end
    local dataStr = json.encode(palaceData)
    --记录到缓存
    redis:set(onlychatframe, dataStr)
    --记录数据入库
    recordBakData(onlychatframe,dataStr)
    return true,preUserId
end

--获取聊天当前全服唯一聊天气泡
function getOnlyChatFrameData()
    local returnData = {}
    local onlychatframe = "z" .. getZoneId() .. ".onlychatframe"
    local redis = getRedis()
    local palaceData = redis:get(onlychatframe)
    if not palaceData then
        local data = getBakData(onlychatframe)
        if data then
            redis:set(onlychatframe, data)
            palaceData = json.decode(data)
        else 
            local chatFrameCfg = getConfig("chatFrameCfg")
            palaceData = {}
            for k,v in pairs(chatFrameCfg) do
                if v.isOnly == 1 and v.isCross == 0 then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
    end
    for k, v in pairs(palaceData) do
        if v.uid then
            returnData[k] = v.uid
        end
    end
    return returnData
end

--获取自己上下数目的排行
function getRankActiveByRank(rankName,uid,rankLength,noUidTb)
    local redis = getRedis()
    local key = "z"..getZoneId().."."..rankName
    local rank = redis:zrevrank(key,uid)
    if not rank then
        return false
    end
    
    local myrank = rank + 1
    local rankMin = myrank - rankLength
    local endIndex = myrank+rankLength
    
    local activeRank = redis:zrevrange(key,rankMin,endIndex)
    local rankArr = {}
    for k,ruid in ipairs(activeRank) do
        if not noUidTb[tostring(ruid)] then
            local aUserinfo = getCacheUserInfo(tonumber(ruid))
            local tmpvalue = redis:zscore(key,ruid)
            local ruidscore = math.floor(tmpvalue / math.pow(10,6))
            table.insert(rankArr,{uid=ruid,value=ruidscore,name=aUserinfo.name,title=aUserinfo.title,ptitle=aUserinfo.ptitle,pic = aUserinfo.pic,lastpic=aUserinfo.lastpic})
        end
    end
    
    return rankArr
end

--宴会模块是否解锁
function crossDinnerIsUnlock(uid)
    if not isSwitchTrue(uid, 'openCrossServerDinner') then
        return false
    end
    if not getCrossSwitch() then
        return false
    end
    local uobjs = getUserObjs(uid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    local mServant = uobjs.getModel('servant')
    local heroNum = 0
    for _,v in pairs(mServant.info) do
        heroNum = heroNum + 1
    end
    local crossDinnerCfg = getConfig("crossDinnerCfg")
    --是否开启开关  是否配置pk服  功能条件已达成
    if tonumber(mUserinfo.level) >= tonumber(crossDinnerCfg.needLv) and heroNum >= tonumber(crossDinnerCfg.needServantNum) then
        return true
    end
    
    return false
end

--公共缓存-设置冲榜活动排行榜数据(rankName最后一段应为开始时间)
function setRankToCommonRedis(uid,rankName,value)
    local redis = getCommonRedis()
    local key = rankName
    local now = os.time()
    
    local keyarr = string.split(rankName,"%.")
    local tmpst = tonumber(keyarr[#keyarr])
    local subtime
    if tmpst and tmpst > 0 then
        subtime = (now-tmpst) % (math.pow(10,6))
    else
        subtime = string.sub(now,5,10)
    end
    
    local tmptime = math.pow(10,6) - tonumber(subtime)
    local newValue = value*math.pow(10,6) + tmptime
    redis:zadd(key,newValue,uid)
    redis:expire(key,30*86400)
end

--公共缓存-获取我的排行榜列表
function getRankByCommonRedis(uid,rankName,pageLengthNum,pageNum)
    local pageL
    if not pageLengthNum then
        pageL = 199
    else
        pageL = pageLengthNum -1
    end
    if not pageNum then
        pageNum = 1
    end
    local sNum = (pageNum-1) * (pageL+1)
    local eNum = sNum+pageL

    local redis = getCommonRedis()
    local key = rankName
    local activeRank = redis:zrevrange(key,sNum,eNum,"withscores")
    local rankArr = {}
    for k,v in ipairs(activeRank) do
        local ruid = tonumber(v[1])
        local tmpvalue = tonumber(v[2])
        local aUserinfo = getCommonCacheUserInfo(tonumber(ruid))
        local ruidscore = math.floor(tmpvalue / math.pow(10,6))
        local rankUserData = {uid=ruid,zid=getUserTrueZid(ruid),value=ruidscore,name=aUserinfo.name,title=aUserinfo.title,ptitle=aUserinfo.ptitle,pic = aUserinfo.pic,rank=sNum+k}
        if k == 1 then
            rankUserData.ptitle = aUserinfo.ptitle
        end
        table.insert(rankArr,rankUserData)
    end
    --我的排名
    local rank = redis:zrevrank(key,uid)
    local myrank
    local myrankArr = {}
    if rank then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,uid)
        local aUserinfo = getCommonCacheUserInfo(tonumber(uid))
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {uid=uid,value=myscore,myrank=myrank,title=aUserinfo.title,ptitle=aUserinfo.ptitle,pic = aUserinfo.pic}
    end

    return rankArr,myrankArr
end

--公共缓存-获取我的排名
function getMyRankByCommonRedis(uid,rankName,isdetail)
    local redis = getCommonRedis()
    local key = rankName
    local rank = redis:zrevrank(key,uid)
    
    local myrank
    local myrankArr = {}
    if rank then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,uid)
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {uid=uid,value=myscore,myrank=myrank}
        
        if isdetail then
            local aUserinfo = getCommonCacheUserInfo(tonumber(uid))
            myrankArr.title = aUserinfo.title
            myrankArr.ptitle = aUserinfo.ptitle
            myrankArr.pic = aUserinfo.pic
        end
    end

    return myrankArr
end

--公共缓存-获取区服排行榜
function getZidRankByCommonRedis(zid,rankName)
    local pageL = 199
    local sNum = 0
    local eNum = sNum+pageL

    local redis = getCommonRedis()
    local key = rankName
    local activeRank = redis:zrevrange(key,sNum,eNum,"withscores")
    local rankArr = {}
    for k,v in ipairs(activeRank) do
        local rzid = tonumber(v[1])
        local tmpvalue = tonumber(v[2])
        local ruidscore = math.floor(tmpvalue / math.pow(10,6))
        local rankUserData = {zid=rzid,value=ruidscore}
        table.insert(rankArr,rankUserData)
    end
    
    --我的区服排名
    local rank = redis:zrevrank(key,zid)
    local myrank
    local myrankArr = {}
    if rank then
        myrank = rank + 1
        local tmpvalue = redis:zscore(key,zid)
        local myscore = math.floor(tmpvalue / math.pow(10,6))
        myrankArr = {zid=zid,value=myscore,myrank=myrank}
    end

    return rankArr,myrankArr
end

--检查特殊积累道具数量是否超限
--目前已检测类型
--门客，红颜，门客皮肤，红颜皮肤，府邸场景，宠幸场景，道具，称号, 聊天气泡，圣兽，文玩
function checkHaveRewards(uid,checkRewards)
    if not uid or not checkRewards or checkRewards == "" then
        return false
    end
    local uobjs = getUserObjs(uid,true)

    --检测特殊奖励不重复获得
    local rearr = string.split(checkRewards, "%_")
    local rType = tonumber(rearr[1])
    local tmpId = tostring(rearr[2])
    local tmpNum = tonumber(rearr[3])
    if rType == 6 then
        --道具
        local mItem = uobjs.getModel('item')
        if mItem.info and mItem.info[tmpId] and mItem.info[tmpId] >= tmpNum then
            return true
        end
    elseif rType == 8 then
        --门客
        local mServant = uobjs.getModel('servant')
        if mServant.info and mServant.info[tmpId] then
            return true
        end
    elseif rType == 10 then
        --红颜
        local mWife = uobjs.getModel('wife')
        if mWife.info and mWife.info[tmpId] then
            return true
        end
    elseif rType == 11 then
        --称号
        local mItem = uobjs.getModel('item')
        if mItem.tinfo and mItem.tinfo[tmpId] then
            return true
        end
    elseif rType == 16 then
        --红颜皮肤
        local wifeSkinCfg = getConfig('wifeSkinCfg')
        if wifeSkinCfg[tmpId] then
            local wid = wifeSkinCfg[tmpId].wifeId
            local mWifeskin = uobjs.getModel('wifeskin')
            if mWifeskin.info and mWifeskin.info[wid] and mWifeskin.info[wid].skin and mWifeskin.info[wid].skin[tmpId] then
                return true
            end
        end
    elseif rType == 19 then
        --门客皮肤
        local servantSkinCfg = getConfig('servantSkinCfg')
        if servantSkinCfg[tmpId] then
            local sid = servantSkinCfg[tmpId].servantId
            local mServant = uobjs.getModel('servant')
            if mServant.info and mServant.info[sid] and mServant.info[sid].skin and mServant.info[sid].skin[tmpId] then
                return true
            end
        end
    elseif rType == 53 then
        -- 封地小人
        local manageNpcCfg = getConfig('manageNpcCfg')
        if manageNpcCfg[tmpId] then
            local mManagenpc = uobjs.getModel('managenpc')
            if mManagenpc.info and mManagenpc.info[tmpId] then
                return true
            end
        end
    elseif rType == 57 then
        -- 聊天气泡
        local wordsColorCfg = getConfig('wordsColorCfg')
        if wordsColorCfg[tmpId] then
            local mItem = uobjs.getModel('item')
            if mItem.tinfo[tmpId] then
                return true
            end
        end
    elseif rType == 66 then
        -- 文玩
        local curiosCfg = getConfig('curiosCfg').curios
        if curiosCfg[tmpId] then
            local mCurios = uobjs.getModel('curios')
            if mCurios.info and mCurios.info[tmpId] then
                return true
            end
        end
    elseif rType == 104 then
        -- 红颜共浴场景
        local wifeBathSceneCfg = getConfig('wifeBathSceneCfg')
        if wifeBathSceneCfg[tmpId] then
            local wid = wifeBathSceneCfg[tmpId].wifeId
            local mWife = uobjs.getModel('wife')
            if mWife.info and mWife.info[wid] and mWife.info[wid].scene and mWife.info[wid].scene[tmpId] then
                return true
            end
        end
    elseif rType == 105 then
         -- 府邸场景
         local sceneProCfg = getConfig('wifeBathSceneCfg')
         if sceneProCfg[tmpId] then
             local mOtherinfo = uobjs.getModel('otherinfo')
             if mOtherinfo.info and mOtherinfo.info.sceneinfo and mOtherinfo.info.sceneinfo.idinfo and mOtherinfo.info.sceneinfo.idinfo[tmpId] then
                 return true
             end
         end
    elseif rType == 107 then
        -- 聊天气泡
        local chatFrameCfg = getConfig('chatFrameCfg')
        if chatFrameCfg[tmpId] then
            local mItem = uobjs.getModel('item')
            if mItem.tinfo[tmpId] then
                return true
            end
        end
    elseif rType == 70 then
        --光环
        local tmpType = tonumber(rearr[3])
        local auraId = tostring(rearr[4])
        local auraLv = tonumber(rearr[5]) or 0
        if tmpType == 1 then
            --门客普通光环
            local mServant = uobjs.getModel('servant')
            local tmpSinfo = mServant.info and mServant.info[tmpId]
            if tmpSinfo and tmpSinfo.aura and tmpSinfo.aura[auraId] and tmpSinfo.aura[auraId] >= auraLv then
                return true
            end
        else
            return false
        end
    end
    return false
end

--检查指定道具使用前置条件
function checkUseCondition(uid, condition)
    local uid = tonumber(uid) or 0
    if uid <= 1000000 or not condition then
        return false
    end
    local cond_arr = string.split(condition, "%|")
    for _, v in ipairs(cond_arr) do
        if not checkHaveRewards(uid,v) then
            return false
        end
    end

    return true
end

--检查指定道具使用前置条件2
function checkUseConditionNew(uid, condition)
    local uid = tonumber(uid) or 0
    if uid <= 1000000 or not condition then
        return false
    end
    local cond_arr = string.split(condition, "%|")
    for _, v in ipairs(cond_arr) do
        if checkHaveRewards(uid,v) then
            return true
        end
    end

    return false
end

--检测道具对应光环是否解锁且未满级(不考虑当前身上已有的道具)
function checkItemCanUse(uid, reward)
    uid = tonumber(uid) or 0
    if uid <= 1000000 or not reward then
        return false
    end
    local uobjs = getUserObjs(uid,true)
    require("lib/shopitemcontrol")
    local reward_v = string.split(reward, "%_")
    local itemType = tonumber(reward_v[1])
    local itemId = tostring(reward_v[2])
    if itemType == 6 then
        local itemCfg = getConfig('itemCfg')
        local itemInfo = itemCfg[itemId]
        --门客光环
        if itemInfo.aimAura then
            local aimAura = itemCfg[itemId].aimAura
            local servantSkinCfg = getConfig('servantSkinCfg')
            for i, chekStr in ipairs(aimAura) do
                local rearr = string.split(chekStr, "%_")
                local rType = tonumber(rearr[1])    --tmpId 的类型限定，目前支持  8 门客 /10 红颜/ 19 门客皮肤
                local tmpId = tostring(rearr[2])     --rType类型下的id
                local pType = tonumber(rearr[3])    --pId 的类型限定，目前支持  1=aura(门客光环)/2=spaura(门客sp光环)/3=spSkinAura(门客皮肤光环)/4=specialSkill(红颜特殊技能解锁)/5=skSkinAura(门客皮肤技能光环)
                local pId = tostring(rearr[4])      --pType类型下的位置id
                if checkSwitch(uid,rType,tmpId,pType) then
                    if rType == 8 then
                        --门客
                        local mServant = uobjs.getModel('servant')
                        if mServant.info[tmpId] then
                            local checkItem = mServant.getAuraMaxNeedNum(tmpId,pType,pId,nil,1)
                            if checkItem and checkItem["6_"..itemId] then
                                return true
                            end
                        end
                    elseif rType == 19 then
                        --门客皮肤
                        if servantSkinCfg[tmpId] then
                            local sid = servantSkinCfg[tmpId].servantId
                            local mServant = uobjs.getModel('servant')
                            if mServant.info[sid] and mServant.info[sid].skin and mServant.info[sid].skin[tmpId] then
                                local checkItem = mServant.getAuraMaxNeedNum(sid,pType,pId,tmpId,1)
                                if checkItem and checkItem["6_"..itemId] then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

--检测红包功能是否可以操作
--type (1=是否在活动期,2是否可领取任务及兑换)
function checkRedEnvelopeByType(uid,Ctype)
    if not false then
        return false
    end
    --记录开服日期
    local redis = getRedis()
    local zid = getZoneId()
    local opentimekey = "z"..zid..".shopneedopentime"
    local opentime = redis:get(opentimekey)
    if not opentime then
        local config = getConfig('config')
        local http = require("socket.http")
        local getzidUrl = config['z'..zid].tankglobalUrl.."?t=getzidinfo&zid="..zid
        local tmp = http.request(getzidUrl)
        local res = json.decode(tmp)
        if res and res["data"] and res["data"][1] and res["data"][1]["opened_at"] and tonumber(res["data"][1]["opened_at"]) > 0 then
            redis:set(opentimekey,res["data"][1]["opened_at"])
            opentime = res["data"][1]["opened_at"]
        end
    end
    opentime = opentime or 0
    local redEnvelopesCfg = getConfig('redEnvelopesCfg')
    local now = os.time()



    local allRunTime = redEnvelopesCfg.keepTime or 0
    local cheTime = opentime + (allRunTime*24*60*60)
    if Ctype and Ctype == 2 then
        cheTime = cheTime + (redEnvelopesCfg.extraTime*24*60*60)
    end
    if now <= cheTime then
        return true
    end
    
    return false
    
end

--不放回随机
function randArrWithoutBack(task, num)
    local resarr = {}
    local len = table.length(task)
    if len < num then
        return resarr
    end
    local tmparr = {}
    for k, v in pairs(task) do
        local idx = tostring(k)
        tmparr[idx] = {}
        tmparr[idx]["weight"] = v.weight or 1
    end
    for i = 1, num do
        local index = getKeyByArrRndSTR(tmparr)
        resarr[index] = 0
        tmparr[index] = nil
    end
    return resarr
end

--奖励差值比较
--返回 rewardStr2比rewardStr1 多的部分的奖励
function rewardsDifference(rewardStr1,rewardStr2)
    if type(rewardStr1)~="string" or rewardStr1 == "" or rewardStr2=="" or not rewardStr2 or not rewardStr1 then
        return rewardStr2
    end

    local differenceRewardStr = ""
    
    local RwdTb1 = {}
    local rewards_table1 = string.split(rewardStr1, "%|")
    for k, v in ipairs(rewards_table1) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        RwdTb1[rewardType.."_"..rewardId] = rewardNum
    end
    local rewards_table2 = string.split(rewardStr2, "%|")
    for k, v in ipairs(rewards_table2) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        local rewardNum = tonumber(reward_v[3])
        if RwdTb1[rewardType.."_"..rewardId] then
            rewardNum = rewardNum - RwdTb1[rewardType.."_"..rewardId]
        end

        if rewardNum > 0 then
            if differenceRewardStr ~= "" then
                differenceRewardStr = differenceRewardStr .. "|"
            end
            differenceRewardStr = differenceRewardStr .. rewardType.."_"..rewardId.."_"..rewardNum
        end
    end

    return differenceRewardStr
end

--设置聚贤阁缓存信息
function sethandbookinfo(uid, stype, id)
    if not uid or not stype or not id then
        return false
    end
    local key = "z" .. getZoneId() .. ".handbook." .. uid
    local redis = getRedis()
    local sdata = redis:get(key)
    local info = {s={},w={}}
    if sdata then
        info = json.decode(sdata)
    end
    info[stype][id] = 1
    redis:set(key,json.encode(info))
    return true
end

--年统计数据
function yearSetStat(uid,field,addnum)
    if true then return true end
    addnum = tonumber(addnum)
    local year = getDateByTimeZone(os.time(), "%Y")
    local key = "z" .. getZoneId() .. ".yearStat-" ..year.. "."..uid
    
    local redis = getCommonRedis()
    return redis:hincrby(key,field,addnum),key
end

--钱粮兵年统计数据
function yearSetResource(uid,field,addnum)
    addnum = tonumber(addnum)
    local today = getWeeTs(os.time())

    local redis = getCommonRedis()
    local key = "z" .. getZoneId() .. ".yearStat-" ..today.. "."..uid --按天记
    local newNum = redis:hincrby(key,field,addnum)
    redis:expire(key, 86400)

    local year = getDateByTimeZone(os.time(), "%Y")
    local maxTotalKey = "z" .. getZoneId() .. ".yearMaxResource-"..year.."."..uid
    local data = redis:hgetall(maxTotalKey)
    data = next(data) and data or {maxnum=0,maxdate=0,key=""}

    if tonumber(data.maxnum)<tonumber(newNum) then
        data.maxnum = tonumber(newNum)
        data.maxdate = today
        data.field=field
        redis:hmset(maxTotalKey, data)
    end
end

--年统计zset排序的
function yearSetZSort(uid,key,addnum,id)
    if true then return true end
    addnum = tonumber(addnum)
    yearSetStat(uid,key,addnum)

    local year = getDateByTimeZone(os.time(), "%Y")
    local zkey = "z" .. getZoneId() .. ".yearSort-"..year.."."..key.."."..uid
    local redis = getCommonRedis()
    redis:zincrby(zkey,addnum,id)
end

--厉兵秣马报名储存数据
function allianceQualifyBm(uid,aid,version)
    local zid = getZoneId()
    local caqKey = "z"..zid..".crossAllianceQualify."..version
    
    local commonRedis = getCommonRedis()
    --已经存在这个帮会的数据了，报警处理
    if commonRedis:hexists(caqKey,aid) then
        return false
    end
    local aData = {}
    local aobjs = getallianceObjs(aid)
    local mAlliance = aobjs.getModel('alliance')
    
    aData["name"] = mAlliance.name
    aData["list"] = mAlliance.list
    aData["level"] = mAlliance.level
    aData["exp"] = mAlliance.exp
    aData["creator"] = mAlliance.creator
    aData["creatorname"] = mAlliance.creatorname
    aData["mn"] = mAlliance.mn
    aData["maxmn"] = mAlliance.maxmn
    aData["userinfo"] = {}
    if mAlliance.list and next(mAlliance.list) then
        local totalAffect = 0
        if next(mAlliance.list) then
            for _,v in pairs(mAlliance.list) do
                local tmpobjs = getUserObjs(v,true)
                local tmpUserinfo = tmpobjs.getModel('userinfo')
                local tmpMyalliance = tmpobjs.getModel('myalliance')
                totalAffect = totalAffect + tmpUserinfo.power
                aData["userinfo"][tostring(v)] = {tmpUserinfo.power,tmpMyalliance.po}
            end
            aData["affect"] = totalAffect
        end
    end
    aData["signupuid"] = uid
    aData["signupudate"] = os.time()
    
    commonRedis:hset(caqKey,aid,json.encode(aData))
    
    local rankKey = "z"..zid..".crossAllianceQualify.Rank."..version
    setRankToCommonRedis(aid,rankKey,aData["affect"])
    return true
end

function isJoinCAQActivity(aid,version)
    local zid = getZoneId()
    local caqKey = "z"..zid..".crossAllianceQualify."..version
    local commonRedis = getCommonRedis()
    --已经存在这个帮会的数据了，报警处理
    if commonRedis:hexists(caqKey,aid) then
        return true
    end
    return false
end

function getCAQRank(uid,aid,version,code)
    local zid = getZoneId()
    local caqKey = "z"..zid..".crossAllianceQualify."..version
    local commonRedis = getCommonRedis()
    local allianceData = commonRedis:hgetall(caqKey)
    
    local crossAllianceQualifyCfg = getConfig("crossAllianceQualifyCfg","activecfg")[code]
    local rankQualification = crossAllianceQualifyCfg.rankQualification
    local endIndex = 199    
    local rankKey = "z"..zid..".crossAllianceQualify.Rank."..version
    local activeRank = commonRedis:zrevrange(rankKey,0,endIndex)
    local rankArr = {}
    local myRankAlliance = nil
    for k,raid in ipairs(activeRank) do
        local allianceInfo = json.decode(allianceData[tostring(raid)])
        local tmpvalue = commonRedis:zscore(rankKey,raid)
        local raidscore = math.floor(tmpvalue / math.pow(10,6))
        local aUserinfo = getCacheUserInfo(tonumber(allianceInfo.signupuid))
        local rankUserData = {aid=raid,power=raidscore,aname=allianceInfo.name,name=aUserinfo.name,date = allianceInfo.signupudate}
        if table.contains(allianceInfo.list,uid) then
            rankUserData.ismyalliance = true
            if k <= rankQualification then
                myRankAlliance = allianceInfo
            end
        end
        table.insert(rankArr,rankUserData)
    end
    --我的帮会信息
    local myallrankArr = {}
    if myRankAlliance then
        for uid,uData in pairs(myRankAlliance.userinfo) do
            local aUserinfo = getCacheUserInfo(tonumber(uid))
            local rankUserData = {uid=uid,name=aUserinfo.name,power = uData[1],po=uData[2]}
            table.insert(myallrankArr,rankUserData)
        end
    end
    
    return rankArr,myallrankArr
end

--检验建立是否是门客皮肤，如果是门客皮肤 再判断皮肤对应的兑换凭证有没有
--false=没有
--true=有
function checkSkinReward(uid,rewards)
    if not rewards or rewards == "" then
        return false
    end
    local checkRewardArr = string.split(rewards, "%_")
    local cType = tonumber(checkRewardArr[1])
    local cId = tostring(checkRewardArr[2])
    --门客皮肤的途经熟练需要在 门课皮肤的判断基础上再次判断 门课皮肤的兑换凭证
    if cType == 19 then
        local cfg = getConfig("servantSkinCfg")
        local checkItemId = cfg[cId].certificate or ""
        if checkItemId and checkItemId ~= "" then
            local uobjs = getUserObjs(uid, true)
            local mItem = uobjs.getModel('item')
            if mItem.info[tostring(checkItemId)] and mItem.info[tostring(checkItemId)]>0 then
                return true
            end
        end
    end
    return false
end

--检测当前是否有可参与的豪华盛宴
function getMsgInRollQueueByBanquet()
    local redis = getRedis()
    local rollQueueKey = "z" .. getZoneId() .. ".roll"
    local data = redis:get(rollQueueKey)
    local info = json.decode(data) or {}

    local item = {}
    local now = os.time()
    for k,v in ipairs(info) do
        
        local sTime = 30*60
        if v.dtype == 99 and now - tonumber(v.st)< sTime then
            table.insert(item, v)
        end
    end
    
    return item
end

--改名开关检测
function checkChangeName(uid)
    if isSwitchTrue(uid,"openSilent") then
        return true
    end
    return false
end

--获取关卡统计信息
function getChallengeInfo(uid)
    local resinfo = {}
    local uobjs = getUserObjs(uid,true)
    local mUserinfo = uobjs.getModel('userinfo')
    local mItem = uobjs.getModel('item')
    local mServant = uobjs.getModel('servant')
    local sinfo,snum = {},0
    for sid, sv in pairs(mServant.info) do
        snum = snum + 1
        table.insert(sinfo,{sid,sv.total,sv.lv})
    end
    table.sort(sinfo,function (a, b) return a[2] > b[2] end)

    resinfo.level = mUserinfo.level --官品
    resinfo.sid_cnt = snum --门客数量
    resinfo.soldier_remain_cnt = mUserinfo.soldier --剩余士兵
    resinfo.forage_remain_cnt = mUserinfo.food --剩余粮草
    resinfo.conscript_cnt = mItem.info["1101"] or 0 --征兵令数量
    resinfo.power_total = mUserinfo.power --权势
    resinfo.gem_remain_cnt = mUserinfo.gem --剩余元宝
    resinfo.is_payment = 0 --是否付费
    if mUserinfo.buyg > 0 then
        resinfo.is_payment = 1
    end
    resinfo.online_time = mUserinfo.totalolt --在线时长
    resinfo.attack_time = getDateByTimeZone(os.time(), '%Y-%m-%d %H:%M:%S') --攻打时间
    for i=1,5 do
        if sinfo[i] then
            resinfo["sid_"..i] = sinfo[i][1]
            resinfo["sid_level_"..i] = sinfo[i][3]
            resinfo["sid_power_"..i] = sinfo[i][2]
        end
    end

    return resinfo
end

-- 老服开启新经营功能后的玩家数据处理
--注意 封地3.0后 challenge配置有修改，本逻辑不可直接执行需检测是否符合最新需求
function openManage(uid)
    if not isSwitchTrue(uid,"FDOldplayerCompensate") then
        return true
    end
    local uobjs = getUserObjs(uid)
    local mChallenge = uobjs.getModel('challenge')
    local mOtherinfo = uobjs.getModel('otherinfo')
    local mServant = uobjs.getModel('servant')
    local mManageNew = uobjs.getModel('managenew')
    local openManage = mOtherinfo.info.openManage or 0
    if openManage == 0 and isSwitchTrue(uid,"openManageNew") then
        local rewards
        local challengeCfg = getConfig("challengeCfg")
        --新经营建筑全部开启
        local manageNewCfg = getConfigWhitSwitch(uid,"manageNewCfg")
        local buidlCfg = manageNewCfg.manageConfig
        for bid,v in pairs(buidlCfg) do
            if not mManageNew.binfo[bid] then
                mManageNew.binfo[bid] = {}
                mManageNew.binfo[bid].lv = 1
                mManageNew.binfo[bid].cdst = os.time()
                mManageNew.binfo[bid].cdtime = formula:getManageNewNeedTime(uid)
                mManageNew.binfo[bid].posinfo = {}
                mManageNew.binfo[bid].num = 0
                addGameTask(uid, "30101", 1)
                addGameTask(uid, "30103", 1, bid)
            end
        end
        mManageNew.updateAllRate()
        if not mManageNew.info.denseinfo then
            mManageNew.info.denseinfo = {}
        end
        --把云全部解锁
        for i = 1, 3, 1 do
            mManageNew.info.denseinfo[tostring(i)] = os.time()
            addGameTask(uid, "30118", 1)
        end
        
        --补发关卡门客奖励
        for i=1,mChallenge.cid do
            -- isSwitchTrue(uid,"openFiefTo3")  challengeCfg[nextCid].extraReward2 
            if challengeCfg[tostring(i)].extraReward then
                local rewards_table = string.split(challengeCfg[tostring(i)].extraReward, "%|")
                for k, v in ipairs(rewards_table) do
                    local reward_v = string.split(v, "%_")
                    local rewardType = tonumber(reward_v[1])
                    local rewardId = tostring(reward_v[2])
                    if rewardType == 8 and not mServant.info[rewardId]  then
                        rewards = rewards and rewards .."|6_"..rewardId.."01_100" or "6_"..rewardId.."01_100"
                    end
                end
                
            end
        end
        
        --成就状态重新检测
        local needCheckTb = {"101","102","103"}
        local mAchievement = uobjs.getModel('achievement')
        local achievementCfg = getConfig("achievementCfg")
        for _,taskType in ipairs(needCheckTb) do
            local stage = mAchievement.info[taskType].stage
            local valueCfg = achievementCfg[taskType].valueNew
            local needV = valueCfg[stage]
            if mAchievement.info[taskType].f == 0 and mAchievement.info[taskType].v >= needV then
                mAchievement.info[taskType].f = 1
            elseif mAchievement.info[taskType].f == 1 and mAchievement.info[taskType].v < needV then
                mAchievement.info[taskType].f = 0
            end
        end
        regReturnModel({"achievement"})
        
        mOtherinfo.info.openManage = os.time()
        if PLATFORM == "tw" then
            mOtherinfo.info.openManage = 2--港台直接开3.0 不能触发引导
        end
        regReturnModel({"otherinfo"})
        
        if rewards then
            local mails = require "lib.mails"
            local systeminfo = {touch=rewards,title=''}
            local mailid = mails:addData(uid,'',3,systeminfo)
            if mailid then
                local mMymail = uobjs.getModel('mymail')
                mMymail.receiveSystemMail(0,mailid,'',999,rewards,{mt="200",forever = 1},os.time())
            end
            
        end
    end
        
end

---两个数组是否有交集
---@param arr1 table {xx,...}
---@param arr2 table {xx,...}
---@return boolean 是否交叉
function arrayInterserction(arr1,arr2)
    if not arr1 or not next(arr1) or not arr2 or not next(arr2) then
        return false
    end

    for _, v in ipairs(arr1) do
        if table.contains(arr2,v) then
            return true
        end
    end

    return false
end

---两个数组是否是包含关系
---@param arr1 table {xx,...} 非空
---@param arr2 table {xx,...} 非空
---@return boolean 是否包含
function arrayContains(arr1,arr2)
    if not arr1 or not next(arr1) or not arr2 or not next(arr2) then
        return false
    end

    for _, v in ipairs(arr2) do
        if not table.contains(arr1,v) then
            return false
        end
    end

    return true
end

---记录超然活动账号所在服特定时间前100名的排名信息
function recordPowerRank()
    local isrun = false
    if isrun and PLATFORM == "cn_h5ly" and getZoneId() == 107 then
        local now = os.time()
        local daysTime = getWeeTs(now)
        local st,et = daysTime+(21*60*60),daysTime+86400-1
        local rankInfo = {}
        if now >= st and now < et then
            local db = getDbo()
            local pinfo = db:getAllRows("select u.uid,u.power from userinfo as u, gameinfo as g where u.uid = g.uid and u.name!='' order by u.power desc,u.level desc,u.uid asc limit 100")
            if pinfo and next(pinfo) then
                for idx, value in ipairs(pinfo) do
                    rankInfo[idx] = {}
                    rankInfo[idx].rank = idx
                    rankInfo[idx].uid = tonumber(value.uid)
                    rankInfo[idx].power = tonumber(value.power)
                end
            end

            local redis = getRedis()
            local keys = "z107.super_ran_ranklist."..daysTime
            redis:setex(keys,86400*30,json.encode(rankInfo))
        end
    end
end

-- 跨服设置排行榜
function setCrossRankActive(id,key,value)
    local redis = getCommonRedis()
    local now = os.time()
    local subtime = string.sub(now, 4, 10)
    local tmptime = math.pow(10, 7) - tonumber(subtime)
    local newValue = value * math.pow(10, 7) + tmptime
    redis:zadd(key,newValue,id)
    redis:expire(key,86400*30)
end

-- 跨服获取排行榜（不推荐用，应用getRankByCommonRedis）
function getCrossRankActive(id,key,index)
    if not index then
        index = 1
    end
    local sNum = (index-1) * 100
    local eNum = sNum+99

    local rankArr = {}
    local redis = getCommonRedis()
    local activeRank = redis:zrevrange(key,sNum,eNum,"withscores")
    for k,v in ipairs(activeRank) do
        local ruid = tonumber(v[1])
        local tmpvalue = tonumber(v[2])
        local ruidscore = math.floor(tmpvalue / math.pow(10,7))
        local zid = getUserTrueZid(ruid)
        local cacheData = getCrossCacheInfo(ruid,zid) --改用getCommonCacheUserInfo
        local uinfo = {uid=ruid,zid=zid,value=ruidscore,name=cacheData.name,level=cacheData.level,title=cacheData.title}
        table.insert(rankArr,uinfo)
    end
    local myrankArr = {}
    local rank = redis:zrevrank(key,id)
    if rank then
        local myrank = tonumber(rank) + 1
        local tmpvalue = redis:zscore(key,id)
        local myscore = math.floor(tmpvalue / math.pow(10,7))
        myrankArr = {uid=id,value=myscore,myrank=myrank}
    end
    return rankArr,myrankArr
end

-- 跨服获取帮会排行榜
function getCrossAlliRankActive(id,key,index,gid)
    if not index then
        index = 1
    end
    local sNum = (index-1) * 100
    local eNum = sNum+99

    local rankArr = {}
    local redis = getCommonRedis()
    local activeRank = redis:zrevrange(key,sNum,eNum,"withscores")
    for k,v in ipairs(activeRank) do
        local ruid = tonumber(v[1])
        local tmpvalue = tonumber(v[2])
        local ruidscore = math.floor(tmpvalue / math.pow(10,7))
        local zid = getUserTrueZid(ruid*10)
        if gid then--有些id无法解析到指定服，所以加一个gid参数
            zid = gid
        end
        local cacheData = getCrossCacheInfo(ruid,zid)  --改用getCommonCacheAllianceInfo
        local uinfo = {id=ruid,zid=zid,value=ruidscore,name=cacheData.name,level=cacheData.level,title=cacheData.title}
        table.insert(rankArr,uinfo)
    end
    local myrankArr = {}
    local rank = redis:zrevrank(key,id)
    if rank then
        local myrank = tonumber(rank) + 1
        local tmpvalue = redis:zscore(key,id)
        local myscore = math.floor(tmpvalue / math.pow(10,7))
        myrankArr = {uid=id,value=myscore,myrank=myrank}
    end
    return rankArr,myrankArr
end

--跨服缓存基础信息,个人或帮会，跨服帮会推荐使用 (废弃，非基础信息即时才用)
function setCrossCacheInfo(id,zid,data)
    local redis = getCommonRedis()
    data = data or {}
    local cacheData = {}
    cacheData.name = data.name
    cacheData.title = data.title
    cacheData.ptitle = data.ptitle
    cacheData.power = data.power
    cacheData.level = data.level
    cacheData.pic = data.pic
    local key = "z"..zid..".corssCacheInfo." .. id
    redis:setex(key, 86400 * 30,json.encode(cacheData))
end

--跨服取基础信息(非基础信息即时才用，推荐getCommonCacheUserInfo，getCommonCacheAllianceInfo)
function getCrossCacheInfo(id,zid)
    local redis = getCommonRedis()
    local key = "z"..zid..".corssCacheInfo." .. id
    local cacheData = redis:get(key)
    if not cacheData then
        cacheData = {}
    else
        cacheData = json.decode(cacheData)
    end
    return cacheData
end

---获取本区服开服时间
---@return number 开服时间
function getServerOpenTime()
    --记录开服日期
    local redis = getRedis()
    local zid = getZoneId()
    local opentimekey = "z"..zid..".shopneedopentime"
    local eflag = redis:exists(opentimekey)
    if not eflag then
        local config = getConfig('config')
        local http = require("socket.http")
        local getzidUrl = config['z'..zid].tankglobalUrl.."?t=getzidinfo&zid="..zid
        local tmp = http.request(getzidUrl)
        local res = json.decode(tmp)
        if res and res["data"] and res["data"][1] and res["data"][1]["opened_at"] and tonumber(res["data"][1]["opened_at"]) > 0 then
            redis:set(opentimekey,res["data"][1]["opened_at"])
        end
    end
    local opentime = redis:get(opentimekey) or 0

    if tonumber(opentime) <= 0 then
        warn:sendMail('serverOpenTime', {zid=getZoneId(),cmd=getCmd()})
    end

    return tonumber(opentime)
end

---获取受开关影响的配置表 (注意不可修改返回的配置,后果严重。慎重！慎重！)
---@param uid number 玩家uid（暂时用于开关：实际未用到）
---@param cfgkey string 配置文件名
---@return any
function getConfigWhitSwitch(uid,cfgkey)
    local cSTb = {} -- cSTb[原配置名] = {开关名,新配置名}
    cSTb['manageNewCfg'] = {"openFiefTo3","managePlusCfg"} --获取封地配置（受开关openFiefTo3的影响）
    cSTb['mainTaskCfg'] = {"openFiefTo3","mainTaskNewCfg"} --获取主线任务配置（受开关openFiefTo3的影响）

    local gameConfig = getConfig(cfgkey)
    if cSTb[cfgkey] and isSwitchTrue(uid,cSTb[cfgkey][1]) then
        gameConfig = getConfig(cSTb[cfgkey][2])
    end
    cSTb['manageNewCfg'] = {"openFiefTo4","manage4Cfg"} --获取封地配置（受开关openFiefTo4的影响）
    cSTb['mainTaskCfg'] = {"openFiefTo4","mainTask4Cfg"} --获取主线任务配置（受开关openFiefTo4的影响）
    cSTb['achievementCfg'] = {"openFiefTo4","achievement4Cfg"} --获取主线任务配置（受开关openFiefTo4的影响）

    if cSTb[cfgkey] and isSwitchTrue(uid,cSTb[cfgkey][1]) then
        gameConfig = getConfig(cSTb[cfgkey][2])
    end

    return gameConfig
end

---获取跨服活动PK服的key
---@return table 活动key对应的列表
function getAcCrossKey()
    local actIdArr = {
        crossServerPower = "crosspowerzids",  --跨服权势
        crossServerIntimacy = "crossimacyzids",  --跨服亲密
        crossServerAtkRace = "crossatkracezids",  --跨服擂台
        crossServerWipeBoss = "crosswipebosszids",  --跨服可汗
        crossServantPower = "crossservantpowerpkzids",  --跨服门客权势
        battleGround = "battlegroundzids",  --跨服风云擂台
        beTheKing = "crosskingpkzids",  --夺帝战
        crossServerWifeBattle = "crosswifebattlezids",  --跨服群芳会
        crossServerGemExpend = "crossgemexpendzids",  --元宝消耗冲榜
        conquerMainLand = "conquerMainLandzids",  --定军中原
        crossServerHegemony = "hegemonyzids",  --群雄逐鹿
        -- crossServerCaptureCity = "capturecityzids",  --攻城掠地
        crossSeaBattle = "crossseabattlezids",  --四海争霸
        secondAnniversaryPool = "crosssapoolzids",  --二周年许愿池冲榜
        crossPeaceAtkRace = "crossatkpeacezids",  --跨服竞技
        crossServerAbility = "cssabilitypkzids",  --跨服资质
        crossAbilityKing = "crossabilitykingpkzids",  --资质夺帝战
        crossCityAllianceBattle = "crosscityalliancepkzids",  --连城斗阵
        treasureFairActive = "treasurefairzids",  --一元夺宝
        jadePlus = "jadepluszids",  --招财进宝
        treasureFairGem = "treasurefairgemzids",  --消耗夺宝
        wifeBattlePromotion = "wifeatkpkzids",  --风云群芳
        crossServerHorsePower = "horsepowerpkzids",  --跨服战马冲榜活动
        crossCaptureCityNew = "capturecityzids",  --攻城掠地改版
        beautyContest = "beautycontestpkzids",  --跨服选美大赛
        crossServerHorseRace = "warhorseracezids",  --跨服战马PVP冲榜活动
        crossCityBattle = "citybattlepkzids",  --雄霸天下
        newThreeKingdoms = "newThreeKingdomsZids",  --新版三国争霸
        newWeaponHouse = "newWeaponHouseZids",  --新神兵宝库
        superKing = "superKingZids",--决战皇城
        crossCityAllianceBattleNew = "crosscityalliancenewpkzids",--列阵破敌
        orchard = "orchardpkzids",--京郊果园
        crossGroupAbility = "crossGroupAbilityZids",--乱世群雄
        superKing2 = "superKing2Zids",--决战皇城
        crossHorseFight = "crossHorseFightZids",--跨服斗马
        cloudHorseFight = "cloudHorseFightZids",--风云赛马
        demonCome = "demoncomezids",  --魔王来袭
        impossibleMaze = "impossibleZids",  --迷宫
        crossYamenPower = "yamenPowerZids",  --跨服民望
        crossCuriosPower = "crossCuriosPowerZids",--跨服文玩价值
        crossCuriosFight="crossCuriosFightZids",--跨服文玩pvp
        carnivalNight2 = "carnivalNightZids", --狂欢之夜2
        troublemakerSnowboy = "troublemakerSnowboyZids",  --捣乱的雪人
        crossDrawPhone = "crossDrawPhoneZids",  --抽手机
        crossGoCompetition = "crossGoCompetitionZids",  --珍珑棋局
        allServerRecharge = "allServerRechargeZids",  --全服团购
        dungeonAdventure = "dungeonAdventureZids",--文玩搭桥
        phoenixDance = "phoenixDanceZids",--凤舞金銮
        crossCuriosGroupPower = "crossCuriosGroupPowerZids",--跨服文玩帮会冲榜
        navigation = "navigationZids",  --大航海
        luckyGift = "luckyGiftZids",  --大航海
        curiosShow = "curiosShowZids",  --文玩展览功能
        totalAnnihilation = "totalAnnihilationZids",  --横扫千军
        kingOfStates = "kingOfStatesZids",  --赛季活动
        crossOneServer = "crossOneServerZids",--跨服门客冲榜
        lwRescue = "lwRescueZids",--千里救援
        snowboy = "snowboyZids",  --捣乱的雪人
        tradeCombat = "tradeCombatZids",  --帮会商战
    }
    
    return actIdArr
end

--通用获取跨服PK组信息
function getCrossActivityGroupZid(aid,mzid,version)
    local mzid = tonumber(mzid)
    local version = tonumber(version)
    local key = getAcCrossKey()[aid]
    if not key or not mzid or not version then
        return false
    end

    local db = getDbo(2000)
    local ret = db:getRow("select info from bkcross where id=:key",{key=key})
    if ret then
        local pkinfos = json.decode(ret.info)
        for _,pkinfo in ipairs(pkinfos) do
            local zidgroups = pkinfo.zids
            if pkinfo.st==version then
                for _,zidgroup in ipairs(zidgroups) do
                    if table.contains(zidgroup,mzid) then
                        return zidgroup,pkinfo
                    end
                end
            end
        end
    end
    return false
end

---同步榜单给决战皇城活动(1000名)
---@param activeid string 榜单活动的aid
---@param rankArr table 已产出的榜单
---@param zidGroup table 活动的pk组
---@param acst number 活动开始时间
---@param acet number 活动结束时间
function addScoreToSuperKing(activeid,rankArr,zidGroup,acst,acet)
    if activeid == "crossServerAtkRace" then
        rankArr = getCrossRankApi(0,getZoneId(),acst)
    end
    local superking = require('lib/superking')
    superking:syncRankScore(activeid,rankArr,zidGroup,acst,acet)
end

---根据奖励返回关联开关
---@param reward string 奖励三段式
---@return string 对应开关字符串 没有为nil
function getRewardSwitch(reward)
    if not reward or reward == "" then
        return
    end
    local rearr = string.split(reward, "%_")
    local rType = tonumber(rearr[1])
    local tmpId = tostring(rearr[2])
    if rType == 6 then
        --道具
        local itemCfg = getConfig('itemCfg')
        if itemCfg[tmpId] and itemCfg[tmpId].switch then
            if itemCfg[tmpId].switch ~= '' then
                return itemCfg[tmpId].switch
            end
        end
    elseif rType == 8 then
        --门客 "switchkey" => "servant_name", "name" => "门客开关"
        local servantCfg = getConfig('servantCfg')
        if servantCfg[tmpId] and servantCfg[tmpId]["state"] == 0 then
            if servantCfg[tmpId].switch and servantCfg[tmpId].switch ~= '' then
                return "servant_name"..tmpId .."|"..servantCfg[tmpId].switch
            else
                return "servant_name"..tmpId
            end
        end
    elseif rType == 10 then
        --红颜 "switchkey" => "wifeName_", "name" => "红颜开关"
        local wifeCfg = getConfig('wifeCfg')
        if wifeCfg[tmpId] and wifeCfg[tmpId].state == 0 then
            return "wifeName_"..tmpId
        end
    elseif rType == 11 then
        --称号 "switchkey" => "title_name", "name" => "称号开关"
        local titleCfg = getConfig('titleCfg')
        if titleCfg[tmpId] and titleCfg[tmpId].state == 0 then
            return "title_name"..tmpId
        end
        --头像 "switchkey" => "portrait_name", "name" => "头像开关"
        local portraitCfg = getConfig('portraitCfg')
        if portraitCfg[tmpId] and portraitCfg[tmpId].state == 0 then
            return "portrait_name"..tmpId
        end
    elseif rType == 16 then
        --红颜皮肤 "switchkey" => "wifeSkin_name", "name" => "红颜皮肤开关"
        local wifeSkinCfg = getConfig('wifeSkinCfg')
        if wifeSkinCfg[tmpId] and wifeSkinCfg[tmpId].state == 0 then
            --红颜皮肤需要额外返回对应的红颜开关,如果该红颜有开关
            local wifeCfg = getConfig('wifeCfg')
            local wifeId = wifeSkinCfg[tmpId].wifeId
            if wifeCfg[wifeId] and wifeCfg[wifeId].state == 0 then
                return "wifeName_"..wifeId.."|".. "wifeSkin_name"..tmpId
            else
                return "wifeSkin_name"..tmpId
            end
        end
    elseif rType == 19 then
        --门客皮肤 "switchkey" => "servantSkin_name", "name" => "门客皮肤开关"
        local servantSkinCfg = getConfig('servantSkinCfg')
        if servantSkinCfg[tmpId] and servantSkinCfg[tmpId].state == 0 then
            --门客皮肤需要额外返回对应的门客开关,如果该门客有开关
            local servantCfg = getConfig('servantCfg')
            local servantId = servantSkinCfg[tmpId].servantId
            if servantCfg[servantId] and servantCfg[servantId]["state"] == 0 then
                return "servant_name"..servantId.."|".. "servantSkin_name"..tmpId
            else
                return "servantSkin_name"..tmpId
            end
        end
    elseif rType == 106 then
        --聊天头像 "switchkey" => "chathead_name", "name" => "聊天头像开关"
        local chatHeadCfg = getConfig('chatHeadCfg')
        if chatHeadCfg[tmpId] and chatHeadCfg[tmpId].state == 0 then
            return "chathead_name"..tmpId
        end
    elseif rType == 107 then
        -- 聊天气泡 "switchkey" => "chatframe_name", "name" => "聊天气泡开关"
        local chatFrameCfg = getConfig('chatFrameCfg')
        if chatFrameCfg[tmpId] and chatFrameCfg[tmpId].state == 0 then
            return "chatframe_name"..tmpId
        end
    elseif rType == 53 then
        --增加经营NPC"switchkey" => "managenpc_name",  "name" => "NPC开关"
        local manageNpcCfg = getConfig('manageNpcCfg.npc')
        if manageNpcCfg[tmpId] then
            return "managenpc_name"..tmpId
        end
    elseif rType == 105 then
        --府邸场景
        local sceneProCfg = getConfig('sceneProCfg')
        local homeSceneCfg = sceneProCfg.homeScene
        if homeSceneCfg[tmpId] and homeSceneCfg[tmpId].switch then
            if homeSceneCfg[tmpId].switch ~= '' then
                return homeSceneCfg[tmpId].switch
            end
        end
    elseif rType == 104 then
        --共浴场景
        local wifeBathSceneCfg = getConfig("wifeBathSceneCfg")
        if wifeBathSceneCfg[tmpId] and wifeBathSceneCfg[tmpId].switch then
            if wifeBathSceneCfg[tmpId].switch ~= '' then
                return wifeBathSceneCfg[tmpId].switch
            end
        end
    elseif rType == 64 then
        --衙门镇民
        local yamenNpcCfg = getConfig("yamenCfg.people")
        if yamenNpcCfg and yamenNpcCfg[tmpId] and yamenNpcCfg[tmpId].state == 0 then
            return "yamennpc_name"..tmpId
        end
    elseif rType == 66 then
        --文玩
        local curiosCfg = getConfig("curiosCfg.curios")
        if curiosCfg and curiosCfg[tmpId] and curiosCfg[tmpId].state == 0 then
            return "curios_name"..tmpId
        end
    elseif rType == 52 then
        --战马 "switchkey" => "horseName_", "name" => "战马开关"
        local warHorseCfg = getConfig('warHorseCfg')
        if warHorseCfg and warHorseCfg[tmpId] and warHorseCfg[tmpId].state and warHorseCfg[tmpId].state == 0 then
            return "horseName_"..tmpId
        end
    elseif rType == 57 then
        -- 聊天字色 "switchkey" => "chatcolor_name", "name" => "聊天字色开关"
        local wordsColorCfg = getConfig('wordsColorCfg')
        if wordsColorCfg[tmpId] and wordsColorCfg[tmpId].state == 0 then
            return "chatcolor_name"..tmpId
        end
    end
end

---检测对应开关是否属于当前平台
---@param switch string 对应开关字符串
---@return boolean 是否可用
function checkSwitchPlatform(switch)
    if not switch or switch == "" then
        return
    end

    --本地测试平台无需检测
    if PLATFORM == 'test' then
        return true
    end

    --需检测开关列表
    local checkType = {
        {key = "wifeName_", config = "wifeCfg"},
        {key = "servant_name", config = "servantCfg"},
        {key = "wifeSkin_name", config = "wifeSkinCfg"},
        {key = "servantSkin_name", config = "servantSkinCfg"},
    }

    for _, info in pairs(checkType) do
        local sid, eid = string.find(switch,info.key)
        --检测开关匹配到
        if sid and eid then
            local configId = tonumber(string.sub(switch,eid+1))
            if not checkConfigPlatform(info.config, configId) then
                return false
            end
            break
        end
    end
    return true
end

---检测指定配置的指定下标是否属于当前平台
---@param configName string 配置名
---@param configId string 配置下标
---@return boolean 是否属于当前平台
function checkConfigPlatform(configName, configId)
    if not configName or configName == "" then
        return
    end
    if not configId or configId == "" then
        return
    end
    configName, configId = tostring(configName),tostring(configId)
    local configCfg = getConfig(configName)
    --部分配置可能需要特殊处理下
    -- if configName == "" then
    --     configCfg = configName.XX
    -- end

    --未取到对应配置
    if not configCfg or not next(configCfg) then
        return
    end
    --对应id未在配置中找到
    if not configCfg[configId] or not next(configCfg[configId]) then
        return
    end
    local platform = configCfg[configId].platform
    --平台列表没有配置表示该ID无需进行平台区分
    if not platform then
        return true
    end
    --配置格式不正确
    if type(platform) ~= 'table' then
        return
    end
    --本地测试平台无需检测 属于微信/h5联运也无法添加,不然前端报错
    if PLATFORM == 'test' then
        -- if table.contains(platform,"cn_wx") or table.contains(platform,"cn_h5ly") then
        --     return true
        -- end
        return false
    end
    --未匹配到当前平台
    if not table.contains(platform,PLATFORM) then
        return
    end
    return true
end

---设置小号标记
---@param uid number
function setLittleUser(uid,param)
    if PLATFORM == "cn_wx" then
        local uobjs = getUserObjs(uid)
        local mGameinfo = uobjs.getModel('gameinfo')
        if not mGameinfo.info.d then
            mGameinfo.info.d=1
            uobjs.save()
        end
        writeLog({uid=uid,cmd=getCmd(),date=os.time(),params = param},"littleuser")
    end
end

---检测小号标记并返回注册的model
---@param uid number
---@param modelarr table
---@return boolean
function chekLittleUser(uid,modelarr)
    local isLittel = false
    if PLATFORM == "cn_wx" then
        local uobjs = getUserObjs(uid)
        local mGameinfo = uobjs.getModel('gameinfo')
        if mGameinfo.info.d==1 then
            regReturnModel(modelarr)
            isLittel = true
        end
    end
    return isLittel
end

---检测道具使用1000次的条件
---@param uid number 玩家uid
---@param itemId string 道具id
---@param useNum number 使用次数
---@return boolean 是否符合
---@return integer 错误码
function checkItemUseNum(uid,itemId,useNum)
    local uid = tonumber(uid)
    local useNum = tonumber(useNum) or 0
    
    if not uid or useNum <= 0 or useNum > 1000 then
        return false,1
    end
    if useNum <= 100 then
        return true
    end

    --检测道具
    local itemCfg = getConfig('itemCfg')
    if not itemCfg[itemId] or not itemCfg[itemId].usePlus then
        return false,2
    end

    --官品检测
    -- local uobjs = getUserObjs(uid)
    -- local mUserinfo = uobjs.getModel('userinfo')
    -- if not mUserinfo.isFuncUnlockBylevel("itemUse") then
    --     return false,3
    -- end

    --时间检测(避免前后端时间差,增加5秒容错,21:30-22:00)
    local now = os.time()
    local today = getWeeTs(now)
    local st = today + 21*3600 + 1800 +5
    local et = today + 22*3600 + 5
    if now > st and now < et then
        return false,4
    end

    return true
end

--同时设置多个本服王称号
function setMoreOtherTitle(titleData)
    local otherdatailtitle = "z" .. getZoneId() .. ".othertitledatail"
    local redis = getRedis()
    local titleCfg = getConfig("titleCfg")
    local palaceData = redis:get(otherdatailtitle)
    if not palaceData then
        local data = getBakData(otherdatailtitle)
        if data then
            palaceData = json.decode(data)
        else
            palaceData = {}
            for k,v in pairs(titleCfg) do
                if v.isCross == 0 and v.isOnly == 0 and v.titleType == 2 then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        for k,v in pairs(titleCfg) do
            if not palaceData[k] and v.isCross == 0 and v.isOnly == 0 and v.titleType == 2 then
                palaceData[k] = {}
            end
        end
    end

    local now = os.time()
    for _, tInfo in pairs(titleData) do
        local titleId = tostring(tInfo.titleId)
        if palaceData[titleId] then
            palaceData[titleId].rank = palaceData[titleId].rank or {}
            --进行防重处理
            if titleCfg[titleId].isOnly == 0 then --可多人同时获得称号
                for _, uInfo in pairs(palaceData[titleId].rank) do
                    --(开始时间相同)&(结束时间相同)&(uid相同)
                    if (not tonumber(uInfo[3]) or tonumber(uInfo[3]) == tonumber(tInfo.st)) and (not tonumber(uInfo[5]) or tonumber(uInfo[5]) == tonumber(tInfo.et)) and tonumber(uInfo[1]) == tonumber(tInfo.uid) then
                        writeLog({uid=tInfo.uid,titleId=titleId,type="otherdatailtitle",cmd=getCmd(),myuid=getMyuid()}, "otherdatailTitleRepWrong")
                        return false
                    end
                end
            end
            palaceData[titleId].sign = ""
            palaceData[titleId].uid = tInfo.uid
            palaceData[titleId].zid = tInfo.zid
            palaceData[titleId].st = tInfo.st or now
            palaceData[titleId].et = tInfo.et
            table.insert(palaceData[titleId].rank,1,{tInfo.uid,"",tInfo.st or now,tInfo.zid,tInfo.et})
        end
	end

    local dataStr = json.encode(palaceData)
    --记录到缓存
    redis:set(otherdatailtitle, dataStr)
    --记录数据入库
    recordBakData(otherdatailtitle,dataStr)
    return true
end

---获取关卡的配置
---@param uid number 玩家uid
---@param cid number 关卡id
---@return any
function getChallengeConfigWhitSwitch(uid,cid)
    local challengeIdCfg
    if isSwitchTrue(uid,"openFiefTo4") then
        challengeIdCfg = {}
        local challenge4BaseCfg = getConfig("challenge4BaseCfg")
        local ChallengeData = challenge4BaseCfg.challenge
        if ChallengeData[tostring(cid)] then
           for k, v in pairs(ChallengeData[tostring(cid)]) do
                challengeIdCfg[k] = v
           end 
        end
        
        --关卡章节号P1  =  roundup（关卡id/41）------向上取整
        --关卡中关号P2  =  roundup（（关卡id-（P1-1）*41）/8）-------向上取整
        --关卡小关号P3  =  mod（（关卡id-（P1-1）*41-1）/8）+1------mod取余数函数
        local p1,p2,p3
        p1 = math.ceil(tonumber(cid)/41)
        p2 = math.ceil((tonumber(cid) - (p1-1)*41)/8)
        p3 = (tonumber(cid)-(p1-1)*41-1)%8+1

        challengeIdCfg.reward = challenge4BaseCfg.reward
        if p3 == 8 then
            challengeIdCfg.dropRatio = challenge4BaseCfg.spDropRatio
            challengeIdCfg.drop = challenge4BaseCfg.spDrop
        end

        challengeIdCfg.type = tonumber(cid)%41 == 0 and 2 or 1
        local heXinValueCfg = challenge4BaseCfg.heXinValue
        local hexinCfg = heXinValueCfg[tostring(p1)]
        if not hexinCfg or not hexinCfg.value then
            return false
        end
        if challengeIdCfg.type == 1 then
            if not challengeIdCfg.atk then
                local hexinValue = hexinCfg.value[p2]
                local atkP1Cfg = challenge4BaseCfg.atkP1
                local atkP2Cfg = challenge4BaseCfg.atkP2
                --关卡的武力值  =  当前关卡的核心值value * 10 + int（value*atkP1/10）+ int（value*atkP2/1000）    【P3不同数值对应的atkP1不同】
                challengeIdCfg.atk = math.floor(hexinValue * 10 + (hexinValue*atkP1Cfg[p3]/10) + (hexinValue*atkP2Cfg[p3]/1000))
                local solderPCfg = challenge4BaseCfg.solderP
                challengeIdCfg.soldier = solderPCfg[p3]*hexinValue
            end
        elseif challengeIdCfg.type == 2 then
            challengeIdCfg.dropRatio = challenge4BaseCfg.spBossRatio
            challengeIdCfg.drop = challenge4BaseCfg.spBossDrop
            if not challengeIdCfg.value then
                --此处的1 是异常的含义，只是为了后续不报错做的兼容，正常来说，hp必须存在
                challengeIdCfg.value = hexinCfg.hp or 1
            end
        end
        local extraRewardCfg = challenge4BaseCfg.extraReward[tostring(cid)]
        if extraRewardCfg then
            challengeIdCfg.extraReward = extraRewardCfg.reward
            challengeIdCfg.unlockPrison = extraRewardCfg.unlockPrison
        end
        
        

        return challengeIdCfg
    end
    local challengeCfg = getConfig("challengeCfg")
    challengeIdCfg = challengeCfg[tostring(cid)]

    return challengeIdCfg
end

function sendGucenterInfo(uid,pid,vip)
    local platArr = {
        test = "http://192.168.8.83",
        cn_wx = "http://gt-fkwx001.leishenhuyu.com",
    }
    if not platArr[PLATFORM] then
        return
    end
    local http = require("socket.http")
    local opendate = getServerOpenTime()
    local redis = getRedis()
    --http://192.168.8.82/gucenter/setpidvip.php?pid=ljl000022&vip=7&zid=1&openservertime=1545037639
    local gucenterUrl = platArr[PLATFORM].."/gucenter/setpidvip.php?pid="..pid.."&zid="..getZoneId().."&vip="..vip.."&openservertime="..opendate
    http.request(gucenterUrl)
    local today = getWeeTs(os.time())
    local todayuserSendVipKey = "z" .. getZoneId() ..uid..".userSendVip."..today
    redis:set(todayuserSendVipKey,1)
    redis:expire(todayuserSendVipKey,86400*2)
end

--截取称号奖励并发放给玩家
function filterTitleRewards(rewards,uid,st)
    if PLATFORM ~= "cn_37wx" and PLATFORM ~= "cn_7477mg" then
        return rewards
    end
    local rewards_table = string.split(rewards, "%|")
    local titleCfg = getConfig('titleCfg')
    local newReward,titleReward
    for k, v in ipairs(rewards_table) do
        local reward_v = string.split(v, "%_")
        local rewardType = tonumber(reward_v[1])
        local rewardId = tostring(reward_v[2])
        --是称号且必须是委任状才直接加到身上
        if rewardType == 11 and titleCfg[rewardId] and titleCfg[rewardId].isTitle == 1 and titleCfg[rewardId].group == 1 then
            titleReward = v
        else
            newReward = newReward and newReward .."|"..v or v
        end
    end
    if titleReward then
        funAddRewards(uid,titleReward,st)
    end

    return newReward
end

--通用兑换商店圣兽兑换检测
function checkBestHorseRewards(uid,checkRewards)
    if not uid or not checkRewards or checkRewards == "" then
        return false
    end
    local uobjs = getUserObjs(uid,true)

    --检测特殊奖励不重复获得
    local rearr = string.split(checkRewards, "%_")
    local rType = tonumber(rearr[1])
    local tmpId = tostring(rearr[2])
    if rType == 52 then
        local warHorseCfg = getConfig("warHorseCfg")
        --是圣兽
        if warHorseCfg[tmpId] and warHorseCfg[tmpId].quality and warHorseCfg[tmpId].quality == 5 then
            local mWarhorse = uobjs.getModel('warhorse')
            --没有战马不可兑换
            if mWarhorse.mn <= 0 then
                return false
            end
        end
    end

    return true
end

--通用兑换商店的 奖励的特殊限制
function shopRewardsCheckExchangeBytype(uid,checkRewards,checkExchangeType)
    if not uid or not checkRewards or checkRewards == "" then
        return false
    end
    local uobjs = getUserObjs(uid,true)

    --检测特殊奖励不重复获得
    local rearr = string.split(checkRewards, "%_")
    local rType = tonumber(rearr[1])
    local tmpId = tostring(rearr[2])
    --1：奖励对应的圣兽拥有且已渡劫则不可购买
    if checkExchangeType == 1 and rType == 6 then
        local itemCfg = getConfig('itemCfg')
        if itemCfg[tmpId] and itemCfg[tmpId].targetValue and next(itemCfg[tmpId].targetValue) then
            local warHorseCfg = getConfig('warHorseCfg')
            for _, bhId in ipairs(itemCfg[tmpId].targetValue) do
                if warHorseCfg[bhId] and warHorseCfg[bhId].quality == 5 then
                    local mWarhorse = uobjs.getModel('warhorse')
                    if mWarhorse.info[bhId] then
                        if mWarhorse.checkDisasterFlag(bhId) then--已渡劫
                            return false
                        end
                    end
                end
            end
        end
    end
    return true
end

---设置帮会任务数据(公共缓存)
---@param mould string 模块id（关联前端业务）
---@param allianceId string|number 帮会id
---@param keyName string 缓存索引
---@param taskName string 索引子项
---@param addNum number 增加值
function setATaskToCommonRedis(mould,allianceId,keyName,taskName,addNum)
    local allianceTaskInfoKey = "a"..allianceId..".taskinfo."..keyName
    local commonRedis = getCommonRedis()
    commonRedis:hincrby(allianceTaskInfoKey,taskName,addNum)
    commonRedis:expire(allianceTaskInfoKey,86400*15)

    regReturnData("allianeAcTask",{mould,allianceId,keyName})
end

---获取所有帮会任务数据(公共缓存)
---@param allianceId string|number 帮会id
---@param keyName string 缓存索引
---@return table 所有帮会任务数据
function getAllATaskByCommonRedis(allianceId,keyName)
    local allianceTaskInfoKey = "a"..allianceId..".taskinfo."..keyName
    local commonRedis = getCommonRedis()
    local taskInfo = commonRedis:hgetall(allianceTaskInfoKey) or {}

    return taskInfo
end

---获取指定类型帮会任务数据(公共缓存)
---@param allianceId string|number 帮会id
---@param keyName string 缓存索引
---@param taskName string 索引子项
---@return any 指定类型帮会任务值
function getATaskByCommonRedis(allianceId,keyName,taskName)
    local allianceTaskInfoKey = "a"..allianceId..".taskinfo."..keyName
    local commonRedis = getCommonRedis()
    local taskValue = commonRedis:hget(allianceTaskInfoKey,taskName)

    return tonumber(taskValue) or 0
end

---设置帮会领取成员(公共缓存)
---@param uid string|number 玩家uid
---@param allianceId string|number 帮会id
---@param keyName string 缓存索引
---@return boolean 是否成功
function setATaskMembers(uid,allianceId,keyName)
    local commonRedis = getCommonRedis()
    local alkey = "a" .. allianceId .. ".memberinfo." .. keyName
    commonRedis:sadd(alkey,uid)
    commonRedis:expire(alkey,86400*15)
    return true
end

---获取帮会领取成员
---@param allianceId string|number 帮会id
---@param keyName string 缓存索引
---@return table 帮会领取成员
function getATaskMembers(allianceId,keyName)
    local commonRedis = getCommonRedis()
    local alkey = "a" .. allianceId .. ".memberinfo." .. keyName
    return commonRedis:smembers(alkey) or {}
end

---检测帮会任务领奖人数上限
---@param uid string|number 玩家uid
---@param allianceId string|number 帮会id
---@param keyName string 缓存索引
---@return boolean 是否达到上限
function checkATaskMembers(uid,allianceId,keyName)
    local uid = tostring(uid)
    local zid = getZoneId()
    local allianceInfo = getCommonCacheAllianceInfo(allianceId,zid)
    local alevel = tostring(allianceInfo.level)
    local allianceCfg = getConfig('allianceCfg')
    local allianceBaseCfg = getConfig('allianceBaseCfg')
    local anum = allianceCfg[alevel].count
    local maxnum = anum + allianceBaseCfg.maxReward
    local menberArr = getATaskMembers(allianceId,keyName)
    local nownum = #menberArr
    if nownum >=  maxnum and (not table.contains(menberArr,uid)) then
        return false
    end

    return true
end

--增加任务数据统一接口
function addAllTaskData(uid, taskType, num, extra)
    --任务模块映射表
    local typeMap = {
        ["1405"] = {degree=1},
        ["1516"] = {degree=1},
        ["403"] = {degree=1},
        ["119"] = {degree=1},
        ["601"] = {degree=1,abilitytask=1},
        ["1801"] = {abilitytask=1},----每使用1个出使令
        ["1802"] = {abilitytask=1},----每使用1个挑战书
        ["1803"] = {abilitytask=1},----每使用1个追杀令
    }

    --获取对应的任务模块
    local modelArr = {}
    if typeMap[taskType] then
        modelArr = typeMap[taskType]
        --若有默认模块可以在此直接置1
        --modelArr['xxx'] = 1
    end

    --执行对应模块的任务计数
    local zid = getUserTrueZid(uid)
    local uobjs = getUserObjs(uid)
    --圣旨模块
    if modelArr["degree"] then
        --如果开启功能执行
        local degreelib = require('lib/degreelib')
        if degreelib:checkIsOpen(uid,zid) then
            local mDegree = uobjs.getModel('degree')
            mDegree.addTaskData(taskType,num)
        end
    end
    --门客皮肤特殊任务
    if modelArr["abilitytask"] then
        local mAbilitytask = uobjs.getModel('abilitytask')
        mAbilitytask.checkQuestType(taskType,num,extra)
    end
    --xxx模块

    return true
end

-- 记录帮会类活动排行榜的个人涨幅
function setCommonPersonalIncrease(perkey, uid, v)
    local key = perkey .. ".common"
    local commonRedis = getCommonRedis()
    commonRedis:zincrby(key, v, uid)
    commonRedis:expire(key, 864000)
end

-- zadd记录帮会类活动排行榜的个人涨幅
function zaddCommonPersonalIncrease(perkey, uid, v)
    local key = perkey .. ".common"
    local commonRedis = getCommonRedis()
    commonRedis:zadd(key, v, uid)
    commonRedis:expire(key, 864000)
end

-- 从帮会类活动排行榜的个人涨幅中移除某人数据
function rmFromCommonPersonalIncrease(perkey, uid, remflag)
    local key = perkey .. ".common"
    local commonRedis = getCommonRedis()
    local score = commonRedis:zscore(key, uid)
    if remflag then
        commonRedis:zrem(key, uid)
        commonRedis:expire(key, 864000)
    end
    return tonumber(score) or 0
end

-- 获取帮会类活动排行榜的个人涨幅
function getCommonPersonalIncrease(perkey, uid, allianceId)
    local key = perkey .. ".common"
    local commonRedis = getCommonRedis()
    local rankData = commonRedis:zrevrange(key, 0, -1, "withscores")
    local myalliRank = {}
    for _, v in pairs(rankData) do
        local auid = tonumber(v[1])
        local aUserinfo = getCommonCacheUserInfo(auid)
        local aflag = false
        if tonumber(aUserinfo.mygid) ~= tonumber(allianceId) then
            aflag = true
        end
        local showrank = true
        if aflag then
            showrank = false
            commonRedis:zrem(key, auid)
            commonRedis:expire(key, 864000)
        end
        if showrank then
            table.insert(myalliRank, { tonumber(auid), tonumber(v[2]), aUserinfo.name, aflag })
        end
    end

    local allirank = {}
    local alliRankList = {}
    for k, v in ipairs(myalliRank) do
        table.insert(alliRankList, { uid = tonumber(v[1]), value = v[2], name = v[3], eflag = v[4] })
        if uid == tonumber(v[1]) then
            allirank.myrank = { uid = tonumber(v[1]), value = v[2], myrank = k, name = v[3] }
        end
    end
    allirank.rankList = alliRankList

    return allirank
end

-- 获取非帮会类活动排行榜的个人涨幅
function getCommonPersonalIncrease2(perkey, uid)
    local key = perkey .. ".common"
    local commonRedis = getCommonRedis()
    local rankData = commonRedis:zrevrange(key, 0, -1, "withscores")
    local myalliRank = {}
    for _, v in pairs(rankData) do
        local auid = tonumber(v[1])
        local aUserinfo = getCommonCacheUserInfo(auid)
        table.insert(myalliRank, { tonumber(auid), tonumber(v[2]), aUserinfo.name })
    end

    local allirank = {}
    local alliRankList = {}
    for k, v in ipairs(myalliRank) do
        table.insert(alliRankList, { uid = tonumber(v[1]), value = v[2], name = v[3] })
        if uid == tonumber(v[1]) then
            allirank.myrank = { uid = tonumber(v[1]), value = v[2], myrank = k, name = v[3] }
        end
    end
    allirank.rankList = alliRankList

    return allirank
end

--道具使用条件检测
function checkItemCondition(uid,targetType,mCondition,servantId,tCondition)
    local uobjs = getUserObjs(uid)
    if targetType == 2 and mCondition > 0 then  --门客皮肤凭证
        local mServant = uobjs.getModel('servant')
        local servantCfg = getConfig('servantCfg')
        if not servantCfg[tostring(mCondition)] then
            return false
        end
        if not mServant.info[tostring(mCondition)] then
            return false
        end
    elseif targetType == 3 and mCondition > 0 then --红颜皮肤&宠幸场景
        local wifeCfg = getConfig("wifeCfg")
        local mWife = uobjs.getModel('wife')
        if not wifeCfg[tostring(mCondition)] then
            return false
        end
        if not mWife.info[tostring(mCondition)] then
            return false
        end
    elseif targetType == 6 and mCondition ~= "" then --组合红颜条件
        local wifeCfg = getConfig("wifeCfg")
        local mWife = uobjs.getModel('wife')
        local wifeIds = string.split(mCondition,"%,")
        for _,wifeId in ipairs(wifeIds) do
            if not wifeCfg[tostring(wifeId)] then
                return false
            end
            if not mWife.info[tostring(wifeId)] then
                return false
            end
        end
    elseif targetType == 15 and next(tCondition) then  --范围门客校验
        local mServant = uobjs.getModel('servant')
        local servantCfg = getConfig('servantCfg')
        if not servantCfg[tostring(servantId)] then
            return false
        end
        if not table.contains(tCondition,tonumber(servantId)) then
            return false
        end
        if not mServant.info[tostring(servantId)] then
            return false
        end
    elseif targetType == 1 and next(tCondition) then  --范围条件检测
        for _, tmpCond in ipairs(tCondition) do
            local reFlag = true
            local cond_arr = string.split(tmpCond, "%|")
            for _, v in ipairs(cond_arr) do
                if not checkHaveRewards(uid,v) then
                    reFlag = false
                    break
                end
            end
            if reFlag then
                return true
            end
        end
        return false
    end

    return true
end

--同时设置多个跨服称号
function setMoreCrossStatue(statueData)
    local crossstatue = "z" .. getZoneId() .. ".crossstatue"
    local redis = getRedis()
    local statueCfg = getConfig("statueCfg")
    local palaceData = redis:get(crossstatue)
    if not palaceData then
        local data = getBakData(crossstatue)
        if data then
            palaceData = json.decode(data)
        else
            palaceData = {}
            for k,v in pairs(statueCfg) do
                if v.isCross == 1 then
                    palaceData[k] = {}
                end
            end
        end
    else
        palaceData = json.decode(palaceData)
        for k,v in pairs(statueCfg) do
            if not palaceData[k] and v.isCross == 1 then
                palaceData[k] = {}
            end
        end
    end

    local now = os.time()
    for _, tInfo in pairs(statueData) do
        local statueId = tostring(tInfo.titleId)
        if palaceData[statueId] then
            palaceData[statueId].rank = palaceData[statueId].rank or {}
            --进行防重处理
            if statueCfg[statueId].isOnly == 0 then --可多人同时获得称号
                for _, uInfo in pairs(palaceData[statueId].rank) do
                    --(开始时间相同)&(结束时间相同)&(uid相同)
                    if (not tonumber(uInfo[3]) or tonumber(uInfo[3]) == tonumber(tInfo.st)) and (not tonumber(uInfo[5]) or tonumber(uInfo[5]) == tonumber(tInfo.et)) and tonumber(uInfo[1]) == tonumber(tInfo.uid) then
                        writeLog({uid=tInfo.uid,statueId=statueId,type="crossstatue",cmd=getCmd(),myuid=getMyuid()}, "crossstatueRepWrong")
                        return false
                    end
                end
            end
            palaceData[statueId].sign = ""
            palaceData[statueId].uid = tInfo.uid
            palaceData[statueId].zid = tInfo.zid
            palaceData[statueId].st = tInfo.st or now
            palaceData[statueId].et = tInfo.et
            table.insert(palaceData[statueId].rank,1,{tInfo.uid,"",tInfo.st or now,tInfo.zid,tInfo.et})
        end
	end

    local dataStr = json.encode(palaceData)
    redis:set(crossstatue, dataStr)
    recordBakData(crossstatue,dataStr)
    return true
end

--缓存骑士团常用基础信息
function getCachePlayerInfo(uid)
    local redis = getRedis()
    local key = "z"..getZoneId()..".cachePlayerInfo."..uid
    local cacheData = redis:hgetall(key) or {}
    
    if not next(cacheData) then
        local uobjs = getUserObjs(uid, true)
        -- local mUserinfo = uobjs.getModel('userinfo')
        local mCrazyplayer = uobjs.getModel('crazyplayer')
        local mCrazytask = uobjs.getModel('crazytask')

        -- cacheData['name'] = mUserinfo.name
        -- cacheData['vip'] = mUserinfo.vip
        cacheData['pic'] = mCrazyplayer.pic
        cacheData['lv'] = mCrazyplayer.lv
        cacheData['titleid'] = mCrazyplayer.titleid
        cacheData['paperlv'] = mCrazytask.paperlv

        redis:hmset(key, cacheData)
        redis:expire(key, 864000)
    end
    return cacheData
end

--更新骑士团常用基础信息
function upCachePlayerInfo(uid, field, value)
    local redis = getRedis()
    local key = "z"..getZoneId()..".cachePlayerInfo."..uid
    if redis:exists(key) then
        redis:hset(key, field, value)
    end
    return true
end

--不可执行部分脚本的服
function cantRunServerTb()
    local noRun = {900,901,902,1000,1999,2000,999}
    return noRun
end

--获取红点
function getRedPoint(uid)
    local redpoint = {}
    local uobjs = getUserObjs(uid)

    local checkModel = {"mymail","onemanwar","atkrace","kingofstates","council","servantatk"}
    for _, v in ipairs(checkModel) do
        local mModel = uobjs.getModel(v)
        if mModel.getRedPoint() then
            redpoint[v]=1
        end
    end
    
    return redpoint
end

--记录当天登陆人数
function setServerTodayLoginNum()
    local now = os.time()
    local today = getWeeTs(now)
    local key = "z" .. getZoneId() .. ".loginnum." .. today
    local commonRedis = getCommonRedis()
    commonRedis:incrby(key,1)
    commonRedis:expire(key,86400*4)
end

--记录指定天登陆人数
function setServerChosendayLoginNum(zid,time,num)
    local num = tonumber(num) or 1
    local today = getWeeTs(time)
    local key = "z" .. zid .. ".loginnum." .. today
    local commonRedis = getCommonRedis()
    commonRedis:incrby(key,num)
    commonRedis:expire(key,86400*4)
end

--获取指定天的登陆人数
function getServerTodayLoginNum(zid,time)
    local zid = tonumber(zid) or getZoneId()
    local time = tonumber(time) or getWeeTs(os.time())
    local key = "z" .. zid .. ".loginnum." .. time
    local commonRedis = getCommonRedis()
    local num = commonRedis:get(key)
    return tonumber(num) or 0
end

--根据pk组key找到活动id
function getActiveNameByPkKey(key)
    local aid
    local keyArr = getAcCrossKey()
    for tmpaid, name in pairs(keyArr) do
        if key == name then
            aid = tmpaid
        end
    end
    return aid
end

--检测决战皇城与紫禁之巅的对战组包含
function checkSuperKingPkGroup(key,zids,st,et,ctype)
    if st >= et then
        return false
    end
    local aid = getActiveNameByPkKey(key)
    local tarAid = "superKing"
    local actIndex = "crossAtvitity"
    if ctype then
        tarAid = "superKing2"
        actIndex = "crossActivities"
    end

    local aidCfg = getConfig(tarAid.."Cfg","activecfg")[1]
    local activeArr = aidCfg[actIndex]
    if not table.contains(activeArr,aid) then
        return false
    end

    local warmupTimeCfg = getConfig("warmupTimeCfg")
    local warmupTime = warmupTimeCfg[aid] and (warmupTimeCfg[aid].warmupTime * 3600) or 0
    local st = st + warmupTime
    local et = et - 86400
    local now = os.time()
    local db = getDbo(2000)
    local warmupTime = warmupTimeCfg[tarAid] and (warmupTimeCfg[tarAid].warmupTime * 3600) or 0
    local extraTime = 86400
    local tarKey = getAcCrossKey()[tarAid]
    local ret = db:getRow("select info from bkcross where id=:key",{key=tarKey})
    if ret then
        local pkinfos = json.decode(ret.info)
        for _,pkinfo in ipairs(pkinfos) do
            local tmpst = tonumber(pkinfo.st) + warmupTime
            local tmpet = tonumber(pkinfo.et) - extraTime
            local zidgroups = pkinfo.zids
            if now <= tmpet and tmpet > tmpst then
                if tmpst > et or st > tmpet then
                    --时间完全不包含则合法
                elseif st >= tmpst and tmpet >= et then
                    --时间包含则判断服交叉
                    for _, zinfo in ipairs(zids) do
                        local tmpidx = {}
                        for i, zid in ipairs(zinfo) do
                            tmpidx[i] = 0
                            for idx, zidgroup in ipairs(zidgroups) do
                                if table.contains(zidgroup,zid) then
                                    tmpidx[i] = idx
                                    break
                                end
                            end
                            if tmpidx[i-1] and tmpidx[i-1] ~= tmpidx[i] then
                                return true
                            end
                        end
                    end
                else
                    --时间交叉则判断有服存在
                    for _, zinfo in ipairs(zids) do
                        for _, zid in ipairs(zinfo) do
                            for idx, zidgroup in ipairs(zidgroups) do
                                if table.contains(zidgroup,zid) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end