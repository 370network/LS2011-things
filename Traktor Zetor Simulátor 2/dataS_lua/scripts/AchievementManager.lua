AchievementManager = {}
source("dataS/scripts/AchievementMessage.lua")
local AchievementManager_mt = Class(AchievementManager)
function AchievementManager:new(customMt)
  if customMt == nil then
    customMt = AchievementManager_mt
  end
  local self = {}
  setmetatable(self, customMt)
  self.achievementList = {}
  self.achievementListByName = {}
  self.achievementPlates = nil
  self.numberOfAchievements = 0
  self.numberOfUnlockedAchievements = 0
  self.achievementsValid = false
  self.achievementMessage = AchievementMessage:new()
  self:loadAchievements()
  return self
end
function AchievementManager:loadAchievements()
  local xmlFile = loadXMLFile("achievementsXML", "dataS/achievements.xml")
  self.numberOfAchievements = 0
  local eof = false
  local i = 0
  repeat
    local baseXMLName = string.format("achievements.achievement(%d)", i)
    local id = getXMLString(xmlFile, baseXMLName .. "#id")
    local idName = getXMLString(xmlFile, baseXMLName .. "#idName")
    local score = getXMLInt(xmlFile, baseXMLName .. "#score")
    local targetScore = getXMLInt(xmlFile, baseXMLName .. "#targetScore")
    local showScore = getXMLBool(xmlFile, baseXMLName .. "#showScore")
    local imageFilename = getXMLString(xmlFile, baseXMLName .. "#imageFilename")
    if id ~= nil and idName ~= nil then
      local name = g_i18n:getText("A_Name_" .. idName)
      local description = g_i18n:getText("A_Desc_" .. idName)
      self:addAchievement(id, idName, name, description, score, targetScore, showScore, imageFilename)
    else
      eof = true
    end
    i = i + 1
  until eof
  delete(xmlFile)
end
function AchievementManager:addAchievement(id, idName, name, description, score, targetScore, showScore, imageFilename)
  local achievement = {}
  achievement.id = tostring(id)
  achievement.idName = idName
  achievement.name = name
  achievement.description = description
  achievement.score = score
  achievement.targetScore = targetScore
  achievement.showScore = showScore
  achievement.imageFilename = imageFilename
  achievement.unlocked = false
  self.achievementList[id] = achievement
  self.achievementListByName[idName] = achievement
  self.numberOfAchievements = self.numberOfAchievements + 1
end
function AchievementManager:loadAchievementsState()
  self.numberOfUnlockedAchievements = 0
  for _, achievement in pairs(self.achievementList) do
    achievement.unlocked = getAchievement(tonumber(achievement.id))
    if achievement.unlocked then
      self.numberOfUnlockedAchievements = self.numberOfUnlockedAchievements + 1
    end
  end
  self.achievementsValid = true
end
function AchievementManager:update(dt)
  self.achievementMessage:update(dt)
  if not self.achievementsValid and areAchievementsAvailable() then
    self:loadAchievementsState()
  end
  if g_currentMission ~= nil and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and not g_currentMission.missionDynamicInfo.isMultiplayer then
    self:handleStandardScoreAchievement("Money1Million", g_currentMission.missionStats.money)
    self:handleStandardScoreAchievement("Money5Million", g_currentMission.missionStats.money)
    self:handleStandardScoreAchievement("Money10Million", g_currentMission.missionStats.money)
    self:handleStandardScoreAchievement("TraveledDistance100", g_currentMission.missionStats.traveledDistanceTotal)
    self:handleStandardScoreAchievement("TraveledDistance1000", g_currentMission.missionStats.traveledDistanceTotal)
    self:handleStandardScoreAchievement("PlayTime10", math.floor(g_currentMission.missionStats.playTime / 60 + 1.0E-4))
    self:handleStandardScoreAchievement("ThreshedHectares10", g_currentMission.missionStats.hectaresThreshedTotal)
    self:handleStandardScoreAchievement("ThreshedHectares100", g_currentMission.missionStats.hectaresThreshedTotal)
    self:handleStandardScoreAchievement("SeededHectares10", g_currentMission.missionStats.hectaresSeededTotal)
    self:handleStandardScoreAchievement("SeededHectares100", g_currentMission.missionStats.hectaresSeededTotal)
    self:handleStandardScoreAchievement("DeliveredBottles50", g_currentMission.deliveredBottles)
    self:handleStandardScoreAchievement("DeliveredBottles100", g_currentMission.deliveredBottles)
  end
end
function AchievementManager:handleStandardScoreAchievement(idName, currentScore)
  local currentAchievement = self.achievementListByName[idName]
  if not currentAchievement.unlocked then
    currentAchievement.score = currentScore
    if currentAchievement.score >= currentAchievement.targetScore then
      currentAchievement.unlocked = true
      unlockAchievement(tonumber(currentAchievement.id))
      if not hasNativeAchievementGUI() then
        self.achievementMessage:showMessage(currentAchievement, 5000)
      end
      self:updatePlates()
      local oldPercentage = self.numberOfUnlockedAchievements / self.numberOfAchievements * 100
      self.numberOfUnlockedAchievements = self.numberOfUnlockedAchievements + 1
      local newPercentage = self.numberOfUnlockedAchievements / self.numberOfAchievements * 100
      if oldPercentage < 50 and 50 <= newPercentage then
        g_currentMission.inGameMessage:showMessage(g_i18n:getText("unlockedOldtimerTitle"), g_i18n:getText("unlockedOldtimerMessage"), 12000, false)
        for i = 1, table.getn(StoreItemsUtil.storeItems) do
          if StoreItemsUtil.storeItems[i].achievementsNeeded == 50 then
            g_shopScreen:updateOwnedVehicles()
            g_shopScreen:onBuyClick(StoreItemsUtil.storeItems[i], true)
          end
        end
      end
      if oldPercentage < 100 and newPercentage == 100 then
        g_currentMission.inGameMessage:showMessage(g_i18n:getText("gotAllAchievementsTitle"), g_i18n:getText("gotAllAchievementsMessage"), 9000, false)
        g_currentMission:addSharedMoney(25000000)
        for i = 1, table.getn(StoreItemsUtil.storeItems) do
          if StoreItemsUtil.storeItems[i].achievementsNeeded == 100 then
            g_shopScreen:updateOwnedVehicles()
            g_shopScreen:onBuyClick(StoreItemsUtil.storeItems[i], true)
          end
        end
      end
    end
  end
end
function AchievementManager:render()
  self.achievementMessage:render()
end
function AchievementManager:updatePlates()
  if self.achievementPlates ~= nil then
    local achievementsParentId = getChild(self.achievementPlates, "achievements")
    if achievementsParentId ~= 0 then
      local numChildren = getNumOfChildren(achievementsParentId)
      for i = 0, numChildren - 1 do
        local nodeId = getChildAt(achievementsParentId, i)
        local achievementId = getUserAttribute(nodeId, "id")
        if achievementId ~= nil and self.achievementList[achievementId] ~= nil and self.achievementList[achievementId].unlocked then
          setVisibility(nodeId, true)
        else
          setVisibility(nodeId, false)
        end
      end
    end
  end
end
