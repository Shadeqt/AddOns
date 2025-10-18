-- Localize frequently called API functions for faster access
local IsUsableAction = IsUsableAction
local IsActionInRange = IsActionInRange
local ActionHasRange = ActionHasRange
local GetPetActionInfo = GetPetActionInfo
local C_Spell = C_Spell

-- Button color state cache to prevent redundant SetVertexColor calls (weak keys for garbage collection)
local buttonColorStateCache = {}
setmetatable(buttonColorStateCache, {__mode = "k"})

-- Clear the cached color state for a button (called on button content changes)
local function clearButtonColorState(button)
	if button and button.icon then
		buttonColorStateCache[button.icon] = nil
	end
end

-- Apply color tint to button: 0=normal(white), 1=out of mana(blue), 2=out of range(red)
local function applyButtonColor(icon, isOutOfMana, isOutOfRange)
	local colorState = isOutOfMana and 1 or (isOutOfRange and 2 or 0)

	if buttonColorStateCache[icon] == colorState then return end
	buttonColorStateCache[icon] = colorState

	if isOutOfMana then
		icon:SetVertexColor(0.1, 0.3, 1.0)
	elseif isOutOfRange then
		icon:SetVertexColor(1.0, 0.3, 0.1)
	else
		icon:SetVertexColor(1.0, 1.0, 1.0)
	end
end

-- Update color for player action button based on current state
local function updatePlayerActionButtonColor(button)
	if not button then return end
	if not button.action then return end
	if not button.icon then return end
	if not ActionHasRange(button.action) then return end

	local _, isOutOfMana = IsUsableAction(button.action)
	local isOutOfRange = IsActionInRange(button.action) == false

	applyButtonColor(button.icon, isOutOfMana, isOutOfRange)
end

-- Hook into Blizzard's action button update functions
hooksecurefunc("ActionButton_UpdateUsable", updatePlayerActionButtonColor)
hooksecurefunc("ActionButton_UpdateRangeIndicator", updatePlayerActionButtonColor)
hooksecurefunc("ActionButton_Update", clearButtonColorState)

-- Pre-cache pet action button references to avoid repeated global lookups
local cachedPetActionButtons = {}
for i = 1, NUM_PET_ACTION_SLOTS do
	cachedPetActionButtons[i] = _G["PetActionButton"..i]
end

-- Update color for pet action button based on current state
local function updatePetActionButtonColor(button)
	if not button then return end
	if not button.icon then return end

	local slotId = button:GetID()
	if not slotId then return end

	local _, _, _, _, _, _, spellId, hasRangeCheck, isInRange = GetPetActionInfo(slotId)
	if not spellId then return end
	if not hasRangeCheck then return end

	local isOutOfRange = hasRangeCheck and not isInRange
	local isOutOfMana = spellId and select(2, C_Spell.IsSpellUsable(spellId)) or false

	applyButtonColor(button.icon, isOutOfMana, isOutOfRange)
end

-- Hook into Blizzard's pet action bar updates (Hunter and Warlock only)
local _, playerClass = UnitClass("player")
if playerClass == "HUNTER" or playerClass == "WARLOCK" then
	hooksecurefunc("PetActionBar_Update", function()
		for i = 1, NUM_PET_ACTION_SLOTS do
			local button = cachedPetActionButtons[i]
			if button and button:IsVisible() then
				updatePetActionButtonColor(button)
			end
		end
	end)
end
