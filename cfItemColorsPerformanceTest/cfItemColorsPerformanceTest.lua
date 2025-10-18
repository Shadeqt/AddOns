-- Performance comparison between cfItemColors and cfItemColorsSimple
-- This addon measures the actual performance of both addons in real-time
-- Usage:
--   /cfperf start - Start tracking performance
--   /cfperf stop  - Stop and show results
--   /cfperf reset - Reset counters

local enabled = false
local stats = {
	cfItemColors = {calls = 0, totalTime = 0, name = "cfItemColors (cached)"},
	cfItemColorsSimple = {calls = 0, totalTime = 0, name = "cfItemColorsSimple (no cache)"}
}

-- Hook GetItemInfo to measure calls
local originalGetItemInfo = GetItemInfo
local function TrackedGetItemInfo(...)
	local startTime = debugprofilestop()
	local results = {originalGetItemInfo(...)}
	local elapsed = debugprofilestop() - startTime

	if enabled then
		-- Track which addon called it (check call stack)
		local caller = debugstack(2, 1, 0)
		if caller:find("cfItemColors/") then
			stats.cfItemColors.calls = stats.cfItemColors.calls + 1
			stats.cfItemColors.totalTime = stats.cfItemColors.totalTime + elapsed
		elseif caller:find("cfItemColorsSimple/") then
			stats.cfItemColorsSimple.calls = stats.cfItemColorsSimple.calls + 1
			stats.cfItemColorsSimple.totalTime = stats.cfItemColorsSimple.totalTime + elapsed
		end
	end

	return unpack(results)
end
GetItemInfo = TrackedGetItemInfo

local function PrintStats()
	print("|cff00ff00=== cfItemColors Performance Comparison ===|r")
	print(string.rep("-", 60))

	for _, stat in pairs(stats) do
		if stat.calls > 0 then
			print(string.format("|cffFFFF00%s|r", stat.name))
			print(string.format("  API Calls: %d", stat.calls))
			print(string.format("  Total Time: %.2f ms", stat.totalTime))
			print(string.format("  Avg Time: %.4f ms per call", stat.totalTime / stat.calls))
			print("")
		end
	end

	if stats.cfItemColors.calls > 0 and stats.cfItemColorsSimple.calls > 0 then
		local ratio = stats.cfItemColorsSimple.calls / stats.cfItemColors.calls
		print(string.format("|cffFF8800Simple made %.2fx more API calls|r", ratio))

		local timeRatio = stats.cfItemColorsSimple.totalTime / stats.cfItemColors.totalTime
		print(string.format("|cffFF8800Simple took %.2fx more time|r", timeRatio))
	end

	print("|cff888888Note: Open bags, character sheet, inspect, merchant, etc.|r")
	print("|cff888888to generate activity for measurement.|r")
end

local function ResetStats()
	for _, stat in pairs(stats) do
		stat.calls = 0
		stat.totalTime = 0
	end
	print("|cff00ff00Performance stats reset|r")
end

SLASH_CFPERF1 = "/cfperf"
SlashCmdList["CFPERF"] = function(msg)
	msg = msg:lower()

	if msg == "start" then
		enabled = true
		ResetStats()
		print("|cff00ff00Performance tracking started|r")
		print("|cff888888Now open bags, bank, character, inspect, etc.|r")
	elseif msg == "stop" then
		enabled = false
		PrintStats()
	elseif msg == "reset" then
		ResetStats()
	elseif msg == "clearcache" then
		-- Clear cfItemColors cache
		if cfItemColors then
			cfItemColors.buttonQualityStateCache = {}
			setmetatable(cfItemColors.buttonQualityStateCache, {__mode = "k"})
			print("|cff00ff00cfItemColors cache cleared|r")
		else
			print("|cffFF0000cfItemColors not loaded|r")
		end
	else
		print("|cffFF0000Usage:|r")
		print("  /cfperf start      - Start tracking")
		print("  /cfperf stop       - Stop and show results")
		print("  /cfperf reset      - Reset counters")
		print("  /cfperf clearcache - Clear cfItemColors cache")
	end
end

print("|cff00ff00cfItemColors Performance Test loaded|r")
print("|cff888888Type /cfperf start to begin tracking|r")
