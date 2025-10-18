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
	addon:BuildButtonCache(merchantItemButtonCache, "MerchantItem%dItemButton", addon.MAX_MERCHANT_SLOTS)
	if not buybackItemButtonCache then
		buybackItemButtonCache = _G["MerchantBuyBackItemItemButton"]
	end
end

local function updateMerchantItemBorders()
	initializeMerchantItemButtonCache()

	local isOnBuybackTab = MerchantFrame.selectedTab == 2
	local numMerchantItems = GetMerchantNumItems()
	for slotIndex = 1, numMerchantItems do
		local merchantButton = merchantItemButtonCache[slotIndex]
		if merchantButton and merchantButton:IsVisible() then
			local itemLink = isOnBuybackTab and GetBuybackItemLink(slotIndex) or GetMerchantItemLink(slotIndex)
			addon:ApplyItemQualityBorderByLink(merchantButton, itemLink)
		end
	end

	if not isOnBuybackTab and buybackItemButtonCache and buybackItemButtonCache:IsVisible() then
		local numBuyback = GetNumBuybackItems()
		local mostRecentBuybackLink = numBuyback > 0 and GetBuybackItemLink(numBuyback) or nil
		addon:ApplyItemQualityBorderByLink(buybackItemButtonCache, mostRecentBuybackLink)
	end
end

function addon:InitMerchantModule()
	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItemBorders)
	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateMerchantItemBorders)
end
