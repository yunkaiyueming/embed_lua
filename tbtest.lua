local configCfg =
{
        rechargeCfg           = {tw = 1, kr = 1, jp = 1, cn_h5ly = 1, cn_wx = 1, cn_wxapp = 1, cn_wb = 1,vi = 1,cn_hw=1,cn_wdly=1,cn_37wd=1,krnew = 1,},
        vipCfg                  = {tw = 1, kr = 1, jp = 1, cn_wx = 1, cn_wxapp = 1, cn_wb = 1, vi = 1,  krnew = 1,},
        dailyChargeCfg      = {tw = 1, kr = 1, jp = 1, vi = 1},
        totalRechargeCfg    = {tw = 1, kr = 1, jp = 1, vi = 1},
        extraRechargeCfg    = {tw = 1, cn_mm = 1},
        newYearCfg            = {tw = 1, kr = 1, jp = 1, vi = 1}, 
        dailyActivityCfg    = {cn_wx = 1, cn_wxapp = 1, cn_wb = 1, vi = 1, kr = 1},
        searchCfg               = {cn_wx = 1, cn_wxapp = 1, cn_wb = 1,},
        playerReturnCfg     = {cn_wx = 1, cn_wxapp = 1, cn_wb = 1,jp = 1,},
        giftCfg                 = {jp = 1, krnew = 1},
        shopCfg                 = {cn_wx = 1, cn_wxapp = 1, cn_wb = 1,},
        shopNewCfg            = {cn_wx = 1, cn_wxapp = 1,  cn_wb = 1,},
        firstchargeCfg    = {cn_wx = 1, cn_wxapp = 1,  cn_wb = 1,krnew = 1,},
        mainTaskCfg           = {cn_wx = 1, cn_wxapp = 1,  cn_wb = 1,  krnew = 1,},
        customGiftCfg         = {cn_wx = 1, cn_wxapp = 1,  cn_wb = 1,},
        servantSkinCfg      = {cn_wx = 1, cn_wxapp = 1,  cn_wb = 1,},
        challengeCfg          = {kr = 1, krnew = 1,},
        dinnerCfg             = {jp = 1, cn_wx = 1, cn_wxapp = 1,  cn_wb = 1,},
        questionnaireCfg  = {cn_37wd = 1},

        mergeZidCfg       ={test=1, cn_wx=1, vi=1},
        
        achievementCfg      ={krnew = 1,},
        servantBaseCfg      ={krnew = 1,},
        servantCfg              ={krnew = 1,},
        atkRaceCfg              ={krnew = 1,},
        levelCfg                    ={krnew = 1,},
        searchCfg                   ={krnew = 1,},
        secondchargeCfg     ={krnew = 1,},
        wifeCfg                     ={krnew = 1,},
                    
}

print(configCfg.searchCfg)
for k,v in pairs(configCfg.searchCfg) do
    print(k,v)
end