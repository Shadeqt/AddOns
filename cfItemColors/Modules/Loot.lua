-- ============================
-- cfItemColors - Loot Module
-- ============================
-- Handles loot window item borders

local addon = cfItemColors

-- Button cache
local lootItemButtonCache = {}

-- Initialize loot item button cache
local function initializeLootItemButtonCache()
	addon:BuildButtonCache(lootItemButtonCache, "LootButton%d", LOOTFRAME_NUMBUTTONS)
end

local function updateLootItemBorders(slotIndex)
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
