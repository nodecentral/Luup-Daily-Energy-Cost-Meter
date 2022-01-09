module("L_ECMDaily1", package.seeall)
        
local PV = "0.4" -- plugin version number
local COM_SID = "urn:nodecentral-net:serviceId:ECMDaily1"
--local ENERGY_SID = "urn:micasaverde-com:serviceId:EnergyMetering1"

function log(msg) 
	luup.log("ECMD: " .. msg)
end
        
local function round(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function GoGetKwH(lul_device)
	local EnergyMeter = luup.variable_get(COM_SID, "Energy Meter", lul_device)
	if (EnergyMeter == "") then 
		luup.variable_set(COM_SID, "PluginStatus", "ERROR: [Energy Meter] Missing! 3/4", lul_device)
		luup.variable_set(COM_SID, "Icon", 2, lul_device)
		log("ERROR: [Energy Meter] value missing")
	elseif string.find(EnergyMeter, "http") then 
		luup.variable_set(COM_SID, "PluginStatus", "[Energy Meter] Registered! 4/4", lul_device)
		luup.variable_set(COM_SID, "Icon", 1, lul_device)
		log("SUCCESS: [Energy Meter] value registered")
		local status, KwHVal, code = luup.inet.wget(EnergyMeter)
		log("GoGetKwH returned = " .. KwHVal .. " | Code = " .. code)
		return KwHVal
	elseif string.match(EnergyMeter, "D%+") then 
		luup.variable_set(COM_SID, "PluginStatus", "[Energy Meter] Registered! 4/4", lul_device)
		luup.variable_set(COM_SID, "Icon", 1, lul_device)
		log("SUCCESS: [Energy Meter] value registered")
		KwHVal = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1", "KwH", EnergyMeter)
		log("GoGetKwH returned = " .. KwHVal)
		--local KwHVal = tostring(KwHVal)
		--luup.variable_set(COM_SID ,"KwHlive", KwHVal , lul_device)
		return KwHVal
	end
end

function readVariables(lul_device)
	local data = {}
		
	data.ActualKwH = luup.variable_get(COM_SID, "KwH", lul_device)
	data.CostKwH = luup.variable_get(COM_SID, "Cost per KwH", lul_device)
	data.CostUnit = luup.variable_get(COM_SID, "Cost Unit", lul_device)
	data.CostDayCharge = luup.variable_get(COM_SID, "Cost per Day", lul_device) or 0
	
	--Daily Variables
	data.DayStartKwH = luup.variable_get(COM_SID, "Day Start KwH", lul_device)
	data.DaySoFarKwH = luup.variable_get(COM_SID, "Day So Far KwH", lul_device)
	
	data.DayStartDate = luup.variable_get(COM_SID, "Day Start Date", lul_device)
	data.DaySoFarDate = luup.variable_get(COM_SID, "Day So Far Date", lul_device)
	
	data.DaySoFarCost = luup.variable_get(COM_SID, "Day So Far Cost", lul_device)
	data.DayEndCost = luup.variable_get(COM_SID, "Day End Cost", lul_device)
	
	return data
		
end


function updateDaySoFar(lul_device) 
	
	log("UPDATE SO FAR TODAY REQUESTED - UPDATE DAY DATA" )
	local data = readVariables(lul_device) 
	
	local DaySoFarDate = os.time()
	
	local DayStartKwH = data.DayStartKwH
	
	local DaySoFarKwH = GoGetKwH(lul_device)
	local DaySoFarKwHUsageCalc = tonumber(DaySoFarKwH) - tonumber(DayStartKwH)
	local DaySoFarKwHUsage = round(DaySoFarKwHUsageCalc,2)
	
	log("data.CostKwH = " .. data.CostKwH)
	
	--local DaySoFarCostCalc = (tonumber(DaySoFarKwH)- DayStartKwH) * data.CostKwH
	local DaySoFarCostCalc = (DaySoFarKwHUsageCalc * data.CostKwH) + data.CostDayCharge
	local DaySoFarCost = round(DaySoFarCostCalc,2)
	
	log("DayStartKwH = " .. DayStartKwH)
	log("DaySoFarKwH = " .. DaySoFarKwH)
	log("DaySoFarKwHUsage = " .. DaySoFarKwHUsage)
	
	luup.variable_set(COM_SID,"Day So Far Date", DaySoFarDate , lul_device)
	luup.variable_set(COM_SID,"Day So Far KwH", DaySoFarKwH , lul_device)
	luup.variable_set(COM_SID,"Day So Far KwH Usage", DaySoFarKwHUsage , lul_device)
	luup.variable_set(COM_SID,"Day So Far Cost", DaySoFarCost , lul_device)

end

local function logUsageCost(kwh, cost)
	local filelog = "/www/DailyEnergyCost.txt"
	local outf = io.open(filelog, "a")
	outf:write(os.date('%Y-%m-%d %H:%M:%S') .. ", " .. kwh .. ", " ..cost .. ", ")
	--local filesize = outf:seek("end")
	--outf:write(filesize)	
	outf:write("\n")		
	outf:close()
end
		
function startNewDay(lul_device) 
	
	log("START NEW DAY REQUESTED - RESET ALL DAY DATA" )
	local data = readVariables(lul_device)
	
	local YesterDayStartKwH = data.DayStartKwH
	local NewDayStartKwH = GoGetKwH(lul_device)
	local YesterDayKwHUsageCalc = tonumber(NewDayStartKwH) - tonumber(YesterDayStartKwH)
	local YesterDayKwHUsage = round(YesterDayKwHUsageCalc,2)
	
	local YesterDayStartDate = data.DayStartDate
	local NewDayStartDate = os.time()
	local YesterDayDuration = tonumber(NewDayStartDate) - tonumber(YesterDayStartDate)
	
	local YesterDayEndCostCalc = YesterDayKwHUsage * data.CostKwH
	local YesterDayEndCost = round(YesterDayEndCostCalc,2)
	
	log("YesterDayStartKwH = " .. YesterDayStartKwH)
	log("NewDayStartKwH = " .. NewDayStartKwH)
	log("YesterDayKwHUsage = " .. YesterDayKwHUsage)
	
	log("YesterDayStartDate = " .. YesterDayStartDate)
	log("NewDayStartDate = " .. NewDayStartDate)
	log("YesterDayDuration = " .. YesterDayDuration)
	
	log("YesterDayCost = " .. YesterDayEndCost)
	
	luup.variable_set(COM_SID,"Yesterday KwH Usage", YesterDayKwHUsage , lul_device)
	luup.variable_set(COM_SID,"Yesterday KwH Cost", YesterDayEndCost , lul_device)
	luup.variable_set(COM_SID,"Yesterday Duration", YesterDayDuration , lul_device)
	luup.variable_set(COM_SID,"Yesterday KwH End", NewDayStartKwH , lul_device)
	luup.variable_set(COM_SID,"Day End Cost", YesterDayEndCost , lul_device)
	
	luup.variable_set(COM_SID,"Day Start Date", NewDayStartDate , lul_device)
	luup.variable_set(COM_SID,"Day Start KwH", NewDayStartKwH , lul_device)
	
	luup.variable_set(COM_SID,"Day So Far Cost", "0.0" , lul_device)
	
	logUsageCost(YesterDayKwHUsage, YesterDayEndCost)
end

function ResetDate(lul_device)
	luup.variable_set(COM_SID,"Day Start Date", 0 , lul_device)
end
		
function checkSetUp(lul_device)
	log("Checking ECMDaily plugin configuration... DevNo = " ..lul_device)
	
	local CostperKwH = luup.variable_get(COM_SID, "Cost per KwH", lul_device)
	log("CostperKwH = " ..tostring(CostperKwH))
	
	if CostperKwH == "0.0" or CostperKwH == 0 or CostperKwH == "0" then 
		luup.variable_set(COM_SID, "PluginStatus", "ERROR: [Cost per KwH] Missing! 2/4", lul_device)
		luup.variable_set(COM_SID, "Icon", 2, lul_device)
		log("ERROR: [Cost per KwH] value missing")
	else
		luup.variable_set(COM_SID, "PluginStatus", "[Cost per KwH] registered! 3/4", lul_device)
		luup.variable_set(COM_SID, "Icon", 1, lul_device)
		log("SUCCESS: [Cost per KwH] is registered..")
		log("checkSetUp = Now lets go get a [KwH] reading..") 
		local KwHPopulation = GoGetKwH(lul_device)
		log("checkSetUp reading  = " ..KwHPopulation)
		luup.variable_set(COM_SID, "KwH", KwHPopulation, lul_device)
		
		--luup.call_delay("GoGetKwH", 60)
		--luup.call_timer("ecmdailyKwHUpdates", 1, "1m", "")
		--luup.call_timer("ecmdailyDailyUpdates", 1, "23:59", "1,2,3,4,5,6,7", "")
		
		--local data = readVariables(lul_device)
		
		--log("Read data settings")
	end
end

local function populateFixedVariables(lul_device)
	log("Setting up plugins variables for ... DevNo = " ..lul_device)
	luup.variable_set(COM_SID, "PluginStatus", "Plugin variables being set up 2/4", lul_device)
	
	local EnergyMeter = luup.variable_get(COM_SID, "Energy Meter", lul_device)
		if (EnergyMeter == nil) then luup.variable_set(COM_SID, "Energy Meter", "" , lul_device) end
	
	local LiveKwH = luup.variable_get(COM_SID, "KwH", lul_device)
		if (LiveKwH == nil) then luup.variable_set(COM_SID, "KwH", "0.0" , lul_device) end
	
	local KwHCost = luup.variable_get(COM_SID, "Cost per KwH", lul_device)
		if (KwHCost == nil) then luup.variable_set(COM_SID, "Cost per KwH", "0.0" , lul_device) end
	local Currency = luup.variable_get(COM_SID, "Cost Unit", lul_device)
		if (Currency == nil) then luup.variable_set(COM_SID, "Cost Unit", "£" , lul_device) end
	local DayCharge = luup.variable_get(COM_SID, "Day Charge", lul_device)
		if (DayCharge == nil) then luup.variable_set(COM_SID, "Day Charge", "0.0" , lul_device) end
	
	-- Daily Fixed Variables
	local DayKwH = luup.variable_get(COM_SID, "Day Start KwH", lul_device)
		if (DayKwH == nil) then luup.variable_set(COM_SID, "Day Start KwH", "0.0" , lul_device) end
	local DayStartDate = luup.variable_get(COM_SID, "Day Start Date", lul_device)
		if (DayStartDate == nil) then luup.variable_set(COM_SID, "Day Start Date", 0 , lul_device) end
		
	local DayEndCost = luup.variable_get(COM_SID, "Day End Cost", lul_device)
		if (DayEndCost == nil) then luup.variable_set(COM_SID, "Day End Cost", "0.0" , lul_device) end
	local SoFarTodayCost = luup.variable_get(COM_SID, "Day So Far Cost", lul_device)
		if (SoFarTodayCost) == nil then luup.variable_set(COM_SID,"Day So Far Cost", "0.0" , lul_device) end
		
	checkSetUp(lul_device)
	
end

function ECMDailyStartUp(lul_device)
	log("Setting up plugin.... DevNo = " ..lul_device)
	luup.variable_set(COM_SID, "Icon", 0, lul_device)
	luup.variable_set(COM_SID, "PluginVersion", PV, lul_device)
	luup.variable_set(COM_SID, "Debug", true, lul_device)
	luup.variable_set(COM_SID, "PluginStatus", "Plugin being installed 1/4 ", lul_device)
	populateFixedVariables(lul_device)
end