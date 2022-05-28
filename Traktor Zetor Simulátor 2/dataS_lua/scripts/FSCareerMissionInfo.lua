FSCareerMissionInfo = {}
local FSCareerMissionInfo_mt = Class(FSCareerMissionInfo, FSMissionInfo)
function FSCareerMissionInfo:new(baseDirectory, customEnvironment, savegameIndex, customMt)
  if customMt == nil then
    customMt = FSCareerMissionInfo_mt
  end
  local self = FSCareerMissionInfo:superClass():new(baseDirectory, customEnvironment, customMt)
  self.savegameIndex = savegameIndex
  self.savegameDirectory = self:getSavegameDirectory(self.savegameIndex)
  self.autoBackupIndex = 1
  return self
end
function FSCareerMissionInfo:delete()
  if self.xmlFile ~= nil then
    delete(self.xmlFile)
  end
end
function FSCareerMissionInfo:loadDefaults()
  FSCareerMissionInfo:superClass().loadDefaults(self)
  self.isValid = false
  self.saveDate = "--.--.--"
  self.resetVehicles = false
  self.vehiclesXML = self.savegameDirectory .. "/vehicles.xml"
  self.densityMapRevision = -1
  self.numCows = 0
  self.mapId = nil
  self.briefingImagePrefix = nil
  self.briefingTextPrefix = nil
  self.scriptFilename = nil
  self.scriptClass = nil
  self.autoBackupIndex = 1
end
function FSCareerMissionInfo:loadFromXML(xmlFile, key)
  if self.savegameIndex < 1 then
    return false
  end
  self.xmlKey = key
  self.xmlFile = xmlFile
  self.isValid = getXMLBool(xmlFile, key .. "#valid")
  if self.isValid == nil then
    return false
  end
  self.densityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. "#densityMapRevision"), -1)
  self.resetVehicles = Utils.getNoNil(getXMLBool(xmlFile, key .. "#resetVehicles"), false)
  self.foundBottleCount = 0
  self.deliveredBottles = 0
  self.foundBottles = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  self.reputation = 0
  self.foundInfoTriggers = "00000000000000000000"
  if self.isValid then
    local mapId = getXMLString(xmlFile, key .. "#mapId")
    if mapId == nil then
      return false
    end
    if not self:setMapId(mapId) then
      return false
    end
    self.difficulty = Utils.getNoNil(getXMLInt(xmlFile, key .. "#difficulty"), 1)
    self.autoBackupIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#autoBackupIndex"), self.autoBackupIndex)
    self.fuelUsage = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#fuelUsage"), 0)
    self.seedUsage = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#seedUsage"), 0)
    self.traveledDistance = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#traveledDistance"), 0)
    self.hectaresSeeded = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#hectaresSeeded"), 0)
    self.seedingDuration = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#seedingDuration"), 0)
    self.hectaresThreshed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#hectaresThreshed"), 0)
    self.farmSiloAmounts = {}
    local numSiloAmounts = Utils.getNoNil(getXMLInt(xmlFile, key .. ".farmSiloAmounts#count"), 0)
    for i = 1, numSiloAmounts do
      local siloAmountKey = key .. string.format(".farmSiloAmounts.farmSiloAmount(%d)", i - 1)
      local fillType = getXMLString(xmlFile, siloAmountKey .. "#fillType")
      local amount = getXMLFloat(xmlFile, siloAmountKey .. "#amount")
      if fillType ~= nil and amount ~= nil then
        self.farmSiloAmounts[fillType] = amount
      end
    end
    self.fruitPrices = {}
    self.yesterdaysFruitPrices = {}
    local numFruitPrices = Utils.getNoNil(getXMLInt(xmlFile, key .. ".fruitPrices#count"), 0)
    for i = 1, numFruitPrices do
      local fruitPriceKey = key .. string.format(".fruitPrices.fruitPrice(%d)", i - 1)
      local fruitType = getXMLString(xmlFile, fruitPriceKey .. "#fruitType")
      local price = getXMLFloat(xmlFile, fruitPriceKey .. "#price")
      local yesterdaysPrice = getXMLFloat(xmlFile, fruitPriceKey .. "#yesterdaysPrice")
      if yesterdaysPrice == nil then
        yesterdaysPrice = price
      end
      if fruitType ~= nil and price ~= nil then
        self.fruitPrices[fruitType] = price
        self.yesterdaysFruitPrices[fruitType] = yesterdaysPrice
      end
    end
    self.threshingDuration = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#threshingDuration"), 0)
    self.revenue = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#revenue"), 0)
    self.expenses = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#expenses"), 0)
    self.playTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#playTime"), 0)
    local moneyStr = getXMLString(xmlFile, key .. "#money")
    self.money = Utils.getNoNil(tonumber(moneyStr), CareerScreen.defaultMoney)
    self.numCows = Utils.getNoNil(getXMLInt(xmlFile, key .. "#numCows"), 0)
    self.milkProductionScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#milkProductionScale"), 1)
    self.milkPriceScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#milkPriceScale"), 1)
    self.manureProductionScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#manureProductionScale"), 1)
    self.dayTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#dayTime"), 400)
    self.timeUntilNextRain = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#timeUntilNextRain"), 0)
    self.timeUntilRainAfterNext = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#timeUntilRainAfterNext"), 0)
    self.rainTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#rainTime"), 0)
    self.nextRainDuration = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#nextRainDuration"), 0)
    self.nextRainType = Utils.getNoNil(getXMLInt(xmlFile, key .. "#nextRainType"), 0)
    self.rainTypeAfterNext = Utils.getNoNil(getXMLInt(xmlFile, key .. "#rainTypeAfterNext"), 0)
    self.nextRainValid = Utils.getNoNil(getXMLBool(xmlFile, key .. "#nextRainValid"), false)
    self.currentDay = Utils.getNoNil(getXMLInt(xmlFile, key .. "#currentDay"), 1)
    self.saveDate = Utils.getNoNil(getXMLString(xmlFile, key .. "#saveDate"), "--.--.--")
    self.foundBottleCount = Utils.getNoNil(getXMLInt(xmlFile, key .. "#foundBottleCount"), 0)
    self.deliveredBottles = Utils.getNoNil(getXMLInt(xmlFile, key .. "#deliveredBottles"), 0)
    self.foundBottles = Utils.getNoNil(getXMLString(xmlFile, key .. "#foundBottles"), self.foundBottles)
    self.reputation = Utils.getNoNil(getXMLInt(xmlFile, key .. "#reputation"), 0)
    self.foundInfoTriggers = Utils.getNoNil(getXMLString(xmlFile, key .. "#foundInfoTriggers"), "00000000000000000000")
  end
  return true
end
function FSCareerMissionInfo:saveToXML()
  if self.xmlKey ~= nil then
    setXMLBool(self.xmlFile, self.xmlKey .. "#valid", self.isValid)
    if self.isValid then
      setXMLInt(self.xmlFile, self.xmlKey .. "#densityMapRevision", self.densityMapRevision)
      setXMLBool(self.xmlFile, self.xmlKey .. "#resetVehicles", self.resetVehicles)
      setXMLString(self.xmlFile, self.xmlKey .. "#mapId", self.mapId)
      setXMLInt(self.xmlFile, self.xmlKey .. "#difficulty", self.difficulty)
      setXMLInt(self.xmlFile, self.xmlKey .. "#autoBackupIndex", self.autoBackupIndex)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#fuelUsage", self.fuelUsage)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#seedUsage", self.seedUsage)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#traveledDistance", self.traveledDistance)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#hectaresSeeded", self.hectaresSeeded)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#seedingDuration", self.seedingDuration)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#hectaresThreshed", self.hectaresThreshed)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#threshingDuration", self.threshingDuration)
      local numSiloAmounts = 0
      for fillType, amount in pairs(self.farmSiloAmounts) do
        local siloAmountKey = self.xmlKey .. string.format(".farmSiloAmounts.farmSiloAmount(%d)", numSiloAmounts)
        setXMLString(self.xmlFile, siloAmountKey .. "#fillType", fillType)
        setXMLFloat(self.xmlFile, siloAmountKey .. "#amount", amount)
        numSiloAmounts = numSiloAmounts + 1
      end
      setXMLInt(self.xmlFile, self.xmlKey .. ".farmSiloAmounts#count", numSiloAmounts)
      local numFruitPrices = 0
      for fruitType, price in pairs(self.fruitPrices) do
        local fruitPriceKey = self.xmlKey .. string.format(".fruitPrices.fruitPrice(%d)", numFruitPrices)
        local yesterdaysPrice = Utils.getNoNil(self.yesterdaysFruitPrices[fruitType], price)
        setXMLString(self.xmlFile, fruitPriceKey .. "#fruitType", fruitType)
        setXMLFloat(self.xmlFile, fruitPriceKey .. "#price", price)
        setXMLFloat(self.xmlFile, fruitPriceKey .. "#yesterdaysPrice", yesterdaysPrice)
        numFruitPrices = numFruitPrices + 1
      end
      setXMLInt(self.xmlFile, self.xmlKey .. ".fruitPrices#count", numFruitPrices)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#revenue", self.revenue)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#expenses", self.expenses)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#playTime", self.playTime)
      local moneyStr = tostring(math.floor(self.money + 1.0E-4))
      setXMLString(self.xmlFile, self.xmlKey .. "#money", moneyStr)
      setXMLInt(self.xmlFile, self.xmlKey .. "#numCows", self.numCows)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#milkProductionScale", self.milkProductionScale)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#milkPriceScale", self.milkPriceScale)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#manureProductionScale", self.manureProductionScale)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#dayTime", self.dayTime)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#timeUntilNextRain", self.timeUntilNextRain)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#timeUntilRainAfterNext", self.timeUntilRainAfterNext)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#rainTime", self.rainTime)
      setXMLFloat(self.xmlFile, self.xmlKey .. "#nextRainDuration", self.nextRainDuration)
      setXMLInt(self.xmlFile, self.xmlKey .. "#nextRainType", self.nextRainType)
      setXMLInt(self.xmlFile, self.xmlKey .. "#rainTypeAfterNext", self.rainTypeAfterNext)
      setXMLBool(self.xmlFile, self.xmlKey .. "#nextRainValid", self.nextRainValid)
      setXMLInt(self.xmlFile, self.xmlKey .. "#currentDay", self.currentDay)
      setXMLString(self.xmlFile, self.xmlKey .. "#saveDate", self.saveDate)
      setXMLInt(self.xmlFile, self.xmlKey .. "#foundBottleCount", self.foundBottleCount)
      setXMLInt(self.xmlFile, self.xmlKey .. "#deliveredBottles", self.deliveredBottles)
      setXMLString(self.xmlFile, self.xmlKey .. "#foundBottles", self.foundBottles)
      setXMLInt(self.xmlFile, self.xmlKey .. "#reputation", self.reputation)
      setXMLString(self.xmlFile, self.xmlKey .. "#foundInfoTriggers", self.foundInfoTriggers)
      local vehiclesFile = io.open(self.vehiclesXML, "w")
      if vehiclesFile ~= nil then
        vehiclesFile:write([[
<?xml version="1.0" encoding="utf-8" standalone="no" ?>
<careerVehicles>
]])
        if g_currentMission ~= nil then
          g_currentMission:saveVehicles(vehiclesFile)
        end
        vehiclesFile:write("</careerVehicles>")
        vehiclesFile:close()
      end
    end
    saveXMLFile(self.xmlFile)
  end
end
function FSCareerMissionInfo:loadFromMission(mission)
  self.difficulty = mission.missionStats.difficulty
  self.fuelUsage = mission.missionStats.fuelUsageTotal
  self.seedUsage = mission.missionStats.seedUsageTotal
  self.traveledDistance = mission.missionStats.traveledDistanceTotal
  self.hectaresSeeded = mission.missionStats.hectaresSeededTotal
  self.seedingDuration = mission.missionStats.seedingDurationTotal
  self.hectaresThreshed = mission.missionStats.hectaresThreshedTotal
  self.farmSiloAmounts = {}
  for fillType, amount in pairs(mission.missionStats.farmSiloAmounts) do
    local fillTypeName = Fillable.fillTypeIntToName[fillType]
    self.farmSiloAmounts[fillTypeName] = amount
  end
  self.fruitPrices = {}
  self.yesterdaysFruitPrices = {}
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    local desc = FruitUtil.fruitIndexToDesc[i]
    self.fruitPrices[desc.name] = desc.pricePerLiter
    self.yesterdaysFruitPrices[desc.name] = desc.yesterdaysPrice
  end
  self.threshingDuration = mission.missionStats.threshingDurationTotal
  self.revenue = mission.missionStats.revenueTotal
  self.expenses = mission.missionStats.expensesTotal
  self.playTime = mission.missionStats.playTime
  self.money = mission.missionStats.money
  for i = 2, table.getn(mission.users) do
    self.money = self.money + mission.users[i].money
  end
  self.numCows = AnimalHusbandry.getNumberOfAnimals()
  self.milkProductionScale = mission.milkProductionScale
  self.milkPriceScale = mission.milkPriceScale
  self.manureProductionScale = mission.manureProductionScale
  self.dayTime = mission.environment.dayTime / 60000
  self.timeUntilNextRain = mission.environment.timeUntilNextRain
  self.timeUntilRainAfterNext = mission.environment.timeUntilRainAfterNext
  self.rainTime = mission.environment.rainTime
  self.nextRainDuration = mission.environment.nextRainDuration
  self.nextRainType = mission.environment.nextRainType
  self.rainTypeAfterNext = mission.environment.rainTypeAfterNext
  self.nextRainValid = true
  self.currentDay = mission.environment.currentDay
  self.foundBottleCount = mission.foundBottleCount
  self.deliveredBottles = mission.deliveredBottles
  self.foundBottles = mission.foundBottles
  self.reputation = mission.reputation
  self.foundInfoTriggers = mission.foundInfoTriggers
  if g_languageShort == "de" then
    self.saveDate = os.date("%d.%m.%Y")
  else
    self.saveDate = os.date("%m.%d.%Y")
  end
end
function FSCareerMissionInfo:setResetVehicles(reset)
  self.resetVehicles = reset
  if self.xmlKey ~= nil then
    setXMLBool(self.xmlFile, self.xmlKey .. "#resetVehicles", self.resetVehicles)
    saveXMLFile(self.xmlFile)
  end
end
function FSCareerMissionInfo:getSavegameDirectory(index)
  return getUserProfileAppPath() .. "savegame" .. index
end
function FSCareerMissionInfo:setMapId(mapId)
  self.mapId = mapId
  local map = MapsUtil.getMapById(self.mapId)
  if map == nil then
    return false
  end
  self.map = map
  self.briefingImagePrefix = map.briefingImagePrefix
  self.briefingTextPrefix = map.briefingTextPrefix
  self.scriptFilename = map.scriptFilename
  self.scriptClass = map.className
  self.defaultVehiclesXMLFilename = map.defaultVehiclesXMLFilename
  if map.customEnvironment ~= nil then
    self.useCustomEnvironmentForScript = true
    self.customEnvironment = map.customEnvironment
  else
    self.useCustomEnvironmentForScript = false
    self.customEnvironment = nil
  end
  self.baseDirectory = map.baseDirectory
  local i18n = g_i18n
  if self.customEnvironment ~= nil then
    i18n = _G[self.customEnvironment].g_i18n
  end
  for i = 1, 3 do
    self.briefingText[i] = Utils.getNoNil(i18n:getDescription(self.briefingTextPrefix .. "BriefingText" .. i), "")
  end
  return true
end
