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

-- Apply quality color to item button border
local function colorItemButton(button, containerID, slotID)
	local border = createBorder(button)
	local itemID = C_Container.GetContainerItemID(containerID, slotID)
	
	if not itemID then
		border:Hide()
		return
	end
	
	local _, _, quality, _, _, itemType = GetItemInfo(itemID)
	
	if itemType == "Quest" then
		border:SetVertexColor(1, 1, 0)
		border:Show()
	elseif quality and quality >= 2 then
		local r, g, b = GetItemQualityColor(quality)
			border:SetVertexColor(r, g, b)
		border:Show()
	else
		border:Hide()
	end
end

-- Update all bag item borders
local function updateBagItems(frame)
	local bagID = frame:GetID()
	local name = frame:GetName()
	
	for i = 1, frame.size do
		local button = _G[name.."Item"..i]
		if button and button:IsVisible() then -- Only process visible buttons
			colorItemButton(button, bagID, button:GetID())
		end
	end
end

-- Update all bank item borders
local function updateBankItems()
	-- Early exit if bank frame not visible
	if not BankFrame or not BankFrame:IsVisible() then return end
	
	for slotID = 1, C_Container.GetContainerNumSlots(BANK_CONTAINER) do
		local button = _G["BankFrameItem"..slotID]
		if button and button:IsVisible() then
			colorItemButton(button, BANK_CONTAINER, slotID)
		end
	end
end

-- Equipment slot names for character and inspect frames
local equipmentSlots = {
	"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
	"Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
	"Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo"
}

-- Apply quality color to any button border using item link
local function colorButtonByLink(button, itemLink)
	local border = createBorder(button)
	
	if not itemLink then
		border:Hide()
		return
	end
	
	-- Extract quality directly from item link (faster than GetItemInfo)
	local quality = select(3, GetItemInfo(itemLink))
	if not quality then
		border:Hide()
		return
	end
	
	-- Check if it's a quest item by item type
	local itemType = select(6, GetItemInfo(itemLink))
	
	if itemType == "Quest" then
		border:SetVertexColor(1, 1, 0)
		border:Show()
	elseif quality >= 2 then
		local r, g, b = GetItemQualityColor(quality)
		border:SetVertexColor(r, g, b)
		border:Show()
	else
		border:Hide()
	end
end

-- Update character equipment item borders
local function updateCharacterItems()
	-- Early exit if character frame not visible
	if not CharacterFrame or not CharacterFrame:IsVisible() then return end
	
	for _, slotName in ipairs(equipmentSlots) do
		local slotID = GetInventorySlotInfo(slotName.."Slot")
		local button = _G["Character"..slotName.."Slot"]
		if button and button:IsVisible() and slotID then
			local itemLink = GetInventoryItemLink("player", slotID)
			colorButtonByLink(button, itemLink)
		end
	end
end

-- Update inspect equipment item borders
local function updateInspectItems()
	-- Early exit if inspect frame not visible
	if not InspectFrame or not InspectFrame:IsVisible() then return end
	
	for _, slotName in ipairs(equipmentSlots) do
		local slotID = GetInventorySlotInfo(slotName.."Slot")
		local button = _G["Inspect"..slotName.."Slot"]
		if button and button:IsVisible() and slotID then
			local itemLink = GetInventoryItemLink("target", slotID)
			colorButtonByLink(button, itemLink)
		end
	end
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
			colorButtonByLink(button, itemLink)
		end
	end
	
	-- Update single buyback slot (only on merchant tab)
	if not isBuybackTab then
		local buybackButton = _G["MerchantBuyBackItemItemButton"]
		if buybackButton and buybackButton:IsVisible() then
			local itemLink = GetBuybackItemLink(GetNumBuybackItems())
			colorButtonByLink(buybackButton, itemLink)
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