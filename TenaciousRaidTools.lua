local frame = CreateFrame("FRAME", "TenaciousRaidToolsHiddenFrame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")

TRT = {}

SLASH_TENACIOUS1 = "/tenacious"
SLASH_TENACIOUS2 = "/tenaciousraidtools"
SLASH_TENACIOUS3 = "/trt"

local function eventHandler(self, event, ...)
   if event == "PLAYER_LOGIN" or event == "CRAFTINGORDERS_SHOW_CUSTOMER" then
	   TenaciousRaidToolsMainFrame:Show()
	   
	   TRT.m = TenaciousRaidToolsMainFrame;
	   TRT.c = TenaciousRaidToolsMainFramePaddington;
   end
end

frame:SetScript("OnEvent", eventHandler)

function SlashCmdList.TENACIOUS(msg, editbox)
    TenaciousRaidToolsMainFrame:SetShown(true)
end

function TenaciousRaidToolsMainFrame_SendTreatiseOrder()
	local craftsman = TenaciousRaidToolsMainFrameWorkOrderInput:GetText()
	print("Send order to",craftsman);
	TenaciousRaidToolsMainFrameWorkOrderInput:AddHistoryLine(craftsman)
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

    ds_Treatise = ds_Treatise+1;
    if (ds_Treatise > 2) then
        ds_Treatise = 1;
    end

    p1,p2,_,_ = GetProfessions();

    skillLine = 0;
    if (ds_Treatise == 1) then
        _,_,_,_,_,_, skillLine, _,_,_ = GetProfessionInfo(p1);
    else
        _,_,_,_,_,_, skillLine, _,_,_ = GetProfessionInfo(p2);
    end

    if (profs[skillLine] ~= nil) then
        C_CraftingOrders.PlaceNewOrder({
            skillLineAbilityID= profs[skillLine] 
            ,orderType=2,
            orderDuration=1, --48hrs
            tipAmount=200*100*100, --200g, covers treatise mats as of US servers on Oct. 27th, 2023
            customerNotes="",
            orderTarget=craftsman,
            reagentItems={{quantity=10,itemID=190456}},
			--Change this to reagentItems={{}} for no mats
			--including all the mats is more trouble than it's worth, just adjust tipAmount
            craftingReagentItems={}})
    end
end

function TenaciousRaidToolsMainFrame_ToggleKillTime()

	print("Todo");
end

function TenaciousRaidToolsMainFrame_SendQuestOrder()
  --sorry, played some code golf to fit this into a macro..
  if x==nil then x=0;end;x=x+1;s={751,447,123,590,280,-33};C_CraftingOrders.PlaceNewOrder({skillLineAbilityID=s[x%#s+1]+47000,orderType=1,orderDuration=2,tipAmount=100,customerNotes="",orderTarget="GUILD",reagentItems={},craftingReagentItems={}})

  --To get the SkillID that the WoW API uses here, you can run this macro with your crafting window open:
  -- /run local x=0; for _, id in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(id);    print(recipeInfo.recipeID, recipeInfo.skillLineAbilityID, recipeInfo.name); x = x+1; if x > 150 then break; end; end

end

-- CRAFTINGORDERS_SHOW_CUSTOMER