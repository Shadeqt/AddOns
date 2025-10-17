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

-- Initialize bag item button cache for specific container frame
local function initializeBagItemButtonCache(containerFrameName, containerFrameSize)
	if not bagItemButtonCache[containerFrameName] then
		bagItemButtonCache[containerFrameName] = {}
		for slotIndex = 1, containerFrameSize do
			bagItemButtonCache[containerFrameName][slotIndex] = _G[containerFrameName.."Item"..slotIndex]
		end
	end
end

-- Initialize bank item button cache
local function initializeBankItemButtonCache(bankSlotCount)
	if #bankItemButtonCache == 0 then
		for slotId = 1, bankSlotCount do
			bankItemButtonCache[slotId] = _G["BankFrameItem"..slotId]
		end
	end
end

-- ============================
-- UPDATE FUNCTIONS
-- ============================

-- Update bag item quality borders for container frame
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

-- Update bank item quality borders
local function updateBankItemBorders()
	if not addon:IsFrameVisible(BankFrame) then return end

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
	-- Hook bag container frame updates
	hooksecurefunc("ContainerFrame_Update", updateBagItemBorders)

	-- Hook bank frame item updates
	hooksecurefunc("BankFrameItemButton_Update", updateBankItemBorders)
end
