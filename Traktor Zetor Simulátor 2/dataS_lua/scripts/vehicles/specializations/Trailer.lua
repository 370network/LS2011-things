source("dataS/scripts/vehicles/specializations/TrailerToggleTipEvent.lua")
Trailer = {}
Trailer.TIPSTATE_CLOSED = 0
Trailer.TIPSTATE_OPENING = 1
Trailer.TIPSTATE_OPEN = 2
Trailer.TIPSTATE_CLOSING = 3
function Trailer.prerequisitesPresent(specializations)
  if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
    print("Warning: Specialization trailer now needs the specialization fillable")
  end
  return SpecializationUtil.hasSpecialization(Attachable, specializations) and SpecializationUtil.hasSpecialization(Fillable, specializations)
end
function Trailer:load(xmlFile)
  self.toggleTipState = SpecializationUtil.callSpecializationsFunction("toggleTipState")
  self.onStartTip = SpecializationUtil.callSpecializationsFunction("onStartTip")
  self.onEndTip = SpecializationUtil.callSpecializationsFunction("onEndTip")
  self.setFillLevel = Utils.prependedFunction(self.setFillLevel, Trailer.setFillLevel)
  self.getCurrentFruitType = Trailer.getCurrentFruitType
  self.lastFillDelta = 0
  self.tipDischargeEndTime = getXMLFloat(xmlFile, "vehicle.tipDischargeEndTime#value")
  local tipAnimRootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.tipAnimation#rootNode"))
  self.tipAnimCharSet = 0
  if tipAnimRootNode ~= nil and tipAnimRootNode ~= 0 then
    self.tipAnimCharSet = getAnimCharacterSet(tipAnimRootNode)
    if self.tipAnimCharSet ~= 0 then
      local clip = getAnimClipIndex(self.tipAnimCharSet, getXMLString(xmlFile, "vehicle.tipAnimation#clip"))
      assignAnimTrackClip(self.tipAnimCharSet, 0, clip)
      setAnimTrackLoopState(self.tipAnimCharSet, 0, false)
      self.tipAnimSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tipAnimation#speedScale"), 1)
      self.tipAnimDuration = getAnimClipDuration(self.tipAnimCharSet, clip)
      if self.tipDischargeEndTime == nil then
        self.tipDischargeEndTime = self.tipAnimDuration * 2
      end
    end
  end
  self.tipState = Trailer.TIPSTATE_CLOSED
  self.tipReferencePoint = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.tipReferencePoint#index"))
  if self.tipReferencePoint == nil then
    self.tipReferencePoint = self.components[1].node
  end
  if self.isClient then
    self.dischargeParticleSystems = {}
    local i = 0
    while true do
      local key = string.format("vehicle.dischargeParticleSystems.dischargeParticleSystem(%d)", i)
      local t = getXMLString(xmlFile, key .. "#type")
      if t == nil then
        break
      end
      local desc = FruitUtil.fruitTypes[t]
      if desc ~= nil then
        local fillType = FruitUtil.fruitTypeToFillType[desc.index]
        local currentPS = {}
        local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.components, false, "$data/vehicles/particleSystems/trailerDischargeParticleSystem.i3d", self.baseDirectory)
        self.dischargeParticleSystems[fillType] = currentPS
        if self.defaultdischargeParticleSystems == nil then
          self.defaultdischargeParticleSystems = currentPS
        end
      end
      i = i + 1
    end
    self.hydraulicSoundEnabled = false
    local hydraulicSound = getXMLString(xmlFile, "vehicle.hydraulicSound#file")
    if hydraulicSound ~= nil and hydraulicSound ~= "" then
      hydraulicSound = Utils.getFilename(hydraulicSound, self.baseDirectory)
      self.hydraulicSound = createSample("hydraulicSound")
      loadSample(self.hydraulicSound, hydraulicSound, false)
      self.hydraulicSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicSound#pitchOffset"), 1)
      self.hydraulicSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicSound#pitchMax"), 2)
    end
    self.fillSoundEnabled = false
    local fillSound = getXMLString(xmlFile, "vehicle.fillSound#file")
    if fillSound ~= nil and fillSound ~= "" then
      fillSound = Utils.getFilename(fillSound, self.baseDirectory)
      self.fillSound = createSample("fillSound")
      loadSample(self.fillSound, fillSound, false)
      self.fillSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillSound#pitchOffset"), 1)
      self.fillSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillSound#pitchMax"), 2)
    end
  end
  self.allowTipDischarge = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.allowTipDischarge#value"), true)
end
function Trailer:delete()
  for _, particleSystem in pairs(self.dischargeParticleSystems) do
    Utils.deleteParticleSystem(particleSystem)
  end
  if self.hydraulicSound ~= nil then
    delete(self.hydraulicSound)
  end
  if self.fillSound ~= nil then
    delete(self.fillSound)
  end
end
function Trailer:mouseEvent(posX, posY, isDown, isUp, button)
end
function Trailer:keyEvent(unicode, sym, modifier, isDown)
end
function Trailer:readStream(streamId, connection)
  if connection:getIsServer() then
    local tipState = streamReadUIntN(streamId, 2)
    if tipState ~= Trailer.TIPSTATE_CLOSED and self.tipAnimCharSet ~= 0 then
      local animTime = streamReadFloat32(streamId)
      Trailer.setAnimTime(self, animTime)
      if tipState ~= Trailer.TIPSTATE_CLOSING then
        self:onStartTip(nil, true)
      else
        self:onEndTip(true)
      end
    else
      Trailer.setAnimTime(self, 0)
    end
    self.tipState = tipState
  end
end
function Trailer:writeStream(streamId, connection)
  if not connection:getIsServer() then
    assert(self.tipState >= 0 and self.tipState <= 3)
    streamWriteUIntN(streamId, self.tipState, 2)
    if self.tipState ~= Trailer.TIPSTATE_CLOSED and self.tipAnimCharSet ~= 0 then
      local animTime = getAnimTrackTime(self.tipAnimCharSet, 0)
      streamWriteFloat32(streamId, animTime)
    end
  end
end
function Trailer:update(dt)
end
function Trailer:updateTick(dt)
  if self.tipState == Trailer.TIPSTATE_OPENING or self.tipState == Trailer.TIPSTATE_OPEN then
    if self.isServer then
      if self.currentFillType ~= Fillable.FILLTYPE_UNKNOW and self.currentTipTrigger ~= nil and g_currentMission:getIsTrailerInTipRange(self, self.currentTipTrigger) then
        local fillType = self.currentFillType
        local m = self.capacity / (self.tipDischargeEndTime / self.tipAnimSpeedScale)
        local curFill = self.fillLevel
        self:setFillLevel(self.fillLevel - m * dt, self.currentFillType)
        local fillDelta = self.fillLevel - curFill
        self.lastFillDelta = fillDelta
        if self.currentTipTrigger.isFarmTrigger then
          local siloFillType = fillType
          if fillType == Fillable.FILLTYPE_DRYGRASS then
            siloFillType = Fillable.FILLTYPE_GRASS
          end
          g_currentMission:setSiloAmount(siloFillType, g_currentMission:getSiloAmount(siloFillType) - fillDelta)
        else
          local fruitType = FruitUtil.fillTypeToFruitType[fillType]
          if fruitType ~= nil then
            local priceMultiplier = self.currentTipTrigger.priceMultipliers[fruitType]
            local difficultyMultiplier = math.max(3 * (3 - g_currentMission.missionStats.difficulty), 1)
            local money = FruitUtil.fruitIndexToDesc[fruitType].pricePerLiter * priceMultiplier * difficultyMultiplier * -fillDelta
            g_currentMission:addSharedMoney(money)
          end
        end
        if fillDelta < 0 then
          self.currentTipTrigger:updateMoving(-fillDelta)
        end
      else
        self:onEndTip()
      end
    end
    if self.isClient then
      if self.tipState == Trailer.TIPSTATE_OPENING and not self.hydraulicSoundEnabled and self.hydraulicSound ~= nil and self:getIsActiveForSound() then
        playSample(self.hydraulicSound, 0, self.hydraulicSoundVolume, 0)
        setSamplePitch(self.hydraulicSound, self.hydraulicSoundPitchOffset - 0.4)
        self.hydraulicSoundEnabled = true
      end
      if (self.tipState == Trailer.TIPSTATE_OPENING or self.tipState == Trailer.TIPSTATE_OPEN) and self.fillLevel > 0 then
        if not self.fillSoundEnabled and self.fillSound ~= nil and self:getIsActiveForSound() then
          playSample(self.fillSound, 0, self.fillSoundVolume, 0)
          self.fillSoundEnabled = true
        end
      elseif self.fillSoundEnabled then
        stopSample(self.fillSound)
        self.fillSoundEnabled = false
      end
    end
    if self.tipState == Trailer.TIPSTATE_OPENING then
      if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipAnimDuration then
        self.tipState = Trailer.TIPSTATE_OPEN
        if self.hydraulicSoundEnabled then
          stopSample(self.hydraulicSound)
          self.hydraulicSoundEnabled = false
        end
      end
    elseif getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipDischargeEndTime then
      self:onEndTip(true)
    end
  elseif self.tipState == Trailer.TIPSTATE_CLOSING then
    if self.isClient and not self.hydraulicSoundEnabled and self.hydraulicSound ~= nil and self:getIsActiveForSound() then
      playSample(self.hydraulicSound, 0, self.hydraulicSoundVolume, 0)
      setSamplePitch(self.hydraulicSound, self.hydraulicSoundPitchOffset)
      self.hydraulicSoundEnabled = true
    end
    if 0 >= getAnimTrackTime(self.tipAnimCharSet, 0) then
      if self.hydraulicSoundEnabled then
        stopSample(self.hydraulicSound)
        self.hydraulicSoundEnabled = false
      end
      disableAnimTrack(self.tipAnimCharSet, 0)
      self.tipState = Trailer.TIPSTATE_CLOSED
    end
  end
  if self.isClient then
    if (self.tipState == Trailer.TIPSTATE_OPENING or self.tipState == Trailer.TIPSTATE_OPEN) and self.fillLevel > 0 then
      Utils.setEmittingState(self.dischargeParticleSystems[self.currentFillType], true)
    else
      Utils.setEmittingState(self.dischargeParticleSystems[self.currentFillType], false)
    end
  end
end
function Trailer:draw()
  if self.isClient and self.currentFillType ~= Fillable.FILLTYPE_UNKNOWN then
    local fruitType = FruitUtil.fillTypeToFruitType[self.currentFillType]
    if fruitType ~= nil then
      g_currentMission:setFruitOverlayFruitType(fruitType)
    end
  end
end
function Trailer:toggleTipState(currentTipTrigger)
  if self.tipState == Trailer.TIPSTATE_CLOSED or self.tipState == Trailer.TIPSTATE_CLOSING then
    self:onStartTip(currentTipTrigger)
  else
    self:onEndTip()
  end
end
function Trailer:onStartTip(currentTipTrigger, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(TrailerToggleTipEvent:new(self, true, currentTipTrigger))
    else
      g_client:getServerConnection():sendEvent(TrailerToggleTipEvent:new(self, true, currentTipTrigger))
    end
  end
  self.currentTipTrigger = currentTipTrigger
  if self.tipAnimCharSet ~= 0 then
    if 0 > getAnimTrackTime(self.tipAnimCharSet, 0) then
      setAnimTrackTime(self.tipAnimCharSet, 0, 0)
    end
    setAnimTrackSpeedScale(self.tipAnimCharSet, 0, self.tipAnimSpeedScale)
    enableAnimTrack(self.tipAnimCharSet, 0)
  end
  self.tipState = Trailer.TIPSTATE_OPENING
end
function Trailer:onEndTip(noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(TrailerToggleTipEvent:new(self, false), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(TrailerToggleTipEvent:new(self, false), nil, nil, self)
    end
  end
  self.currentTipTrigger = nil
  if self.tipAnimCharSet ~= 0 then
    if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipAnimDuration then
      setAnimTrackTime(self.tipAnimCharSet, 0, self.tipAnimDuration)
    end
    setAnimTrackSpeedScale(self.tipAnimCharSet, 0, -self.tipAnimSpeedScale)
    enableAnimTrack(self.tipAnimCharSet, 0)
  end
  if self.fillSoundEnabled then
    stopSample(self.fillSound)
    self.fillSoundEnabled = false
  end
  self.tipState = Trailer.TIPSTATE_CLOSING
end
function Trailer:getCurrentFruitType()
  local fruitType = FruitUtil.fillTypeToFruitType[self.currentFillType]
  if fruitType == nil then
    fruitType = FruitUtil.FRUITTYPE_UNKNOWN
  end
  return fruitType
end
function Trailer:setFillLevel(fillLevel, fillType, force)
  if self.isClient and (self.currentFillType ~= fillType or fillLevel <= 0) then
    Utils.setEmittingState(self.dischargeParticleSystems[self.currentFillType], false)
  end
end
function Trailer:onAttach(attacherVehicle)
end
function Trailer:onDetach()
  if self.deactivateOnDetach then
    Trailer.onDeactivate(self)
  else
    Trailer.onDeactivateSounds(self)
  end
end
function Trailer:onLeave()
  if self.deactivateOnLeave then
    Trailer.onDeactivate(self)
  else
    Trailer.onDeactivateSounds(self)
  end
end
function Trailer:onDeactivate()
  Trailer.onDeactivateSounds(self)
end
function Trailer:onDeactivateSounds()
  if self.fillSoundEnabled then
    stopSample(self.fillSound)
    self.fillSoundEnabled = false
  end
  if self.hydraulicSoundEnabled then
    stopSample(self.hydraulicSound)
    self.hydraulicSoundEnabled = false
  end
end
function Trailer:setAnimTime(animTime)
  if self.tipAnimCharSet ~= 0 then
    enableAnimTrack(self.tipAnimCharSet, 0)
    setAnimTrackTime(self.tipAnimCharSet, 0, animTime, true)
    disableAnimTrack(self.tipAnimCharSet, 0)
  end
end
