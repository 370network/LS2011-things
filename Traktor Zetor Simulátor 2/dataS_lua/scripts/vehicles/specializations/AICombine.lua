AICombine = {}
source("dataS/scripts/vehicles/specializations/AICombineSetStartedEvent.lua")
function AICombine.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Hirable, specializations) and SpecializationUtil.hasSpecialization(Combine, specializations)
end
function AICombine:load(xmlFile)
  self.startAIThreshing = SpecializationUtil.callSpecializationsFunction("startAIThreshing")
  self.stopAIThreshing = SpecializationUtil.callSpecializationsFunction("stopAIThreshing")
  self.onTrafficCollisionTrigger = AICombine.onTrafficCollisionTrigger
  self.onCutterTrafficCollisionTrigger = AICombine.onCutterTrafficCollisionTrigger
  self.onTrailerTrigger = AICombine.onTrailerTrigger
  self.canStartAIThreshing = AICombine.canStartAIThreshing
  self.getIsAIThreshingAllowed = AICombine.getIsAIThreshingAllowed
  self.isAIThreshing = false
  self.aiTreshingDirectionNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTreshingDirectionNode#index"))
  if self.aiTreshingDirectionNode == nil then
    self.aiTreshingDirectionNode = self.components[1].node
  end
  self.lookAheadDistance = 10
  self.turnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnTimeout"), 200)
  self.turnTimeoutLong = self.turnTimeout * 10
  self.turnTimer = self.turnTimeout
  self.turnEndDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnEndDistance"), 4)
  self.waitForTurnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.waitForTurnTime"), 1500)
  self.waitForTurnTime = 0
  self.sideWatchDirOffset = -8
  self.sideWatchDirSize = 8
  self.frontAreaSize = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontAreaSize#value"), 2)
  self.waitingForTrailerToUnload = false
  self.waitingForDischarge = false
  self.waitForDischargeTime = 0
  self.waitForDischargeTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.waitForDischargeTime"), 5000)
  self.turnStage = 0
  self.aiTrafficCollisionTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrafficCollisionTrigger#index"))
  self.aiTurnThreshWidthScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnThreshWidthScale#value"), 0.9)
  self.aiTrailerTriggers = {}
  local i = 0
  while true do
    local key = string.format("vehicle.aiTrailerTriggers.aiTrailerTrigger(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    local pipeState = getXMLInt(xmlFile, key .. "#pipeState")
    if node ~= nil and pipeState ~= nil then
      self.aiTrailerTriggers[node] = {node = node, pipeState = pipeState}
    end
    i = i + 1
  end
  local aiTrailerTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrailerTrigger#index"))
  if aiTrailerTrigger ~= nil then
    self.aiTrailerTriggers[aiTrailerTrigger] = {node = aiTrailerTrigger, pipeState = 2}
  end
  for _, aiTrailerTrigger in pairs(self.aiTrailerTriggers) do
    addTrigger(aiTrailerTrigger.node, "onTrailerTrigger", self)
  end
  self.trailersInRange = {}
  self.isTrailerInRange = false
  self.trailerInRangePipeState = 0
  self.trafficCollisionIgnoreList = {}
  for k, v in pairs(self.components) do
    self.trafficCollisionIgnoreList[v.node] = true
  end
  self.numCollidingVehicles = 0
  self.numCutterCollidingVehicles = {}
  self.driveBackTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.driveBackTimeout"), 1000)
  self.driveBackTime = 0
  self.driveBackAfterDischarge = false
  self.dtSum = 0
  local aiMotorSound = getXMLString(xmlFile, "vehicle.aiMotorSound#file")
  if aiMotorSound ~= nil and aiMotorSound ~= "" then
    aiMotorSound = Utils.getFilename(aiMotorSound, self.baseDirectory)
    self.aiMotorSoundRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#radius"), 50)
    self.aiMotorSoundInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#innerRadius"), 10)
    self.aiMotorSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#volume"), 1)
    self.aiMotorSound = createAudioSource("aiMotorSound", aiMotorSound, self.aiMotorSoundRadius, self.aiMotorSoundInnerRadius, self.aiMotorSoundVolume, 0)
    link(self.components[1].node, self.aiMotorSound)
    setVisibility(self.aiMotorSound, false)
  end
  local aiThreshingSound = getXMLString(xmlFile, "vehicle.aiTreshingSound#file")
  if aiThreshingSound ~= nil and aiThreshingSound ~= "" then
    aiThreshingSound = Utils.getFilename(aiThreshingSound, self.baseDirectory)
    self.aiThreshingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#pitchOffset"), 0)
    self.aiThreshingSoundRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#radius"), 50)
    self.aiThreshingSoundInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#innerRadius"), 10)
    self.aiThreshingSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#volume"), 1)
    self.aiThreshingSound = createAudioSource("aiThreshingSound", aiThreshingSound, self.aiThreshingSoundRadius, self.aiThreshingSoundInnerRadius, self.aiThreshingSoundVolume, 0)
    link(self.components[1].node, self.aiThreshingSound)
    setVisibility(self.aiThreshingSound, false)
  end
  self.turnStage1Timeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnForwardTimeout"), 20000)
  self.turnStage2Timeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnBackwardTimeout"), 20000)
  self.turnStage4Timeout = 3000
  self.waitingForWeather = false
  self.aiRescueTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiRescue#timeout"), 1500)
  self.aiRescueTimer = self.aiRescueTimeout
  self.aiRescueForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiRescue#force"), 60)
  self.aiRescueSpeedThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiRescue#speedThreshold"), 1.0E-4)
  self.aiRescueNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiRescue#index"))
  if self.aiRescueNode == nil then
    self.aiRescueNode = self.components[1].node
  end
  self.numAttachedTrailers = 0
end
function AICombine:delete()
  for _, aiTrailerTrigger in pairs(self.aiTrailerTriggers) do
    removeTrigger(aiTrailerTrigger.node)
  end
  if self.aiTrafficCollisionTrigger ~= nil then
    removeTrigger(self.aiTrafficCollisionTrigger)
  end
  for cutter, implement in pairs(self.attachedCutters) do
    AICombine.removeCutterTrigger(self, cutter)
  end
end
function AICombine:readStream(streamId, connection)
  local isAIThreshing = streamReadBool(streamId)
  if isAIThreshing then
    self:startAIThreshing(true)
  else
    self:stopAIThreshing(true)
  end
end
function AICombine:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isAIThreshing)
end
function AICombine:mouseEvent(posX, posY, isDown, isUp, button)
end
function AICombine:keyEvent(unicode, sym, modifier, isDown)
end
function AICombine:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.TOGGLE_AI) then
    if self.isAIThreshing then
      self:stopAIThreshing()
    elseif self:canStartAIThreshing() then
      self:startAIThreshing()
    end
  end
end
function AICombine:updateTick(dt)
  if self.isServer then
    if self.isAIThreshing then
      if self.isBroken then
        self:stopAIThreshing()
      end
      self.dtSum = self.dtSum + dt
      if self.dtSum > 50 then
        AICombine.updateAIMovement(self, self.dtSum)
        self.dtSum = 0
      end
      if (0 < self.grainTankFillLevel or 0 >= self.grainTankCapacity) and (self.grainTankFillLevel >= self.grainTankCapacity * 0.8 or self.isTrailerInRange) then
        if 0 < self.trailerInRangePipeState then
          self:setPipeState(self.trailerInRangePipeState)
        else
          self:setPipeState(2)
        end
        if self.isTrailerInRange then
          self.waitForDischargeTime = self.time + self.waitForDischargeTimeout
        end
        if self.grainTankFillLevel >= self.grainTankCapacity and 0 < self.grainTankCapacity then
          self.driveBackAfterDischarge = true
          self.waitingForDischarge = true
          self.waitForDischargeTime = self.time + self.waitForDischargeTimeout
        end
      elseif self.waitingForDischarge and 0 >= self.grainTankFillLevel or self.waitForDischargeTime <= self.time then
        self.waitingForDischarge = false
        if self.driveBackAfterDischarge then
          self.driveBackTime = self.time + self.driveBackTimeout
          self.driveBackAfterDischarge = false
        end
        if not self.isTrailerInRange then
          self:setPipeState(1)
        end
        if self:getIshreshingAllowed(true) then
          self:setIsThreshing(true)
        end
      end
    else
      self.dtSum = 0
    end
  end
end
function AICombine:draw()
  if self.isAIThreshing then
    g_currentMission:addHelpButtonText(g_i18n:getText("DismissEmployee"), InputBinding.TOGGLE_AI)
  elseif self:canStartAIThreshing() then
    g_currentMission:addHelpButtonText(g_i18n:getText("HireEmployee"), InputBinding.TOGGLE_AI)
  end
end
function AICombine:startAIThreshing(noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(AICombineSetStartedEvent:new(self, true), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(AICombineSetStartedEvent:new(self, true))
    end
  end
  self:hire()
  if not self.isAIThreshing then
    self.isAIThreshing = true
    self.isTrailerInRange = false
    if self.isServer then
      self.turnTimer = self.turnTimeoutLong
      self.turnStage = 0
      local x, y, z = localDirectionToWorld(self.aiTreshingDirectionNode, 0, 0, 1)
      local length = Utils.vector2Length(x, z)
      self.aiThreshingDirectionX = x / length
      self.aiThreshingDirectionZ = z / length
      local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
      self.aiThreshingTargetX = x
      self.aiThreshingTargetZ = z
      for cutter, implement in pairs(self.attachedCutters) do
        local jointDesc = self.attacherJoints[implement.jointDescIndex]
        jointDesc.moveDown = true
      end
      self.numCollidingVehicles = 0
      if self.aiTrafficCollisionTrigger ~= nil then
        addTrigger(self.aiTrafficCollisionTrigger, "onTrafficCollisionTrigger", self)
      end
      for cutter, implement in pairs(self.attachedCutters) do
        AICombine.addCutterTrigger(self, cutter)
      end
    end
    self.speedDisplayScale = 0.5
    self.waitingForDischarge = false
    self:setIsThreshing(true, true)
    self.checkSpeedLimit = false
    self.waitingForWeather = false
    if not self.isEntered then
      setVisibility(self.aiMotorSound, true)
      setVisibility(self.aiThreshingSound, true)
    end
  end
end
function AICombine:stopAIThreshing(noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(AICombineSetStartedEvent:new(self, false), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(AICombineSetStartedEvent:new(self, false))
    end
  end
  self:dismiss()
  if self.isAIThreshing then
    self.isAIThreshing = false
    self.speedDisplayScale = 1
    self.allowsThreshing = true
    self.checkSpeedLimit = true
    self.waitingForWeather = false
    setVisibility(self.aiMotorSound, false)
    setVisibility(self.aiThreshingSound, false)
    self:setIsThreshing(false, true)
    if self.isServer then
      self.motor:setSpeedLevel(0, false)
      self.motor.maxRpmOverride = nil
      WheelsUtil.updateWheelsPhysics(self, 0, self.lastSpeed, 0, false, self.requiredDriveMode)
      if self.aiTrafficCollisionTrigger ~= nil then
        removeTrigger(self.aiTrafficCollisionTrigger)
      end
      for cutter, implement in pairs(self.attachedCutters) do
        AICombine.removeCutterTrigger(self, cutter)
      end
      if not self:getIsActive() then
        self:onLeave()
      end
    end
  end
end
function AICombine:onEnter(isControlling)
  if isControlling then
    setVisibility(self.aiMotorSound, false)
    setVisibility(self.aiThreshingSound, false)
  else
    setVisibility(self.aiMotorSound, true)
  end
end
function AICombine:onLeave()
  if self.isAIThreshing then
    setVisibility(self.aiMotorSound, true)
    setVisibility(self.aiThreshingSound, true)
  else
    setVisibility(self.aiMotorSound, false)
  end
end
function AICombine:updateAIMovement(dt)
  if not self:getIsAIThreshingAllowed() then
    self:stopAIThreshing()
    return
  end
  if not self.isControlled then
    if g_currentMission.environment.needsLights then
      self:setLightsVisibility(true)
    else
      self:setLightsVisibility(false)
    end
  end
  local allowedToDrive = true
  if self.grainTankCapacity == 0 and (not (not self.pipeParticleActivated or self.isPipeUnloading) or not self.pipeStateIsUnloading[self.currentPipeState]) then
    self.waitingForTrailerToUnload = true
  end
  if self.waitingForTrailerToUnload then
    if self.lastValidOutputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      local trailer = self:findTrailerToUnload(self.lastValidOutputFruitType)
      if trailer ~= nil then
        self.waitingForTrailerToUnload = false
      end
    else
      self.waitingForTrailerToUnload = false
    end
  end
  if self.grainTankFillLevel >= self.grainTankCapacity and self.grainTankCapacity > 0 or self.waitingForTrailerToUnload or self.waitingForDischarge or 0 < self.numCollidingVehicles then
    allowedToDrive = false
  end
  for k, v in pairs(self.numCutterCollidingVehicles) do
    if 0 < v then
      allowedToDrive = false
      break
    end
  end
  if 0 < self.turnStage and (self.waitForTurnTime > self.time or self.pipeIsUnloading) then
    allowedToDrive = false
  end
  if not self:getIshreshingAllowed(true) then
    allowedToDrive = false
    self:setIsThreshing(false)
    self.waitingForWeather = true
  elseif self.waitingForWeather then
    if self.turnStage == 0 then
      self.driveBackTime = self.time + self.driveBackTimeout
    end
    self:startThreshing()
    self.waitingForWeather = false
  end
  if not allowedToDrive then
    local lx, lz = 0, 1
    AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, lx, lz)
    return
  end
  local speedLevel = 2
  local leftMarker, rightMarker
  local fruitType = self.lastValidInputFruitType
  for cutter, implement in pairs(self.attachedCutters) do
    if cutter.aiLeftMarker ~= nil and leftMarker == nil then
      leftMarker = cutter.aiLeftMarker
    end
    if cutter.aiRightMarker ~= nil and rightMarker == nil then
      rightMarker = cutter.aiRightMarker
    end
    if Cutter.getUseLowSpeedLimit(cutter) then
      speedLevel = 1
    end
  end
  if leftMarker == nil or rightMarker == nil then
    self:stopAIThreshing()
    return
  end
  if self.driveBackTime >= self.time then
    local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
    local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTreshingDirectionNode, self.aiThreshingTargetX, y, self.aiThreshingTargetZ)
    AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, true, false, lx, lz, speedLevel, 1)
    return
  end
  local hasArea = true
  if 1 > self.lastArea then
    local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
    local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
    local lInX, lInY, lInZ = getWorldTranslation(leftMarker)
    local rInX, rInY, rInZ = getWorldTranslation(rightMarker)
    local heightX = lInX + dirX * self.frontAreaSize
    local heightZ = lInZ + dirZ * self.frontAreaSize
    local area = Utils.getFruitArea(fruitType, lInX, lInZ, rInX, rInZ, heightX, heightZ)
    if area < 1 then
      hasArea = false
    end
  end
  if hasArea then
    self.turnTimer = self.turnTimeout
  else
    self.turnTimer = self.turnTimer - dt
  end
  local newTargetX, newTargetY, newTargetZ
  local moveForwards = true
  local updateWheels = true
  if 0 > self.turnTimer or 0 < self.turnStage then
    if 0 < self.turnStage then
      local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
      local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
      local myDirX, myDirY, myDirZ = localDirectionToWorld(self.aiTreshingDirectionNode, 0, 0, 1)
      newTargetX = self.aiThreshingTargetX
      newTargetY = y
      newTargetZ = self.aiThreshingTargetZ
      if self.turnStage == 1 then
        self.turnStageTimer = self.turnStageTimer - dt
        if self.lastSpeed < self.aiRescueSpeedThreshold then
          self.aiRescueTimer = self.aiRescueTimer - dt
        else
          self.aiRescueTimer = self.aiRescueTimeout
        end
        if 0.25 < myDirX * dirX + myDirZ * dirZ or 0 > self.turnStageTimer or 0 > self.aiRescueTimer then
          self.turnStage = 2
          moveForwards = false
          if 0 > self.turnStageTimer or 0 > self.aiRescueTimer then
            self.aiThreshingTargetBeforeSaveX = self.aiThreshingTargetX
            self.aiThreshingTargetBeforeSaveZ = self.aiThreshingTargetZ
            newTargetX = self.aiThreshingTargetBeforeTurnX
            newTargetZ = self.aiThreshingTargetBeforeTurnZ
            moveForwards = false
            self.turnStage = 4
            self.turnStageTimer = self.turnStage4Timeout
          else
            self.turnStageTimer = self.turnStage2Timeout
          end
          self.aiRescueTimer = self.aiRescueTimeout
        end
      elseif self.turnStage == 2 then
        self.turnStageTimer = self.turnStageTimer - dt
        if self.lastSpeed < self.aiRescueSpeedThreshold then
          self.aiRescueTimer = self.aiRescueTimer - dt
        else
          self.aiRescueTimer = self.aiRescueTimeout
        end
        if 0.85 < myDirX * dirX + myDirZ * dirZ or 0 > self.turnStageTimer or 0 > self.aiRescueTimer then
          AICombine.switchToTurnStage3(self)
        else
          moveForwards = false
        end
      elseif self.turnStage == 3 then
        if self.lastSpeed < self.aiRescueSpeedThreshold then
          self.aiRescueTimer = self.aiRescueTimer - dt
        else
          self.aiRescueTimer = self.aiRescueTimeout
        end
        local dx, dz = x - newTargetX, z - newTargetZ
        local dot = dx * dirX + dz * dirZ
        if -dot < self.turnEndDistance then
          self.turnTimer = self.turnTimeoutLong
          self.turnStage = 0
        elseif 0 > self.aiRescueTimer then
          self.aiThreshingTargetBeforeSaveX = self.aiThreshingTargetX
          self.aiThreshingTargetBeforeSaveZ = self.aiThreshingTargetZ
          newTargetX = self.aiThreshingTargetBeforeTurnX
          newTargetZ = self.aiThreshingTargetBeforeTurnZ
          moveForwards = false
          self.turnStage = 4
          self.turnStageTimer = self.turnStage4Timeout
        end
      elseif self.turnStage == 4 then
        self.turnStageTimer = self.turnStageTimer - dt
        if self.lastSpeed < self.aiRescueSpeedThreshold then
          self.aiRescueTimer = self.aiRescueTimer - dt
        else
          self.aiRescueTimer = self.aiRescueTimeout
        end
        if 0 > self.aiRescueTimer then
          self.aiRescueTimer = self.aiRescueTimeout
          local x, y, z = localDirectionToWorld(self.aiRescueNode, 0, 0, -1)
          local scale = self.aiRescueForce / Utils.vector2Length(x, z)
          addForce(self.aiRescueNode, x * scale, 0, z * scale, 0, 0, 0, true)
        end
        if 0 > self.turnStageTimer then
          self.aiRescueTimer = self.aiRescueTimeout
          self.turnStageTimer = self.turnStage1Timeout
          self.turnStage = 1
          newTargetX = self.aiThreshingTargetBeforeSaveX
          newTargetZ = self.aiThreshingTargetBeforeSaveZ
        else
          local dirX, dirZ = -dirX, -dirZ
          local targetX, targetZ = self.aiThreshingTargetX, self.aiThreshingTargetZ
          local dx, dz = x - targetX, z - targetZ
          local dot = dx * dirX + dz * dirZ
          local projTargetX = targetX + dirX * dot
          local projTargetZ = targetZ + dirZ * dot
          newTargetX = projTargetX - dirX * self.lookAheadDistance
          newTargetZ = projTargetZ - dirZ * self.lookAheadDistance
          moveForwards = false
        end
      end
    elseif fruitType == FruitUtil.FRUITTYPE_UNKNOWN then
      self:stopAIThreshing()
      return
    else
      local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
      local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
      local sideX, sideZ = -dirZ, dirX
      local lInX, lInY, lInZ = getWorldTranslation(leftMarker)
      local rInX, rInY, rInZ = getWorldTranslation(rightMarker)
      local threshWidth = Utils.vector2Length(lInX - rInX, lInZ - rInZ)
      local turnLeft = true
      local lWidthX = x - sideX * 0.5 * threshWidth + dirX * self.sideWatchDirOffset
      local lWidthZ = z - sideZ * 0.5 * threshWidth + dirZ * self.sideWatchDirOffset
      local lStartX = lWidthX - sideX * 0.7 * threshWidth
      local lStartZ = lWidthZ - sideZ * 0.7 * threshWidth
      local lHeightX = lStartX + dirX * self.sideWatchDirSize
      local lHeightZ = lStartZ + dirZ * self.sideWatchDirSize
      local rWidthX = x + sideX * 0.5 * threshWidth + dirX * self.sideWatchDirOffset
      local rWidthZ = z + sideZ * 0.5 * threshWidth + dirZ * self.sideWatchDirOffset
      local rStartX = rWidthX + sideX * 0.7 * threshWidth
      local rStartZ = rWidthZ + sideZ * 0.7 * threshWidth
      local rHeightX = rStartX + dirX * self.sideWatchDirSize
      local rHeightZ = rStartZ + dirZ * self.sideWatchDirSize
      local leftFruit = Utils.getFruitArea(fruitType, lStartX, lStartZ, lWidthX, lWidthZ, lHeightX, lHeightZ)
      local rightFruit = Utils.getFruitArea(fruitType, rStartX, rStartZ, rWidthX, rWidthZ, rHeightX, rHeightZ)
      if 0 < leftFruit or 0 < rightFruit then
        if leftFruit > rightFruit then
          turnLeft = true
        else
          turnLeft = false
        end
      else
        self:stopAIThreshing()
        return
      end
      local targetX, targetZ = self.aiThreshingTargetX, self.aiThreshingTargetZ
      threshWidth = threshWidth * self.aiTurnThreshWidthScale
      local x, z = Utils.projectOnLine(x, z, targetX, targetZ, dirX, dirZ)
      if turnLeft then
        newTargetX = x - sideX * threshWidth
        newTargetY = y
        newTargetZ = z - sideZ * threshWidth
      else
        newTargetX = x + sideX * threshWidth
        newTargetY = y
        newTargetZ = z + sideZ * threshWidth
      end
      self.aiThreshingDirectionX = -dirX
      self.aiThreshingDirectionZ = -dirZ
      self.turnStage = 1
      self.aiRescueTimer = self.aiRescueTimeout
      self.turnStageTimer = self.turnStage1Timeout
      self.aiThreshingTargetBeforeTurnX = self.aiThreshingTargetX
      self.aiThreshingTargetBeforeTurnZ = self.aiThreshingTargetZ
      self.waitForTurnTime = self.time + self.waitForTurnTimeout
      for cutter, implement in pairs(self.attachedCutters) do
        local jointDesc = self.attacherJoints[implement.jointDescIndex]
        jointDesc.moveDown = false
      end
      self.allowsThreshing = false
      updateWheels = false
      if turnLeft then
      else
      end
    end
  else
    local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
    local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
    local targetX, targetZ = self.aiThreshingTargetX, self.aiThreshingTargetZ
    local dx, dz = x - targetX, z - targetZ
    local dot = dx * dirX + dz * dirZ
    local projTargetX = targetX + dirX * dot
    local projTargetZ = targetZ + dirZ * dot
    newTargetX = projTargetX + self.aiThreshingDirectionX * self.lookAheadDistance
    newTargetY = y
    newTargetZ = projTargetZ + self.aiThreshingDirectionZ * self.lookAheadDistance
  end
  if updateWheels then
    local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTreshingDirectionNode, newTargetX, newTargetY, newTargetZ)
    if self.turnStage == 2 and math.abs(lx) < 0.1 then
      AICombine.switchToTurnStage3(self)
      moveForwards = true
    end
    AIVehicleUtil.driveInDirection(self, dt, 25, 0.5, 0.5, 20, true, moveForwards, lx, lz, speedLevel, 0.9)
    local maxlx = 0.7071067
    local colDirX = lx
    local colDirZ = lz
    if maxlx < colDirX then
      colDirX = maxlx
      colDirZ = 0.7071067
    elseif colDirX < -maxlx then
      colDirX = -maxlx
      colDirZ = 0.7071067
    end
    if self.aiTrafficCollisionTrigger ~= nil then
      AIVehicleUtil.setCollisionDirection(self.aiTreshingDirectionNode, self.aiTrafficCollisionTrigger, colDirX, colDirZ)
    end
    for k, v in pairs(self.numCutterCollidingVehicles) do
      AIVehicleUtil.setCollisionDirection(self.aiTreshingDirectionNode, k, colDirX, colDirZ)
    end
  end
  self.aiThreshingTargetX = newTargetX
  self.aiThreshingTargetZ = newTargetZ
end
function AICombine:switchToDirection(myDirX, myDirZ)
  self.aiThreshingDirectionX = myDirX
  self.aiThreshingDirectionZ = myDirZ
end
function AICombine:addCutterTrigger(cutter)
  if self.isServer then
    if cutter.aiTrafficCollisionTrigger ~= nil then
      addTrigger(cutter.aiTrafficCollisionTrigger, "onCutterTrafficCollisionTrigger", self)
      self.numCutterCollidingVehicles[cutter.aiTrafficCollisionTrigger] = 0
    end
    for k, v in pairs(cutter.components) do
      self.trafficCollisionIgnoreList[v.node] = true
    end
  end
end
function AICombine:removeCutterTrigger(cutter)
  if self.isServer then
    if cutter.aiTrafficCollisionTrigger ~= nil then
      removeTrigger(cutter.aiTrafficCollisionTrigger)
      self.numCutterCollidingVehicles[cutter.aiTrafficCollisionTrigger] = nil
    end
    for k, v in pairs(cutter.components) do
      self.trafficCollisionIgnoreList[v.node] = nil
    end
  end
end
function AICombine:attachImplement(implement)
  local object = implement.object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER then
    if self.isAIThreshing and self.isServer then
      AICombine.addCutterTrigger(self, object)
    end
  elseif object.attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILER or object.attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILERLOW then
    self.numAttachedTrailers = self.numAttachedTrailers + 1
  end
end
function AICombine:detachImplement(implementIndex)
  local object = self.attachedImplements[implementIndex].object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER then
    if self.isAIThreshing and self.isServer then
      AICombine.removeCutterTrigger(self, object)
    end
  elseif object.attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILER or object.attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILERLOW then
    self.numAttachedTrailers = self.numAttachedTrailers - 1
  end
end
function AICombine:onTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    if otherId == g_currentMission.player.rootNode then
      if onEnter then
        self.numCollidingVehicles = self.numCollidingVehicles + 1
      elseif onLeave then
        self.numCollidingVehicles = math.max(self.numCollidingVehicles - 1, 0)
      end
    else
      local vehicle = g_currentMission.nodeToVehicle[otherId]
      if vehicle ~= nil and self.trafficCollisionIgnoreList[otherId] == nil then
        if onEnter then
          self.numCollidingVehicles = self.numCollidingVehicles + 1
        elseif onLeave then
          self.numCollidingVehicles = math.max(self.numCollidingVehicles - 1, 0)
        end
      end
    end
  end
end
function AICombine:onCutterTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    if otherId == g_currentMission.player.rootNode then
      if onEnter then
        self.numCutterCollidingVehicles[triggerId] = self.numCutterCollidingVehicles[triggerId] + 1
      elseif onLeave then
        self.numCutterCollidingVehicles[triggerId] = math.max(self.numCutterCollidingVehicles[triggerId] - 1, 0)
      end
    else
      local vehicle = g_currentMission.nodeToVehicle[otherId]
      if vehicle ~= nil and self.trafficCollisionIgnoreList[otherId] == nil then
        if onEnter then
          self.numCutterCollidingVehicles[triggerId] = self.numCutterCollidingVehicles[triggerId] + 1
        elseif onLeave then
          self.numCutterCollidingVehicles[triggerId] = math.max(self.numCutterCollidingVehicles[triggerId] - 1, 0)
        end
      end
    end
  end
end
function AICombine:onTrailerTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    local trailer = g_currentMission.nodeToVehicle[otherId]
    if trailer ~= nil and trailer.fillRootNode ~= nil then
      if onEnter then
        self.trailersInRange[trailer] = self.aiTrailerTriggers[triggerId].pipeState
        self.trailerInRangePipeState = math.max(self.trailerInRangePipeState, self.aiTrailerTriggers[triggerId].pipeState)
        self.isTrailerInRange = true
      else
        self.trailersInRange[trailer] = nil
        self.isTrailerInRange = false
        self.trailerInRangePipeState = 0
        for trailer, pipeState in pairs(self.trailersInRange) do
          self.trailerInRangePipeState = math.max(self.trailerInRangePipeState, pipeState)
          self.isTrailerInRange = true
        end
      end
    end
  end
end
function AICombine:switchToTurnStage3()
  self.turnStage = 3
  for cutter, implement in pairs(self.attachedCutters) do
    local jointDesc = self.attacherJoints[implement.jointDescIndex]
    jointDesc.moveDown = true
  end
  self.allowsThreshing = true
  self.aiRescueTimer = self.aiRescueTimeout
end
function AICombine:canStartAIThreshing()
  if g_currentMission.disableCombineAI then
    return false
  end
  if self.numAttachedCutters <= 0 then
    return false
  end
  if 0 < self.numAttachedTrailers then
    return false
  end
  if Hirable.numHirablesHired >= g_currentMission.maxNumHirables then
    return false
  end
  return true
end
function AICombine:getIsAIThreshingAllowed()
  if g_currentMission.disableCombineAI then
    return false
  end
  if self.numAttachedCutters <= 0 then
    return false
  end
  if 0 < self.numAttachedTrailers then
    return false
  end
  return true
end
