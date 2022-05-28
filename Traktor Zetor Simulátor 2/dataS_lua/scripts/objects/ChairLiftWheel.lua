ChairLiftWheel = {}
local ChairLiftWheel_mt = Class(ChairLiftWheel)
function ChairLiftWheel:onCreate(id)
  g_currentMission:addUpdateable(ChairLiftWheel:new(id))
end
function ChairLiftWheel:new(name)
  local instance = {}
  setmetatable(instance, ChairLiftWheel_mt)
  instance.wheelId = name
  return instance
end
function ChairLiftWheel:delete()
end
function ChairLiftWheel:update(dt)
  rotate(self.wheelId, 0, -0.001 * dt, 0)
end
