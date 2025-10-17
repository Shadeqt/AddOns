-- ============================
-- cfItemColors - Equipment Module
-- ============================
-- Handles character and inspect equipment borders

local addon = cfItemColors

-- Button caches
local equipmentSlotButtonCache = {}
local equipmentSlotIdCache = {}

-- Equipment slot names for character and inspect frames
local equipmentSlotNames = {
	"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
	"Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
	"Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo"
}

-- ============================
-- CACHE INITIALIZATION
-- ============================

-- Cached equipment slot Ids (eliminates repeated GetInventorySlotInfo calls)
local function initializeEquipmentSlotIdCache()
	if next(equipmentSlotIdCache) == nil then
		for _, slotName in ipairs(equipmentSlotNames) do
			equipmentSlotIdCache[slotName] = GetInventorySlotInfo(slotName.."Slot")
		end
	end
end

-- Initialize equipment slot button cache for frame prefix (Character/Inspect)
local function initializeEquipmentSlotButtonCache(framePrefix)
	if not equipmentSlotButtonCache[framePrefix] then
		equipmentSlotButtonCache[framePrefix] = {}
		for _, slotName in ipairs(equipmentSlotNames) do
			local equipmentButtonName = framePrefix..slotName.."Slot"
			equipmentSlotButtonCache[framePrefix][slotName] = _G[equipmentButtonName]
		end
	end
end

-- ============================
-- UPDATE FUNCTIONS
-- ============================

-- Update equipment item quality borders for character or inspect frame
local function updateEquipmentItemBorders(framePrefix, unitId, parentFrame)
	if not addon:IsFrameVisible(parentFrame) then return end

	initializeEquipmentSlotButtonCache(framePrefix)
	initializeEquipmentSlotIdCache()

	for _, slotName in ipairs(equipmentSlotNames) do
		local slotId = equipmentSlotIdCache[slotName]
		local equipmentButton = equipmentSlotButtonCache[framePrefix][slotName]
		if equipmentButton and equipmentButton:IsVisible() and slotId then
			local itemLink = GetInventoryItemLink(unitId, slotId)
			addon:ApplyItemQualityBorderByLink(equipmentButton, itemLink)
		end
	end
end

-- Update character equipment item quality borders
local function updateCharacterEquipmentBorders()
	updateEquipmentItemBorders("Character", "player", CharacterFrame)
end

-- Clear all inspect equipment borders (called when starting new inspect)
local function clearInspectEquipmentBorders()
	-- Only clear if cache exists (no need to initialize just to clear)
	if not equipmentSlotButtonCache["Inspect"] then return end

	for _, slotName in ipairs(equipmentSlotNames) do
		local equipmentButton = equipmentSlotButtonCache["Inspect"][slotName]
		if equipmentButton and equipmentButton.cfQualityBorder then
			equipmentButton.cfQualityBorder:Hide()
			addon.buttonQualityStateCache[equipmentButton] = nil
		end
	end
end

-- Update inspect equipment item quality borders
local function updateInspectEquipmentBorders(expectedTargetGUID)
	-- Verify target hasn't changed (prevent stale timer updates)
	if expectedTargetGUID and UnitGUID("target") ~= expectedTargetGUID then
		return
	end

	updateEquipmentItemBorders("Inspect", "target", InspectFrame)
end

-- ============================
-- MODULE INITIALIZATION
-- ============================

function addon:InitEquipmentModule(eventFrame)
	-- Hook character equipment updates
	hooksecurefunc("PaperDollItemSlotButton_Update", updateCharacterEquipmentBorders)

	-- Register inspect hooks if inspect UI is already loaded
	if IsAddOnLoaded("Blizzard_InspectUI") then
		self:RegisterInspectHooks(eventFrame)
	end

	-- Store functions for external access
	self.clearInspectEquipmentBorders = clearInspectEquipmentBorders
	self.updateInspectEquipmentBorders = updateInspectEquipmentBorders
end

-- Register inspect frame event handlers and hooks
function addon:RegisterInspectHooks(eventFrame)
	eventFrame:RegisterEvent("INSPECT_READY")
	eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", updateInspectEquipmentBorders)
end
