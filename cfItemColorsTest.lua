-- Performance Test for cfItemColors vs cfItemColorsSimple
-- Usage: /cftest [iterations]

local testIterations = 100
local results = {}

local function TestPerformance(testName, testFunc, iterations)
	collectgarbage("collect")
	local startTime = debugprofilestop()
	local startMemory = collectgarbage("count")

	for i = 1, iterations do
		testFunc()
	end

	local endTime = debugprofilestop()
	local endMemory = collectgarbage("count")

	results[testName] = {
		time = endTime - startTime,
		memory = endMemory - startMemory,
		iterations = iterations
	}
end

local function SimulateBagUpdate()
	-- Simulate opening/updating all bags
	for bagId = 0, 4 do
		local numSlots = C_Container.GetContainerNumSlots(bagId)
		for slotId = 1, numSlots do
			local itemId = C_Container.GetContainerItemID(bagId, slotId)
			if itemId then
				GetItemInfo(itemId)
			end
		end
	end
end

local function SimulateCharacterUpdate()
	-- Simulate character sheet equipment update
	for slotId = 1, 19 do
		local itemLink = GetInventoryItemLink("player", slotId)
		if itemLink then
			GetItemInfo(itemLink)
		end
	end
end

local function PrintResults()
	print("|cff00ff00cfItemColors Performance Test Results|r")
	print(string.rep("-", 60))

	for testName, data in pairs(results) do
		print(string.format("|cffFFFF00%s|r", testName))
		print(string.format("  Time: %.2f ms (%.4f ms per iteration)",
			data.time, data.time / data.iterations))
		print(string.format("  Memory: %.2f KB", data.memory))
		print("")
	end

	-- Compare
	local bagTest1 = results["Bag Update (Current)"]
	local bagTest2 = results["Bag Update (Cached)"]

	if bagTest1 and bagTest2 then
		local speedup = bagTest1.time / bagTest2.time
		print(string.format("|cff00ff00Cached version is %.2fx faster|r", speedup))
	end
end

SLASH_CFTEST1 = "/cftest"
SlashCmdList["CFTEST"] = function(msg)
	local iterations = tonumber(msg) or 100

	print("|cff00ff00Starting performance test with " .. iterations .. " iterations...|r")

	-- Test bag updates
	TestPerformance("Bag Update (Current)", SimulateBagUpdate, iterations)

	-- Test character sheet
	TestPerformance("Character Sheet Update", SimulateCharacterUpdate, iterations)

	-- Show results
	C_Timer.After(0.1, PrintResults)
end

print("|cff00ff00cfItemColors Test loaded. Type /cftest to run performance test.|r")
