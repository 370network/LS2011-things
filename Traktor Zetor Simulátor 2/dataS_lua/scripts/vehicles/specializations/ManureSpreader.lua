ManureSpreader = {}
function ManureSpreader.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function ManureSpreader:load(xmlFile)
  self.setIsTurnedOn = Utils.prependedFunction(self.setIsTurnedOn, ManureSpreader.setIsTurnedOn)
  self.rotatingPartsAnimTime = 0
  self.rotatingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.rotatingParts.rotatingPart(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local entry = {}
    entry.node = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#node"))
    entry.speed = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#speed"), 0.005)
    if entry.node ~= nil then
      table.insert(self.rotatingParts, entry)
    end
    i = i + 1
  end
  local doorAnimation = {}
  doorAnimation.name = getXMLString(xmlFile, "vehicle.doorAnimation#name")
  doorAnimation.openSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.doorAnimation#openSpeedScale"), 1)
  doorAnimation.closeSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.doorAnimation#closeSpeedScale"), -doorAnimation.openSpeedScale)
  if doorAnimation.name ~= nil then
    self.doorAnimation = doorAnimation
  end
end
function ManureSpreader:delete()
end
function ManureSpreader:readStream(streamId, connection)
end
function ManureSpreader:writeStream(streamId, connection)
end
function ManureSpreader:readUpdateStream(streamId, timestamp, connection)
end
function ManureSpreader:writeUpdateStream(streamId, connection, dirtyMask)
end
function ManureSpreader:mouseEvent(posX, posY, isDown, isUp, button)
end
function ManureSpreader:keyEvent(unicode, sym, modifier, isDown)
end
function ManureSpreader:update(dt)
end
function ManureSpreader:updateTick(dt)
  if self.isTurnedOn and self:getIsActive() then
    self.rotatingPartsAnimTime = self.rotatingPartsAnimTime + dt
    for _, rotatingPart in ipairs(self.rotatingParts) do
      setRotation(rotatingPart.node, 0, rotatingPart.speed * self.rotatingPartsAnimTime, 0)
    end
  end
end
function ManureSpreader:draw()
end
function ManureSpreader:onDetach()
end
function ManureSpreader:onLeave()
end
function ManureSpreader:onDeactivate()
end
function ManureSpreader:onDeactivateSounds()
end
function ManureSpreader:setIsTurnedOn(isTurnedOn, noEventSend)
  if isTurnedOn ~= self.isTurnedOn and self:getIsTurnedOnAllowed(isTurnedOn) and self.doorAnimation ~= nil then
    if isTurnedOn then
      self:playAnimation(self.doorAnimation.name, self.doorAnimation.openSpeedScale, self:getAnimationTime(self.doorAnimation.name), true)
    else
      self:playAnimation(self.doorAnimation.name, self.doorAnimation.closeSpeedScale, self:getAnimationTime(self.doorAnimation.name), true)
    end
  end
end
