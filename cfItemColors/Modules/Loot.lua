-- ============================
-- cfItemColors - Loot Module
-- ============================
-- Handles loot window item borders

local addon = cfItemColors

-- Button cache
local lootItemButtonCache = {}

-- Initialize loot item button cache
local function initializeLootItemButtonCache()
	if #lootItemButtonCache == 0 then
		for slotIndex = 1, LOOTFRAME_NUMBUTTONS do
			lootItemButtonCache[slotIndex] = _G["LootButton"..slotIndex]
		end
	end
end

-- Update loot item quality borders
local function updateLootItemBorders(slotIndex)
	if not addon:IsFrameVisible(LootFrame) then return end

	initializeLootItemButtonCache()

	local lootButton = lootItemButtonCache[slotIndex]
	if lootButton then
		local itemLink = GetLootSlotLink(slotIndex)
		if itemLink then
			addon:ApplyItemQualityBorderByLink(lootButton, itemLink)
		end
	end
end

function addon:InitLootModule()
	hooksecurefunc("LootFrame_UpdateButton", updateLootItemBorders)
end
