-- ============================
-- cfItemColors - Initialization
-- ============================
-- Event handling and module initialization

local addon = cfItemColors

-- Initialize addon event handling and UI hooks
local addonEventFrame = CreateFrame("Frame")
addonEventFrame:RegisterEvent("PLAYER_LOGIN")
addonEventFrame:RegisterEvent("ADDON_LOADED")
addonEventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

addonEventFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "PLAYER_LOGIN" then
		addon:InitBagsModule()
		addon:InitEquipmentModule(self)
		addon:InitMerchantModule()
		addon:InitLootModule()
		addon:InitQuestsModule(self)

	elseif event == "ADDON_LOADED" and addonName == "Blizzard_InspectUI" then
		addon:RegisterInspectHooks(self)

	elseif event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		addon:InitProfessionsModule()

	elseif event == "INSPECT_READY" then
		addon.clearInspectEquipmentBorders()

		if addon.pendingInspectTimer and addon.pendingInspectTimer.Cancel then
			addon.pendingInspectTimer:Cancel()
		end

		local targetGUID = UnitGUID("target")

		if C_Timer.NewTimer then
			addon.pendingInspectTimer = C_Timer.NewTimer(0.05, function()
				addon.updateInspectEquipmentBorders(targetGUID)
				addon.pendingInspectTimer = nil
			end)
		else
			addon.pendingInspectTimer = nil
			C_Timer.After(0.05, function()
				addon.updateInspectEquipmentBorders(targetGUID)
			end)
		end

	elseif event == "UNIT_INVENTORY_CHANGED" and addonName == "target" then
		if addon:IsFrameVisible(InspectFrame) then
			addon.updateInspectEquipmentBorders()
		end

	elseif event == "QUEST_LOG_UPDATE" then
		addon.updateQuestLogBorders()

	elseif event == "GET_ITEM_INFO_RECEIVED" then
		local itemId = addonName
		addon:OnGetItemInfoReceived(itemId)

	end
end)

