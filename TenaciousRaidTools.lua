local frame = CreateFrame("FRAME", "TenaciousRaidToolsHiddenFrame")
frame:RegisterEvent("PLAYER_LOGIN")

TRT = {}

SLASH_TENACIOUS1 = "/tenacious"
SLASH_TENACIOUS2 = "/tenaciousraidtools"
SLASH_TENACIOUS3 = "/trt"

local function eventHandler(self, event, ...)
   if event == "PLAYER_LOGIN" then
       print("Hello, World!")
	   TenaciousRaidToolsMainFrame:Show()
	   
	   TRT.m = TenaciousRaidToolsMainFrame;
	   TRT.c = TenaciousRaidToolsMainFramePaddington;
   end
end

frame:SetScript("OnEvent", eventHandler)

function SlashCmdList.TENACIOUS(msg, editbox)
    TenaciousRaidToolsMainFrame:SetShown(true)
end
