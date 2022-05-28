TipTrigger = {}
local TipTrigger_mt = Class(TipTrigger, Object)
InitStaticObjectClass(TipTrigger, "TipTrigger", ObjectIds.OBJECT_TIP_TRIGGER)
function TipTrigger:onCreate(id)
  local trigger = TipTrigger:new(g_server ~= nil, g_client ~= nil)
  local index = g_currentMission:addOnCreateLoadedObject(trigger)
  trigger:load(id)
  trigger:register(true)
end
function TipTrigger:new(isServer, isClient)
  local self = Object:new(isServer, isClient, TipTrigger_mt)
  self.className = "TipTrigger"
  self.triggerId = 0
  g_currentMission:addTipTrigger(self)
  return self
end
function TipTrigger:load(id)
  self.triggerId = id
  addTrigger(id, "triggerCallback", self)
  self.appearsOnPDA = Utils.getNoNil(getUserAttribute(id, "appearsOnPDA"), false)
  self.isFarmTrigger = Utils.getNoNil(getUserAttribute(id, "isFarmTrigger"), false)
  self.stationName = Utils.getNoNil(getUserAttribute(id, "stationName"), "Station")
  self.acceptedFruitTypes = {}
  self.priceMultipliers = {}
  local fruitTypes = getUserAttribute(id, "fruitTypes")
  local priceMultipliersString = getUserAttribute(id, "priceMultipliers")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    local multipliers = {}
    if priceMultipliersString ~= nil then
      multipliers = Utils.splitString(" ", priceMultipliersString)
    elseif not self.isFarmTrigger then
      print("Error: Missing priceMultipliersString user attribute for TipTrigger " .. getName(id))
    end
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        self.acceptedFruitTypes[desc.index] = true
        self.priceMultipliers[desc.index] = tonumber(multipliers[k])
        if self.priceMultipliers[desc.index] == nil then
          self.priceMultipliers[desc.index] = 0
          if not self.isFarmTrigger then
            print("Error: " .. k .. "th priceMultiplier is invalid in TipTrigger " .. getName(id))
          end
        end
      end
    end
  end
  local parent = getParent(id)
  local movingIndex = getUserAttribute(id, "movingIndex")
  if movingIndex ~= nil then
    self.movingId = Utils.indexToObject(parent, movingIndex)
    if self.movingId ~= nil then
      self.moveMinY = Utils.getNoNil(getUserAttribute(id, "moveMinY"), 0)
      self.moveMaxY = Utils.getNoNil(getUserAttribute(id, "moveMaxY"), 0)
      self.moveScale = Utils.getNoNil(getUserAttribute(id, "moveScale"), 0.001) * 0.01
      self.moveBackScale = (self.moveMaxY - self.moveMinY) / Utils.getNoNil(getUserAttribute(id, "moveBackTime"), 10000)
    end
  end
  self.isEnabled = true
  self.tipTriggerDirtyFlag = self:getNextDirtyFlag()
  return self
end
function TipTrigger:delete()
  g_currentMission:removeTipTrigger(self)
  removeTrigger(self.triggerId)
  delete(self.triggerId)
  TipTrigger:superClass().delete(self)
end
function TipTrigger:readStream(streamId, connection)
  if connection:getIsServer() and self.movingId ~= nil then
    local x, y, z = getTranslation(self.movingId)
    y = streamReadFloat32(streamId)
    setTranslation(self.movingId, x, y, z)
  end
end
function TipTrigger:writeStream(streamId, connection)
  if not connection:getIsServer() and self.movingId ~= nil then
    local x, y, z = getTranslation(self.movingId)
    streamWriteFloat32(streamId, y)
  end
end
function TipTrigger:readUpdateStream(streamId, timestamp, connection)
  self:readStream(streamId, connection)
end
function TipTrigger:writeUpdateStream(streamId, connection, dirtyMask)
  self:writeStream(streamId, connection)
end
function TipTrigger:update(dt)
  if self.movingId ~= nil then
    local x, y, z = getTranslation(self.movingId)
    local newY = math.max(y - dt * self.moveBackScale, self.moveMinY)
    setTranslation(self.movingId, x, newY, z)
  end
end
function TipTrigger:updateMoving(delta)
  if self.movingId ~= nil and self.isServer then
    local x, y, z = getTranslation(self.movingId)
    local newY = math.min(y + delta * self.moveScale, self.moveMaxY)
    setTranslation(self.movingId, x, newY, z)
    self:raiseDirtyFlags(self.tipTriggerDirtyFlag)
  end
end
function TipTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if self.isEnabled then
    if onEnter then
      local trailer = g_currentMission.objectToTrailer[otherShapeId]
      if trailer ~= nil and trailer.allowTipDischarge then
        if g_currentMission.trailerTipTriggers[trailer] == nil then
          g_currentMission.trailerTipTriggers[trailer] = {}
        end
        table.insert(g_currentMission.trailerTipTriggers[trailer], self)
      end
    elseif onLeave then
      local trailer = g_currentMission.objectToTrailer[otherShapeId]
      if trailer ~= nil and trailer.allowTipDischarge then
        local triggers = g_currentMission.trailerTipTriggers[trailer]
        if triggers ~= nil then
          for i = 1, table.getn(triggers) do
            if triggers[i] == self then
              table.remove(triggers, i)
              if table.getn(triggers) == 0 then
                g_currentMission.trailerTipTriggers[trailer] = nil
              end
              break
            end
          end
        end
      end
    end
  end
end
