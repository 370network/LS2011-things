Honk = {}
source("dataS/scripts/vehicles/specializations/HonkEvent.lua")
function Honk.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Steerable, specializations)
end
function Honk:load(xmlFile)
  self.playHonk = SpecializationUtil.callSpecializationsFunction("playHonk")
  local honkSoundFile = getXMLString(xmlFile, "vehicle.honkSound#file")
  local clientHonkSoundFile = getXMLString(xmlFile, "vehicle.honkSound#client")
  if honkSoundFile ~= nil and clientHonkSoundFile ~= nil then
    honkSoundFile = Utils.getFilename(honkSoundFile, self.baseDirectory)
    clientHonkSoundFile = Utils.getFilename(clientHonkSoundFile, self.baseDirectory)
    self.honkSoundId = createSample("honkSound")
    loadSample(self.honkSoundId, honkSoundFile, false)
    self.honkSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.honkSound#volume"), 1)
    self.honkSoundRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.honkSound#radius"), 50)
    self.honkSoundInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.honkSound#innerRadius"), 10)
    self.clientHonkSound = createAudioSource("clientHonkSound", clientHonkSoundFile, self.honkSoundRadius, self.honkSoundInnerRadius, self.honkSoundVolume, 0)
    link(self.components[1].node, self.clientHonkSound)
    setVisibility(self.clientHonkSound, false)
    self.honkPlaying = false
  end
end
function Honk:delete()
  if self.honkSoundId ~= nil then
    delete(self.honkSoundId)
    self.honkSoundId = nil
  end
end
function Honk:readStream(streamId, connection)
end
function Honk:writeStream(streamId, connection)
end
function Honk:mouseEvent(posX, posY, isDown, isUp, button)
end
function Honk:keyEvent(unicode, sym, modifier, isDown)
end
function Honk:update(dt)
  if self:getIsActiveForInput() and self.honkSoundId ~= nil then
    if InputBinding.isPressed(InputBinding.HONK) then
      if not self.honkPlaying then
        self:playHonk(true)
      end
    elseif self.honkPlaying then
      self:playHonk(false)
    end
  end
end
function Honk:updateTick(dt)
end
function Honk:draw()
end
function Honk:onLeave()
  if self.honkSoundId ~= nil then
    setVisibility(self.clientHonkSound, false)
    stopSample(self.honkSoundId)
  end
end
function Honk:onDetach()
  if self.honkSoundId ~= nil then
    setVisibility(self.clientHonkSound, false)
    stopSample(self.honkSoundId)
  end
end
function Honk:playHonk(isPlaying, noEventSend)
  if self.honkSoundId ~= nil then
    HonkEvent.sendEvent(self, isPlaying, noEventSend)
    self.honkPlaying = isPlaying
    if isPlaying then
      if self:getIsActive() then
        if self:getIsActiveForSound() then
          playSample(self.honkSoundId, 0, self.honkSoundVolume, 0)
        elseif self.isControlled then
          setVisibility(self.clientHonkSound, true)
        end
      end
    else
      stopSample(self.honkSoundId)
      setVisibility(self.clientHonkSound, false)
    end
  end
end
