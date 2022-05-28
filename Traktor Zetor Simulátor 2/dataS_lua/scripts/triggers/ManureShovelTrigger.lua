ManureShovelTrigger = {}
local ManureShovelTrigger_mt = Class(ManureShovelTrigger)
function ManureShovelTrigger:onCreate(id)
  g_currentMission:addUpdateable(ManureShovelTrigger:new(id))
end
function ManureShovelTrigger:new(nodeId)
  local self = {}
  setmetatable(self, ManureShovelTrigger_mt)
  self.triggerId = nodeId
  if g_currentMission:getIsServer() then
    addTrigger(nodeId, "triggerCallback", self)
  end
  self.isEnabled = true
  self.isSiloTrigger = Utils.getNoNil(getUserAttribute(nodeId, "isSiloTrigger"), false)
  self.currentShovel = nil
  return self
end
function ManureShovelTrigger:delete()
  if g_currentMission:getIsServer() then
    removeTrigger(self.triggerId)
  end
end
function ManureShovelTrigger:update(dt)
  if self.currentShovel ~= nil then
    local shovel = self.currentShovel
    if not shovel.manureIsFilled and not shovel:getIsManureEmptying() then
      local allowed = true
      if self.isSiloTrigger then
        local silo = g_currentMission:getSiloAmount(Fillable.FILLTYPE_MANURE)
        if silo < shovel.manureCapacity then
          allowed = false
        else
          g_currentMission:setSiloAmount(Fillable.FILLTYPE_MANURE, silo - shovel.manureCapacity)
        end
      end
      if allowed then
        shovel:setManureIsFilled(true)
      end
    end
  end
end
function ManureShovelTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  if self.isEnabled and (onEnter or onLeave) then
    local shovel = g_currentMission.nodeToVehicle[otherShapeId]
    if onLeave then
      if self.currentShovel == shovel then
        self.currentShovel = nil
      end
    elseif shovel ~= nil and shovel.setManureIsFilled ~= nil and shovel.manureCapacity ~= nil then
      self.currentShovel = shovel
    end
  end
end
