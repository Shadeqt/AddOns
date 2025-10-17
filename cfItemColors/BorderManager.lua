-- ============================
-- cfItemColors - Border Manager
-- ============================
-- Border creation and application functions

local addon = cfItemColors

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
		-- Only hide border if it exists (avoid creating just to hide)
		if itemButton.cfQualityBorder then
			itemButton.cfQualityBorder:Hide()
			self.buttonQualityStateCache[itemButton] = 0
		end
		return
	end

	local _, _, itemQuality, _, _, itemType = GetItemInfo(itemId)
	self:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
end

-- Apply quality border to item button using item link
function addon:ApplyItemQualityBorderByLink(itemButton, itemLink)
	if not itemLink then
		-- Only hide border if it exists (avoid creating just to hide)
		if itemButton.cfQualityBorder then
			itemButton.cfQualityBorder:Hide()
			self.buttonQualityStateCache[itemButton] = 0
		end
		return
	end

	local _, _, itemQuality, _, _, itemType = GetItemInfo(itemLink)
	if not itemQuality then
		-- Only hide border if it exists (avoid creating just to hide)
		if itemButton.cfQualityBorder then
			itemButton.cfQualityBorder:Hide()
			self.buttonQualityStateCache[itemButton] = 0
		end
		return
	end

	self:ApplyItemQualityBorder(itemButton, itemQuality, itemType)
end
