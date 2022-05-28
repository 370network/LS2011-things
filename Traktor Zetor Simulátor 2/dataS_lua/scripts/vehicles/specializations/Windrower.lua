source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/WindrowAreaEvent.lua")
Windrower = {}
function Windrower.prerequisitesPresent(specializations)
  return true
end
function Windrower:load(xmlFile)
  self.setIsTurnedOn = SpecializationUtil.callSpecializationsFunction("setIsTurnedOn")
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  if self.groundReferenceNode == nil then
    self.groundReferenceNode = self.components[1].node
  end
  self.animation = {}
  self.animation.animCharSet = 0
  self.animationEnabled = false
  local rootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.animation#rootNode"))
  if rootNode ~= nil then
    self.animation.animCharSet = getAnimCharacterSet(rootNode)
    if self.animation.animCharSet ~= 0 then
      self.animation.clip = getAnimClipIndex(self.animation.animCharSet, getXMLString(xmlFile, "vehicle.animation#animationClip"))
      if 0 <= self.animation.clip then
        assignAnimTrackClip(self.animation.animCharSet, 0, self.animation.clip)
        self.animation.speedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.animation#speedScale"), 1)
        setAnimTrackSpeedScale(self.animation.animCharSet, self.animation.clip, self.animation.speedScale)
        setAnimTrackLoopState(self.animation.animCharSet, 0, true)
      end
    end
  end
  local numWindrowerDropAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.windrowerDropAreas#count"), 0)
  if numWindrowerDropAreas == 0 then
    print("Warning: No drop areas specified in '" .. self.configFileName .. "'")
  elseif numWindrowerDropAreas ~= 1 and numWindrowerDropAreas ~= table.getn(self.cuttingAreas) then
    print("Warning: Number of cutting areas and drop areas should be equal in '" .. self.configFileName .. "'")
  end
  self.windrowerDropAreas = {}
  for i = 1, numWindrowerDropAreas do
    self.windrowerDropAreas[i] = {}
    local areanamei = string.format("vehicle.windrowerDropAreas.windrowerDropArea%d", i)
    self.windrowerDropAreas[i].start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    self.windrowerDropAreas[i].width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    self.windrowerDropAreas[i].height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  self.accumulatedCuttingAreaValues = {}
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
    self.accumulatedCuttingAreaValues[i] = 0
  end
  if self.isClient then
    local windrowerSound = getXMLString(xmlFile, "vehicle.windrowerSound#file")
    if windrowerSound ~= nil and windrowerSound ~= "" then
      windrowerSound = Utils.getFilename(windrowerSound, self.baseDirectory)
      self.windrowerSound = createSample("windrowerSound")
      self.windrowerSoundEnabled = false
      loadSample(self.windrowerSound, windrowerSound, false)
      self.windrowerSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.windrowerSound#pitchOffset"), 1)
      self.windrowerSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.windrowerSound#volume"), 1)
    end
  end
  self.isTurnedOn = false
  self.wasToFast = false
  self.windrowerGroundFlag = self.nextDirtyFlag
  self.nextDirtyFlag = self.windrowerGroundFlag * 2
end
function Windrower:delete()
  if self.windrowerSound ~= nil then
    delete(self.windrowerSound)
  end
end
function Windrower:mouseEvent(posX, posY, isDown, isUp, button)
end
function Windrower:keyEvent(unicode, sym, modifier, isDown)
end
function Windrower:readStream(streamId, connection)
  local isTurnedOn = streamReadBool(streamId)
  self:setIsTurnedOn(isTurnedOn, true)
end
function Windrower:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isTurnedOn)
end
function Windrower:readUpdateStream(streamId, timestamp, connection)
end
function Windrower:writeUpdateStream(streamId, connection, dirtyMask)
end
function Windrower:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setIsTurnedOn(not self.isTurnedOn)
  end
end
function Windrower:updateTick(dt)
  self.wasToFast = false
  if self:getIsActive() and self.isTurnedOn then
    if self.isServer then
      local toFast = self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 31
      if not toFast then
        local x, y, z = getWorldTranslation(self.groundReferenceNode)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        if y <= terrainHeight + self.groundReferenceThreshold then
          local numDropAreas = table.getn(self.windrowerDropAreas)
          local numAreas = table.getn(self.cuttingAreas)
          if 0 < numDropAreas and 0 < numAreas then
            local sum = 0
            local fruitType = FruitUtil.FRUITTYPE_GRASS
            local fruitTypeFix = false
            local foldAnimTime = self.foldAnimTime
            local cuttingAreasSend = {}
            local dropAreasSend = {}
            for i = 1, numAreas do
              local cuttingArea = self.cuttingAreas[i]
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
            for i = 1, numDropAreas do
              local dropArea = self.windrowerDropAreas[i]
              local dx, dy, dz = getWorldTranslation(dropArea.start)
              local dx1, dy1, dz1 = getWorldTranslation(dropArea.width)
              local dx2, dy2, dz2 = getWorldTranslation(dropArea.height)
              table.insert(dropAreasSend, {
                dx,
                dz,
                dx1,
                dz1,
                dx2,
                dz2
              })
            end
            if 0 < table.getn(cuttingAreasSend) then
              local cuttingAreasSend, dropAreasSend, fruitType, bitType = WindrowAreaEvent.runLocally(cuttingAreasSend, dropAreasSend, self.accumulatedCuttingAreaValues)
              if 0 < table.getn(cuttingAreasSend) then
                g_server:broadcastEvent(WindrowAreaEvent:new(cuttingAreasSend, dropAreasSend, fruitType, bitType))
              end
            end
          end
        end
      end
      self.wasToFast = toFast
    end
    if self.isClient and not self.windrowerSoundEnabled and self:getIsActiveForSound() then
      playSample(self.windrowerSound, 0, self.windrowerSoundVolume, 0)
      setSamplePitch(self.windrowerSound, self.windrowerSoundPitchOffset)
      self.windrowerSoundEnabled = true
    end
  end
end
function Windrower:draw()
  if self.isClient then
    if self.isTurnedOn then
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    else
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    end
    if self.wasToFast then
      g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
    end
  end
end
function Windrower:onDetach()
  if self.deactivateOnDetach then
    Windrower.onDeactivate(self)
  else
    Windrower.onDeactivateSounds(self)
  end
end
function Windrower:onLeave()
  if self.deactivateOnLeave then
    Windrower.onDeactivate(self)
  else
    Windrower.onDeactivateSounds(self)
  end
end
function Windrower:onDeactivate()
  if self.animationEnabled then
    disableAnimTrack(self.animation.animCharSet, 0)
    self.animationEnabled = false
  end
  Windrower.onDeactivateSounds(self)
  self.isTurnedOn = false
end
function Windrower:onDeactivateSounds()
  if self.windrowerSoundEnabled then
    stopSample(self.windrowerSound)
    self.windrowerSoundEnabled = false
  end
end
function Windrower:setIsTurnedOn(isTurnedOn, noEventSend)
  SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
  self.isTurnedOn = isTurnedOn
  if not isTurnedOn then
    if self.windrowerSoundEnabled then
      stopSample(self.windrowerSound)
      self.windrowerSoundEnabled = false
    end
    if self.animationEnabled then
      disableAnimTrack(self.animation.animCharSet, 0)
      self.animationEnabled = false
    end
  elseif not self.animationEnabled then
    enableAnimTrack(self.animation.animCharSet, 0)
    self.animationEnabled = true
  end
end
