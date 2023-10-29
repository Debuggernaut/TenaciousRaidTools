local frame = CreateFrame("FRAME", "TenaciousRaidToolsHiddenFrame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")

_TRTData = {
    cur = {dps = 0};
    boss = {dps = 0};
    overall = {dps = 0};
}

SLASH_TENACIOUS1 = "/tenacious"
SLASH_TENACIOUS2 = "/tenaciousraidtools"
SLASH_TENACIOUS3 = "/trt"

local function parseStats(combat)

    local time = combat:GetCombatTime()

    local curData = {}
    curData.actors = {}

    local total=0;
    local f = combat:GetActorList(DETAILS_ATTRIBUTE_DAMAGE)
    for x=1,#f do
        if not f[x]:IsEnemy() and not f[x]:IsPetOrGuardian() then
            --print(f[x]:name(), " ",f[x].total / 1000.0); 
            if (UnitIsDeadOrGhost(f[x]:name())) then
                --print(f[x]:name()," is dead, omitting their damage")
            else
                curData.actors[#curData.actors+1] = f[x]
                total = total + f[x].total
            end
        end
    end
    curData.total = total
    curData.time = time
    curData.dps = total/time

    return curData
end

local function updateDetailsData()
    print("Updating data..");
    local combat = Details:GetCombat(0);
    local isBoss = combat:GetBossInfo() ~= nil

    _TRTData.cur = parseStats(combat)
    if isBoss then
        _TRTData.boss = _TRTData.cur
    elseif not _TRTData.haveCheckedForBosses then
        _TRTData.haveCheckedForBosses = true

        -- perf issues if you don't ever clear your data
        -- local totalCombats = Details:GetCombatSegments()
        -- if totalCombats > 10 then
        --     totalCombats = 10
        -- end

        for i=1,10 do
            combat = Details:GetCombat(i);
            if combat == nil then
                break
            end
            if combat:GetBossInfo() ~= nil then
                _TRTData.boss = parseStats(combat)
                print("Boss at i=", i)
                break
            end
        end
    end

    local overall = Details:GetCombat(-1)
    _TRTData.overall = parseStats(overall)
    
    local curdeeps = _TRTData.cur.dps
    local odeeps = _TRTData.overall.dps
    local labelStr = string.format("Estimated Group DPS: Current %4.0fk, Overall %4.0fk",
        curdeeps/1000.0, odeeps/1000.0)
    TenaciousRaidToolsMainFramePadText:SetText(labelStr);

    if _TRTData.boss ~= nil then
        local lastboss = _TRTData.boss.dps
        labelStr = string.format("Last Boss %4.0fk", lastboss/1000.0)
        TenaciousRaidToolsMainFramePadText2:SetText(labelStr);
    end
end

local function eventHandler(self, event, ...)
    --if event == "CRAFTINGORDERS_SHOW_CUSTOMER" then
        TenaciousRaidToolsMainFrame:Show()

        --TRT.m = TenaciousRaidToolsMainFrame;
        --TRT.c = TenaciousRaidToolsMainFramePaddington;
    --end
end

frame:SetScript("OnEvent", eventHandler)

function SlashCmdList.TENACIOUS(msg, editbox)
    TenaciousRaidToolsMainFrame:SetShown(true)
end

function TenaciousRaidToolsMainFrame_SendTreatiseOrder()
    local craftsman = TenaciousRaidToolsMainFrameWorkOrderInput:GetText()
    local guildOrder = false

    if (craftsman == '' or craftsman == nil) then
        guildOrder = true
    else
        --Note that this history line thing doesn't work for some reason:
        TenaciousRaidToolsMainFrameWorkOrderInput:AddHistoryLine(craftsman)
    end

    --print("Send order to",craftsman);
    local profs = {};
    profs[164] = 47600;
    profs[165] = 47595;
    profs[171] = 47601;
    profs[182] = 47598;
    profs[186] = 47594;
    profs[197] = 47593;
    profs[202] = 47602;
    profs[333] = 47599;
    profs[393] = 47928;
    profs[755] = 47596;
    --profs[773] = ; inscription

    local ds_Treatise = ds_Treatise + 1;
    if (ds_Treatise > 2) then
        ds_Treatise = 1;
    end

    local p1, p2, _, _ = GetProfessions();

    local skillLine = 0;
    if (ds_Treatise == 1) then
        _, _, _, _, _, _, skillLine, _, _, _ = GetProfessionInfo(p1);
    else
        _, _, _, _, _, _, skillLine, _, _, _ = GetProfessionInfo(p2);
    end

    local orderType = 2
    local target = craftsman
    if guildOrder then
        orderType = 1
        target = ""
    end
    if (profs[skillLine] ~= nil) then
        C_CraftingOrders.PlaceNewOrder({
            skillLineAbilityID = profs[skillLine],
            orderType = orderType,
            orderDuration = 1,     --48hrs
            tipAmount = 200 * 100 * 100, --200g, covers treatise mats as of US servers on Oct. 27th, 2023
            customerNotes = "",
            orderTarget = target,
            reagentItems = { { quantity = 10, itemID = 190456 } },
            --Change this to reagentItems={{}} for no mats
            --including all the mats is more trouble than it's worth, just adjust tipAmount
            craftingReagentItems = {}
        })
    end
end

_TRTData.lastUnit = {}

local function a2t(tt, str1, str2)
    local left = NORMAL_FONT_COLOR_CODE .. str1 .. FONT_COLOR_CODE_CLOSE
    local right = HIGHLIGHT_FONT_COLOR_CODE .. str2 .. FONT_COLOR_CODE_CLOSE
    tt:AddDoubleLine(left, right)
end

local function coolFormat(time)
    local str = ""
    local s = time
    if s > 60 then
        local m = math.floor(s/60.0)
        s = math.floor(s) % 60

        str = string.format("%0.0f ",m)
    end

    str = str .. string.format("%1.1fs", s)

    return str
end

if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not data or not data.type then return end
        if data.type == Enum.TooltipDataType.Unit then
            _TRTData.lastUnit = data
            --UnitTokenFromGUID(_TRTData.lastUnit.guid)
            local hp = UnitHealth("mouseover")
            --/dump UnitHealth(_TRTData.lastUnit.guid)
            a2t(tooltip, "Hitpoints:", string.format("%0.1fk", hp/1000.0))

            a2t(tooltip, "Kill time estimates:","")
            if _TRTData.cur.dps > 0 then
                a2t(tooltip, "Current rate:", coolFormat(hp / _TRTData.cur.dps))
            end
            if _TRTData.overall.dps > 0 then
                a2t(tooltip, "Overall:", coolFormat(hp / _TRTData.overall.dps))
            end
            if _TRTData.boss.dps > 0 then
                a2t(tooltip, "Last Boss:", coolFormat(hp / _TRTData.boss.dps))
            end

        end
    end)
end

function TenaciousRaidToolsMainFrame_ToggleKillTime()
    local haveCheckedForBosses = false
    local cb = TenaciousRaidToolsMainFramePaddington;
    if (cb:GetChecked()) then
        if Details == nil then
            TenaciousRaidToolsMainFramePadText:SetText("Error: Details not detected");
            cb:SetChecked(false)
            return
        end

        --Update now and every 5 seconds
        updateDetailsData()
        _TRTData.timer = C_Timer.NewTimer(5, updateDetailsData);

    else
        TenaciousRaidToolsMainFramePadText:SetText("");
        TenaciousRaidToolsMainFramePadText2:SetText("");
        if _TRTData.timer ~= nil then 
            _TRTData.timer:Cancel()
        end
    end
end

local x = nil

function TenaciousRaidToolsMainFrame_SendQuestOrder()
    if x == nil then x = 0; end;
    x = x + 1;

    --skillIDs -47k sry
    local s = { 751, 447, 123, 590, 280, -33 };
    C_CraftingOrders.PlaceNewOrder(
        {
            skillLineAbilityID = s[x % #s + 1] + 47000,
            orderType = 1,
            orderDuration = 2,
            tipAmount = 100,
            customerNotes = "",
            orderTarget = "GUILD",
            reagentItems = {},
            craftingReagentItems = {}
        });

    --sorry, played some code golf to fit this into a macro.. original macro is here:
    --if x==nil then x=0;end;x=x+1;s={751,447,123,590,280,-33};C_CraftingOrders.PlaceNewOrder({skillLineAbilityID=s[x%#s+1]+47000,orderType=1,orderDuration=2,tipAmount=100,customerNotes="",orderTarget="GUILD",reagentItems={},craftingReagentItems={}})

    --To get the SkillID that the WoW API uses here, you can run this macro with your crafting window open:
    -- /run local x=0; for _, id in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(id);    print(recipeInfo.recipeID, recipeInfo.skillLineAbilityID, recipeInfo.name); x = x+1; if x > 150 then break; end; end
end
