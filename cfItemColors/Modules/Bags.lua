-- ============================
-- cfItemColors - Bags Module
-- ============================
-- Handles bag and bank item borders

local addon = cfItemColors

-- Button caches
local bagItemButtonCache = {}
local bankItemButtonCache = {}

-- ============================
-- CACHE INITIALIZATION
-- ============================

local function initializeBagItemButtonCache(containerFrameName, containerFrameSize)
	if not bagItemButtonCache[containerFrameName] then
		bagItemButtonCache[containerFrameName] = {}
		for slotIndex = 1, containerFrameSize do
			bagItemButtonCache[containerFrameName][slotIndex] = _G[containerFrameName.."Item"..slotIndex]
		end
	end
end

local function initializeBankItemButtonCache(bankSlotCount)
	addon:BuildButtonCache(bankItemButtonCache, "BankFrameItem%d", bankSlotCount)
end

-- ============================
-- UPDATE FUNCTIONS
-- ============================

local function updateBagItemBorders(containerFrame)
	local containerId = containerFrame:GetID()
	local containerFrameName = containerFrame:GetName()

	initializeBagItemButtonCache(containerFrameName, containerFrame.size)

	for slotIndex = 1, containerFrame.size do
		local itemButton = bagItemButtonCache[containerFrameName][slotIndex]
		if itemButton and itemButton:IsVisible() then
			addon:ApplyContainerItemBorder(itemButton, containerId, itemButton:GetID())
		end
	end
end

local function updateBankItemBorders()
	local bankSlotCount = C_Container.GetContainerNumSlots(BANK_CONTAINER)
	initializeBankItemButtonCache(bankSlotCount)

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
