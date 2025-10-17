-- ============================
-- CONSTANTS
-- ============================

-- Item quality constants for efficient comparison
local QUEST_ITEM_QUALITY = 99

-- UI frame constants
local MAX_MERCHANT_SLOTS = 12
local MAX_QUEST_REWARD_SLOTS = 6
local MAX_PROFESSION_REAGENTS = 8

-- ============================
-- UTILITY FUNCTIONS
-- ============================

-- Check if frame is valid and visible
local function isFrameVisible(frame)
	return frame and frame:IsVisible()
end

-- ============================
-- COLOR DEFINITIONS
-- ============================

-- Item quality color definitions: {r, g, b}
local itemQualityColors = {
	[0] = {0.62, 0.62, 0.62}, -- Poor (gray)
	[1] = {1.00, 1.00, 1.00}, -- Common (white)
	[2] = {0.12, 1.00, 0.00}, -- Uncommon (green)
	[3] = {0.00, 0.44, 0.87}, -- Rare (blue)
	[4] = {0.64, 0.21, 0.93}, -- Epic (purple)
	[5] = {1.00, 0.50, 0.00}, -- Legendary (orange)
	[6] = {0.90, 0.80, 0.50}, -- Artifact (light orange)
	[7] = {0.00, 0.80, 1.00}, -- Heirloom (light blue)
	[QUEST_ITEM_QUALITY] = {1.00, 1.00, 0.00}, -- Quest items (yellow)
}

-- ============================
-- STATE MANAGEMENT
-- ============================

-- State cache to prevent redundant border updates
local buttonQualityStateCache = {}

-- ============================
-- BORDER CREATION & APPLICATION
-- ============================

-- Get RGB values for item quality color
local function getItemQualityColor(quality)
	local colorData = itemQualityColors[quality]
	if not colorData then
		return 1, 1, 1 -- Default to white
	end
	return colorData[1], colorData[2], colorData[3]
end

-- Create quality border texture for item button
local function createQualityBorder(itemButton)
	if itemButton.cfQualityBorder then
		return itemButton.cfQualityBorder
	end
	
	local qualityBorder = itemButton:CreateTexture(nil, "OVERLAY")
	qualityBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	qualityBorder:SetBlendMode("ADD")
	qualityBorder:SetAlpha(0.7)
	qualityBorder:SetWidth(70)
	qualityBorder:SetHeight(72)
	qualityBorder:SetPoint("CENTER", itemButton)
	
	-- Override positioning for specific button types (uses default 70x72 size)
	local buttonName = itemButton:GetName() or ""
	if string.find(buttonName, "QuestInfoRewardsFrameQuestInfoItem") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	elseif buttonName and string.find(buttonName, "QuestLogItem") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	elseif buttonName and string.find(buttonName, "TradeSkillSkillIcon") then
		qualityBorder:SetPoint("CENTER", itemButton)
	elseif buttonName and string.find(buttonName, "TradeSkillReagent%d+$") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	end
	
	qualityBorder:Hide()
	
	itemButton.cfQualityBorder = qualityBorder
	return qualityBorder
end

-- Apply quality color to item button border based on item quality and type
local function applyItemQualityBorder(itemButton, itemQuality, itemType)
	-- Convert to numeric state key for efficient comparison
	local stateKey = (itemType == "Quest" and QUEST_ITEM_QUALITY) or itemQuality or 0
	
	-- Skip if state hasn't changed
	if buttonQualityStateCache[itemButton] == stateKey then return end
	
	buttonQualityStateCache[itemButton] = stateKey
	local qualityBorder = createQualityBorder(itemButton)

	-- Show border for quest items or uncommon+ quality (>= 2)
	if stateKey == QUEST_ITEM_QUALITY or stateKey >= 2 then
		local r, g, b = getItemQualityColor(stateKey)
		qualityBorder:SetVertexColor(r, g, b)
		qualityBorder:Show()
	else
		qualityBorder:Hide()
	end
end

-- Apply quality border to container item button (bags/bank)
local function applyContainerItemBorder(itemButton, containerId, slotId)
	local itemId = C_Container.GetContainerItemID(containerId, slotId)

	if not itemId then
		-- Only hide border if it exists (avoid creating just to hide)
		if itemButton.cfQualityBorder then
			itemButton.cfQualityBorder:Hide()
			buttonQualityStateCache[itemButton] = 0
		end
		return
	end

	local _, _, itemQuality, _, _, itemType = GetItemInfo(itemId)
	applyItemQualityBorder(itemButton, itemQuality, itemType)
end

-- ============================
-- BUTTON CACHE MANAGEMENT
-- ============================

-- Button caches for performance optimization
local bagItemButtonCache = {}
local bankItemButtonCache = {}
local equipmentSlotButtonCache = {}
local merchantItemButtonCache = {}
local buybackItemButtonCache = nil  -- Initialized in initializeMerchantItemButtonCache
local lootItemButtonCache = {}
local questRewardButtonCache = {}
local questLogButtonCache = {}
local professionButtonCache = {}

-- Initialize bag item button cache for specific container frame
local function initializeBagItemButtonCache(containerFrameName, containerFrameSize)
	if not bagItemButtonCache[containerFrameName] then
		bagItemButtonCache[containerFrameName] = {}
		for slotIndex = 1, containerFrameSize do
			bagItemButtonCache[containerFrameName][slotIndex] = _G[containerFrameName.."Item"..slotIndex]
		end
	end
end

-- Initialize bank item button cache
local function initializeBankItemButtonCache(bankSlotCount)
	if #bankItemButtonCache == 0 then
		for slotId = 1, bankSlotCount do
			bankItemButtonCache[slotId] = _G["BankFrameItem"..slotId]
		end
	end
end

-- Update bag item quality borders for container frame
local function updateBagItemBorders(containerFrame)
	local containerId = containerFrame:GetID()
	local containerFrameName = containerFrame:GetName()
	
	initializeBagItemButtonCache(containerFrameName, containerFrame.size)
	
	for slotIndex = 1, containerFrame.size do
		local itemButton = bagItemButtonCache[containerFrameName][slotIndex]
		if itemButton and itemButton:IsVisible() then
			applyContainerItemBorder(itemButton, containerId, itemButton:GetID())
		end
	end
end

-- ============================
-- UPDATE FUNCTIONS
-- ============================

-- Update bank item quality borders
local function updateBankItemBorders()
	if not isFrameVisible(BankFrame) then return end
	
	local bankSlotCount = C_Container.GetContainerNumSlots(BANK_CONTAINER)
	initializeBankItemButtonCache(bankSlotCount)
	
	for slotId = 1, bankSlotCount do
		local itemButton = bankItemButtonCache[slotId]
		if itemButton and itemButton:IsVisible() then
			applyContainerItemBorder(itemButton, BANK_CONTAINER, slotId)
		end
	end
end

-- Equipment slot names for character and inspect frames
local equipmentSlotNames = {
	"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
	"Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
	"Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo"
}

-- Cached equipment slot Ids (eliminates repeated GetInventorySlotInfo calls)
local equipmentSlotIdCache = {}
local function initializeEquipmentSlotIdCache()
	if next(equipmentSlotIdCache) == nil then
		for _, slotName in ipairs(equipmentSlotNames) do
			equipmentSlotIdCache[slotName] = GetInventorySlotInfo(slotName.."Slot")
		end
	end
end

-- Apply quality border to item button using item link
local function applyItemQualityBorderByLink(itemButton, itemLink)
	if not itemLink then
		-- Only hide border if it exists (avoid creating just to hide)
		if itemButton.cfQualityBorder then
			itemButton.cfQualityBorder:Hide()
			buttonQualityStateCache[itemButton] = 0
		end
		return
	end

	local _, _, itemQuality, _, _, itemType = GetItemInfo(itemLink)
	if not itemQuality then
		-- Only hide border if it exists (avoid creating just to hide)
		if itemButton.cfQualityBorder then
			itemButton.cfQualityBorder:Hide()
			buttonQualityStateCache[itemButton] = 0
		end
		return
	end

	applyItemQualityBorder(itemButton, itemQuality, itemType)
end

-- Initialize equipment slot button cache for frame prefix (Character/Inspect)
local function initializeEquipmentSlotButtonCache(framePrefix)
	if not equipmentSlotButtonCache[framePrefix] then
		equipmentSlotButtonCache[framePrefix] = {}
		for _, slotName in ipairs(equipmentSlotNames) do
			local equipmentButtonName = framePrefix..slotName.."Slot"
			equipmentSlotButtonCache[framePrefix][slotName] = _G[equipmentButtonName]
		end
	end
end

-- Update equipment item quality borders for character or inspect frame
local function updateEquipmentItemBorders(framePrefix, unitId, parentFrame)
	if not isFrameVisible(parentFrame) then return end
	
	initializeEquipmentSlotButtonCache(framePrefix)
	initializeEquipmentSlotIdCache()
	
	for _, slotName in ipairs(equipmentSlotNames) do
		local slotId = equipmentSlotIdCache[slotName]
		local equipmentButton = equipmentSlotButtonCache[framePrefix][slotName]
		if equipmentButton and equipmentButton:IsVisible() and slotId then
			local itemLink = GetInventoryItemLink(unitId, slotId)
			applyItemQualityBorderByLink(equipmentButton, itemLink)
		end
	end
end

-- Update character equipment item quality borders
local function updateCharacterEquipmentBorders()
	updateEquipmentItemBorders("Character", "player", CharacterFrame)
end

-- Clear all inspect equipment borders (called when starting new inspect)
local function clearInspectEquipmentBorders()
	-- Only clear if cache exists (no need to initialize just to clear)
	if not equipmentSlotButtonCache["Inspect"] then return end

	for _, slotName in ipairs(equipmentSlotNames) do
		local equipmentButton = equipmentSlotButtonCache["Inspect"][slotName]
		if equipmentButton and equipmentButton.cfQualityBorder then
			equipmentButton.cfQualityBorder:Hide()
			buttonQualityStateCache[equipmentButton] = nil
		end
	end
end

-- Update inspect equipment item quality borders
local function updateInspectEquipmentBorders(expectedTargetGUID)
	-- Verify target hasn't changed (prevent stale timer updates)
	if expectedTargetGUID and UnitGUID("target") ~= expectedTargetGUID then
		return
	end

	updateEquipmentItemBorders("Inspect", "target", InspectFrame)
end

-- Initialize merchant item button cache
local function initializeMerchantItemButtonCache()
	if #merchantItemButtonCache == 0 then
		for slotIndex = 1, MAX_MERCHANT_SLOTS do
			merchantItemButtonCache[slotIndex] = _G["MerchantItem"..slotIndex.."ItemButton"]
		end
		buybackItemButtonCache = _G["MerchantBuyBackItemItemButton"]
	end
end

-- Update merchant item quality borders
local function updateMerchantItemBorders()
	if not isFrameVisible(MerchantFrame) then return end
	
	initializeMerchantItemButtonCache()
	
	local isOnBuybackTab = MerchantFrame.selectedTab == 2
	
	-- Update main merchant item slots
	for slotIndex = 1, MAX_MERCHANT_SLOTS do
		local merchantButton = merchantItemButtonCache[slotIndex]
		if merchantButton and merchantButton:IsVisible() then
			local itemLink = isOnBuybackTab and GetBuybackItemLink(slotIndex) or GetMerchantItemLink(slotIndex)
			applyItemQualityBorderByLink(merchantButton, itemLink)
		end
	end
	
	-- Update buyback slot (only visible on merchant tab)
	if not isOnBuybackTab and buybackItemButtonCache and buybackItemButtonCache:IsVisible() then
		-- Get most recent buyback item (highest valid index)
		local numBuyback = GetNumBuybackItems()
		local mostRecentBuybackLink = numBuyback > 0 and GetBuybackItemLink(numBuyback) or nil
		applyItemQualityBorderByLink(buybackItemButtonCache, mostRecentBuybackLink)
	end
end

-- Initialize loot item button cache
local function initializeLootItemButtonCache()
	if #lootItemButtonCache == 0 then
		for slotIndex = 1, LOOTFRAME_NUMBUTTONS do -- Usually 4 loot slots
			lootItemButtonCache[slotIndex] = _G["LootButton"..slotIndex]
		end
	end
end

-- Update loot item quality borders
local function updateLootItemBorders()
	if not isFrameVisible(LootFrame) then return end
	
	initializeLootItemButtonCache()
	
	for slotIndex = 1, GetNumLootItems() do
		local lootButton = lootItemButtonCache[slotIndex]
		if lootButton and lootButton:IsVisible() then
			local _, _, _, lootQuality = GetLootSlotInfo(slotIndex)
			-- Use our unified border application function
			applyItemQualityBorder(lootButton, lootQuality, nil)
		end
	end
end

-- Get item quality for quest reward/choice at given index
local function getQuestItemQuality(itemIndex, numChoices, isQuestLog)
	if itemIndex <= numChoices then
		-- This is a choice reward
		if isQuestLog then
			local _, _, _, quality = GetQuestLogChoiceInfo(itemIndex)
			return quality
		else
			local _, _, _, quality = GetQuestItemInfo("choice", itemIndex)
			return quality
		end
	else
		-- This is a fixed reward
		local rewardIndex = itemIndex - numChoices
		if isQuestLog then
			local _, _, _, quality = GetQuestLogRewardInfo(rewardIndex)
			return quality
		else
			local _, _, _, quality = GetQuestItemInfo("reward", rewardIndex)
			return quality
		end
	end
end

-- Initialize quest reward button cache
local function initializeQuestRewardButtonCache()
	if #questRewardButtonCache == 0 then
		-- Quest reward buttons use the pattern QuestInfoRewardsFrameQuestInfoItem1, etc.
		for slotIndex = 1, MAX_QUEST_REWARD_SLOTS do
			questRewardButtonCache[slotIndex] = _G["QuestInfoRewardsFrameQuestInfoItem"..slotIndex]
		end
	end
end

-- Update quest reward item quality borders
local function updateQuestRewardBorders()
	if not isFrameVisible(QuestFrame) then return end

	initializeQuestRewardButtonCache()

	-- Handle both quest choices and fixed rewards
	local numChoices = GetNumQuestChoices()
	local numRewards = GetNumQuestRewards()
	local totalItems = numChoices + numRewards

	for itemIndex = 1, totalItems do
		local rewardButton = questRewardButtonCache[itemIndex]
		if rewardButton and rewardButton:IsVisible() then
			local itemQuality = getQuestItemQuality(itemIndex, numChoices, false)
			applyItemQualityBorder(rewardButton, itemQuality, nil)
		end
	end
end

-- Initialize quest log button cache
local function initializeQuestLogButtonCache()
	if #questLogButtonCache == 0 then
		for slotIndex = 1, MAX_QUEST_REWARD_SLOTS do
			questLogButtonCache[slotIndex] = _G["QuestLogItem"..slotIndex]
		end
	end
end

-- Update quest log item quality borders
local function updateQuestLogBorders()
	if not isFrameVisible(QuestLogFrame) then return end
	
	initializeQuestLogButtonCache()
	
	local selectedQuest = GetQuestLogSelection()
	if not selectedQuest or selectedQuest == 0 then return end
	
	local numChoices = GetNumQuestLogChoices()
	local numRewards = GetNumQuestLogRewards()
	local totalItems = numChoices + numRewards
	
	for itemIndex = 1, totalItems do
		local itemButton = questLogButtonCache[itemIndex]
		if itemButton and itemButton:IsVisible() then
			local itemQuality = getQuestItemQuality(itemIndex, numChoices, true)
			applyItemQualityBorder(itemButton, itemQuality, nil)
		end
	end
end

-- Initialize profession button cache
local function initializeProfessionButtonCache()
	if #professionButtonCache == 0 then
		-- Crafted item button
		professionButtonCache.craftedItem = _G["TradeSkillSkillIcon"]

		-- Reagent frames - use the frame, not the texture
		for reagentIndex = 1, MAX_PROFESSION_REAGENTS do
			professionButtonCache[reagentIndex] = _G["TradeSkillReagent"..reagentIndex]
		end
	end
end

-- Update profession window item quality borders
local function updateProfessionBorders()
	if not isFrameVisible(TradeSkillFrame) then return end
	
	initializeProfessionButtonCache()
	
	local selectedRecipe = GetTradeSkillSelectionIndex()
	if not selectedRecipe or selectedRecipe == 0 then return end
	
	-- Color the crafted item
	local craftedButton = professionButtonCache.craftedItem
	if craftedButton and craftedButton:IsVisible() then
		local itemLink = GetTradeSkillItemLink(selectedRecipe)
		applyItemQualityBorderByLink(craftedButton, itemLink)
	end

	-- Color the reagents
	local numReagents = GetTradeSkillNumReagents(selectedRecipe)
	for reagentIndex = 1, numReagents do
		local reagentButton = professionButtonCache[reagentIndex]
		if reagentButton and reagentButton:IsVisible() then
			local itemLink = GetTradeSkillReagentItemLink(selectedRecipe, reagentIndex)
			applyItemQualityBorderByLink(reagentButton, itemLink)
		end
	end
end

-- TODO: Future frame support
-- - Trade Window (player trade items)
-- - Mail Attachments (incoming/outgoing mail items)
-- - Auction House (auction items and bids)
-- - Guild Bank (guild bank items)

-- ============================
-- HOOK REGISTRATION HELPERS
-- ============================

-- Register inspect frame event handlers and hooks
local function registerInspectHooks(eventFrame)
	eventFrame:RegisterEvent("INSPECT_READY")
	eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", updateInspectEquipmentBorders)
end

-- Register profession window hooks
local function registerProfessionHooks()
	if TradeSkillFrame then
		TradeSkillFrame:HookScript("OnShow", updateProfessionBorders)
		hooksecurefunc("TradeSkillFrame_SetSelection", updateProfessionBorders)
	end
end

-- ============================
-- EVENT HANDLING & HOOKS
-- ============================

-- Initialize addon event handling and UI hooks
local addonEventFrame = CreateFrame("Frame")
addonEventFrame:RegisterEvent("PLAYER_LOGIN")
addonEventFrame:RegisterEvent("ADDON_LOADED")

addonEventFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "PLAYER_LOGIN" then
		-- Hook bag container frame updates
		hooksecurefunc("ContainerFrame_Update", updateBagItemBorders)
		
		-- Hook bank frame item updates
		hooksecurefunc("BankFrameItemButton_Update", updateBankItemBorders)
		
		-- Hook character equipment updates
		hooksecurefunc("PaperDollItemSlotButton_Update", updateCharacterEquipmentBorders)
		
		-- Hook merchant frame updates
		hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItemBorders)
		hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateMerchantItemBorders)
		
		-- Hook loot frame updates
		hooksecurefunc("LootFrame_UpdateButton", updateLootItemBorders)
		
		-- Hook quest frame updates
		hooksecurefunc("QuestInfo_Display", updateQuestRewardBorders)
		hooksecurefunc("QuestFrameItems_Update", updateQuestRewardBorders)
		
		-- Hook quest log updates
		self:RegisterEvent("QUEST_LOG_UPDATE")
		if QuestLogFrame then
			QuestLogFrame:HookScript("OnShow", updateQuestLogBorders)
		end
		
		-- Hook profession window updates
		registerProfessionHooks()

		-- Register inspect events and hook if inspect UI is already loaded
		if IsAddOnLoaded("Blizzard_InspectUI") then
			registerInspectHooks(self)
		end

	elseif event == "ADDON_LOADED" and addonName == "Blizzard_InspectUI" then
		-- Register inspect events and hook when inspect UI loads
		registerInspectHooks(self)

	elseif event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		-- Hook profession window when trade skill UI loads
		registerProfessionHooks()
		
	elseif event == "INSPECT_READY" then
		-- Clear old borders immediately to prevent showing stale colors
		clearInspectEquipmentBorders()

		-- Update inspect frame when inspection is ready (delay for item links to load from server)
		local targetGUID = UnitGUID("target")
		C_Timer.After(0.05, function()
			updateInspectEquipmentBorders(targetGUID)
		end)

	elseif event == "UNIT_INVENTORY_CHANGED" and addonName == "target" then
		-- Update inspect frame when target's inventory changes
		if isFrameVisible(InspectFrame) then
			updateInspectEquipmentBorders()
		end

	elseif event == "QUEST_LOG_UPDATE" then
		-- Update quest log borders when quest log changes
		updateQuestLogBorders()

	end
end)

