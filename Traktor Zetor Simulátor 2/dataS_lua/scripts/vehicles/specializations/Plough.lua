Plough = {}
source("dataS/scripts/vehicles/specializations/PloughRotationEvent.lua")
source("dataS/scripts/vehicles/specializations/PloughAreaEvent.lua")
function Plough.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function Plough:load(xmlFile)
  self.groundContactReport = SpecializationUtil.callSpecializationsFunction("groundContactReport")
  self.setRotationMax = SpecializationUtil.callSpecializationsFunction("setRotationMax")
  local rotationPartNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.rotationPart#index"))
  if rotationPartNode ~= nil then
    self.rotationPart = {}
    self.rotationPart.node = rotationPartNode
    local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.rotationPart#minRot"))
    self.rotationPart.minRot = {}
    self.rotationPart.minRot[1] = Utils.degToRad(Utils.getNoNil(x, 0))
    self.rotationPart.minRot[2] = Utils.degToRad(Utils.getNoNil(y, 0))
    self.rotationPart.minRot[3] = Utils.degToRad(Utils.getNoNil(z, 0))
    x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.rotationPart#maxRot"))
    self.rotationPart.maxRot = {}
    self.rotationPart.maxRot[1] = Utils.degToRad(Utils.getNoNil(x, 0))
    self.rotationPart.maxRot[2] = Utils.degToRad(Utils.getNoNil(y, 0))
    self.rotationPart.maxRot[3] = Utils.degToRad(Utils.getNoNil(z, 0))
    self.rotationPart.rotTime = Utils.getNoNil(getXMLString(xmlFile, "vehicle.rotationPart#rotTime"), 2) * 1000
    self.rotationPart.touchRotLimit = Utils.degToRad(Utils.getNoNil(getXMLString(xmlFile, "vehicle.rotationPart#touchRotLimit"), 10))
  end
  self.contactReportNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.contactReportNode#index"))
  if self.contactReportNode == nil then
    self.contactReportNode = self.components[1].node
  end
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  local ploughTurnSound = getXMLString(xmlFile, "vehicle.ploughTurnSound#file")
  if ploughTurnSound ~= nil and ploughTurnSound ~= "" then
    ploughTurnSound = Utils.getFilename(ploughTurnSound, self.baseDirectory)
    self.ploughTurnSound = createSample("ploughTurnSound")
    loadSample(self.ploughTurnSound, ploughTurnSound, false)
    self.ploughTurnSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.ploughTurnSound#pitchOffset"), 0)
    self.ploughTurnSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.ploughTurnSound#volume"), 1)
    self.ploughTurnSoundEnabled = false
  end
  local ploughSound = getXMLString(xmlFile, "vehicle.ploughSound#file")
  if ploughSound ~= nil and ploughSound ~= "" then
    ploughSound = Utils.getFilename(ploughSound, self.baseDirectory)
    self.ploughSound = createSample("ploughSound")
    loadSample(self.ploughSound, ploughSound, false)
    self.ploughSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.ploughSound#pitchOffset"), 0)
    self.ploughSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.ploughSound#volume"), 1)
    self.ploughSoundEnabled = false
  end
  self.groundParticleSystems = {}
  local psName = "vehicle.groundParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.groundParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.groundParticleSystemActive = false
  self.aiTerrainDetailChannel1 = g_currentMission.sowingChannel
  self.aiTerrainDetailChannel2 = g_currentMission.cultivatorChannel
  self.rotateLeftToMax = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.rotateLeftToMax#value"), true)
  self.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.onlyActiveWhenLowered#value"), true)
  self.ploughHasGroundContact = false
  self.ploughHasContactReport = false
  self.rotationMax = false
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
  self.ploughContactReportsActive = false
  self.startActivationTimeout = 2000
  self.startActivationTime = 0
  self.ploughLimitToField = false
  self.ploughGroundContactFlag = self.nextDirtyFlag
  self.nextDirtyFlag = self.ploughGroundContactFlag * 2
end
function Plough:delete()
  Utils.deleteParticleSystem(self.groundParticleSystems)
  if self.ploughTurnSound ~= nil then
    delete(self.ploughTurnSound)
  end
  if self.ploughSound ~= nil then
    delete(self.ploughSound)
  end
  Plough.removeContactReports(self)
end
function Plough:readStream(streamId, connection)
  self.rotateMax = streamReadBool(streamId)
  if self.rotationPart ~= nil then
    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    setRotation(self.rotationPart.node, x, y, z)
  end
end
function Plough:writeStream(streamId, connection)
  streamWriteBool(streamId, self.rotateMax)
  if self.rotationPart ~= nil then
    local x, y, z = getRotation(self.rotationPart.node)
    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)
  end
end
function Plough:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    self.ploughHasGroundContact = streamReadBool(streamId)
  end
end
function Plough:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.ploughHasGroundContact)
  end
end
function Plough:mouseEvent(posX, posY, isDown, isUp, button)
end
function Plough:keyEvent(unicode, sym, modifier, isDown)
end
function Plough:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setRotationMax(not self.rotationMax)
  end
end
function Plough:updateTick(dt)
  if self:getIsActive() then
    local updateDensity = true
    if self.rotationPart ~= nil then
      local x, y, z = getRotation(self.rotationPart.node)
      local maxRot = self.rotationPart.maxRot
      local minRot = self.rotationPart.minRot
      local eps = self.rotationPart.touchRotLimit
      if eps < math.abs(x - maxRot[1]) and eps < math.abs(x - minRot[1]) or eps < math.abs(y - maxRot[2]) and eps < math.abs(y - minRot[2]) or eps < math.abs(z - maxRot[3]) and eps < math.abs(z - minRot[3]) then
        updateDensity = false
        if self.isClient and self.ploughTurnSound ~= nil and not self.ploughTurnSoundEnabled and self:getIsActiveForSound() then
          playSample(self.ploughTurnSound, 0, self.ploughTurnSoundVolume, 0)
          setSamplePitch(self.ploughTurnSound, self.ploughTurnSoundPitchOffset)
          self.ploughTurnSoundEnabled = true
        end
      elseif self.isClient then
        stopSample(self.ploughTurnSound)
        self.ploughTurnSoundEnabled = false
      end
      local x, y, z = getRotation(self.rotationPart.node)
      local rot = {
        x,
        y,
        z
      }
      local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart.maxRot, self.rotationPart.minRot, 3, self.rotationPart.rotTime, dt, not self.rotationMax)
      setRotation(self.rotationPart.node, unpack(newRot))
    end
    if self.isServer then
      local hasGroundContact = self.ploughHasContactReport
      if not hasGroundContact and self.groundReferenceNode ~= nil then
        local x, y, z = getWorldTranslation(self.groundReferenceNode)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        if y <= terrainHeight + self.groundReferenceThreshold then
          hasGroundContact = true
        end
      end
      if self.ploughHasGroundContact ~= hasGroundContact then
        self:raiseDirtyFlags(self.ploughGroundContactFlag)
      end
      self.ploughHasGroundContact = hasGroundContact
    end
    local hasGroundContact = self.ploughHasGroundContact
    if hasGroundContact and updateDensity then
      if self.startActivationTime <= self.time and self.isServer then
        local cuttingAreasSend = {}
        if not self.onlyActiveWhenLowered or self:isLowered(false) then
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
            local limitToField = self.ploughLimitToField
            if not g_currentMission.allowClientsCreateFields then
              local owner = self:getOwner()
              if owner ~= nil and not owner:getIsLocal() then
                limitToField = true
              end
            end
            PloughAreaEvent.runLocally(cuttingAreasSend, limitToField)
            g_server:broadcastEvent(PloughAreaEvent:new(cuttingAreasSend, limitToField))
          end
        end
      end
      if self:doCheckSpeedLimit() and self.attacherVehicle.lastSpeed * 3600 > 20 then
        self.speedViolationTimer = self.speedViolationTimer - dt
        if self.isServer and 0 > self.speedViolationTimer then
          self.attacherVehicle:detachImplementByObject(self)
        end
      else
        self.speedViolationTimer = self.speedViolationMaxTime
      end
      if self.isClient and self.ploughSound ~= nil and not self.ploughSoundEnabled and 3 < self.lastSpeed * 3600 and self:getIsActiveForSound() then
        playSample(self.ploughSound, 0, self.ploughSoundVolume, 0)
        setSamplePitch(self.ploughSound, self.ploughSoundPitchOffset)
        self.ploughSoundEnabled = true
      end
      if self.lastSpeed * 3600 > 5 and not self.groundParticleSystemActive then
        self.groundParticleSystemActive = true
        Utils.setEmittingState(self.groundParticleSystems, true)
      end
      if self.lastSpeed * 3600 < 5 and self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
    else
      self.speedViolationTimer = self.speedViolationMaxTime
      if self.ploughSoundEnabled then
        stopSample(self.ploughSound)
        self.ploughSoundEnabled = false
      end
      if self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
    end
  elseif self.groundParticleSystemActive then
    self.groundParticleSystemActive = false
    Utils.setEmittingState(self.groundParticleSystems, false)
  end
  if self.ploughSoundEnabled and self.isClient and 3 > self.lastSpeed * 3600 then
    stopSample(self.ploughSound)
    self.ploughSoundEnabled = false
  end
end
function Plough:draw()
  g_currentMission:addHelpButtonText(g_i18n:getText("Turn_plough"), InputBinding.IMPLEMENT_EXTRA)
  if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "1", InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL1)), 0.092, 0.048)
  end
end
function Plough:onAttach(attacherVehicle)
  Plough.onActivate(self)
  Plough.addContactReports(self)
  self.startActivationTime = self.time + self.startActivationTimeout
end
function Plough:onDetach()
  self.ploughLimitToField = false
  if self.deactivateOnDetach then
    Plough.onDeactivate(self)
    Plough.removeContactReports(self)
  else
    Plough.onDeactivateSounds(self)
  end
end
function Plough:onActivate()
end
function Plough:onDeactivate()
  self.speedViolationTimer = self.speedViolationMaxTime
  if self.groundParticleSystemActive then
    self.groundParticleSystemActive = false
    Utils.setEmittingState(self.groundParticleSystems, false)
  end
  Plough.onDeactivateSounds(self)
end
function Plough:onDeactivateSounds()
  if self.ploughSoundEnabled then
    stopSample(self.ploughSound)
    self.ploughSoundEnabled = false
  end
  if self.ploughTurnSound ~= nil and self.ploughTurnSoundEnabled then
    stopSample(self.ploughTurnSound)
    self.ploughTurnSoundEnabled = false
  end
end
function Plough:aiRotateLeft()
  self.rotationMax = self.rotateLeftToMax
end
function Plough:aiRotateRight()
  self.rotationMax = not self.rotateLeftToMax
end
function Plough:aiTurnOn()
  self.ploughLimitToField = true
end
function Plough:aiTurnOff()
  self.ploughLimitToField = false
end
function Plough:aiInvertsMarkerOnTurn(turnLeft)
  if turnLeft then
    return self.rotationMax ~= self.rotateLeftToMax
  else
    return self.rotationMax == self.rotateLeftToMax
  end
end
function Plough:addContactReports()
  if not self.ploughContactReportsActive then
    addContactReport(self.contactReportNode, 1.0E-4, "groundContactReport", self)
    self.ploughContactReportsActive = true
  end
end
function Plough:removeContactReports()
  if self.ploughContactReportsActive then
    removeContactReport(self.contactReportNode)
    self.ploughHasContactReport = false
    self.ploughContactReportsActive = false
  end
end
function Plough:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)
  if otherObjectId == g_currentMission.terrainRootNode then
    self.ploughHasContactReport = isStart or 0 < normalForce or 0 < tangentialForce
  end
end
function Plough:setRotationMax(rotationMax, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(PloughRotationEvent:new(self, rotationMax), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(PloughRotationEvent:new(self, rotationMax))
    end
  end
  self.rotationMax = rotationMax
end
