SowingMachineFillTrigger = {}
local SowingMachineFillTrigger_mt = Class(SowingMachineFillTrigger)
function SowingMachineFillTrigger:onCreate(id)
  g_currentMission:addNonUpdateable(SowingMachineFillTrigger:new(id))
end
function SowingMachineFillTrigger:new(nodeId)
  local self = {}
  setmetatable(self, SowingMachineFillTrigger_mt)
  self.triggerId = nodeId
  addTrigger(nodeId, "triggerCallback", self)
  self.isEnabled = true
  return self
end
function SowingMachineFillTrigger:delete()
  removeTrigger(self.triggerId)
end
function SowingMachineFillTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  if self.isEnabled and (onEnter or onLeave) then
    local sowingMachine = g_currentMission.objectToTrailer[otherShapeId]
    if sowingMachine ~= nil and sowingMachine.addSowingMachineFillTrigger ~= nil and sowingMachine.removeSowingMachineFillTrigger ~= nil then
      if onEnter then
        sowingMachine:addSowingMachineFillTrigger(self)
      else
        sowingMachine:removeSowingMachineFillTrigger(self)
      end
    end
  end
end
