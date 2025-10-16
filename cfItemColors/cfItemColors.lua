-- cfItemColors - Simple item quality border coloring addon

-- Create border texture for item buttons
local function createQualityBorder(button)
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

-- Update item border color based on quality
local function updateItemBorder(button, bagID, slotID)
	local border = createQualityBorder(button)
	local itemID = C_Container.GetContainerItemID(bagID, slotID)
	
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

-- Initialize on login
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	hooksecurefunc("ContainerFrame_Update", function(frame)
		local bagID = frame:GetID()
		local name = frame:GetName()
		
		for i = 1, frame.size do
			local button = _G[name.."Item"..i]
			if button then
				updateItemBorder(button, bagID, button:GetID())
			end
		end
	end)
end)