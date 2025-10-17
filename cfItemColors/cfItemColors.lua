-- Item quality constants for efficient comparison
local QUEST_ITEM_QUALITY = 99

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

-- State cache to prevent redundant border updates
local buttonQualityStateCache = {}

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
	qualityBorder:SetWidth(68)
	qualityBorder:SetHeight(68)
	qualityBorder:SetPoint("CENTER", itemButton)
	
	-- Override positioning for quest reward buttons
	local buttonName = itemButton:GetName() or ""
	if string.find(buttonName, "QuestInfoRewardsFrameQuestInfoItem") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -16, 2)
		qualityBorder:SetWidth(72)
		qualityBorder:SetHeight(72)
	elseif buttonName and string.find(buttonName, "QuestLogItem") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -16, 2)
		qualityBorder:SetWidth(72)
		qualityBorder:SetHeight(72)
	elseif buttonName and string.find(buttonName, "TradeSkillSkillIcon") then
		qualityBorder:SetPoint("CENTER", itemButton, "CENTER", 1, 1)
		qualityBorder:SetWidth(74)
		qualityBorder:SetHeight(74)
	elseif buttonName and string.find(buttonName, "TradeSkillReagent%d+$") then
		-- Position border over the icon area of the reagent frame
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -16, 1)
		qualityBorder:SetWidth(72)
		qualityBorder:SetHeight(72)
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
	
	if stateKey == QUEST_ITEM_QUALITY then
		local r, g, b = getItemQualityColor(QUEST_ITEM_QUALITY)
		qualityBorder:SetVertexColor(r, g, b)
		qualityBorder:Show()
	elseif stateKey >= 2 then
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
		createQualityBorder(itemButton):Hide()
		return
	end
	
	local _, _, itemQuality, _, _, itemType = GetItemInfo(itemId)
	applyItemQualityBorder(itemButton, itemQuality, itemType)
end

-- Button caches for performance optimization
local bagItemButtonCache = {}
local bankItemButtonCache = {}
local equipmentSlotButtonCache = {}
local merchantItemButtonCache = {}
local buybackItemButtonCache
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

-- Update bank item quality borders
local function updateBankItemBorders()
	if not BankFrame then return end
	if not BankFrame:IsVisible() then return end
	
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
		createQualityBorder(itemButton):Hide()
		return
	end
	
	local _, _, itemQuality, _, _, itemType = GetItemInfo(itemLink)
	if not itemQuality then
		createQualityBorder(itemButton):Hide()
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
	if not parentFrame then return end
	if not parentFrame:IsVisible() then return end
	
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

-- Update inspect equipment item quality borders
local function updateInspectEquipmentBorders()
	updateEquipmentItemBorders("Inspect", "target", InspectFrame)
end

-- Initialize merchant item button cache
local function initializeMerchantItemButtonCache()
	if #merchantItemButtonCache == 0 then
		for slotIndex = 1, 12 do
			merchantItemButtonCache[slotIndex] = _G["MerchantItem"..slotIndex.."ItemButton"]
		end
		buybackItemButtonCache = _G["MerchantBuyBackItemItemButton"]
	end
end

-- Update merchant item quality borders
local function updateMerchantItemBorders()
	if not MerchantFrame then return end
	if not MerchantFrame:IsVisible() then return end
	
	initializeMerchantItemButtonCache()
	
	local isOnBuybackTab = MerchantFrame.selectedTab == 2
	
	-- Update main merchant item slots (1-12)
	for slotIndex = 1, 12 do
		local merchantButton = merchantItemButtonCache[slotIndex]
		if merchantButton and merchantButton:IsVisible() then
			local itemLink = isOnBuybackTab and GetBuybackItemLink(slotIndex) or GetMerchantItemLink(slotIndex)
			applyItemQualityBorderByLink(merchantButton, itemLink)
		end
	end
	
	-- Update buyback slot (only visible on merchant tab)
	if not isOnBuybackTab and buybackItemButtonCache and buybackItemButtonCache:IsVisible() then
		-- Find most recent buyback item efficiently
		local mostRecentBuybackLink
		for slotIndex = 12, 1, -1 do  -- Search backwards for efficiency
			local buybackLink = GetBuybackItemLink(slotIndex)
			if buybackLink then
				mostRecentBuybackLink = buybackLink
				break
			end
		end
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
	if not LootFrame then return end
	if not LootFrame:IsVisible() then return end
	
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

-- Initialize quest reward button cache
local function initializeQuestRewardButtonCache()
	if #questRewardButtonCache == 0 then
		-- Quest reward buttons use the pattern QuestInfoRewardsFrameQuestInfoItem1, etc.
		for slotIndex = 1, 6 do
			questRewardButtonCache[slotIndex] = _G["QuestInfoRewardsFrameQuestInfoItem"..slotIndex]
		end
	end
end

-- Update quest reward item quality borders
local function updateQuestRewardBorders()
	if not QuestFrame then return end
	if not QuestFrame:IsVisible() then return end

	initializeQuestRewardButtonCache()

	-- Handle both quest choices and fixed rewards
	local numChoices = GetNumQuestChoices()
	local numRewards = GetNumQuestRewards()
	local totalItems = numChoices + numRewards

	for itemIndex = 1, totalItems do
		local rewardButton = questRewardButtonCache[itemIndex]
		if rewardButton and rewardButton:IsVisible() then
			local itemQuality
			if itemIndex <= numChoices then
				-- This is a choice reward
				_, _, _, itemQuality = GetQuestItemInfo("choice", itemIndex)
			else
				-- This is a fixed reward
				local rewardIndex = itemIndex - numChoices
				_, _, _, itemQuality = GetQuestItemInfo("reward", rewardIndex)
			end

			-- Apply border using our unified function
			applyItemQualityBorder(rewardButton, itemQuality, nil)
		end
	end
end

-- Initialize quest log button cache
local function initializeQuestLogButtonCache()
	if #questLogButtonCache == 0 then
		for slotIndex = 1, 6 do
			questLogButtonCache[slotIndex] = _G["QuestLogItem"..slotIndex]
		end
	end
end

-- Update quest log item quality borders
local function updateQuestLogBorders()
	if not QuestLogFrame or not QuestLogFrame:IsVisible() then return end
	
	initializeQuestLogButtonCache()
	
	local selectedQuest = GetQuestLogSelection()
	if not selectedQuest or selectedQuest == 0 then return end
	
	local numChoices = GetNumQuestLogChoices()
	local numRewards = GetNumQuestLogRewards()
	local totalItems = numChoices + numRewards
	
	for itemIndex = 1, totalItems do
		local itemButton = questLogButtonCache[itemIndex]
		if itemButton and itemButton:IsVisible() then
			local itemQuality
			if itemIndex <= numChoices then
				_, _, _, itemQuality = GetQuestLogChoiceInfo(itemIndex)
			else
				_, _, _, itemQuality = GetQuestLogRewardInfo(itemIndex - numChoices)
			end
			
			applyItemQualityBorder(itemButton, itemQuality, nil)
		end
	end
end

-- Initialize profession button cache
local function initializeProfessionButtonCache()
	if #professionButtonCache == 0 then
		-- Crafted item button
		professionButtonCache.craftedItem = _G["TradeSkillSkillIcon"]
		
		-- Reagent frames (up to 8 reagents) - use the frame, not the texture
		for reagentIndex = 1, 8 do
			professionButtonCache[reagentIndex] = _G["TradeSkillReagent"..reagentIndex]
		end
	end
end

-- Update profession window item quality borders
local function updateProfessionBorders()
	if not TradeSkillFrame or not TradeSkillFrame:IsVisible() then return end
	
	initializeProfessionButtonCache()
	
	local selectedRecipe = GetTradeSkillSelectionIndex()
	if not selectedRecipe or selectedRecipe == 0 then return end
	
	-- Color the crafted item
	local craftedButton = professionButtonCache.craftedItem
	if craftedButton and craftedButton:IsVisible() then
		local itemLink = GetTradeSkillItemLink(selectedRecipe)
		if itemLink then
			local _, _, itemQuality = GetItemInfo(itemLink)
			if itemQuality then
				applyItemQualityBorder(craftedButton, itemQuality, nil)
			end
		end
	end
	
	-- Color the reagents
	local numReagents = GetTradeSkillNumReagents(selectedRecipe)
	for reagentIndex = 1, numReagents do
		local reagentButton = professionButtonCache[reagentIndex]
		if reagentButton and reagentButton:IsVisible() then
			local itemLink = GetTradeSkillReagentItemLink(selectedRecipe, reagentIndex)
			if itemLink then
				local _, _, itemQuality = GetItemInfo(itemLink)
				if itemQuality then
					applyItemQualityBorder(reagentButton, itemQuality, nil)
				end
			end
		end
	end
end

-- TODO: Future frame support
-- - Trade Window (player trade items)
-- - Mail Attachments (incoming/outgoing mail items)  
-- - Auction House (auction items and bids)
-- - Guild Bank (guild bank items)

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
		if TradeSkillFrame then
			TradeSkillFrame:HookScript("OnShow", updateProfessionBorders)
			hooksecurefunc("TradeSkillFrame_SetSelection", updateProfessionBorders)
		end
		
		-- Register inspect events if inspect UI is already loaded
		if IsAddOnLoaded("Blizzard_InspectUI") then
			self:RegisterEvent("INSPECT_READY")
			self:RegisterEvent("UNIT_INVENTORY_CHANGED")
		end
		
	elseif event == "ADDON_LOADED" and addonName == "Blizzard_InspectUI" then
		-- Register inspect events when inspect UI loads
		self:RegisterEvent("INSPECT_READY")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
		
	elseif event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		-- Hook profession window when trade skill UI loads
		if TradeSkillFrame then
			TradeSkillFrame:HookScript("OnShow", updateProfessionBorders)
			hooksecurefunc("TradeSkillFrame_SetSelection", updateProfessionBorders)
		end
		
	elseif event == "INSPECT_READY" then
		-- Update inspect frame when inspection is ready (small delay for item links to load)
		C_Timer.After(0.01, updateInspectEquipmentBorders)
		
	elseif event == "UNIT_INVENTORY_CHANGED" and addonName == "target" then
		-- Update inspect frame when target's inventory changes
		if InspectFrame and InspectFrame:IsShown() then
			updateInspectEquipmentBorders()
		end
		
	elseif event == "QUEST_LOG_UPDATE" then
		-- Update quest log borders when quest log changes
		updateQuestLogBorders()
		
	end
end)

