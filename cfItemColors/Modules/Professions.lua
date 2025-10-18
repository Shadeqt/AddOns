-- ============================
-- cfItemColors - Professions Module
-- ============================
-- Handles tradeskill/profession window item borders

local addon = cfItemColors

-- Button cache
local professionButtonCache = {}

-- Initialize profession button cache
local function initializeProfessionButtonCache()
	-- Cache the crafted item button
	addon:CacheButton(professionButtonCache, "craftedItem", "TradeSkillSkillIcon")

	-- Cache reagent buttons
	addon:BuildButtonCache(professionButtonCache, "TradeSkillReagent%d", addon.MAX_PROFESSION_REAGENTS)
end

local function updateProfessionBorders()
	initializeProfessionButtonCache()

	local selectedRecipe = GetTradeSkillSelectionIndex()
	if not selectedRecipe or selectedRecipe == 0 then return end

	local craftedButton = professionButtonCache.craftedItem
	if craftedButton and craftedButton:IsVisible() then
		local itemLink = GetTradeSkillItemLink(selectedRecipe)
		addon:ApplyItemQualityBorderByLink(craftedButton, itemLink)
	end

	local numReagents = GetTradeSkillNumReagents(selectedRecipe)
	for reagentIndex = 1, numReagents do
		local reagentButton = professionButtonCache[reagentIndex]
		if reagentButton and reagentButton:IsVisible() then
			local itemLink = GetTradeSkillReagentItemLink(selectedRecipe, reagentIndex)
			addon:ApplyItemQualityBorderByLink(reagentButton, itemLink)
		end
	end
end

function addon:InitProfessionsModule()
	if TradeSkillFrame then
		TradeSkillFrame:HookScript("OnShow", updateProfessionBorders)
		hooksecurefunc("TradeSkillFrame_SetSelection", updateProfessionBorders)
	end
end
