-- Button color state constants for efficient comparison
local BUTTON_STATE_NORMAL = 0
local BUTTON_STATE_OUT_OF_MANA = 1
local BUTTON_STATE_OUT_OF_RANGE = 2

-- Button color definitions: {r, g, b, a, isDesaturated}
local buttonColorStates = {
	[BUTTON_STATE_NORMAL] = {1.00, 1.00, 1.00, 1.00, false}, -- Normal (white)
	[BUTTON_STATE_OUT_OF_MANA] = {0.10, 0.30, 1.00, 1.00, true}, -- Out of mana (blue)
	[BUTTON_STATE_OUT_OF_RANGE] = {1.00, 0.30, 0.10, 1.00, true}, -- Out of range (red)
}

-- Button caches for performance optimization
local petActionButtonCache = {}

-- Get RGBA values for button color state
local function getButtonColorState(stateKey)
	local colorData = buttonColorStates[stateKey]
	if not colorData then
		return 1, 1, 1, 1, false -- Default to normal
	end
	return colorData[1], colorData[2], colorData[3], colorData[4], colorData[5]
end

-- Determine button color state based on usability conditions
local function determineButtonColorState(isOutOfMana, isOutOfRange)
	if isOutOfMana then
		return BUTTON_STATE_OUT_OF_MANA
	elseif isOutOfRange then
		return BUTTON_STATE_OUT_OF_RANGE
	else
		return BUTTON_STATE_NORMAL
	end
end

-- Apply color state to button icon
local function applyButtonColorState(buttonIcon, stateKey)
	local r, g, b, a, isDesaturated = getButtonColorState(stateKey)
	buttonIcon:SetVertexColor(r, g, b, a)
	buttonIcon:SetDesaturated(isDesaturated)
end

-- Apply color state to player action button (action bars)
local function updatePlayerActionButtonColor(actionButton)
	if not actionButton then return end
	if not actionButton.action then return end
	if not actionButton.icon then return end
	if not actionButton:IsVisible() then return end
	if not ActionHasRange(actionButton.action or 0) then return end

	local isUsable, isOutOfMana = IsUsableAction(actionButton.action)
	local isOutOfRange = IsActionInRange(actionButton.action) == false

	local stateKey = determineButtonColorState(isOutOfMana, isOutOfRange)
	applyButtonColorState(actionButton.icon, stateKey)
end

-- Apply color state to pet action button (pet action bar)
local function updatePetActionButtonColor(petButton)
	if not petButton then return end
	if not petButton.icon then return end
	if not petButton:IsVisible() then return end

	local slotId = petButton:GetID()
	if not slotId then return end

	local _, _, _, _, _, _, spellId, hasRangeCheck, isInRange = GetPetActionInfo(slotId)
	if not spellId and not hasRangeCheck then return end
	
	local isOutOfRange = hasRangeCheck and not isInRange
	local isOutOfMana = spellId and select(2, C_Spell.IsSpellUsable(spellId)) or false

	local stateKey = determineButtonColorState(isOutOfMana, isOutOfRange)
	applyButtonColorState(petButton.icon, stateKey)
end

-- Update all visible pet action button colors
local function updateAllVisiblePetActionButtons()
	if not PetHasActionBar() then return end
	
	for slotIndex = 1, NUM_PET_ACTION_SLOTS do
		local petButton = petActionButtonCache[slotIndex]
		if petButton and petButton:IsVisible() then
			updatePetActionButtonColor(petButton)
		end
	end
end

-- Initialize pet action button cache
local function initializePetActionButtonCache()
	if #petActionButtonCache == 0 then
		for slotIndex = 1, NUM_PET_ACTION_SLOTS do
			petActionButtonCache[slotIndex] = _G["PetActionButton"..slotIndex]
		end
	end
end

-- Initialize player action button hooks
local function initializePlayerActionButtonHooks()
	hooksecurefunc("ActionButton_UpdateUsable", updatePlayerActionButtonColor)
	hooksecurefunc("ActionButton_UpdateRangeIndicator", updatePlayerActionButtonColor)
end

-- Initialize pet action button hooks and events
local function initializePetActionButtonHooks(eventFrame)
	initializePetActionButtonCache()
	
	for slotIndex = 1, NUM_PET_ACTION_SLOTS do
		local petButton = petActionButtonCache[slotIndex]
		if petButton then
			petButton:HookScript("OnShow", function() 
				updatePetActionButtonColor(petButton) 
			end)
			updatePetActionButtonColor(petButton)
		end
	end

	hooksecurefunc("PetActionBar_Update", updateAllVisiblePetActionButtons)

	eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
	eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

-- Check if player class can have pets (Classic WoW)
local function doesPlayerClassHavePets()
	local _, playerClass = UnitClass("player")
	return playerClass == "HUNTER" or playerClass == "WARLOCK"
end

-- Initialize addon event handling and UI hooks
local addonEventFrame = CreateFrame("Frame")
addonEventFrame:RegisterEvent("PLAYER_LOGIN")

addonEventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		-- Hook player action button updates
		initializePlayerActionButtonHooks()
		
		-- Hook pet action button updates for classes that have pets
		if doesPlayerClassHavePets() then
			initializePetActionButtonHooks(self)
		end
		return
	end
	
	-- Handle pet-related events only for classes that have pets
	if not doesPlayerClassHavePets() then return end
	
	if event == "UNIT_POWER_UPDATE" and ... == "pet" then
		updateAllVisiblePetActionButtons()
		
	elseif event == "PLAYER_TARGET_CHANGED" or event == "SPELL_UPDATE_COOLDOWN" then
		updateAllVisiblePetActionButtons()
	end
end)