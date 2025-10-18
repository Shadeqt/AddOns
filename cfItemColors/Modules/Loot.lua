-- ============================
-- cfItemColors - Loot Module
-- ============================
-- Handles loot window item borders

local addon = cfItemColors

-- Button cache
local lootItemButtonCache = {}

local function updateLootItemBorders(slotIndex)
	addon:BuildButtonCache(lootItemButtonCache, "LootButton%d", LOOTFRAME_NUMBUTTONS)

	local lootButton = lootItemButtonCache[slotIndex]
	if lootButton and lootButton:IsVisible() then
		local itemLink = GetLootSlotLink(slotIndex)
		addon:ApplyItemQualityBorderByLink(lootButton, itemLink)
	end
end

function addon:InitLootModule()
	hooksecurefunc("LootFrame_UpdateButton", updateLootItemBorders)
end
