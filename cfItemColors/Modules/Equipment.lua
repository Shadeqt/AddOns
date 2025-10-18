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
-- UPDATE FUNCTIONS
-- ============================

local function updateEquipmentItemBorders(framePrefix, unitId, parentFrame)
	if not addon:IsFrameVisible(parentFrame) then return end

	-- Initialize slot ID cache
	if next(equipmentSlotIdCache) == nil then
		for _, slotName in ipairs(equipmentSlotNames) do
			equipmentSlotIdCache[slotName] = GetInventorySlotInfo(slotName.."Slot")
		end
	end

	-- Initialize button cache for this frame prefix
	if not equipmentSlotButtonCache[framePrefix] then
		equipmentSlotButtonCache[framePrefix] = {}
		for _, slotName in ipairs(equipmentSlotNames) do
			local equipmentButtonName = framePrefix..slotName.."Slot"
			equipmentSlotButtonCache[framePrefix][slotName] = _G[equipmentButtonName]
		end
	end

	for _, slotName in ipairs(equipmentSlotNames) do
		local slotId = equipmentSlotIdCache[slotName]
		local equipmentButton = equipmentSlotButtonCache[framePrefix][slotName]
		if equipmentButton and equipmentButton:IsVisible() and slotId then
			local itemLink = GetInventoryItemLink(unitId, slotId)
			addon:ApplyItemQualityBorderByLink(equipmentButton, itemLink)
		end
	end
end

local function updateCharacterEquipmentBorders()
	updateEquipmentItemBorders("Character", "player", CharacterFrame)
end

local function clearInspectEquipmentBorders()
	if not equipmentSlotButtonCache["Inspect"] then return end

	for _, slotName in ipairs(equipmentSlotNames) do
		local equipmentButton = equipmentSlotButtonCache["Inspect"][slotName]
		if equipmentButton and equipmentButton.cfQualityBorder then
			equipmentButton.cfQualityBorder:Hide()
			addon.buttonQualityStateCache[equipmentButton] = nil
		end
	end
end

local function updateInspectEquipmentBorders(expectedTargetGUID)
	if expectedTargetGUID and UnitGUID("target") ~= expectedTargetGUID then
		return
	end

	updateEquipmentItemBorders("Inspect", "target", InspectFrame)
end

-- ============================
-- MODULE INITIALIZATION
-- ============================

function addon:InitEquipmentModule(eventFrame)
	hooksecurefunc("PaperDollItemSlotButton_Update", updateCharacterEquipmentBorders)

	if IsAddOnLoaded("Blizzard_InspectUI") then
		self:RegisterInspectHooks(eventFrame)
	end

	self.clearInspectEquipmentBorders = clearInspectEquipmentBorders
	self.updateInspectEquipmentBorders = updateInspectEquipmentBorders
end

function addon:RegisterInspectHooks(eventFrame)
	eventFrame:RegisterEvent("INSPECT_READY")
	eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", updateInspectEquipmentBorders)
end
