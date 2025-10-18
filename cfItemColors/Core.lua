-- ============================
-- cfItemColors - Core Module
-- ============================
-- Constants, utilities, and shared state

-- Create addon namespace
cfItemColors = cfItemColors or {}
local addon = cfItemColors

-- ============================
-- CONSTANTS
-- ============================

-- Item quality constants
addon.QUEST_ITEM_QUALITY = 99

-- UI frame constants
addon.MAX_MERCHANT_SLOTS = 12
addon.MAX_QUEST_REWARD_SLOTS = 6
addon.MAX_PROFESSION_REAGENTS = 8

-- ============================
-- COLOR DEFINITIONS
-- ============================

-- Item quality color definitions: {r, g, b}
addon.itemQualityColors = {
	[0] = {0.62, 0.62, 0.62}, -- Poor (gray)
	[1] = {1.00, 1.00, 1.00}, -- Common (white)
	[2] = {0.12, 1.00, 0.00}, -- Uncommon (green)
	[3] = {0.00, 0.44, 0.87}, -- Rare (blue)
	[4] = {0.64, 0.21, 0.93}, -- Epic (purple)
	[5] = {1.00, 0.50, 0.00}, -- Legendary (orange)
	[6] = {0.90, 0.80, 0.50}, -- Artifact (light orange)
	[7] = {0.00, 0.80, 1.00}, -- Heirloom (light blue)
	[addon.QUEST_ITEM_QUALITY] = {1.00, 1.00, 0.00}, -- Quest items (yellow)
}

-- ============================
-- STATE MANAGEMENT
-- ============================

-- State cache to prevent redundant border updates
-- Uses weak keys to prevent memory leaks from destroyed buttons
addon.buttonQualityStateCache = {}
setmetatable(addon.buttonQualityStateCache, {__mode = "k"})

-- Pending item info requests (for items not yet cached by client)
-- Maps itemId -> array of {button, containerId, slotId, link}
addon.pendingItemUpdates = {}

-- ============================
-- UTILITY FUNCTIONS
-- ============================

-- Check if frame is valid and visible
function addon:IsFrameVisible(frame)
	return frame and frame:IsVisible()
end

-- Handle GET_ITEM_INFO_RECEIVED event to retry failed GetItemInfo calls
function addon:OnGetItemInfoReceived(itemId)
	local pending = self.pendingItemUpdates[itemId]
	if not pending then return end

	-- Retry all pending updates for this item
	for _, updateInfo in ipairs(pending) do
		if updateInfo.containerId then
			-- Retry container item update
			self:ApplyContainerItemBorder(updateInfo.button, updateInfo.containerId, updateInfo.slotId)
		elseif updateInfo.link then
			-- Retry item link update
			self:ApplyItemQualityBorderByLink(updateInfo.button, updateInfo.link)
		end
	end

	-- Clear pending updates for this item
	self.pendingItemUpdates[itemId] = nil
end

-- Get RGB values for item quality color
function addon:GetItemQualityColor(quality)
	local colorData = self.itemQualityColors[quality]
	if not colorData then
		return 1, 1, 1 -- Default to white
	end
	return colorData[1], colorData[2], colorData[3]
end

-- ============================
-- BORDER CREATION
-- ============================

-- Create quality border texture for item button
function addon:CreateQualityBorder(itemButton)
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
	elseif string.find(buttonName, "QuestProgressItem") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	elseif string.find(buttonName, "QuestLogItem") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	elseif string.find(buttonName, "TradeSkillSkillIcon") then
		qualityBorder:SetPoint("CENTER", itemButton)
	elseif string.find(buttonName, "^TradeSkillReagent%d+$") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	end

	qualityBorder:Hide()

	itemButton.cfQualityBorder = qualityBorder
	return qualityBorder
end

-- ============================
-- BORDER APPLICATION
-- ============================

-- Hide border and clear cache for button (prevents creating border just to hide it)
function addon:HideBorder(itemButton)
	if itemButton.cfQualityBorder then
		itemButton.cfQualityBorder:Hide()
		self.buttonQualityStateCache[itemButton] = 0
	end
end

-- Apply quality color to item button border based on item quality and type
function addon:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
	-- Convert to numeric state key for efficient comparison
	local stateKey = (itemType == "Quest" and self.QUEST_ITEM_QUALITY) or itemQuality or 0

	-- Skip if state hasn't changed
	if self.buttonQualityStateCache[itemButton] == stateKey then return end

	self.buttonQualityStateCache[itemButton] = stateKey
	local qualityBorder = self:CreateQualityBorder(itemButton)

	-- Show border for quest items or uncommon+ quality (>= 2)
	if stateKey == self.QUEST_ITEM_QUALITY or stateKey >= 2 then
		local r, g, b = self:GetItemQualityColor(stateKey)
		qualityBorder:SetVertexColor(r, g, b)
		qualityBorder:Show()
	else
		qualityBorder:Hide()
	end
end

-- Apply quality border to container item button (bags/bank)
function addon:ApplyContainerItemBorder(itemButton, containerId, slotId)
	local itemId = C_Container.GetContainerItemID(containerId, slotId)

	if not itemId then
		self:HideBorder(itemButton)
		return
	end

	local itemName, _, itemQuality, _, _, itemType = GetItemInfo(itemId)

	-- If GetItemInfo returns nil, item isn't cached yet - queue for retry
	-- Check itemName (first return) as it's most reliable indicator
	if not itemName then
		self.pendingItemUpdates[itemId] = self.pendingItemUpdates[itemId] or {}
		table.insert(self.pendingItemUpdates[itemId], {
			button = itemButton,
			containerId = containerId,
			slotId = slotId
		})
		return
	end

	self:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
end

-- Apply quality border to item button using item link
function addon:ApplyItemQualityBorderByLink(itemButton, itemLink)
	if not itemLink then
		self:HideBorder(itemButton)
		return
	end

	local itemName, _, itemQuality, _, _, itemType = GetItemInfo(itemLink)

	-- If GetItemInfo returns nil, item isn't cached yet - queue for retry
	-- Check itemName (first return) as it's most reliable indicator
	if not itemName then
		-- Extract itemId from link for event tracking
		local itemId = tonumber(itemLink:match("item:(%d+)"))
		if itemId then
			self.pendingItemUpdates[itemId] = self.pendingItemUpdates[itemId] or {}
			table.insert(self.pendingItemUpdates[itemId], {
				button = itemButton,
				link = itemLink
			})
		end
		return
	end

	self:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
end
