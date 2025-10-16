-- Quality color mapping (cached for performance)
local qualityColors = {
	[0] = {0.62, 0.62, 0.62}, -- Poor (gray)
	[1] = {1.00, 1.00, 1.00}, -- Common (white)
	[2] = {0.12, 1.00, 0.00}, -- Uncommon (green)
	[3] = {0.00, 0.44, 0.87}, -- Rare (blue)
	[4] = {0.64, 0.21, 0.93}, -- Epic (purple)
	[5] = {1.00, 0.50, 0.00}, -- Legendary (orange)
	[6] = {0.90, 0.80, 0.50}, -- Artifact (light orange)
	[7] = {0.00, 0.80, 1.00}, -- Heirloom (light blue)
	Quest = {1.00, 1.00, 0.00}, -- Quest items (yellow)
}

-- Get quality color (with centralized color control)
local function getQualityColor(quality)
	local color = qualityColors[quality]
	if not color then
		return 1, 1, 1 -- Default to white
	end
	return color[1], color[2], color[3]
end

-- Create border texture for item buttons
local function createBorder(button)
	if button.cfQualityBorder then
		return button.cfQualityBorder
	end
	
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:SetAlpha(0.7)
	border:SetWidth(68)
	border:SetHeight(68)
	border:SetPoint("CENTER", button)
	border:Hide()
	
	button.cfQualityBorder = border
	return border
end

-- Apply quality color to any button border (unified function)
local function applyBorderColor(button, quality, itemType)
	local border = createBorder(button)
	
	if itemType == "Quest" then
		local r, g, b = getQualityColor(itemType)
		border:SetVertexColor(r, g, b)
		border:Show()
	elseif quality and quality >= 2 then
		local r, g, b = getQualityColor(quality)
		border:SetVertexColor(r, g, b)
		border:Show()
	else
		border:Hide()
	end
end

-- Apply quality color to container item button
local function applyContainerBorderColor(button, containerID, slotID)
	local itemID = C_Container.GetContainerItemID(containerID, slotID)
	
	if not itemID then
		createBorder(button):Hide()
		return
	end
	
	local _, _, quality, _, _, itemType = GetItemInfo(itemID)
	applyBorderColor(button, quality, itemType)
end

-- Update bag item borders
local function updateBagBorders(frame)
	local bagID = frame:GetID()
	local name = frame:GetName()
	
	for i = 1, frame.size do
		local button = _G[name.."Item"..i]
		if button and button:IsVisible() then -- Only process visible buttons
			applyContainerBorderColor(button, bagID, button:GetID())
		end
	end
end

-- Update bank item borders
local function updateBankBorders()
	-- Early exit if bank frame not visible
	if not BankFrame or not BankFrame:IsVisible() then return end
	
	for slotID = 1, C_Container.GetContainerNumSlots(BANK_CONTAINER) do
		local button = _G["BankFrameItem"..slotID]
		if button and button:IsVisible() then
			applyContainerBorderColor(button, BANK_CONTAINER, slotID)
		end
	end
end

-- Equipment slot names for character and inspect frames
local equipmentSlots = {
	"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
	"Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
	"Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo"
}

-- Apply quality color to button using item link
local function applyBorderColorByLink(button, itemLink)
	if not itemLink then
		createBorder(button):Hide()
		return
	end
	
	local quality = select(3, GetItemInfo(itemLink))
	local itemType = select(6, GetItemInfo(itemLink))
	
	if not quality then
		createBorder(button):Hide()
		return
	end
	
	applyBorderColor(button, quality, itemType)
end

-- Update equipment item borders (unified function)
local function updateEquipmentItems(framePrefix, unit, parentFrame)
	-- Early exit if parent frame not visible
	if not parentFrame or not parentFrame:IsVisible() then return end
	
	for _, slotName in ipairs(equipmentSlots) do
		local slotID = GetInventorySlotInfo(slotName.."Slot")
		local button = _G[framePrefix..slotName.."Slot"]
		if button and button:IsVisible() and slotID then
			local itemLink = GetInventoryItemLink(unit, slotID)
			applyBorderColorByLink(button, itemLink)
		end
	end
end

-- Update character equipment item borders
local function updateCharacterItems()
	updateEquipmentItems("Character", "player", CharacterFrame)
end

-- Update inspect equipment item borders
local function updateInspectItems()
	updateEquipmentItems("Inspect", "target", InspectFrame)
end

-- Update merchant item borders
local function updateMerchantItems()
	-- Early exit if merchant frame not visible
	if not MerchantFrame or not MerchantFrame:IsVisible() then return end
	
	local isBuybackTab = MerchantFrame.selectedTab == 2
	
	-- Update main merchant items (1-12)
	for i = 1, 12 do
		local button = _G["MerchantItem"..i.."ItemButton"]
		if button and button:IsVisible() then
			local itemLink = isBuybackTab and GetBuybackItemLink(i) or GetMerchantItemLink(i)
			applyBorderColorByLink(button, itemLink)
		end
	end
	
	-- Update single buyback slot (only on merchant tab)
	if not isBuybackTab then
		local buybackButton = _G["MerchantBuyBackItemItemButton"]
		if buybackButton and buybackButton:IsVisible() then
			local itemLink = GetBuybackItemLink(GetNumBuybackItems())
			applyBorderColorByLink(buybackButton, itemLink)
		end
	end
end

-- Initialize hooks on login
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "PLAYER_LOGIN" then
		-- Hook bag container updates
		hooksecurefunc("ContainerFrame_Update", updateBagItems)
		
		-- Hook bank frame updates
		hooksecurefunc("BankFrameItemButton_Update", updateBankItems)
		
		-- Hook character frame updates
		hooksecurefunc("PaperDollItemSlotButton_Update", updateCharacterItems)
		
		-- Hook merchant frame updates
		hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)
		hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateMerchantItems)
		
		-- Check if inspect UI is already loaded
		if IsAddOnLoaded("Blizzard_InspectUI") then
			frame:RegisterEvent("INSPECT_READY")
			frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
		end
		
	elseif event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
		-- Register inspect events when inspect UI loads
		frame:RegisterEvent("INSPECT_READY")
		frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
		frame:UnregisterEvent("ADDON_LOADED")
		
	elseif event == "INSPECT_READY" then
		-- Update inspect frame when inspection is ready (small delay for item links)
		C_Timer.After(0.01, updateInspectItems)
		
	elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "target" then
		-- Update inspect frame when target's inventory changes
		if InspectFrame and InspectFrame:IsShown() then
			updateInspectItems()
		end
	end
end)