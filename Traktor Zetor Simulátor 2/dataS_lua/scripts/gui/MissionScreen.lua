MissionScreen = {}
local MissionScreen_mt = Class(MissionScreen)
function MissionScreen:new()
  local instance = {}
  setmetatable(instance, MissionScreen_mt)
  instance.selectedIndex = 0
  instance.missions = {}
  instance.missionElements = {}
  return instance
end
function MissionScreen:onStartClick()
  self:startSelectedMission()
end
function MissionScreen:onBackClick()
  g_gui:showGui("MainScreen")
end
function MissionScreen:onClickGame()
end
function MissionScreen:onOpen()
  if self.missions ~= nil then
    for _, mission in pairs(self.missions) do
      self:updateMissionStrings(mission)
    end
  end
end
function MissionScreen:onDoubleClick()
  self:onStartClick()
end
function MissionScreen:onListSelectionChanged(rowIndex)
  self.selectedIndex = rowIndex
end
function MissionScreen:onCreateTextItem(element, args)
  local index = tonumber(args)
  element:setText(g_i18n:getText("Savegame") .. " " .. index)
end
function MissionScreen:onMissionScreenCreated(element)
  self:getMissions()
  self.selectedIndex = 1
  self.list:setSelectedRow(self.selectedIndex)
end
function MissionScreen:onCreateListTemplate(element)
  if self.listTemplate == nil then
    self.listTemplate = element
  end
end
function MissionScreen:onCreateMissionBitmap(element)
  if self.currentMission ~= nil then
    element:setImageFilename(self.currentMission.overlayActiveFilename)
  end
end
function MissionScreen:onCreateDemoLockedBitmap(element)
  if self.currentMission ~= nil then
    if g_isDemo then
      if self.currentMission.missionId == "12" or self.currentMission.missionId == "13" then
        element.visible = false
      end
    else
      element.visible = false
    end
  end
end
function MissionScreen:onCreateList(list)
  self.list = list
end
function MissionScreen:scrollListUp()
  self.list:scrollList(-1)
end
function MissionScreen:scrollListDown()
  self.list:scrollList(1)
end
function MissionScreen:getMissions()
  local xmlFile = loadXMLFile("missions.xml", "dataS/missions.xml")
  local i = 0
  local record = getXMLString(g_savegameXML, "savegames.missions#record")
  local count = 1
  local records = {}
  for missionRecord in string.gmatch(record, "%w+") do
    records[count] = missionRecord + 0
    count = count + 1
  end
  local finished = getXMLString(g_savegameXML, "savegames.missions#finished")
  count = 1
  for missionId in string.gmatch(finished, "%w+") do
    g_finishedMissions[missionId] = 1
    g_finishedMissionsRecord[missionId] = records[count]
    count = count + 1
  end
  if g_isDemo then
    while true do
      local key = string.format("missions.mission(%d)", i)
      local id = getXMLInt(xmlFile, key .. "#id")
      if id == nil then
        break
      end
      local mission = FSMissionMissionInfo:new("", nil)
      mission:loadDefaults()
      if mission:loadFromXML(xmlFile, key) and (mission.missionId == "12" or mission.missionId == "13") then
        table.insert(self.missions, mission)
        if self.listTemplate ~= nil then
          self.missionElements[mission.missionId] = {}
          self.currentMission = mission
          local new = self.listTemplate:clone(self.listTemplate.parent)
          new:updateAbsolutePosition()
          self.currentMission = nil
          self:updateMissionStrings(mission)
        end
      end
      i = i + 1
    end
    i = 0
    while true do
      local key = string.format("missions.mission(%d)", i)
      local id = getXMLInt(xmlFile, key .. "#id")
      if id == nil then
        break
      end
      local mission = FSMissionMissionInfo:new("", nil)
      mission:loadDefaults()
      if mission:loadFromXML(xmlFile, key) and mission.missionId ~= "12" and mission.missionId ~= "13" then
        table.insert(self.missions, mission)
        if self.listTemplate ~= nil then
          self.missionElements[mission.missionId] = {}
          self.currentMission = mission
          local new = self.listTemplate:clone(self.listTemplate.parent)
          new:updateAbsolutePosition()
          self.currentMission = nil
          self:updateMissionStrings(mission)
        end
      end
      i = i + 1
    end
  else
    while true do
      local key = string.format("missions.mission(%d)", i)
      local id = getXMLInt(xmlFile, key .. "#id")
      if id == nil then
        break
      end
      local mission = FSMissionMissionInfo:new("", nil)
      mission:loadDefaults()
      if mission:loadFromXML(xmlFile, key) then
        table.insert(self.missions, mission)
        if self.listTemplate ~= nil then
          self.missionElements[mission.missionId] = {}
          self.currentMission = mission
          local new = self.listTemplate:clone(self.listTemplate.parent)
          new:updateAbsolutePosition()
          self.currentMission = nil
          self:updateMissionStrings(mission)
        end
      end
      i = i + 1
    end
  end
  self.startIndex = 1
  self.selectedIndex = 1
  delete(xmlFile)
  if self.listTemplate ~= nil then
    self.listTemplate.parent:removeElement(self.listTemplate)
  end
end
function MissionScreen:updateMissionStrings(mission)
  local elements = self.missionElements[mission.id]
  if elements.title ~= nil then
    elements.title:setText(mission.name)
  end
  if elements.desc ~= nil then
    elements.desc:setText(mission.description)
  end
  local medalOverlay = "empty"
  if mission.id ~= nil and g_finishedMissions[mission.id] ~= nil and g_finishedMissionsRecord[mission.id] ~= nil then
    local recordStr = ""
    local medalStr = ""
    if mission.missionType == "time" then
      local timeMinutesF = g_finishedMissionsRecord[mission.id] / 60000
      local timeMinutes = math.floor(timeMinutesF)
      local timeSeconds = math.floor((timeMinutesF - timeMinutes) * 60)
      local recordFloor = (timeSeconds + 60 * timeMinutes) * 1000
      if recordFloor <= mission.bronzeTime * 1000 then
        medalOverlay = "bronze"
        medalStr = "(" .. g_i18n:getText("Bronze") .. ")"
      end
      if recordFloor <= mission.silverTime * 1000 then
        medalOverlay = "silver"
        medalStr = "(" .. g_i18n:getText("Silver") .. ")"
      end
      if recordFloor <= mission.goldTime * 1000 then
        medalOverlay = "gold"
        medalStr = "(" .. g_i18n:getText("Gold") .. ")"
      end
      recordStr = string.format(g_i18n:getText("Record") .. ": %02d:%02d %s", timeMinutes, timeSeconds, medalStr)
    end
    if mission.missionType == "stacking" or mission.missionType == "strawElevatoring" then
      local record = g_finishedMissionsRecord[mission.id]
      local filename = "dataS2/missions/empty_medal.png"
      if record >= mission.bronzeTime then
        medalOverlay = "bronze"
        medalStr = "(" .. g_i18n:getText("Bronze") .. ")"
      end
      if record >= mission.silverTime then
        medalOverlay = "silver"
        medalOverlay = self.silverMedalOverlay
        medalStr = "(" .. g_i18n:getText("Silver") .. ")"
      end
      if record >= mission.goldTime then
        medalOverlay = "gold"
        medalStr = "(" .. g_i18n:getText("Gold") .. ")"
      end
      if mission.missionType == "stacking" then
        recordStr = string.format(g_i18n:getText("pallets") .. ": %d %s", g_finishedMissionsRecord[mission.id], medalStr)
      end
      if mission.missionType == "strawElevatoring" then
        recordStr = string.format(g_i18n:getText("bales") .. ": %d %s", g_finishedMissionsRecord[mission.id], medalStr)
      end
    end
    if elements.record ~= nil then
      elements.record:setText(recordStr)
    end
    if elements.medalBitmap ~= nil then
      if medalOverlay == "gold" then
        elements.medalBitmap:setImageFilename("dataS2/missions/gold_medal.png")
      elseif medalOverlay == "silver" then
        elements.medalBitmap:setImageFilename("dataS2/missions/silver_medal.png")
      elseif medalOverlay == "bronze" then
        elements.medalBitmap:setImageFilename("dataS2/missions/bronze_medal.png")
      else
        elements.medalBitmap:setImageFilename("dataS2/missions/empty_medal.png")
      end
    end
  end
end
function MissionScreen:onCreateMissionTitle(element)
  if self.currentMission ~= nil then
    self.missionElements[self.currentMission.id].title = element
  end
end
function MissionScreen:onCreateMissionDesc(element)
  if self.currentMission ~= nil then
    self.missionElements[self.currentMission.id].desc = element
  end
end
function MissionScreen:onCreateMissionRecord(element)
  if self.currentMission ~= nil then
    self.missionElements[self.currentMission.id].record = element
  end
end
function MissionScreen:onCreateMissionMedal(element)
  if self.currentMission ~= nil then
    self.missionElements[self.currentMission.id].medal = element
  end
end
function MissionScreen:onCreateMissionMedalBitmap(element)
  if self.currentMission ~= nil then
    self.missionElements[self.currentMission.id].medalBitmap = element
  end
end
function MissionScreen:startSelectedMission()
  local missionInfo = self.missions[self.selectedIndex]
  if g_isDemo and missionInfo.missionId ~= "12" and missionInfo.missionId ~= "13" then
    return
  end
  setTerrainLoadDirectory("")
  local missionDynamicInfo = {}
  missionDynamicInfo.isMultiplayer = false
  self:onStartMission(missionInfo, missionDynamicInfo)
end
function MissionScreen:onStartMission(missionInfo, missionDynamicInfo)
  g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
  g_gui:showGui("MPLoadingScreen")
  g_mpLoadingScreen:startLocal()
end
function MissionScreen:update(dt)
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
