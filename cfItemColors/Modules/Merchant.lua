-- ============================
-- cfItemColors - Merchant Module
-- ============================
-- Handles merchant and buyback item borders

local addon = cfItemColors

-- Button caches
local merchantItemButtonCache = {}
local buybackItemButtonCache = nil

-- Initialize merchant item button cache
local function initializeMerchantItemButtonCache()
	if #merchantItemButtonCache == 0 then
		for slotIndex = 1, addon.MAX_MERCHANT_SLOTS do
			merchantItemButtonCache[slotIndex] = _G["MerchantItem"..slotIndex.."ItemButton"]
		end
		buybackItemButtonCache = _G["MerchantBuyBackItemItemButton"]
	end
end

-- Update merchant item quality borders
local function updateMerchantItemBorders()
	if not addon:IsFrameVisible(MerchantFrame) then return end

	initializeMerchantItemButtonCache()

	local isOnBuybackTab = MerchantFrame.selectedTab == 2

	-- Update main merchant item slots
	for slotIndex = 1, addon.MAX_MERCHANT_SLOTS do
		local merchantButton = merchantItemButtonCache[slotIndex]
		if merchantButton and merchantButton:IsVisible() then
			local itemLink = isOnBuybackTab and GetBuybackItemLink(slotIndex) or GetMerchantItemLink(slotIndex)
			addon:ApplyItemQualityBorderByLink(merchantButton, itemLink)
		end
	end

	-- Update buyback slot (only visible on merchant tab)
	if not isOnBuybackTab and buybackItemButtonCache and buybackItemButtonCache:IsVisible() then
		-- Get most recent buyback item (highest valid index)
		local numBuyback = GetNumBuybackItems()
		local mostRecentBuybackLink = numBuyback > 0 and GetBuybackItemLink(numBuyback) or nil
		addon:ApplyItemQualityBorderByLink(buybackItemButtonCache, mostRecentBuybackLink)
	end
end

function addon:InitMerchantModule()
	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItemBorders)
	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateMerchantItemBorders)
end
