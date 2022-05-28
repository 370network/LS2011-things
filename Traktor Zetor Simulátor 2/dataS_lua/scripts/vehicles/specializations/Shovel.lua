Shovel = {}
function Shovel.prerequisitesPresent(specializations)
  return true
end
function Shovel:load(xmlFile)
  self.findTrailerRaycastCallback = Shovel.findTrailerRaycastCallback
  self.setManureIsFilled = Shovel.setManureIsFilled
  self.getIsManureEmptying = Shovel.getIsManureEmptying
  self.manureTipReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.manure#tipReferenceNode"))
  self.manureFillPlane = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.manure#fillPlane"))
  self.manureCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.manure#capacity"), 0)
  self.manureIsFilled = false
  self.emptyParticleSystems = {}
  Utils.loadParticleSystem(xmlFile, self.emptyParticleSystems, "vehicle.emptyParticleSystem", self.components, false, nil, self.baseDirectory)
  self.shovelDirtyFlag = self:getNextDirtyFlag()
  self:setManureIsFilled(false)
end
function Shovel:delete()
  Utils.deleteParticleSystem(self.emptyParticleSystems)
end
function Shovel:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local manureIsFilled = getXMLBool(xmlFile, key .. "#manureIsFilled")
  if manureIsFilled ~= nil then
    self:setManureIsFilled(manureIsFilled)
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Shovel:getSaveAttributesAndNodes(nodeIdent)
  local attributes = "manureIsFilled=\"" .. tostring(self.manureIsFilled) .. "\""
  return attributes, nil
end
function Shovel:readStream(streamId, connection)
  local isFilled = streamReadBool(streamId)
  self:setManureIsFilled(isFilled)
end
function Shovel:writeStream(streamId, connection)
  streamWriteBool(streamId, self.manureIsFilled)
end
function Shovel:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    local isFilled = streamReadBool(streamId)
    self:setManureIsFilled(isFilled)
  end
end
function Shovel:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.manureIsFilled)
  end
end
function Shovel:mouseEvent(posX, posY, isDown, isUp, button)
end
function Shovel:keyEvent(unicode, sym, modifier, isDown)
end
function Shovel:update(dt)
end
function Shovel:updateTick(dt)
  if self:getIsActive() and self.isServer and self.manureIsFilled and self.manureTipReferenceNode ~= nil and self.manureFillPlane ~= nil and self:getIsManureEmptying() then
    self.trailerFound = 0
    local x, y, z = getWorldTranslation(self.manureTipReferenceNode)
    raycastAll(x, y, z, 0, -1, 0, "findTrailerRaycastCallback", 10, self)
    local trailer = g_currentMission.objectToTrailer[self.trailerFound]
    if self.trailerFound ~= 0 and trailer ~= nil and trailer:allowFillType(Fillable.FILLTYPE_MANURE) and trailer.allowFillFromAir then
      trailer:resetFillLevelIfNeeded(Fillable.FILLTYPE_MANURE)
      trailer:setFillLevel(trailer.fillLevel + self.manureCapacity, Fillable.FILLTYPE_MANURE)
    end
    self:setManureIsFilled(false)
  end
end
function Shovel:draw()
end
function Shovel:onDetach()
  if self.deactivateOnDetach then
    Shovel.onDeactivate(self)
  else
    Shovel.onDeactivateSounds(self)
  end
end
function Shovel:onLeave()
  if self.deactivateOnLeave then
    Shovel.onDeactivate(self)
  else
    Shovel.onDeactivateSounds(self)
  end
end
function Shovel:onDeactivate()
  Shovel.onDeactivateSounds(self)
end
function Shovel:onDeactivateSounds()
end
function Shovel:setManureIsFilled(isFilled)
  if self.manureIsFilled ~= isFilled then
    self.manureIsFilled = isFilled
    if not isFilled then
      Utils.resetNumOfEmittedParticles(self.emptyParticleSystems)
      Utils.setEmittingState(self.emptyParticleSystems, true)
    end
    if self.isServer then
      self:raiseDirtyFlags(self.shovelDirtyFlag)
    end
  end
  if self.manureFillPlane ~= nil then
    setVisibility(self.manureFillPlane, self.manureIsFilled)
  end
end
function Shovel:getIsManureEmptying()
  if self.manureTipReferenceNode ~= nil then
    local dx, dy, dz = localDirectionToWorld(self.manureTipReferenceNode, 0, 0, 1)
    if dy < -0.573576436351 then
      return true
    end
  end
  return false
end
function Shovel:findTrailerRaycastCallback(transformId, x, y, z, distance)
  if getUserAttribute(transformId, "vehicleType") == 2 then
    self.trailerFound = transformId
    return false
  end
  return true
end
