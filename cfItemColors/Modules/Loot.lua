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
local function updateLootItemBorders()
	if not addon:IsFrameVisible(LootFrame) then return end

	initializeLootItemButtonCache()

	for slotIndex = 1, GetNumLootItems() do
		local lootButton = lootItemButtonCache[slotIndex]
		if lootButton and lootButton:IsVisible() then
			local _, _, _, lootQuality = GetLootSlotInfo(slotIndex)
			addon:ApplyItemQualityBorder(lootButton, lootQuality, nil)
		end
	end
end

function addon:InitLootModule()
	hooksecurefunc("LootFrame_UpdateButton", updateLootItemBorders)
end
