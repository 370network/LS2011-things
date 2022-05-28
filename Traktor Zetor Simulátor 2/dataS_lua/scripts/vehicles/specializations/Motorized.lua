Motorized = {}
source("dataS/scripts/vehicles/specializations/SteerableToggleRefuelEvent.lua")
source("dataS/scripts/vehicles/specializations/SetMotorTurnedOnEvent.lua")
function Motorized.prerequisitesPresent(specializations)
  return true
end
function Motorized:load(xmlFile)
  self.startMotor = SpecializationUtil.callSpecializationsFunction("startMotor")
  self.stopMotor = SpecializationUtil.callSpecializationsFunction("stopMotor")
  self.startRefuel = SpecializationUtil.callSpecializationsFunction("startRefuel")
  self.stopRefuel = SpecializationUtil.callSpecializationsFunction("stopRefuel")
  self.setFuelFillLevel = SpecializationUtil.callSpecializationsFunction("setFuelFillLevel")
  self.fuelCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelCapacity"), 500)
  self.fuelUsage = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelUsage"), 0.01)
  self.setHasRefuelStationInRange = Motorized.setHasRefuelStationInRange
  self.motorizedFillActivatable = MotorizedRefuelActivatable:new(self)
  self.hasRefuelStationInRange = false
  self.doRefuel = false
  self:setFuelFillLevel(self.fuelCapacity)
  self.sentFuelFillLevel = self.fuelFillLevel
  self.refuelSampleRunning = false
  self.refuelSample = createSample("refuelSample")
  loadSample(self.refuelSample, "data/maps/sounds/refuel.wav", false)
  local motorMinRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#minRpm"), 1000)
  local motorMaxRpmStr = getXMLString(xmlFile, "vehicle.motor#maxRpm")
  local motorMaxRpm1, motorMaxRpm2, motorMaxRpm3, motorMaxRpm4 = Utils.getVectorFromString(motorMaxRpmStr)
  motorMaxRpm1 = Utils.getNoNil(motorMaxRpm1, 800)
  motorMaxRpm2 = Utils.getNoNil(motorMaxRpm2, 1000)
  motorMaxRpm3 = Utils.getNoNil(motorMaxRpm3, 1800)
  motorMaxRpm4 = Utils.getNoNil(motorMaxRpm4, motorMaxRpm2)
  local motorMaxRpm = {
    motorMaxRpm1,
    motorMaxRpm2,
    motorMaxRpm3,
    motorMaxRpm4
  }
  local brakeForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#brakeForce"), 10) * 2
  local lowBrakeForceScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#lowBrakeForceScale"), 0.5)
  local lowBrakeForceSpeedLimit = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#lowBrakeForceSpeedLimit"), 20) / 3600
  local accelerationsStr = getXMLString(xmlFile, "vehicle.motor#accelerations")
  local acceleration1, acceleration2, acceleration3, acceleration4 = Utils.getVectorFromString(accelerationsStr)
  acceleration1 = Utils.getNoNil(acceleration1, 0.8)
  acceleration2 = Utils.getNoNil(acceleration2, 0.8)
  acceleration3 = Utils.getNoNil(acceleration3, 1)
  acceleration4 = Utils.getNoNil(acceleration4, 0.8)
  local accelerations = {
    acceleration1,
    acceleration2,
    acceleration3,
    acceleration4
  }
  local maxTorque1, maxTorque2, maxTorque3, maxTorque4 = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.motor#maxTorques"))
  maxTorque1 = Utils.getNoNil(maxTorque1, -1) * 3
  maxTorque2 = Utils.getNoNil(maxTorque2, -1) * 3
  maxTorque3 = Utils.getNoNil(maxTorque3, -1) * 3
  maxTorque4 = Utils.getNoNil(maxTorque4, -1) * 3
  local maxTorques = {
    maxTorque1,
    maxTorque2,
    maxTorque3,
    maxTorque4
  }
  local forwardGearRatioStr = getXMLString(xmlFile, "vehicle.motor#forwardGearRatio")
  local forwardGearRatio1, forwardGearRatio2, forwardGearRatio3, forwardGearRatio4 = Utils.getVectorFromString(forwardGearRatioStr)
  forwardGearRatio1 = Utils.getNoNil(forwardGearRatio1, 2)
  forwardGearRatio2 = Utils.getNoNil(forwardGearRatio2, forwardGearRatio1)
  forwardGearRatio3 = Utils.getNoNil(forwardGearRatio3, forwardGearRatio2)
  forwardGearRatio4 = Utils.getNoNil(forwardGearRatio4, forwardGearRatio2)
  local forwardGearRatios = {
    forwardGearRatio1,
    forwardGearRatio2,
    forwardGearRatio3,
    forwardGearRatio4
  }
  local backwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#backwardGearRatio"), 1.5)
  local differentialRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#differentialRatio"), 1)
  local rpmFadeOutRange = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#rpmFadeOutRange"), 20)
  local forwardTorqueCurve = AnimCurve:new(linearInterpolator1)
  local backwardTorqueCurve = AnimCurve:new(linearInterpolator1)
  local hasBackwardTorqueCurve = false
  local torqueI = 0
  while true do
    local key = string.format("vehicle.motor.backwardTorque(%d)", torqueI)
    local rpm = getXMLFloat(xmlFile, key .. "#rpm")
    local torque = getXMLFloat(xmlFile, key .. "#torque")
    if torque == nil or rpm == nil then
      break
    end
    hasBackwardTorqueCurve = true
    backwardTorqueCurve:addKeyframe({
      v = torque * 3,
      time = rpm
    })
    torqueI = torqueI + 1
  end
  local torqueI = 0
  while true do
    local key = string.format("vehicle.motor.torque(%d)", torqueI)
    local rpm = getXMLFloat(xmlFile, key .. "#rpm")
    local torque = getXMLFloat(xmlFile, key .. "#torque")
    if torque == nil or rpm == nil then
      break
    end
    forwardTorqueCurve:addKeyframe({
      v = torque * 3,
      time = rpm
    })
    if not hasBackwardTorqueCurve then
      backwardTorqueCurve:addKeyframe({
        v = torque * 3,
        time = rpm
      })
    end
    torqueI = torqueI + 1
  end
  self.motor = VehicleMotor:new(motorMinRpm, motorMaxRpm, forwardTorqueCurve, backwardTorqueCurve, brakeForce, accelerations, forwardGearRatios, backwardGearRatio, differentialRatio, rpmFadeOutRange, maxTorques)
  self.motor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
  local motorStartSound = getXMLString(xmlFile, "vehicle.motorStartSound#file")
  if motorStartSound ~= nil and motorStartSound ~= "" then
    motorStartSound = Utils.getFilename(motorStartSound, self.baseDirectory)
    self.motorStartSound = createSample("motorStartSound")
    loadSample(self.motorStartSound, motorStartSound, false)
    self.motorStartSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStartSound#pitchOffset"), 0)
    self.motorStartSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStartSound#volume"), 1)
    self.motorStartDuration = getSampleDuration(self.motorStartSound)
  end
  local motorStopSound = getXMLString(xmlFile, "vehicle.motorStopSound#file")
  if motorStopSound ~= nil and motorStopSound ~= "" then
    motorStopSound = Utils.getFilename(motorStopSound, self.baseDirectory)
    self.motorStopSound = createSample("motorStopSound")
    loadSample(self.motorStopSound, motorStopSound, false)
    self.motorStopSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStopSound#pitchOffset"), 0)
    self.motorStopSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStopSound#volume"), 1)
  end
  local motorSound = getXMLString(xmlFile, "vehicle.motorSound#file")
  if motorSound ~= nil and motorSound ~= "" then
    motorSound = Utils.getFilename(motorSound, self.baseDirectory)
    self.motorSound = createSample("motorSound")
    loadSample(self.motorSound, motorSound, false)
    self.motorSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchOffset"), 0)
    self.motorSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchScale"), 0.05)
    self.motorSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchMax"), 2)
    self.motorSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#volume"), 1)
    self.motorSoundEnabled = false
  end
  local motorSoundRun = getXMLString(xmlFile, "vehicle.motorSoundRun#file")
  if motorSoundRun ~= nil and motorSoundRun ~= "" then
    motorSoundRun = Utils.getFilename(motorSoundRun, self.baseDirectory)
    self.motorSoundRun = createSample("motorSoundRun")
    loadSample(self.motorSoundRun, motorSoundRun, false)
    self.motorSoundRunPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchOffset"), 0)
    self.motorSoundRunPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchScale"), 0.05)
    self.motorSoundRunPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchMax"), 2)
    self.motorSoundRunVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#volume"), 1)
  end
  self.motorStartDuration = 0
  if self.motorStartSound ~= nil then
    self.motorStartDuration = getSampleDuration(self.motorStartSound)
  end
  self.motorStartDuration = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStartDuration"), self.motorStartDuration)
  self.motorStartTime = 0
  local reverseDriveSound = getXMLString(xmlFile, "vehicle.reverseDriveSound#file")
  if reverseDriveSound ~= nil and reverseDriveSound ~= "" then
    reverseDriveSound = Utils.getFilename(reverseDriveSound, self.baseDirectory)
    self.reverseDriveSound = createSample("reverseDriveSound")
    self.reverseDriveSoundEnabled = false
    loadSample(self.reverseDriveSound, reverseDriveSound, false)
    self.reverseDriveSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.reverseDriveSound#volume"), 1)
  end
  local compressedAirSound = getXMLString(xmlFile, "vehicle.compressedAirSound#file")
  if compressedAirSound ~= nil and compressedAirSound ~= "" then
    compressedAirSound = Utils.getFilename(compressedAirSound, self.baseDirectory)
    self.compressedAirSound = createSample("compressedAirSound")
    self.compressedAirSoundEnabled = false
    loadSample(self.compressedAirSound, compressedAirSound, false)
    self.compressedAirSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressedAirSound#pitchOffset"), 1)
    self.compressedAirSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressedAirSound#volume"), 1)
  end
  local compressionSound = getXMLString(xmlFile, "vehicle.compressionSound#file")
  if compressionSound ~= nil and compressionSound ~= "" then
    compressionSound = Utils.getFilename(compressionSound, self.baseDirectory)
    self.compressionSound = createSample("compressionSound")
    loadSample(self.compressionSound, compressionSound, false)
    self.compressionSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressionSound#pitchOffset"), 1)
    self.compressionSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressionSound#volume"), 1)
    self.compressionSoundTime = 0
    self.compressionSoundEnabled = false
  end
  self.isMotorStarted = false
  self.exhaustParticleSystems = {}
  local exhaustParticleSystemCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.exhaustParticleSystems#count"), 0)
  for i = 1, exhaustParticleSystemCount do
    local namei = string.format("vehicle.exhaustParticleSystems.exhaustParticleSystem%d", i)
    Utils.loadParticleSystem(xmlFile, self.exhaustParticleSystems, namei, self.components, false, nil, self.baseDirectory)
  end
  self.lastRoundPerMinute = 0
  self.motorizedDirtyFlag = self:getNextDirtyFlag()
end
function Motorized:delete()
  Utils.deleteParticleSystem(self.exhaustParticleSystems)
  if self.refuelSample ~= nil then
    delete(self.refuelSample)
    self.refuelSample = nil
  end
  if self.motorSound ~= nil then
    delete(self.motorSound)
  end
  if self.motorSoundRun ~= nil then
    delete(self.motorSoundRun)
  end
  if self.motorStartSound ~= nil then
    delete(self.motorStartSound)
  end
  if self.motorStopSound ~= nil then
    delete(self.motorStopSound)
  end
  if self.reverseDriveSound ~= nil then
    delete(self.reverseDriveSound)
  end
  if self.compressedAirSound ~= nil then
    delete(self.compressedAirSound)
  end
  if self.compressionSound ~= nil then
    delete(self.compressionSound)
  end
end
function Motorized:readStream(streamId, connection)
  local isMotorStarted = streamReadBool(streamId)
  if isMotorStarted then
    self:startMotor(true)
  else
    self:stopMotor(true)
  end
  local doRefuel = streamReadBool(streamId)
  if doRefuel then
    self:startRefuel(true)
  else
    self:stopRefuel(true)
  end
  local newFuelFillLevel = streamReadFloat32(streamId)
  self:setFuelFillLevel(newFuelFillLevel)
end
function Motorized:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isMotorStarted)
  streamWriteBool(streamId, self.doRefuel)
  streamWriteFloat32(streamId, self.fuelFillLevel)
end
function Motorized:readUpdateStream(streamId, timestamp, connection)
  if connection.isServer and streamReadBool(streamId) then
    local fuelFillLevel = streamReadUIntN(streamId, 15) / 32767 * self.fuelCapacity
    self:setFuelFillLevel(fuelFillLevel)
  end
end
function Motorized:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection.isServer and streamWriteBool(streamId, bitAND(dirtyMask, self.motorizedDirtyFlag) ~= 0) then
    local percent = 0
    if self.fuelCapacity ~= 0 then
      percent = Utils.clamp(self.fuelFillLevel / self.fuelCapacity, 0, 1)
    end
    streamWriteUIntN(streamId, math.floor(percent * 32767), 15)
  end
end
function Motorized:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local fuelFillLevel = getXMLFloat(xmlFile, key .. "#fuelFillLevel")
  if fuelFillLevel ~= nil then
    if self.fuelCapacity ~= 0 then
      local minFuelFillLevel = 0.1 * self.fuelCapacity
      local numToRefill = math.max(minFuelFillLevel - fuelFillLevel, 0)
      if 0 < numToRefill then
        fuelFillLevel = minFuelFillLevel
        local delta = numToRefill * g_fuelPricePerLiter
        g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta
        g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta
        g_currentMission:addSharedMoney(-delta)
      end
    end
    self:setFuelFillLevel(fuelFillLevel)
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Motorized:getSaveAttributesAndNodes(nodeIdent)
  local attributes = "fuelFillLevel=\"" .. self.fuelFillLevel .. "\""
  return attributes, nil
end
function Motorized:mouseEvent(posX, posY, isDown, isUp, button)
end
function Motorized:keyEvent(unicode, sym, modifier, isDown)
end
function Motorized:updateTick(dt)
  if self.isServer and math.abs(self.fuelFillLevel - self.sentFuelFillLevel) > 0.001 then
    self:raiseDirtyFlags(self.motorizedDirtyFlag)
    self.sentFuelFillLevel = self.fuelFillLevel
  end
end
function Motorized:update(dt)
  if self.doRefuel then
    if self.isClient then
      if self:getIsActiveForSound() then
        if not self.refuelSampleRunning then
          playSample(self.refuelSample, 0, 1, 0)
          self.refuelSampleRunning = true
        end
      elseif self.refuelSampleRunning then
        stopSample(self.refuelSample)
        self.refuelSampleRunning = false
      end
    end
    if self.isServer then
      local refuelSpeed = 0.01
      local currentFillLevel = self.fuelFillLevel
      self:setFuelFillLevel(self.fuelFillLevel + refuelSpeed * dt)
      local delta = self.fuelFillLevel - currentFillLevel
      if delta <= 0.05 then
        self:stopRefuel()
      end
      delta = delta * g_fuelPricePerLiter
      g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta
      g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta
      g_currentMission:addSharedMoney(-delta)
    end
  elseif self.refuelSampleRunning then
    stopSample(self.refuelSample)
    self.refuelSampleRunning = false
  end
  if self.isMotorStarted then
    if self:getIsActiveForSound() then
      if self.motorSound ~= nil and not self.motorSoundEnabled and self.playMotorSoundTime <= self.time then
        playSample(self.motorSound, 0, self.motorSoundVolume, 0)
        if self.motorSoundRun ~= nil then
          playSample(self.motorSoundRun, 0, 0, 0)
        end
        self.motorSoundEnabled = true
      end
      if self.compressionSound ~= nil and not self.compressionSoundEnabled and self.compressionSoundTime <= self.time then
        playSample(self.compressionSound, 1, self.compressionSoundVolume, 0)
        setSamplePitch(self.compressionSound, self.compressionSoundPitchOffset)
        self.compressionSoundTime = self.time + 180000
        self.compressionSoundEnabled = true
      end
    end
    if self.reverseDriveSound ~= nil then
      local isDrivingBackwards = self.movingDirection == -1
      if self.lastAcceleration ~= nil and 0 <= self.lastAcceleration then
        isDrivingBackwards = false
      end
      if isDrivingBackwards then
        if not self.reverseDriveSoundEnabled and self:getIsActiveForSound() then
          playSample(self.reverseDriveSound, 0, self.reverseDriveSoundVolume, 0)
          self.reverseDriveSoundEnabled = true
        end
      elseif self.reverseDriveSoundEnabled then
        stopSample(self.reverseDriveSound)
        self.reverseDriveSoundEnabled = false
      end
    end
    if 0 < table.getn(self.wheels) then
      local alpha = 0.9
      local roundPerMinute = self.lastRoundPerMinute * alpha + (1 - alpha) * (self.motor.lastMotorRpm - self.motor.minRpm)
      self.lastRoundPerMinute = roundPerMinute
      local roundPerSecond = roundPerMinute / 60
      if self.motorSound ~= nil then
        setSamplePitch(self.motorSound, math.min(self.motorSoundPitchOffset + self.motorSoundPitchScale * math.abs(roundPerSecond), self.motorSoundPitchMax))
        if self.motorSoundRun ~= nil then
          setSamplePitch(self.motorSoundRun, math.min(self.motorSoundRunPitchOffset + self.motorSoundRunPitchScale * math.abs(roundPerSecond), self.motorSoundRunPitchMax))
        end
      end
      local input = 0
      if self.axisForward ~= nil then
        input = self.axisForward
      end
      if self.compressedAirSound ~= nil then
        local maxRpm = self.motor:getMaxRpm()
        local enoughRpm = false
        if self.motor.lastMotorRpm > maxRpm / 2 then
          enoughRpm = true
        end
        if input < -0.5 and enoughRpm then
          self.compressedAirSoundEnabled = false
        end
        if 0.7 < input and not self.compressedAirSoundEnabled and enoughRpm then
          if self:getIsActiveForSound() then
            playSample(self.compressedAirSound, 1, self.compressedAirSoundVolume, 0)
            setSamplePitch(self.compressedAirSound, self.compressedAirSoundPitchOffset)
          end
          self.compressedAirSoundEnabled = true
        end
      end
      if self.motorSoundRun ~= nil then
        local maxRpm = self.motor.maxRpm[3]
        if 0.01 < math.abs(input) or self.motor.speedLevel ~= 0 then
          local rpmVolume = Utils.clamp(math.abs(roundPerMinute) / (maxRpm - self.motor.minRpm), 0, 1)
          setSampleVolume(self.motorSoundRun, rpmVolume)
        else
          local rpmVolume = Utils.clamp(math.abs(roundPerMinute) / ((maxRpm - self.motor.minRpm) * 2), 0, 1)
          setSampleVolume(self.motorSoundRun, rpmVolume)
        end
      end
    end
  end
end
function Motorized:draw()
end
function Motorized:startMotor(noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self, true), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent:new(self, true))
    end
  end
  if not self.isMotorStarted then
    self.isMotorStarted = true
    self.reverseDriveSoundEnabled = false
    local motorSoundDuration = 0
    if self.motorStartSound ~= nil then
      if self.isClient and self:getIsActiveForSound() then
        playSample(self.motorStartSound, 1, self.motorStartSoundVolume, 0)
        setSamplePitch(self.motorStartSound, self.motorStartSoundPitchOffset)
      end
      motorSoundDuration = getSampleDuration(self.motorStartSound)
    end
    self.motorStartTime = self.time + self.motorStartDuration
    self.playMotorSoundTime = self.time + motorSoundDuration
    self.compressionSoundTime = self.time + 180000
    self.lastRoundPerMinute = 0
    if self.isClient then
      Utils.setEmittingState(self.exhaustParticleSystems, true)
    end
  end
end
function Motorized:stopMotor(noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self, false), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent:new(self, false))
    end
  end
  self.isMotorStarted = false
  Motorized.stopSounds(self)
  if self:getIsActiveForSound() and self.isClient and self.motorStopSound ~= nil then
    setSamplePitch(self.motorStopSound, self.motorStopSoundPitchOffset)
    playSample(self.motorStopSound, 1, self.motorStopSoundVolume, 0)
  end
  self.motor:setSpeedLevel(0, false)
  if self.isClient then
    Utils.setEmittingState(self.exhaustParticleSystems, false)
  end
end
function Motorized:stopSounds()
  if self.isClient then
    if self.motorSound ~= nil then
      stopSample(self.motorSound)
      self.motorSoundEnabled = false
    end
    self.playMotorRunSound = false
    if self.motorSoundRun ~= nil then
      stopSample(self.motorSoundRun)
    end
    if self.motorStartSound ~= nil then
      stopSample(self.motorStartSound)
    end
    if self.compressionSoundEnabled then
      stopSample(self.compressionSound)
      self.compressionSoundEnabled = false
    end
    if self.reverseDriveSoundEnabled then
      stopSample(self.reverseDriveSound)
      self.reverseDriveSoundEnabled = false
    end
  end
end
function Motorized:startRefuel(noEventSend)
  if self.hasRefuelStationInRange then
    if noEventSend == nil or noEventSend == false then
      if g_server ~= nil then
        g_server:broadcastEvent(SteerableToggleRefuelEvent:new(self, true), nil, nil, self)
      else
        g_client:getServerConnection():sendEvent(SteerableToggleRefuelEvent:new(self, true))
      end
    end
    self.doRefuel = true
  end
end
function Motorized:stopRefuel(noEventSend)
  if self.doRefuel then
    if noEventSend == nil or noEventSend == false then
      if g_server ~= nil then
        g_server:broadcastEvent(SteerableToggleRefuelEvent:new(self, false), nil, nil, self)
      else
        g_client:getServerConnection():sendEvent(SteerableToggleRefuelEvent:new(self, false))
      end
    end
    self.doRefuel = false
    if self.refuelSampleRunning then
      stopSample(self.refuelSample)
      self.refuelSampleRunning = false
    end
  end
end
function Motorized:setFuelFillLevel(newFillLevel)
  self.fuelFillLevel = math.max(math.min(newFillLevel, self.fuelCapacity), 0)
end
function Motorized:setHasRefuelStationInRange(hasRefuelStationInRange)
  if hasRefuelStationInRange ~= self.hasRefuelStationInRange then
    if hasRefuelStationInRange then
      g_currentMission:addActivatableObject(self.motorizedFillActivatable)
    else
      if self.isServer then
        self:stopRefuel()
      end
      g_currentMission:removeActivatableObject(self.motorizedFillActivatable)
    end
    self.hasRefuelStationInRange = hasRefuelStationInRange
  end
end
MotorizedRefuelActivatable = {}
local MotorizedRefuelActivatable_mt = Class(MotorizedRefuelActivatable)
function MotorizedRefuelActivatable:new(motorized)
  local self = {}
  setmetatable(self, MotorizedRefuelActivatable_mt)
  self.motorized = motorized
  self.activateText = "unknown"
  return self
end
function MotorizedRefuelActivatable:getIsActivatable()
  if not self.motorized:getIsActiveForInput() or self.motorized.fuelFillLevel == self.motorized.fuelCapacity then
    return false
  end
  self:updateActivateText()
  return true
end
function MotorizedRefuelActivatable:onActivateObject()
  if self.motorized.doRefuel then
    self.motorized:stopRefuel()
  else
    self.motorized:startRefuel()
  end
  self:updateActivateText()
  g_currentMission:addActivatableObject(self)
end
function MotorizedRefuelActivatable:drawActivate()
  g_currentMission.hudFuelOverlay:render()
end
function MotorizedRefuelActivatable:updateActivateText()
  if self.motorized.doRefuel then
    self.activateText = string.format(g_i18n:getText("stop_Refuel"), self.motorized.typeDesc)
  else
    self.activateText = string.format(g_i18n:getText("Refuel"), self.motorized.typeDesc)
  end
end
