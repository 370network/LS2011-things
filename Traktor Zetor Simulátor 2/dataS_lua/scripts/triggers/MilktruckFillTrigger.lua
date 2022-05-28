MilktruckFillTrigger = {}
local MilktruckFillTrigger_mt = Class(MilktruckFillTrigger)
function MilktruckFillTrigger:onCreate(id)
  if g_currentMission:getIsServer() then
    g_currentMission:addNonUpdateable(MilktruckFillTrigger:new(id))
  end
end
function MilktruckFillTrigger:new(id)
  local self = {}
  setmetatable(self, MilktruckFillTrigger_mt)
  self.triggerId = id
  if g_currentMission:getIsServer() then
    addTrigger(id, "triggerCallback", self)
  end
  return self
end
function MilktruckFillTrigger:delete()
  if g_currentMission:getIsServer() then
    removeTrigger(self.triggerId)
  end
end
function MilktruckFillTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter then
    local object = g_currentMission:getNodeObject(otherShapeId)
    if object ~= nil and object.milktruckStopNode ~= nil and object.milktruckStopNode == otherShapeId then
      object:onEnteredMilktruckFillTrigger(self)
    end
  end
end
