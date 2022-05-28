MissionStats = {}
source("dataS/scripts/environment/EnvironmentTmpEvent.lua")
MissionStats.alpha = 1
MissionStats.alphaInc = 0.05
local MissionStats_mt = Class(MissionStats)
function MissionStats:new()
  local self = {}
  setmetatable(self, MissionStats_mt)
  return self
end
function MissionStats:setMissionInfo(missionInfo, missionDynamicInfo)
  self.timeScale = g_settingsTimeScale
  self.difficulty = missionInfo.difficulty
  if self.difficulty == nil then
    self.difficulty = 3
  end
  self.money = missionInfo.money
  self.fuelUsageTotal = missionInfo.fuelUsage
  self.fuelUsageSession = 0
  self.seedUsageTotal = missionInfo.seedUsage
  self.seedUsageSession = 0
  self.traveledDistanceTotal = missionInfo.traveledDistance
  self.traveledDistanceSession = 0
  self.hectaresSeededTotal = missionInfo.hectaresSeeded
  self.hectaresSeededSession = 0
  self.seedingDurationTotal = missionInfo.seedingDuration
  self.seedingDurationSession = 0
  self.hectaresThreshedTotal = missionInfo.hectaresThreshed
  self.hectaresThreshedSession = 0
  self.threshingDurationTotal = missionInfo.threshingDuration
  self.threshingDurationSession = 0
  self.farmSiloAmounts = {}
  for fillTypeName, amount in pairs(missionInfo.farmSiloAmounts) do
    local fillType = Fillable.fillTypeNameToInt[fillTypeName]
    if fillType ~= nil then
      self.farmSiloAmounts[fillType] = amount
    end
  end
  self.revenueTotal = missionInfo.revenue
  self.revenueSession = 0
  self.expensesTotal = missionInfo.expenses
  self.expensesSession = 0
  self.playTime = missionInfo.playTime
  self.playTimeSession = 0
end
function MissionStats:update(dt)
  local dtMinutes = dt / 60000
  self.playTime = self.playTime + dtMinutes
  self.playTimeSession = self.playTimeSession + dtMinutes
end
function MissionStats:setEnvironmentTemperature(pdaWeatherTemperaturesDay, pdaWeatherTemperaturesNight)
  self.pdaWeatherTemperaturesDay = pdaWeatherTemperaturesDay
  self.pdaWeatherTemperaturesNight = pdaWeatherTemperaturesNight
end
