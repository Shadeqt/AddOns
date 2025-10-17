-- ============================
-- cfItemColors - Quests Module
-- ============================
-- Handles quest reward and quest log item borders

local addon = cfItemColors

-- Button caches
local questRewardButtonCache = {}
local questLogButtonCache = {}

-- ============================
-- HELPER FUNCTIONS
-- ============================

-- Get item quality for quest reward/choice at given index
local function getQuestItemQuality(itemIndex, numChoices, isQuestLog)
	if itemIndex <= numChoices then
		-- This is a choice reward
		if isQuestLog then
			local _, _, _, quality = GetQuestLogChoiceInfo(itemIndex)
			return quality
		else
			local _, _, _, quality = GetQuestItemInfo("choice", itemIndex)
			return quality
		end
	else
		-- This is a fixed reward
		local rewardIndex = itemIndex - numChoices
		if isQuestLog then
			local _, _, _, quality = GetQuestLogRewardInfo(rewardIndex)
			return quality
		else
			local _, _, _, quality = GetQuestItemInfo("reward", rewardIndex)
			return quality
		end
	end
end

-- ============================
-- CACHE INITIALIZATION
-- ============================

-- Initialize quest reward button cache
local function initializeQuestRewardButtonCache()
	if #questRewardButtonCache == 0 then
		for slotIndex = 1, addon.MAX_QUEST_REWARD_SLOTS do
			questRewardButtonCache[slotIndex] = _G["QuestInfoRewardsFrameQuestInfoItem"..slotIndex]
		end
	end
end

-- Initialize quest log button cache
local function initializeQuestLogButtonCache()
	if #questLogButtonCache == 0 then
		for slotIndex = 1, addon.MAX_QUEST_REWARD_SLOTS do
			questLogButtonCache[slotIndex] = _G["QuestLogItem"..slotIndex]
		end
	end
end

-- ============================
-- UPDATE FUNCTIONS
-- ============================

-- Update quest reward item quality borders
local function updateQuestRewardBorders()
	if not addon:IsFrameVisible(QuestFrame) then return end

	initializeQuestRewardButtonCache()

	local numChoices = GetNumQuestChoices()
	local numRewards = GetNumQuestRewards()
	local totalItems = numChoices + numRewards

	for itemIndex = 1, totalItems do
		local rewardButton = questRewardButtonCache[itemIndex]
		if rewardButton and rewardButton:IsVisible() then
			local itemQuality = getQuestItemQuality(itemIndex, numChoices, false)
			addon:ApplyItemQualityBorder(rewardButton, itemQuality, nil)
		end
	end
end

-- Update quest log item quality borders
local function updateQuestLogBorders()
	if not addon:IsFrameVisible(QuestLogFrame) then return end

	initializeQuestLogButtonCache()

	local selectedQuest = GetQuestLogSelection()
	if not selectedQuest or selectedQuest == 0 then return end

	local numChoices = GetNumQuestLogChoices()
	local numRewards = GetNumQuestLogRewards()
	local totalItems = numChoices + numRewards

	for itemIndex = 1, totalItems do
		local itemButton = questLogButtonCache[itemIndex]
		if itemButton and itemButton:IsVisible() then
			local itemQuality = getQuestItemQuality(itemIndex, numChoices, true)
			addon:ApplyItemQualityBorder(itemButton, itemQuality, nil)
		end
	end
end

-- ============================
-- MODULE INITIALIZATION
-- ============================

function addon:InitQuestsModule(eventFrame)
	-- Hook quest frame updates
	hooksecurefunc("QuestInfo_Display", updateQuestRewardBorders)
	hooksecurefunc("QuestFrameItems_Update", updateQuestRewardBorders)

	-- Hook quest log updates
	eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
	if QuestLogFrame then
		QuestLogFrame:HookScript("OnShow", updateQuestLogBorders)
	end

	-- Store function for event handler
	self.updateQuestLogBorders = updateQuestLogBorders
end
