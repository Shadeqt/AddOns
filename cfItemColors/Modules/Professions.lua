-- ============================
-- cfItemColors - Professions Module
-- ============================
-- Handles tradeskill/profession window item borders

local addon = cfItemColors

-- Button cache
local professionButtonCache = {}

-- Initialize profession button cache
local function initializeProfessionButtonCache()
	if #professionButtonCache == 0 then
		-- Crafted item button
		professionButtonCache.craftedItem = _G["TradeSkillSkillIcon"]

		-- Reagent frames - use the frame, not the texture
		for reagentIndex = 1, addon.MAX_PROFESSION_REAGENTS do
			professionButtonCache[reagentIndex] = _G["TradeSkillReagent"..reagentIndex]
		end
	end
end

-- Update profession window item quality borders
local function updateProfessionBorders()
	if not addon:IsFrameVisible(TradeSkillFrame) then return end

	initializeProfessionButtonCache()

	local selectedRecipe = GetTradeSkillSelectionIndex()
	if not selectedRecipe or selectedRecipe == 0 then return end

	-- Color the crafted item
	local craftedButton = professionButtonCache.craftedItem
	if craftedButton and craftedButton:IsVisible() then
		local itemLink = GetTradeSkillItemLink(selectedRecipe)
		addon:ApplyItemQualityBorderByLink(craftedButton, itemLink)
	end

	-- Color the reagents
	local numReagents = GetTradeSkillNumReagents(selectedRecipe)
	for reagentIndex = 1, numReagents do
		local reagentButton = professionButtonCache[reagentIndex]
		if reagentButton and reagentButton:IsVisible() then
			local itemLink = GetTradeSkillReagentItemLink(selectedRecipe, reagentIndex)
			addon:ApplyItemQualityBorderByLink(reagentButton, itemLink)
		end
	end
end

-- Register profession window hooks
function addon:RegisterProfessionHooks()
	if TradeSkillFrame then
		TradeSkillFrame:HookScript("OnShow", updateProfessionBorders)
		hooksecurefunc("TradeSkillFrame_SetSelection", updateProfessionBorders)
	end
end

function addon:InitProfessionsModule()
	-- Hook profession window if already loaded
	self:RegisterProfessionHooks()
end
