FSMissionMissionInfo = {}
local FSMissionMissionInfo_mt = Class(FSMissionMissionInfo, FSMissionInfo)
function FSMissionMissionInfo:new(baseDirectory, customEnvironment, customMt)
  if customMt == nil then
    customMt = FSMissionMissionInfo_mt
  end
  local self = FSMissionMissionInfo:superClass():new(baseDirectory, customEnvironment, customMt)
  return self
end
function FSMissionMissionInfo:loadDefaults()
  FSMissionMissionInfo:superClass().loadDefaults(self)
  self.missionId = "0"
  self.bronzeTime = 0
  self.silverTime = 0
  self.goldTime = 0
  self.missionType = "unknown"
  self.name = ""
  self.name_i18n = ""
  self.description = ""
end
function FSMissionMissionInfo:loadFromXML(xmlFile, key)
  if not FSMissionMissionInfo:superClass().loadFromXML(self, xmlFile, key) then
    return false
  end
  self.missionId = self.id
  local i18n = g_i18n
  if self.customEnvironment ~= nil then
    i18n = _G[self.customEnvironment].g_i18n
  end
  self.name = Utils.getXMLI18NValue(xmlFile, key, getXMLString, "name", "", self.customEnvironment, true)
  self.description = Utils.getXMLI18NValue(xmlFile, key, getXMLString, "description", "", self.customEnvironment, true)
  self.bronzeTime = getXMLFloat(xmlFile, key .. ".bronze")
  self.silverTime = getXMLFloat(xmlFile, key .. ".silver")
  self.goldTime = getXMLFloat(xmlFile, key .. ".gold")
  self.missionType = getXMLString(xmlFile, key .. ".mission_type")
  local imageActive = getXMLString(xmlFile, key .. ".image#active")
  self.overlayActiveFilename = imageActive
  return true
end
