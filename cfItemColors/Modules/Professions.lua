-- ============================
-- cfItemColors - Professions Module
-- ============================
-- Handles tradeskill/profession window item borders

local addon = cfItemColors

-- Button cache
local professionButtonCache = {}

local function updateProfessionBorders()
	-- Initialize caches
	addon:CacheButton(professionButtonCache, "craftedItem", "TradeSkillSkillIcon")
	addon:BuildButtonCache(professionButtonCache, "TradeSkillReagent%d", addon.MAX_PROFESSION_REAGENTS)

	local selectedRecipe = GetTradeSkillSelectionIndex()
	if not selectedRecipe or selectedRecipe == 0 then return end

	-- Update crafted item border
	local craftedButton = professionButtonCache.craftedItem
	if craftedButton and craftedButton:IsVisible() then
		local itemLink = GetTradeSkillItemLink(selectedRecipe)
		addon:ApplyItemQualityBorderByLink(craftedButton, itemLink)
	end

	-- Update reagent borders
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
