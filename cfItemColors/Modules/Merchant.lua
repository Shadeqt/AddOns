-- ============================
-- cfItemColors - Merchant Module
-- ============================
-- Handles merchant and buyback item borders

local addon = cfItemColors

-- Button caches
local merchantItemButtonCache = {}
local buybackItemButtonCache = nil

local function updateMerchantItemBorders()
	-- Initialize caches
	addon:BuildButtonCache(merchantItemButtonCache, "MerchantItem%dItemButton", addon.MAX_MERCHANT_SLOTS)
	if not buybackItemButtonCache then
		buybackItemButtonCache = _G["MerchantBuyBackItemItemButton"]
	end

	local isOnBuybackTab = MerchantFrame.selectedTab == 2
	local numMerchantItems = GetMerchantNumItems()

	-- Update merchant item borders
	for slotIndex = 1, numMerchantItems do
		local merchantButton = merchantItemButtonCache[slotIndex]
		if merchantButton and merchantButton:IsVisible() then
			local itemLink = isOnBuybackTab and GetBuybackItemLink(slotIndex) or GetMerchantItemLink(slotIndex)
			addon:ApplyItemQualityBorderByLink(merchantButton, itemLink)
		end
	end

	-- Update buyback button border
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
