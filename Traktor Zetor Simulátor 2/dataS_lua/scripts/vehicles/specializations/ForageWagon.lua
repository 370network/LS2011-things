source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/ForageWagonAreaEvent.lua")
ForageWagon = {}
function ForageWagon.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Trailer, specializations)
end
function ForageWagon:load(xmlFile)
  self.setIsTurnedOn = SpecializationUtil.callSpecializationsFunction("setIsTurnedOn")
  local forageWgnSound = getXMLString(xmlFile, "vehicle.forageWgnSound#file")
  if forageWgnSound ~= nil and forageWgnSound ~= "" then
    forageWgnSound = Utils.getFilename(forageWgnSound, self.baseDirectory)
    self.forageWgnSound = createSample("forageWgnSound")
    self.forageWgnSoundEnabled = false
    loadSample(self.forageWgnSound, forageWgnSound, false)
    self.forageWgnSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.forageWgnSound#pitchOffset"), 1)
    self.forageWgnSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.forageWgnSound#volume"), 1)
  end
  self.pickupAnimationName = Utils.getNoNil(getXMLString(xmlFile, "vehicle.pickupAnimation#name"), "")
  if self.playAnimation == nil or self.getIsAnimationPlaying == nil then
    self.pickupAnimationName = ""
  end
  self.pickupAnimationLowerSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pickupAnimation#lowerSpeed"), 1)
  self.pickupAnimationLiftSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pickupAnimation#liftSpeed"), -self.pickupAnimationLowerSpeed)
  self.fillScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillScale#value"), 1)
  self.wasToFast = false
  self.isTurnedOn = false
  self.lastForageWagonArea = 0
  self.forageWagonGroundFlag = self:getNextDirtyFlag()
end
function ForageWagon:delete()
  if self.forageWgnSound ~= nil then
    delete(self.forageWgnSound)
  end
end
function ForageWagon:readStream(streamId, connection)
  local turnedOn = streamReadBool(streamId)
  self:setIsTurnedOn(turnedOn, true)
  local fillLevel = streamReadInt32(streamId)
  self:setFillLevel(fillLevel, Fillable.FILLTYPE_GRASS)
end
function ForageWagon:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isTurnedOn)
  streamWriteInt32(streamId, self.fillLevel)
end
function ForageWagon:readUpdateStream(streamId, timestamp, connection)
end
function ForageWagon:writeUpdateStream(streamId, connection, dirtyMask)
end
function ForageWagon:mouseEvent(posX, posY, isDown, isUp, button)
end
function ForageWagon:keyEvent(unicode, sym, modifier, isDown)
end
function ForageWagon:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setIsTurnedOn(not self.isTurnedOn)
  end
end
function ForageWagon:updateTick(dt)
  self.wasToFast = false
  self.lastForageWagonArea = 0
  if self:getIsActive() then
    if self.isTurnedOn and self:allowFillType(Fillable.FILLTYPE_GRASS) and self.capacity > self.fillLevel then
      local toFast = self:doCheckSpeedLimit() and self.attacherVehicle.lastSpeed * 3600 > 29
      if self.isServer and not toFast then
        local cuttingAreasSend = {}
        for k, cuttingArea in pairs(self.cuttingAreas) do
          if self:getIsAreaActive(cuttingArea) then
            local x, y, z = getWorldTranslation(cuttingArea.start)
            local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
            local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
            table.insert(cuttingAreasSend, {
              x,
              z,
              x1,
              z1,
              x2,
              z2
            })
          end
        end
        if 0 < table.getn(cuttingAreasSend) then
          local area = ForageWagonAreaEvent.runLocally(cuttingAreasSend)
          if 0 < area then
            self.lastForageWagonArea = area
            local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
            local literPerSqm = g_strawLitersPerSqm * 2
            local sqm = area * pixelToSqm
            local deltaLevel = sqm * literPerSqm * self.fillScale
            self:setFillLevel(self.fillLevel + deltaLevel, Fillable.FILLTYPE_GRASS)
            g_server:broadcastEvent(ForageWagonAreaEvent:new(cuttingAreasSend))
          end
        end
      end
      self.wasToFast = toFast
      if self.isClient and not self.forageWgnSoundEnabled and self:getIsActiveForSound() then
        playSample(self.forageWgnSound, 0, self.forageWgnSoundVolume, 0)
        setSamplePitch(self.forageWgnSound, self.forageWgnSoundPitchOffset)
        self.forageWgnSoundEnabled = true
      end
    end
    if self.isClient and self.forageWgnSoundEnabled and not self.isTurnedOn then
      stopSample(self.forageWgnSound)
      self.forageWgnSoundEnabled = false
    end
  end
end
function ForageWagon:draw()
  if self.wasToFast then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
  end
  if self.isTurnedOn then
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  else
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  end
end
function ForageWagon:onDetach()
  if self.deactivateOnDetach then
    ForageWagon.onDeactivate(self)
  else
    ForageWagon.onDeactivateSounds(self)
  end
end
function ForageWagon:onLeave()
  if self.deactivateOnLeave then
    ForageWagon.onDeactivate(self)
  else
    ForageWagon.onDeactivateSounds(self)
  end
end
function ForageWagon:onDeactivate()
  self.isTurnedOn = false
  ForageWagon.onDeactivateSounds(self)
end
function ForageWagon:setIsTurnedOn(isTurnedOn, noEventSend)
  SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
  self.isTurnedOn = isTurnedOn
  if self.pickupAnimationName ~= "" then
    local animTime
    if self:getIsAnimationPlaying(self.pickupAnimationName) then
      animTime = self:getAnimationTime(self.pickupAnimationName)
    end
    if isTurnedOn then
      self:playAnimation(self.pickupAnimationName, self.pickupAnimationLowerSpeed, animTime, true)
    else
      self:playAnimation(self.pickupAnimationName, self.pickupAnimationLiftSpeed, animTime, true)
    end
  end
end
function ForageWagon:onDeactivateSounds()
  if self.forageWgnSoundEnabled then
    stopSample(self.forageWgnSound)
    self.forageWgnSoundEnabled = false
  end
end
