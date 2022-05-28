Nightlight2 = {}
local Nightlight2_mt = Class(Nightlight2)
function Nightlight2:onCreate(id)
  g_currentMission:addUpdateable(Nightlight2:new(id))
end
function Nightlight2:new(name)
  local instance = {}
  setmetatable(instance, Nightlight2_mt)
  instance.nightId = name
  instance.isSunOn = true
  setVisibility(instance.nightId, not instance.isSunOn)
  return instance
end
function Nightlight2:delete()
end
function Nightlight2:update(dt)
  if g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.isSunOn ~= self.isSunOn then
    self.isSunOn = g_currentMission.environment.isSunOn
    setVisibility(self.nightId, not self.isSunOn)
  end
end
