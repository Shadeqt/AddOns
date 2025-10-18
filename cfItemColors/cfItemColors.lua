-- Item quality color definitions
local QUALITY_COLORS = {
	[0] = {0.62, 0.62, 0.62}, -- Poor (gray)
	[1] = {1.00, 1.00, 1.00}, -- Common (white)
	[2] = {0.12, 1.00, 0.00}, -- Uncommon (green)
	[3] = {0.00, 0.44, 0.87}, -- Rare (blue)
	[4] = {0.64, 0.21, 0.93}, -- Epic (purple)
	[5] = {1.00, 0.50, 0.00}, -- Legendary (orange)
	[99] = {1.00, 1.00, 0.00}, -- Quest (yellow)
}

-- Equipment slot names for inspect frame
local EQUIPMENT_SLOTS = {"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
	"Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
	"Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo"}

-- Pre-calculated slot IDs (computed once at load time to avoid repeated API calls)
local EQUIPMENT_SLOT_IDS = {}
for _, slotName in ipairs(EQUIPMENT_SLOTS) do
	EQUIPMENT_SLOT_IDS[slotName] = GetInventorySlotInfo(slotName.."Slot")
end

-- Get existing border texture or create new one
local function getOrCreateBorder(button)
	-- Return existing custom border if already created
	if button.cfQualityBorder then
		return button.cfQualityBorder
	end

	-- Use built-in IconBorder if available (currently active)
	if button.IconBorder then
		return button.IconBorder
	end

	-- Create new border texture for buttons without IconBorder
	local border = button:CreateTexture(nil, "OVERLAY")

	-- Current fallback: WhiteIconFrame texture (native item border look)
	border:SetTexture("Interface\\Common\\WhiteIconFrame")
	border:SetTexCoord(0, 1, 0, 1)
	border:SetBlendMode("BLEND")
	border:SetAlpha(1)

	-- Alternative: Action button border (brighter glow effect)
	-- border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	-- border:SetTexCoord(0.25, 0.75, 0.25, 0.75) -- Crop to fit square slots
	-- border:SetBlendMode("ADD")
	-- border:SetAlpha(0.8)

	-- Position border to match icon texture
	local buttonName = button:GetName() or ""
	local iconTexture = button.icon or _G[buttonName.."IconTexture"]
	if iconTexture then
		border:SetAllPoints(iconTexture)
	else
		border:SetAllPoints(button)
	end

	border:Hide()
	button.cfQualityBorder = border
	return border
end

-- Apply quality color to item button
local function applyQualityColor(button, itemIdOrLink)
	local border = getOrCreateBorder(button)

	-- Hide border if no item
	if not itemIdOrLink then
		border:Hide()
		return
	end

	-- Get item info
	local _, _, quality, _, _, itemType, _, _, _, _, _, classID = GetItemInfo(itemIdOrLink)
	if not quality then
		-- Item data not loaded yet, retry on next update
		return
	end

	-- Determine quality level (quest items use special quality value)
	local isQuest = (itemType == "Quest") or (classID == 12)
	local qualityLevel = isQuest and 99 or quality

	-- Show colored border for uncommon+ items
	if qualityLevel >= 2 then
		local color = QUALITY_COLORS[qualityLevel]
		border:SetVertexColor(color[1], color[2], color[3])
		border:Show()
	else
		border:Hide()
	end
end

-- Bags
hooksecurefunc("ContainerFrame_Update", function(frame)
	local bagId = frame:GetID()
	local frameName = frame:GetName()
	for i = 1, frame.size do
		local button = _G[frameName.."Item"..i]
		if button then
			local itemId = C_Container.GetContainerItemID(bagId, button:GetID())
			applyQualityColor(button, itemId)
		end
	end
end)

-- Bank
hooksecurefunc("BankFrameItemButton_Update", function()
	for i = 1, C_Container.GetContainerNumSlots(BANK_CONTAINER) do
		local button = _G["BankFrameItem"..i]
		if button then
			local itemId = C_Container.GetContainerItemID(BANK_CONTAINER, i)
			applyQualityColor(button, itemId)
		end
	end
end)

-- Character equipment
hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
	if not button then return end
	local slotId = button:GetID()
	local itemLink = GetInventoryItemLink("player", slotId)
	applyQualityColor(button, itemLink)
end)

-- Inspect
local function updateInspectEquipment()
	if not InspectFrame or not InspectFrame:IsVisible() then return end

	for _, slotName in ipairs(EQUIPMENT_SLOTS) do
		local slotId = EQUIPMENT_SLOT_IDS[slotName]
		local button = _G["Inspect"..slotName.."Slot"]
		if button and slotId then
			local itemLink = GetInventoryItemLink("target", slotId)
			applyQualityColor(button, itemLink)
		end
	end
end

local inspectEventFrame = CreateFrame("Frame")

local function setupInspectHooks()
	inspectEventFrame:RegisterEvent("INSPECT_READY")
	inspectEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", updateInspectEquipment)
	inspectEventFrame:SetScript("OnEvent", function(self, event, unit)
		if event == "INSPECT_READY" then
			C_Timer.After(0.1, updateInspectEquipment) -- Delay for server data
		elseif event == "UNIT_INVENTORY_CHANGED" and unit == "target" then
			if InspectFrame and InspectFrame:IsVisible() then
				updateInspectEquipment()
			end
		end
	end)
end

-- Wait for Blizzard_InspectUI to load
if IsAddOnLoaded("Blizzard_InspectUI") then
	setupInspectHooks()
else
	inspectEventFrame:RegisterEvent("ADDON_LOADED")
	inspectEventFrame:SetScript("OnEvent", function(self, event, addon)
		if addon == "Blizzard_InspectUI" then
			setupInspectHooks()
			self:UnregisterEvent("ADDON_LOADED")
		end
	end)
end

-- Merchant and buyback
local function updateMerchantItems()
	local onMerchantTab = MerchantFrame.selectedTab == 1
	local currentPage = MerchantFrame.page or 1
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE
	local totalItems = GetMerchantNumItems()
	local visibleSlots = onMerchantTab and MERCHANT_ITEMS_PER_PAGE or 12 -- Buyback shows 12 slots

	-- Update main merchant/buyback slots
	for slotIndex = 1, visibleSlots do
		local button = _G["MerchantItem"..slotIndex.."ItemButton"]
		local itemIndex = pageOffset + slotIndex
		local itemLink

		if onMerchantTab then
			if itemIndex <= totalItems then
				itemLink = GetMerchantItemLink(itemIndex)
			end
		else
			itemLink = GetBuybackItemLink(slotIndex)
		end

		if button then
			applyQualityColor(button, itemLink)
		end
	end

	-- Update buyback preview button (only on merchant tab)
	if onMerchantTab then
		local buybackButton = _G["MerchantBuyBackItemItemButton"]
		if buybackButton then
			local numBuyback = GetNumBuybackItems()
			local buybackLink = numBuyback > 0 and GetBuybackItemLink(numBuyback) or nil
			applyQualityColor(buybackButton, buybackLink)
		end
	end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateMerchantItems)

-- Loot
hooksecurefunc("LootFrame_UpdateButton", function(index)
	local button = _G["LootButton"..index]
	if button then
		local itemLink = GetLootSlotLink(index)
		applyQualityColor(button, itemLink)
	end
end)

-- Quest rewards (NPC and quest log)
local function updateQuestRewards(buttonNamePrefix, useQuestLogAPI)
	local numChoices, numRewards

	if useQuestLogAPI then
		numChoices = GetNumQuestLogChoices()
		numRewards = GetNumQuestLogRewards()
	else
		numChoices = GetNumQuestChoices()
		numRewards = GetNumQuestRewards()
	end

	for itemIndex = 1, numChoices + numRewards do
		local button = _G[buttonNamePrefix..itemIndex]
		if button then
			local itemLink
			if itemIndex <= numChoices then
				if useQuestLogAPI then
					itemLink = GetQuestLogItemLink("choice", itemIndex)
				else
					itemLink = GetQuestItemLink("choice", itemIndex)
				end
			else
				local rewardIndex = itemIndex - numChoices
				if useQuestLogAPI then
					itemLink = GetQuestLogItemLink("reward", rewardIndex)
				else
					itemLink = GetQuestItemLink("reward", rewardIndex)
				end
			end
			applyQualityColor(button, itemLink)
		end
	end
end

local function updateQuestInfoRewards()
	local isQuestLog = QuestLogFrame and QuestLogFrame:IsVisible()
	updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem", isQuestLog)
end

hooksecurefunc("QuestInfo_Display", updateQuestInfoRewards)

-- Quest required items
local function updateQuestRequiredItems()
	local numItems = GetNumQuestItems()
	for i = 1, numItems do
		local button = _G["QuestProgressItem"..i]
		if button then
			local itemLink = GetQuestItemLink("required", i)
			applyQualityColor(button, itemLink)
		end
	end
end

hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)

-- Quest log
local function updateQuestLogRewards()
	if not QuestLogFrame then return end

	local selectedQuest = GetQuestLogSelection()
	if not selectedQuest or selectedQuest == 0 then return end

	updateQuestRewards("QuestLogItem", true)
end

-- Update when quest log opens
if QuestLogFrame then
	QuestLogFrame:HookScript("OnShow", updateQuestLogRewards)
end

-- Update when clicking different quests in quest log
hooksecurefunc("QuestLog_Update", updateQuestLogRewards)

-- Professions (trade skills)
local function updateTradeSkillItems()
	if not TradeSkillFrame or not TradeSkillFrame:IsVisible() then return end

	local recipeIndex = GetTradeSkillSelectionIndex()
	if not recipeIndex or recipeIndex <= 0 then return end

	-- Update reagent buttons (materials required)
	for i = 1, 8 do
		local button = _G["TradeSkillReagent"..i]
		if button then
			local itemLink = GetTradeSkillReagentItemLink(recipeIndex, i)
			applyQualityColor(button, itemLink)
		end
	end

	-- Update result icon (item being crafted)
	local resultButton = TradeSkillSkillIcon
	if resultButton then
		local itemLink = GetTradeSkillItemLink(recipeIndex)
		applyQualityColor(resultButton, itemLink)
	end
end

local professionEventFrame = CreateFrame("Frame")

local function setupProfessionHooks()
	hooksecurefunc("TradeSkillFrame_SetSelection", updateTradeSkillItems)
	hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillItems)
end

-- Wait for Blizzard_TradeSkillUI to load
if IsAddOnLoaded("Blizzard_TradeSkillUI") then
	setupProfessionHooks()
else
	professionEventFrame:RegisterEvent("ADDON_LOADED")
	professionEventFrame:SetScript("OnEvent", function(self, event, addon)
		if addon == "Blizzard_TradeSkillUI" then
			setupProfessionHooks()
			self:UnregisterEvent("ADDON_LOADED")
		end
	end)
end

-- Missing frames (not yet implemented):
-- MailFrame (inbox and send mail attachments)
-- TradeFrame (player-to-player trading window)
-- AuctionFrame (auction house - requires Blizzard_AuctionUI)
-- CraftFrame (enchanting and some other professions)
