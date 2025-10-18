-- ============================
-- cfItemColors - Quests Module
-- ============================
-- Handles quest reward and quest log item borders

local addon = cfItemColors

-- Button caches
local questRewardButtonCache = {}
local questRequiredItemButtonCache = {}
local questLogButtonCache = {}

-- ============================
-- HELPER FUNCTIONS
-- ============================

-- Get item link for quest reward/choice at given index
local function getQuestItemLink(itemIndex, numChoices, isQuestLog)
	if itemIndex <= numChoices then
		-- This is a choice reward
		if isQuestLog then
			return GetQuestLogItemLink("choice", itemIndex)
		else
			return GetQuestItemLink("choice", itemIndex)
		end
	else
		-- This is a fixed reward
		local rewardIndex = itemIndex - numChoices
		if isQuestLog then
			return GetQuestLogItemLink("reward", rewardIndex)
		else
			return GetQuestItemLink("reward", rewardIndex)
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

-- Initialize quest required item button cache
local function initializeQuestRequiredItemButtonCache()
	if #questRequiredItemButtonCache == 0 then
		for slotIndex = 1, addon.MAX_QUEST_REWARD_SLOTS do
			questRequiredItemButtonCache[slotIndex] = _G["QuestProgressItem"..slotIndex]
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

-- Core function to update quest item borders (works for both reward and log)
local function updateQuestItemBordersCore(buttonCache, numChoices, totalItems, isQuestLog)
	for itemIndex = 1, totalItems do
		local itemButton = buttonCache[itemIndex]
		if itemButton and itemButton:IsVisible() then
			local itemLink = getQuestItemLink(itemIndex, numChoices, isQuestLog)
			addon:ApplyItemQualityBorderByLink(itemButton, itemLink)
		end
	end
end

-- Update quest reward item quality borders
local function updateQuestRewardBorders()
	if not addon:IsFrameVisible(QuestFrame) then return end

	initializeQuestRewardButtonCache()

	local numChoices = GetNumQuestChoices()
	local numRewards = GetNumQuestRewards()
	local totalItems = numChoices + numRewards

	updateQuestItemBordersCore(questRewardButtonCache, numChoices, totalItems, false)
end

-- Update quest required item borders (items you need to turn in)
local function updateQuestRequiredItemBorders()
	if not addon:IsFrameVisible(QuestFrame) then return end

	initializeQuestRequiredItemButtonCache()

	local numRequiredItems = GetNumQuestItems()
	for itemIndex = 1, numRequiredItems do
		local itemButton = questRequiredItemButtonCache[itemIndex]
		if itemButton and itemButton:IsVisible() then
			local itemLink = GetQuestItemLink("required", itemIndex)
			addon:ApplyItemQualityBorderByLink(itemButton, itemLink)
		end
	end
end

-- Update quest log item quality borders
local function updateQuestLogBorders()
	if not QuestLogFrame then return end

	initializeQuestLogButtonCache()

	local selectedQuest = GetQuestLogSelection()
	if not selectedQuest or selectedQuest == 0 then return end

	local numChoices = GetNumQuestLogChoices()
	local numRewards = GetNumQuestLogRewards()
	local totalItems = numChoices + numRewards

	updateQuestItemBordersCore(questLogButtonCache, numChoices, totalItems, true)
end

-- ============================
-- MODULE INITIALIZATION
-- ============================

function addon:InitQuestsModule(eventFrame)
	-- Hook quest frame updates (rewards)
	hooksecurefunc("QuestInfo_Display", updateQuestRewardBorders)
	hooksecurefunc("QuestFrameItems_Update", updateQuestRewardBorders)

	-- Hook quest progress updates (required items for turn-in)
	hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItemBorders)

	-- Hook quest log updates
	eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
	if QuestLogFrame then
		QuestLogFrame:HookScript("OnShow", updateQuestLogBorders)
	end

	-- Store function for event handler
	self.updateQuestLogBorders = updateQuestLogBorders
end
