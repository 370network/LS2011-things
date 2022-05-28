GasStation = {}
local GasStation_mt = Class(GasStation)
function GasStation:onCreate(id)
  g_currentMission:addNonUpdateable(GasStation:new(id))
end
function GasStation:new(id, customMt)
  local self = {}
  if customMt ~= nil then
    setmetatable(self, customMt)
  else
    setmetatable(self, GasStation_mt)
  end
  self.triggerId = id
  addTrigger(id, "triggerCallback", self)
  self.isEnabled = true
  self.shapesCount = {}
  return self
end
function GasStation:delete()
  removeTrigger(self.triggerId)
end
function GasStation:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if self.isEnabled and (onEnter or onLeave) then
    if self.shapesCount[otherId] == nil then
      self.shapesCount[otherId] = 0
    end
    if onEnter then
      self.shapesCount[otherId] = self.shapesCount[otherId] + 1
    elseif onLeave then
      self.shapesCount[otherId] = self.shapesCount[otherId] - 1
    end
    local vehicle = g_currentMission.nodeToVehicle[otherId]
    if vehicle ~= nil and vehicle.setHasRefuelStationInRange ~= nil then
      vehicle:setHasRefuelStationInRange(self.shapesCount[otherId] > 0)
    end
  end
end
