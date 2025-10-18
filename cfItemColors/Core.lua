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
-- Maps itemId -> array of {button, itemId}
addon.pendingItemUpdates = {}

-- Pending inspect timer (cancelable to prevent timer stacking)
addon.pendingInspectTimer = nil

-- ============================
-- UTILITY FUNCTIONS
-- ============================

-- Check if frame is valid and visible
function addon:IsFrameVisible(frame)
	return frame and frame:IsVisible()
end

-- Build cache of buttons from pattern (e.g., "LootButton%d")
function addon:BuildButtonCache(cache, pattern, count)
	if #cache == 0 then
		for i = 1, count do
			cache[i] = _G[pattern:format(i)]
		end
	end
	return cache
end

-- Cache a single button by name
function addon:CacheButton(cache, key, frameName)
	if not cache[key] then
		cache[key] = _G[frameName]
	end
end

-- Retry pending border updates when item info becomes available
function addon:OnGetItemInfoReceived(itemId)
	local pending = self.pendingItemUpdates[itemId]
	if not pending then return end

	local itemName, _, itemQuality, _, _, itemType = GetItemInfo(itemId)

	if itemName then
		for _, updateInfo in ipairs(pending) do
			-- Clear cached state before applying to force update
			self.buttonQualityStateCache[updateInfo.button] = nil
			self:ApplyItemQualityBorder(updateInfo.button, itemQuality, itemType)
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
-- UNIFIED UPDATE PATTERNS
-- ============================

-- Update borders for array of buttons using item link getter function
-- itemLinkGetter signature: function(index, button) -> itemLink
function addon:UpdateButtonBordersWithItemLinks(buttonCache, maxCount, itemLinkGetter)
	for index = 1, maxCount do
		local button = buttonCache[index]
		if button and button:IsVisible() then
			local itemLink = itemLinkGetter(index, button)
			self:ApplyItemQualityBorderByLink(button, itemLink)
		end
	end
end

-- Build cache and update borders in one call (for simple cases)
-- pattern: button name pattern like "LootButton%d"
-- count: number of buttons to cache
-- itemLinkGetter: function(index, button) -> itemLink
function addon:InitCacheAndUpdateBorders(buttonCache, pattern, count, itemLinkGetter)
	self:BuildButtonCache(buttonCache, pattern, count)
	self:UpdateButtonBordersWithItemLinks(buttonCache, count, itemLinkGetter)
end

-- ============================
-- BORDER CREATION
-- ============================

-- Create border texture for item button
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

	-- Quest and reagent buttons need left-offset positioning
	local buttonName = itemButton:GetName() or ""
	if string.find(buttonName, "Quest") or string.find(buttonName, "^TradeSkillReagent%d+$") then
		qualityBorder:SetPoint("LEFT", itemButton, "LEFT", -15, 2)
	end

	qualityBorder:Hide()

	itemButton.cfQualityBorder = qualityBorder
	return qualityBorder
end

-- ============================
-- BORDER APPLICATION
-- ============================

-- Hide border and clear cache
function addon:HideBorder(itemButton)
	if itemButton.cfQualityBorder then
		itemButton.cfQualityBorder:Hide()
		self.buttonQualityStateCache[itemButton] = nil
	end
end

-- Clear cache state for array of buttons (forces refresh on next update)
function addon:ClearButtonCacheState(buttonCache, count)
	for index = 1, count do
		local button = buttonCache[index]
		if button then
			self.buttonQualityStateCache[button] = nil
		end
	end
end

-- Apply quality border to item button
function addon:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
	local stateKey = (itemType == "Quest" and self.QUEST_ITEM_QUALITY) or itemQuality or 0

	if self.buttonQualityStateCache[itemButton] == stateKey then return end

	self.buttonQualityStateCache[itemButton] = stateKey
	local qualityBorder = self:CreateQualityBorder(itemButton)

	if stateKey == self.QUEST_ITEM_QUALITY or stateKey >= 2 then
		local r, g, b = self:GetItemQualityColor(stateKey)
		qualityBorder:SetVertexColor(r, g, b)
		qualityBorder:Show()
	else
		qualityBorder:Hide()
	end
end

-- Apply border to container item (bags/bank)
function addon:ApplyContainerItemBorder(itemButton, containerId, slotId)
	local itemId = C_Container.GetContainerItemID(containerId, slotId)

	if not itemId then
		self:HideBorder(itemButton)
		return
	end

	local itemName, _, itemQuality, _, _, itemType = GetItemInfo(itemId)

	if not itemName then
		self.pendingItemUpdates[itemId] = self.pendingItemUpdates[itemId] or {}
		table.insert(self.pendingItemUpdates[itemId], {
			button = itemButton,
			itemId = itemId
		})
		return
	end

	self:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
end

-- Apply border using item link
function addon:ApplyItemQualityBorderByLink(itemButton, itemLink)
	if not itemLink then
		self:HideBorder(itemButton)
		return
	end

	local itemName, _, itemQuality, _, _, itemType = GetItemInfo(itemLink)

	if not itemName then
		local itemId = tonumber(itemLink:match("item:(%d+)"))
		if itemId then
			self.pendingItemUpdates[itemId] = self.pendingItemUpdates[itemId] or {}
			table.insert(self.pendingItemUpdates[itemId], {
				button = itemButton,
				itemId = itemId
			})
		end
		return
	end

	self:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
end
