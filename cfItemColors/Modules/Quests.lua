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
	addon:BuildButtonCache(questRewardButtonCache, "QuestInfoRewardsFrameQuestInfoItem%d", addon.MAX_QUEST_REWARD_SLOTS)
end

-- Initialize quest required item button cache
local function initializeQuestRequiredItemButtonCache()
	addon:BuildButtonCache(questRequiredItemButtonCache, "QuestProgressItem%d", addon.MAX_QUEST_REWARD_SLOTS)
end

-- Initialize quest log button cache
local function initializeQuestLogButtonCache()
	addon:BuildButtonCache(questLogButtonCache, "QuestLogItem%d", addon.MAX_QUEST_REWARD_SLOTS)
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

local function updateQuestRewardBorders()
	if not addon:IsFrameVisible(QuestFrame) and not addon:IsFrameVisible(QuestLogFrame) then return end

	initializeQuestRewardButtonCache()

	local numChoices, numRewards
	if addon:IsFrameVisible(QuestLogFrame) then
		numChoices = GetNumQuestLogChoices()
		numRewards = GetNumQuestLogRewards()
	else
		numChoices = GetNumQuestChoices()
		numRewards = GetNumQuestRewards()
	end

	local totalItems = numChoices + numRewards
	updateQuestItemBordersCore(questRewardButtonCache, numChoices, totalItems, addon:IsFrameVisible(QuestLogFrame))
end

local function updateQuestRequiredItemBorders()
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
	hooksecurefunc("QuestInfo_Display", updateQuestRewardBorders)
	hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItemBorders)

	eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
	if QuestLogFrame then
		QuestLogFrame:HookScript("OnShow", updateQuestLogBorders)
	end

	self.updateQuestLogBorders = updateQuestLogBorders
end
