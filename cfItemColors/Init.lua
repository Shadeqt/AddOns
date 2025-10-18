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
		-- Initialize all modules
		addon:InitBagsModule()
		addon:InitEquipmentModule(self)
		addon:InitMerchantModule()
		addon:InitLootModule()
		addon:InitQuestsModule(self)

	elseif event == "ADDON_LOADED" and addonName == "Blizzard_InspectUI" then
		-- Register inspect events and hook when inspect UI loads
		addon:RegisterInspectHooks(self)

	elseif event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		-- Hook profession window when trade skill UI loads
		addon:InitProfessionsModule()

	elseif event == "INSPECT_READY" then
		-- Clear old borders immediately to prevent showing stale colors
		addon.clearInspectEquipmentBorders()

		-- Update inspect frame when inspection is ready (delay for item links to load from server)
		local targetGUID = UnitGUID("target")
		C_Timer.After(0.05, function()
			addon.updateInspectEquipmentBorders(targetGUID)
		end)

	elseif event == "UNIT_INVENTORY_CHANGED" and addonName == "target" then
		-- Update inspect frame when target's inventory changes
		if addon:IsFrameVisible(InspectFrame) then
			addon.updateInspectEquipmentBorders()
		end

	elseif event == "QUEST_LOG_UPDATE" then
		-- Update quest log borders when quest log changes
		addon.updateQuestLogBorders()

	elseif event == "GET_ITEM_INFO_RECEIVED" then
		-- Retry pending border updates when item info loads from server
		local itemId = addonName  -- Second parameter is itemId for this event
		addon:OnGetItemInfoReceived(itemId)

	end
end)
