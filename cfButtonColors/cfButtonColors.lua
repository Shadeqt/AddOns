-- Color definitions: {r, g, b, a, desaturate}
local buttonColors = {
	normal = { 1, 1, 1, 1, false },           -- White, no desaturation
	outOfMana = { 0.1, 0.3, 1, 1, true },    -- Blue, desaturated
	outOfRange = { 1, 0.3, 0.1, 1, true },   -- Red, desaturated
}

-- State cache to avoid redundant color applications
local buttonStates = {}

-- Apply color to button icon (only if state changed)
local function applyButtonColor(buttonIcon, colorState)
	-- Skip if state hasn't changed
	if buttonStates[buttonIcon] == colorState then return end
	
	buttonStates[buttonIcon] = colorState
	local colorSettings = buttonColors[colorState]
	buttonIcon:SetVertexColor(colorSettings[1], colorSettings[2], colorSettings[3], colorSettings[4])
	buttonIcon:SetDesaturated(colorSettings[5])
end

-- Determine color state based on usability conditions
local function getColorState(isOutOfMana, isOutOfRange)
	if isOutOfMana then 
		return "outOfMana"
	elseif isOutOfRange then 
		return "outOfRange"
	else 
		return "normal"
	end
end

-- Color player action buttons based on range and resource availability
local function colorPlayerActionButton(actionButton)
	-- Early exits for efficiency
	if not actionButton then return end
	if not actionButton.action then return end
	if not actionButton.icon then return end
	if not actionButton:IsVisible() then return end
	if not ActionHasRange(actionButton.action or 0) then return end

	-- Check button state
	local isUsable, isOutOfMana = IsUsableAction(actionButton.action)
	local isOutOfRange = IsActionInRange(actionButton.action) == false

	-- Apply appropriate color
	local colorState = getColorState(isOutOfMana, isOutOfRange)
	applyButtonColor(actionButton.icon, colorState)
end

-- Color pet action buttons based on range and resource availability
local function colorPetActionButton(petButton)
	-- Early exits for efficiency
	if not petButton then return end
	if not petButton.icon then return end
	if not petButton:IsVisible() then return end

	local petActionSlot = petButton:GetID()
	if not petActionSlot then return end

	local _, _, _, _, _, _, spellID, hasRangeCheck, isInRange = GetPetActionInfo(petActionSlot)
	if not spellID and not hasRangeCheck then return end
	
	-- Check pet action state
	local isOutOfRange = hasRangeCheck and not isInRange
	local isOutOfMana = spellID and select(2, C_Spell.IsSpellUsable(spellID)) or false

	-- Apply appropriate color
	local colorState = getColorState(isOutOfMana, isOutOfRange)
	applyButtonColor(petButton.icon, colorState)
end

-- Cache for pet action buttons
local cachedPetButtons = {}

local function updateAllPetButtons()
	if not PetHasActionBar() then return end
	for slotIndex = 1, NUM_PET_ACTION_SLOTS do
		local petButton = cachedPetButtons[slotIndex]
		if petButton and petButton:IsVisible() then
			colorPetActionButton(petButton)
		end
	end
end

-- Initialize player action functionality
local function initializePlayerActions()
	-- Hook into WoW's button update functions for regular action buttons
	hooksecurefunc("ActionButton_UpdateUsable", colorPlayerActionButton)
	hooksecurefunc("ActionButton_UpdateRangeIndicator", colorPlayerActionButton)
end

-- Initialize pet action functionality (only called for pet classes with pets)
local function initializePetActions(eventFrame)
	-- Cache pet buttons and set up hooks
	for slotIndex = 1, NUM_PET_ACTION_SLOTS do
		local petButton = _G["PetActionButton" .. slotIndex]
		if petButton then
			cachedPetButtons[slotIndex] = petButton
			petButton:HookScript("OnShow", function() colorPetActionButton(petButton) end)
			colorPetActionButton(petButton)
		end
	end

	-- Hook pet action bar updates
	hooksecurefunc("PetActionBar_Update", updateAllPetButtons)

	-- Register pet action events
	eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
	eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

-- Check if player class can have pets (Classic 1.15.7)
local function isPetClass()
	local _, playerClass = UnitClass("player")
	return playerClass == "HUNTER" or playerClass == "WARLOCK"
end

-- Main addon initialization and event handling
local addonFrame = CreateFrame("Frame")

addonFrame:RegisterEvent("PLAYER_LOGIN")

addonFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		-- Initialize player action bar coloring (always)
		initializePlayerActions()
		
		-- Only initialize pet system for pet classes
		if isPetClass() then
			initializePetActions(self)
		end
		return
	end
	
	-- Early exit if not a pet class
	if not isPetClass() then return end
	
	if event == "UNIT_POWER_UPDATE" and ... == "pet" then
		-- Pet's mana/energy/rage changed
		updateAllPetButtons()
		
	elseif event == "PLAYER_TARGET_CHANGED" or event == "SPELL_UPDATE_COOLDOWN" then
		-- Target changed or cooldown updated
		updateAllPetButtons()
	end
end)