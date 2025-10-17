-- Color Configuration and State Management

-- Color definitions: {red, green, blue, alpha, shouldDesaturate}
local BUTTON_COLOR_STATES = {
	normal = { 1, 1, 1, 1, false },
	outOfMana = { 0.1, 0.3, 1, 1, true },
	outOfRange = { 1, 0.3, 0.1, 1, true },
}

-- Cache to prevent redundant color applications
local buttonIconColorStates = {}

local function applyButtonColorIfChanged(buttonIcon, newColorState)
	if buttonIconColorStates[buttonIcon] == newColorState then 
		return 
	end
	
	buttonIconColorStates[buttonIcon] = newColorState
	local colorConfig = BUTTON_COLOR_STATES[newColorState]
	buttonIcon:SetVertexColor(colorConfig[1], colorConfig[2], colorConfig[3], colorConfig[4])
	buttonIcon:SetDesaturated(colorConfig[5])
end

local function determineButtonColorState(isOutOfMana, isOutOfRange)
	if isOutOfMana then 
		return "outOfMana"
	elseif isOutOfRange then 
		return "outOfRange"
	else 
		return "normal"
	end
end

-- Button Coloring Logic
local function updatePlayerActionButtonColor(actionButton)
	if not actionButton then return end
	if not actionButton.action then return end
	if not actionButton.icon then return end
	if not actionButton:IsVisible() then return end
	if not ActionHasRange(actionButton.action or 0) then return end

	local isUsable, isOutOfMana = IsUsableAction(actionButton.action)
	local isOutOfRange = IsActionInRange(actionButton.action) == false

	local requiredColorState = determineButtonColorState(isOutOfMana, isOutOfRange)
	applyButtonColorIfChanged(actionButton.icon, requiredColorState)
end

local function updatePetActionButtonColor(petButton)
	if not petButton then return end
	if not petButton.icon then return end
	if not petButton:IsVisible() then return end

	local petActionSlot = petButton:GetID()
	if not petActionSlot then return end

	local _, _, _, _, _, _, spellID, hasRangeCheck, isInRange = GetPetActionInfo(petActionSlot)
	if not spellID and not hasRangeCheck then return end
	
	local isOutOfRange = hasRangeCheck and not isInRange
	local isOutOfMana = spellID and select(2, C_Spell.IsSpellUsable(spellID)) or false

	local requiredColorState = determineButtonColorState(isOutOfMana, isOutOfRange)
	applyButtonColorIfChanged(petButton.icon, requiredColorState)
end

-- Pet Action Button Management
local cachedPetActionButtons = {}

local function updateAllVisiblePetActionButtons()
	if not PetHasActionBar() then return end
	
	for slotIndex = 1, NUM_PET_ACTION_SLOTS do
		local petButton = cachedPetActionButtons[slotIndex]
		if petButton and petButton:IsVisible() then
			updatePetActionButtonColor(petButton)
		end
	end
end

-- Initialization Functions
local function initializePlayerActionButtonColoring()
	hooksecurefunc("ActionButton_UpdateUsable", updatePlayerActionButtonColor)
	hooksecurefunc("ActionButton_UpdateRangeIndicator", updatePlayerActionButtonColor)
end

local function initializePetActionButtonColoring(eventFrame)
	for slotIndex = 1, NUM_PET_ACTION_SLOTS do
		local petButton = _G["PetActionButton" .. slotIndex]
		if petButton then
			cachedPetActionButtons[slotIndex] = petButton
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

-- Check if player class can have pets (Classic 1.15.7)
local function doesPlayerClassHavePets()
	local _, playerClass = UnitClass("player")
	return playerClass == "HUNTER" or playerClass == "WARLOCK"
end

-- Addon Initialization and Event Handling
local addonEventFrame = CreateFrame("Frame")
addonEventFrame:RegisterEvent("PLAYER_LOGIN")

addonEventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		initializePlayerActionButtonColoring()
		
		if doesPlayerClassHavePets() then
			initializePetActionButtonColoring(self)
		end
		return
	end
	
	if not doesPlayerClassHavePets() then return end
	
	if event == "UNIT_POWER_UPDATE" and ... == "pet" then
		updateAllVisiblePetActionButtons()
		
	elseif event == "PLAYER_TARGET_CHANGED" or event == "SPELL_UPDATE_COOLDOWN" then
		updateAllVisiblePetActionButtons()
	end
end)