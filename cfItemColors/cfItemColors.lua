-- Create border texture for item buttons
local function createBorder(button)
	if button.cfQualityBorder then
		return button.cfQualityBorder
	end
	
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:SetAlpha(0.8)
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
		if button then
			colorItemButton(button, bagID, button:GetID())
		end
	end
end

-- Update all bank item borders
local function updateBankItems()
	for slotID = 1, C_Container.GetContainerNumSlots(BANK_CONTAINER) do
		local button = _G["BankFrameItem"..slotID]
		if button then
			colorItemButton(button, BANK_CONTAINER, slotID)
		end
	end
end

-- Initialize hooks on login
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function()
	-- Hook bag container updates
	hooksecurefunc("ContainerFrame_Update", updateBagItems)
	
	-- Hook bank frame updates
	hooksecurefunc("BankFrameItemButton_Update", updateBankItems)
end)