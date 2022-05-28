MilktruckStartTrigger = {}
local MilktruckStartTrigger_mt = Class(MilktruckStartTrigger)
function MilktruckStartTrigger:onCreate(id)
  if g_currentMission:getIsServer() then
    g_currentMission:addNonUpdateable(MilktruckStartTrigger:new(id))
  end
end
function MilktruckStartTrigger:new(id)
  local self = {}
  setmetatable(self, MilktruckStartTrigger_mt)
  self.triggerId = id
  if g_currentMission:getIsServer() then
    addTrigger(id, "triggerCallback", self)
  end
  return self
end
function MilktruckStartTrigger:delete()
  if g_currentMission:getIsServer() then
    removeTrigger(self.triggerId)
  end
end
function MilktruckStartTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter then
    local object = g_currentMission:getNodeObject(otherShapeId)
    if object ~= nil and object.milktruckStopNode ~= nil and object.milktruckStopNode == otherShapeId then
      object:onEnteredMilktruckStartTrigger(self)
    end
  end
end
