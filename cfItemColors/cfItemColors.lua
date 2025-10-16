-- cfItemColors - Simple item quality border coloring addon
-- Based on analysis of oGlow, ColoredInventoryItems, Baganator, and DragonflightUI

-- Configuration
local config = {
	enabled = true,
	intensity = 0.8,
	minQuality = 2, -- Uncommon and above (0=Poor, 1=Common, 2=Uncommon, etc.)
}

-- Create border texture for item buttons
local function createQualityBorder(button)
	if button.cfQualityBorder then
		return button.cfQualityBorder
	end
	
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:SetAlpha(config.intensity)
	border:SetWidth(68)
	border:SetHeight(68)
	border:SetPoint("CENTER", button)
	border:Hide()
	
	button.cfQualityBorder = border
	return border
end

-- Update item border color based on quality
local function updateItemBorder(button, bagID, slotID)
	if not config.enabled then return end
	
	local border = createQualityBorder(button)
	local itemID = C_Container.GetContainerItemID(bagID, slotID)
	
	if itemID then
		local quality = select(3, GetItemInfo(itemID))
		
		if quality and quality >= config.minQuality then
			local r, g, b = GetItemQualityColor(quality)
			border:SetVertexColor(r, g, b)
			border:Show()
		else
			border:Hide()
		end
	else
		border:Hide()
	end
end

-- Hook bag slot updates
local function hookBagSlots()
	-- Hook container frame updates
	hooksecurefunc("ContainerFrame_Update", function(frame)
		local bagID = frame:GetID()
		local name = frame:GetName()
		
		for i = 1, frame.size do
			local button = _G[name.."Item"..i]
			if button then
				local slotID = button:GetID()
				updateItemBorder(button, bagID, slotID)
			end
		end
	end)
end

-- Initialize addon
local function initialize()
	hookBagSlots()
	print("|cff33ff99cfItemColors:|r Loaded - Item quality borders enabled")
end

-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == "cfItemColors" then
		-- Load saved variables here if needed
		
	elseif event == "PLAYER_LOGIN" then
		initialize()
	end
end)