Tedder = {}
source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/TedderAreaEvent.lua")
function Tedder.prerequisitesPresent(specializations)
  return true
end
function Tedder:load(xmlFile)
  assert(self.setIsTurnedOn == nil, "Tedder needs to be the first specialization which implements setIsTurnedOn")
  self.setIsTurnedOn = Tedder.setIsTurnedOn
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  if self.groundReferenceNode == nil then
    self.groundReferenceNode = self.components[1].node
  end
  self.animTime = 0
  self.rotors = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.rotors.rotor(%d)", i)
    local node = {}
    node.index = getXMLString(xmlFile, baseName .. "#index")
    local direction = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#direction"), 1)
    node.speed = direction * Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#speed"), -0.008)
    if node.index == nil then
      break
    end
    node.index = Utils.indexToObject(self.components, node.index)
    if node.index ~= nil then
      table.insert(self.rotors, node)
    end
    i = i + 1
  end
  local numTedderDropAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.tedderDropAreas#count"), 0)
  if numTedderDropAreas ~= table.getn(self.cuttingAreas) then
    print("Warning: Number of cutting areas and drop areas should be equal")
  end
  self.tedderDropAreas = {}
  for i = 1, numTedderDropAreas do
    self.tedderDropAreas[i] = {}
    local areanamei = string.format("vehicle.tedderDropAreas.tedderDropArea%d", i)
    self.tedderDropAreas[i].start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    self.tedderDropAreas[i].width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    self.tedderDropAreas[i].height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
    self.cuttingAreas[i].grassParticleSystemIndex = getXMLInt(xmlFile, areanamei .. "#particleSystemIndex")
  end
  self.speedRotatingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.speedRotatingParts.speedRotatingPart(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      local entry = {}
      entry.node = node
      entry.rotationSpeedScale = getXMLFloat(xmlFile, baseName .. "#rotationSpeedScale")
      if entry.rotationSpeedScale == nil then
        entry.rotationSpeedScale = 1 / Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#radius"), 1)
      end
      entry.foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#foldMinLimit"), 0)
      entry.foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#foldMaxLimit"), 1)
      table.insert(self.speedRotatingParts, entry)
    end
    i = i + 1
  end
  self.grassParticleSystems = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.grassParticleSystems.grassParticleSystem(%d)", i)
    local particleSystem = {}
    particleSystem.ps = {}
    local ps = Utils.loadParticleSystem(xmlFile, particleSystem.ps, baseName, self.components, false, nil, self.baseDirectory)
    if ps == nil then
      break
    end
    particleSystem.disableTime = 0
    particleSystem.isEnabled = false
    table.insert(self.grassParticleSystems, particleSystem)
    i = i + 1
  end
  if self.isClient then
    local tedderSound = getXMLString(xmlFile, "vehicle.tedderSound#file")
    if tedderSound ~= nil and tedderSound ~= "" then
      tedderSound = Utils.getFilename(tedderSound, self.baseDirectory)
      self.tedderSound = createSample("tedderSound")
      self.tedderSoundEnabled = false
      loadSample(self.tedderSound, tedderSound, false)
      self.tedderSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tedderSound#pitchOffset"), 1)
      self.tedderSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tedderSound#volume"), 1)
    end
  end
  self.isTurnedOn = false
  self.wasToFast = false
  self.tedderParticleSystemFlag = self:getNextDirtyFlag()
end
function Tedder:delete()
  for k, v in pairs(self.grassParticleSystems) do
    Utils.deleteParticleSystem(v.ps)
  end
  if self.tedderSound ~= nil then
    delete(self.tedderSound)
  end
end
function Tedder:readStream(streamId, connection)
  local isTurnedOn = streamReadBool(streamId)
  local animTime = streamReadFloat32(streamId)
  Tedder.setRotorAnimTime(self, animTime)
  self:setIsTurnedOn(isTurnedOn, true)
end
function Tedder:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isTurnedOn)
  streamWriteFloat32(streamId, self.animTime)
end
function Tedder:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    local hasUpdate = streamReadBool(streamId)
    if hasUpdate then
      for k, v in ipairs(self.grassParticleSystems) do
        local enabled = streamReadBool(streamId)
        Utils.setEmittingState(v.ps, enabled)
      end
    end
  end
end
function Tedder:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    if bitAND(dirtyMask, self.tedderParticleSystemFlag) ~= 0 then
      streamWriteBool(streamId, true)
      for k, v in ipairs(self.grassParticleSystems) do
        streamWriteBool(streamId, v.isEnabled)
      end
    else
      streamWriteBool(streamId, false)
    end
  end
end
function Tedder:mouseEvent(posX, posY, isDown, isUp, button)
end
function Tedder:keyEvent(unicode, sym, modifier, isDown)
end
function Tedder:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setIsTurnedOn(not self.isTurnedOn)
  end
end
function Tedder:updateTick(dt)
  self.wasToFast = false
  if self:getIsActive() then
    local hasGroundContact = false
    local x, y, z = getWorldTranslation(self.groundReferenceNode)
    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
    if y <= terrainHeight + self.groundReferenceThreshold then
      hasGroundContact = true
    end
    if hasGroundContact then
      local foldAnimTime = self.foldAnimTime
      if self.isTurnedOn then
        local toFast = self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 31
        if self.isServer then
          local cuttingAreasSend = {}
          if not toFast then
            local numAreas = math.min(table.getn(self.tedderDropAreas), table.getn(self.cuttingAreas))
            for i = 1, numAreas do
              local cuttingArea = self.cuttingAreas[i]
              if self:getIsAreaActive(cuttingArea) then
                local x, y, z = getWorldTranslation(cuttingArea.start)
                local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
                local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
                local dropArea = self.tedderDropAreas[i]
                local dx, dy, dz = getWorldTranslation(dropArea.start)
                local dx1, dy1, dz1 = getWorldTranslation(dropArea.width)
                local dx2, dy2, dz2 = getWorldTranslation(dropArea.height)
                table.insert(cuttingAreasSend, {
                  x,
                  z,
                  x1,
                  z1,
                  x2,
                  z2,
                  dx,
                  dz,
                  dx1,
                  dz1,
                  dx2,
                  dz2,
                  0,
                  i
                })
              end
            end
            if 0 < table.getn(cuttingAreasSend) then
              local cuttingAreasSend, bitType = TedderAreaEvent.runLocally(cuttingAreasSend)
              if 0 < table.getn(cuttingAreasSend) then
                for i = 1, table.getn(cuttingAreasSend) do
                  local cuttingArea = self.cuttingAreas[cuttingAreasSend[i][14]]
                  if cuttingArea.grassParticleSystemIndex ~= nil then
                    local ps = self.grassParticleSystems[cuttingArea.grassParticleSystemIndex + 1]
                    if ps ~= nil then
                      ps.disableTime = self.time + 300
                      if not ps.isEnabled then
                        ps.isEnabled = true
                        self:raiseDirtyFlags(self.tedderParticleSystemFlag)
                        if self.isClient then
                          Utils.setEmittingState(ps.ps, true)
                        end
                      end
                    end
                  end
                end
                g_server:broadcastEvent(TedderAreaEvent:new(cuttingAreasSend, bitType))
              end
            end
          end
        end
        self.wasToFast = toFast
      end
      for k, v in pairs(self.speedRotatingParts) do
        if foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit then
          rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
        end
      end
    end
    if self.isServer then
      for k, v in pairs(self.grassParticleSystems) do
        if self.time > v.disableTime and v.isEnabled then
          v.isEnabled = false
          self:raiseDirtyFlags(self.tedderParticleSystemFlag)
          if self.isClient then
            Utils.setEmittingState(v.ps, false)
          end
        end
      end
    end
    if self.isTurnedOn then
      self.animTime = self.animTime + dt
      Tedder.setRotorAnimTime(self, self.animTime)
      if self.isClient and not self.tedderSoundEnabled and self:getIsActiveForSound() then
        playSample(self.tedderSound, 0, self.tedderSoundVolume, 0)
        setSamplePitch(self.tedderSound, self.tedderSoundPitchOffset)
        self.tedderSoundEnabled = true
      end
    end
  end
end
function Tedder:draw()
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
function Tedder:onDetach()
  if self.deactivateOnDetach then
    Tedder.onDeactivate(self)
  else
    Tedder.onDeactivateSounds(self)
  end
end
function Tedder:onLeave()
  if self.deactivateOnLeave then
    Tedder.onDeactivate(self)
  else
    Tedder.onDeactivateSounds(self)
  end
end
function Tedder:onDeactivate()
  if self.isClient then
    for k, v in pairs(self.grassParticleSystems) do
      v.isEnabled = false
      Utils.setEmittingState(v.ps, false)
    end
  end
  Tedder.onDeactivateSounds(self)
  self.isTurnedOn = false
end
function Tedder:onDeactivateSounds()
  if self.tedderSoundEnabled then
    stopSample(self.tedderSound)
    self.tedderSoundEnabled = false
  end
end
function Tedder:setIsTurnedOn(isTurnedOn, noEventSend)
  SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
  self.isTurnedOn = isTurnedOn
  if not isTurnedOn and self.tedderSoundEnabled then
    stopSample(self.tedderSound)
    self.tedderSoundEnabled = false
  end
end
function Tedder:setRotorAnimTime(animTime)
  self.animTime = animTime
  for i = 1, table.getn(self.rotors) do
    local rotor = self.rotors[i].index
    local rotorRot = self.rotors[i].speed * animTime
    setRotation(rotor, 0, rotorRot, 0)
  end
end
