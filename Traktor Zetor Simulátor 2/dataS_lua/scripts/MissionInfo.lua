MissionInfo = {}
local MissionInfo_mt = Class(MissionInfo)
function MissionInfo:new(baseDirectory, customEnvironment, customMt)
  if customMt == nil then
    customMt = MissionInfo_mt
  end
  local self = {}
  setmetatable(self, customMt)
  self.id = "invalid"
  self.scriptFilename = ""
  self.scriptClass = ""
  self.useCustomEnvironmentForScript = false
  self.customEnvironment = customEnvironment
  self.baseDirectory = baseDirectory
  return self
end
function MissionInfo:loadDefaults()
end
function MissionInfo:loadFromXML(xmlFile, key)
  self.id = getXMLString(xmlFile, key .. "#id")
  self.scriptFilename = getXMLString(xmlFile, key .. ".script#filename")
  self.scriptClass = getXMLString(xmlFile, key .. ".script#class")
  if self.id == nil then
    print("Error: Missing id attribute in mission " .. key)
    return false
  end
  if self.scriptFilename == nil or self.scriptClass == nil then
    print("Error: Missing script attributes in mission " .. self.id)
    return false
  end
  if not self:isValidMissionId(self.id) then
    print("Error: Invalid mission id '" .. self.id .. "'")
    return false
  end
  self.scriptFilename, self.useCustomEnvironmentForScript = Utils.getFilename(self.scriptFilename, self.baseDirectory)
  if self.customEnvironment ~= nil then
    if not self:isValidMissionId(self.customEnvironment) then
      print("Error: Invalid mission customEnvironment '" .. self.customEnvironment .. "'")
      return false
    end
    self.id = self.customEnvironment .. "." .. self.id
    if self.useCustomEnvironmentForScript then
      self.scriptClass = self.customEnvironment .. "." .. self.scriptClass
    end
  end
  return true
end
function MissionInfo:isValidMissionId(id)
  if id:len() == 0 then
    return false
  end
  if id:find("[^%w_]") ~= nil then
    return false
  end
  return true
end
