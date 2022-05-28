GuiProfile = {}
local GuiProfile_mt = Class(GuiProfile)
function GuiProfile:new()
  local instance = setmetatable({}, GuiProfile_mt)
  instance.values = {}
  instance.name = ""
  return instance
end
function GuiProfile:loadFromXML(xmlFile, key)
  local name = getXMLString(xmlFile, key .. "#name")
  if name == nil then
    return false
  end
  self.name = name
  local i = 0
  while true do
    local k = key .. ".Value(" .. i .. ")"
    local name = getXMLString(xmlFile, k .. "#name")
    local value = getXMLString(xmlFile, k .. "#value")
    if name == nil or value == nil then
      break
    end
    self.values[name] = value
    i = i + 1
  end
  return true
end
function GuiProfile:getValue(value)
  return self.values[value]
end
