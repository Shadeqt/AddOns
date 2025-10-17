-- ============================
-- cfItemColors - Core Module
-- ============================
-- Constants, utilities, and shared state

-- Create addon namespace
cfItemColors = cfItemColors or {}
local addon = cfItemColors

-- ============================
-- CONSTANTS
-- ============================

-- Item quality constants
addon.QUEST_ITEM_QUALITY = 99

-- UI frame constants
addon.MAX_MERCHANT_SLOTS = 12
addon.MAX_QUEST_REWARD_SLOTS = 6
addon.MAX_PROFESSION_REAGENTS = 8

-- ============================
-- COLOR DEFINITIONS
-- ============================

-- Item quality color definitions: {r, g, b}
addon.itemQualityColors = {
	[0] = {0.62, 0.62, 0.62}, -- Poor (gray)
	[1] = {1.00, 1.00, 1.00}, -- Common (white)
	[2] = {0.12, 1.00, 0.00}, -- Uncommon (green)
	[3] = {0.00, 0.44, 0.87}, -- Rare (blue)
	[4] = {0.64, 0.21, 0.93}, -- Epic (purple)
	[5] = {1.00, 0.50, 0.00}, -- Legendary (orange)
	[6] = {0.90, 0.80, 0.50}, -- Artifact (light orange)
	[7] = {0.00, 0.80, 1.00}, -- Heirloom (light blue)
	[addon.QUEST_ITEM_QUALITY] = {1.00, 1.00, 0.00}, -- Quest items (yellow)
}

-- ============================
-- STATE MANAGEMENT
-- ============================

-- State cache to prevent redundant border updates
addon.buttonQualityStateCache = {}

-- ============================
-- UTILITY FUNCTIONS
-- ============================

-- Check if frame is valid and visible
function addon:IsFrameVisible(frame)
	return frame and frame:IsVisible()
end

-- Get RGB values for item quality color
function addon:GetItemQualityColor(quality)
	local colorData = self.itemQualityColors[quality]
	if not colorData then
		return 1, 1, 1 -- Default to white
	end
	return colorData[1], colorData[2], colorData[3]
end
