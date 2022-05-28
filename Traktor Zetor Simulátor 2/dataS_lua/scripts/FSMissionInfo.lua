FSMissionInfo = {}
local FSMissionInfo_mt = Class(FSMissionInfo, MissionInfo)
FSMissionInfo.UNPLAYED = 0
FSMissionInfo.FAILED = 1
FSMissionInfo.COMPLETED = 2
function FSMissionInfo:new(baseDirectory, customEnvironment, customMt)
  if customMt == nil then
    customMt = FSMissionInfo_mt
  end
  local self = FSMissionInfo:superClass():new(baseDirectory, customEnvironment, customMt)
  self.isTutorial = false
  self.missingEquipment = {}
  self.newlyUnlocked = false
  self.briefingImageBasePath = ""
  self.briefingText = {}
  self.state = FSMissionInfo.UNPLAYED
  return self
end
function FSMissionInfo:loadDefaults()
  FSMissionInfo:superClass().loadDefaults(self)
  self.difficulty = 1
  self.fuelUsage = 0
  self.seedUsage = 0
  self.traveledDistance = 0
  self.hectaresSeeded = 0
  self.seedingDuration = 0
  self.hectaresThreshed = 0
  self.threshingDuration = 0
  self.farmSiloAmounts = {}
  self.fruitPrices = {}
  self.yesterdaysFruitPrices = {}
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    local name = FruitUtil.fruitIndexToDesc[i].name
    self.farmSiloAmounts[name] = 5000
    self.fruitPrices[name] = g_startPrices[i]
    self.yesterdaysFruitPrices[name] = g_startPrices[i]
  end
  self.farmSiloAmounts.grass = 0
  self.farmSiloAmounts.dryGrass = 0
  self.farmSiloAmounts.chaff = 0
  self.farmSiloAmounts.manure = 0
  self.farmSiloAmounts.liquidManure = 0
  self.revenue = 0
  self.expenses = 0
  self.playTime = 0
  self.money = 1000
  if not isServer then
    self.money = 0
  end
  self.numCows = 0
  self.milkProductionScale = 1
  self.milkPriceScale = 1
  self.manureProductionScale = 1
  self.dayTime = 400
  self.timeUntilNextRain = 0
  self.timeUntilRainAfterNext = 0
  self.rainTime = 0
  self.nextRainDuration = 0
  self.nextRainType = 0
  self.rainTypeAfterNext = 0
  self.nextRainValid = false
  self.currentDay = 1
  self.foundBottleCount = 0
  self.deliveredBottles = 0
  self.foundBottles = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  self.reputation = 0
  self.foundInfoTriggers = "00000000000000000000"
end
function FSMissionInfo:loadFromXML(xmlFile, key)
  if not FSMissionInfo:superClass().loadFromXML(self, xmlFile, key) then
    return false
  end
  local i18n = g_i18n
  if self.customEnvironment ~= nil then
    i18n = _G[self.customEnvironment].g_i18n
  end
  self.briefingImageBasePath = Utils.getXMLI18NValue(xmlFile, key, getXMLString, "briefing", "", self.customEnvironment, true)
  self.briefingImageBasePath = Utils.getFilename(self.briefingImageBasePath, self.baseDirectory)
  for i = 1, 3 do
    self.briefingText[i] = Utils.getXMLI18NValue(xmlFile, key, getXMLString, "briefingText" .. i, "", self.customEnvironment, true)
  end
  return true
end
