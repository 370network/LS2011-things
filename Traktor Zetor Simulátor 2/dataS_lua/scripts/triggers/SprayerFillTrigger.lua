SprayerFillTrigger = {}
local SprayerFillTrigger_mt = Class(SprayerFillTrigger)
function SprayerFillTrigger:onCreate(id)
  g_currentMission:addNonUpdateable(SprayerFillTrigger:new(id))
end
function SprayerFillTrigger:new(nodeId)
  local self = {}
  setmetatable(self, SprayerFillTrigger_mt)
  self.triggerId = nodeId
  addTrigger(nodeId, "triggerCallback", self)
  self.isEnabled = true
  self.isSiloTrigger = Utils.getNoNil(getUserAttribute(nodeId, "isSiloTrigger"), false)
  self.fillType = Fillable.FILLTYPE_UNKNOWN
  local sprayTypeStr = getUserAttribute(nodeId, "sprayType")
  if sprayTypeStr ~= nil then
    self.sprayTypeDesc = Sprayer.sprayTypes[sprayTypeStr]
    if self.sprayTypeDesc ~= nil then
      local fillType = Sprayer.sprayTypeToFillType[self.sprayTypeDesc.index]
      if fillType ~= nil then
        self.fillType = fillType
      end
    end
  end
  return self
end
function SprayerFillTrigger:delete()
  removeTrigger(self.triggerId)
end
function SprayerFillTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  if self.isEnabled and (onEnter or onLeave) then
    local sprayer = g_currentMission.objectToTrailer[otherShapeId]
    if sprayer ~= nil and sprayer.addSprayerFillTrigger ~= nil and sprayer.removeSprayerFillTrigger ~= nil then
      if onEnter then
        sprayer:addSprayerFillTrigger(self)
      else
        sprayer:removeSprayerFillTrigger(self)
      end
    end
  end
end
function SprayerFillTrigger:getIsActivatable(fillable)
  if not fillable:allowFillType(self.fillType, false) or self.isSiloTrigger and g_currentMission:getSiloAmount(self.fillType) <= 0 then
    return false
  end
  return true
end
