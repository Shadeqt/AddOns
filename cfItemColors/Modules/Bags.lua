-- ============================
-- cfItemColors - Bags Module
-- ============================
-- Handles bag and bank item borders

local addon = cfItemColors

-- Button caches
local bagItemButtonCache = {}
local bankItemButtonCache = {}

-- ============================
-- UPDATE FUNCTIONS
-- ============================

local function updateBagItemBorders(containerFrame)
	local containerId = containerFrame:GetID()
	local containerFrameName = containerFrame:GetName()

	-- Initialize bag button cache for this container
	if not bagItemButtonCache[containerFrameName] then
		bagItemButtonCache[containerFrameName] = {}
		for slotIndex = 1, containerFrame.size do
			bagItemButtonCache[containerFrameName][slotIndex] = _G[containerFrameName.."Item"..slotIndex]
		end
	end

	for slotIndex = 1, containerFrame.size do
		local itemButton = bagItemButtonCache[containerFrameName][slotIndex]
		if itemButton and itemButton:IsVisible() then
			addon:ApplyContainerItemBorder(itemButton, containerId, itemButton:GetID())
		end
	end
end

local function updateBankItemBorders()
	local bankSlotCount = C_Container.GetContainerNumSlots(BANK_CONTAINER)
	addon:BuildButtonCache(bankItemButtonCache, "BankFrameItem%d", bankSlotCount)

	for slotId = 1, bankSlotCount do
		local itemButton = bankItemButtonCache[slotId]
		if itemButton and itemButton:IsVisible() then
			addon:ApplyContainerItemBorder(itemButton, BANK_CONTAINER, slotId)
		end
	end
end

-- ============================
-- MODULE INITIALIZATION
-- ============================

function addon:InitBagsModule()
	hooksecurefunc("ContainerFrame_Update", updateBagItemBorders)
	hooksecurefunc("BankFrameItemButton_Update", updateBankItemBorders)
end
