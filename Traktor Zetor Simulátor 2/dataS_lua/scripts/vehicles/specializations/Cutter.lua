Cutter = {}
source("dataS/scripts/vehicles/specializations/CutterAreaEvent.lua")
function Cutter.prerequisitesPresent(specializations)
  return true
end
function Cutter:load(xmlFile)
  self.setReelSpeedScale = SpecializationUtil.callSpecializationsFunction("setReelSpeedScale")
  self.onStartReel = SpecializationUtil.callSpecializationsFunction("onStartReel")
  self.onStopReel = SpecializationUtil.callSpecializationsFunction("onStopReel")
  self.isReelStarted = Cutter.isReelStarted
  self.resetFruitType = SpecializationUtil.callSpecializationsFunction("resetFruitType")
  self.setFruitType = SpecializationUtil.callSpecializationsFunction("setFruitType")
  self.getInputFruitType = Cutter.getInputFruitType
  self.reelNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.reel#index"))
  self.reelSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.reel#speed"), 0.003)
  self.reelSpeedScale = 1
  self.rollNodes = {}
  local rollNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.roll#index"))
  if rollNode ~= nil then
    local speed = 0.009000000000000001
    table.insert(self.rollNodes, {node = rollNode, speed = speed})
  end
  local i = 0
  while true do
    local key = string.format("vehicle.rolls.roll(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local rollNode = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    local speed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speed"), 0.003)
    if rollNode ~= nil then
      table.insert(self.rollNodes, {node = rollNode, speed = speed})
    end
    i = i + 1
  end
  local indexSpikesStr = getXMLString(xmlFile, "vehicle.reelspikes#index")
  self.spikesCount = getXMLInt(xmlFile, "vehicle.reelspikes#count")
  self.spikesRootNode = Utils.indexToObject(self.components, indexSpikesStr)
  self.sideArm = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.sidearms#index"))
  self.sideArmMovable = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.sidearms#movable"), false)
  self.threshingParticleSystems = {}
  local psName = "vehicle.threshingParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.threshingParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.fruitExtraObjects = {}
  local i = 0
  while true do
    local key = string.format("vehicle.fruitExtraObjects.fruitExtraObject(%d)", i)
    local t = getXMLString(xmlFile, key .. "#fruitType")
    local index = getXMLString(xmlFile, key .. "#index")
    if t == nil or index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      if self.currentExtraObject == nil then
        self.currentExtraObject = node
        setVisibility(node, true)
      else
        setVisibility(node, false)
      end
      self.fruitExtraObjects[t] = node
    end
    i = i + 1
  end
  self.threshingUVScrollParts = {}
  local i = 0
  while true do
    local key = string.format("vehicle.threshingUVScrollParts.threshingUVScrollPart(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    local speed = Utils.getVectorNFromString(getXMLString(xmlFile, key .. "#speed"), 2)
    if node ~= nil and speed then
      table.insert(self.threshingUVScrollParts, {node = node, speed = speed})
    end
    i = i + 1
  end
  self.preferedCombineSize = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.preferedCombineSize"), 1)
  self.fruitTypes = {}
  self.fruitTypes[FruitUtil.FRUITTYPE_UNKNOWN] = true
  local fruitTypes = getXMLString(xmlFile, "vehicle.fruitTypes#fruitTypes")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        self.fruitTypes[desc.index] = true
      end
    end
  end
  self.convertedFruits = {}
  local i = 0
  while true do
    local key = string.format("vehicle.convertedFruits.convertedFruit(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local inputType = getXMLString(xmlFile, key .. "#input")
    local outputType = getXMLString(xmlFile, key .. "#output")
    if inputType ~= nil and outputType ~= nil then
      local inputDesc = FruitUtil.fruitTypes[inputType]
      local outputDesc = FruitUtil.fruitTypes[outputType]
      if inputDesc ~= nil and outputDesc ~= nil then
        self.convertedFruits[inputDesc.index] = outputDesc.index
      end
    end
    i = i + 1
  end
  self.currentFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.currentInputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.reelStarted = false
  self.forceLowSpeed = false
  self.speedLimitLow = 12
  self.speedLimit = 17.5
  self.speedViolationMaxTime = 50
  self.speedViolationTimer = self.speedViolationMaxTime
  self.printRainWarning = false
  self.lastArea = 0
  self.lastAreaBiggerZero = 0 < self.lastArea
  self.cutterGroundFlag = self:getNextDirtyFlag()
end
function Cutter:delete()
  Utils.deleteParticleSystem(self.threshingParticleSystems)
end
function Cutter:readStream(streamId, timestamp, connection)
  self.lastAreaBiggerZero = streamReadBool(streamId)
end
function Cutter:writeStream(streamId, connection, dirtyMask)
  streamWriteBool(streamId, self.lastAreaBiggerZero)
end
function Cutter:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    self.lastAreaBiggerZero = streamReadBool(streamId)
  end
end
function Cutter:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.lastAreaBiggerZero)
  end
end
function Cutter:mouseEvent(posX, posY, isDown, isUp, button)
end
function Cutter:keyEvent(unicode, sym, modifier, isDown)
end
function Cutter:update(dt)
  Utils.setEmittingState(self.threshingParticleSystems, self.reelStarted and self.lastAreaBiggerZero)
  if self.reelStarted then
    for _, rollNode in pairs(self.rollNodes) do
      rotate(rollNode.node, -dt * rollNode.speed, 0, 0)
    end
    if self.reelNode ~= nil then
      rotate(self.reelNode, -dt * self.reelSpeed * self.reelSpeedScale, 0, 0)
      if self.sideArmMovable then
      end
      local atx, aty, atz = getRotation(self.reelNode)
      for i = 1, self.spikesCount do
        local spike = getChildAt(self.spikesRootNode, i - 1)
        setRotation(spike, -atx, aty, atz)
      end
    end
  end
end
function Cutter:updateTick(dt)
  if self.isServer then
    self.lastArea = 0
    self.printRainWarning = false
  end
  if self.reelStarted and 0 > self.movingDirection then
    local speedLimit = self.speedLimit
    if Cutter.getUseLowSpeedLimit(self) then
      speedLimit = self.speedLimitLow
    end
    if self:doCheckSpeedLimit() and speedLimit < self.lastSpeed * 3600 then
      self.speedViolationTimer = self.speedViolationTimer - dt
    else
      self.speedViolationTimer = self.speedViolationMaxTime
    end
    if self.isServer and 0 < self.speedViolationTimer then
      local isAllowed = true
      if self.attacherVehicle ~= nil then
        isAllowed = self.attacherVehicle:getIshreshingAllowed(false)
      end
      if isAllowed then
        local lowFillLevel = false
        if self.attacherVehicle ~= nil and (self.attacherVehicle.grainTankFillLevel == 0 or self.attacherVehicle.grainTankFillLevel / self.attacherVehicle.grainTankCapacity <= self.attacherVehicle.minThreshold) then
          lowFillLevel = true
        end
        local foundFruitType = false
        local oldFruitType = self.currentFruitType
        local oldInputFruitType = self.currentInputFruitType
        local allowsThreshing = true
        if self.attacherVehicle ~= nil then
          allowsThreshing = self.attacherVehicle.allowsThreshing
        end
        if allowsThreshing then
          if self.currentFruitType == FruitUtil.FRUITTYPE_UNKNOWN or lowFillLevel then
            for fruitType, v in pairs(self.fruitTypes) do
              local outputFruitType = fruitType
              if self.convertedFruits[fruitType] ~= nil then
                outputFruitType = self.convertedFruits[fruitType]
              end
              local isOk = true
              if self.attacherVehicle ~= nil and self.attacherVehicle.allowGrainTankFruitType ~= nil then
                isOk = self.attacherVehicle:allowGrainTankFruitType(outputFruitType)
              end
              if isOk then
                for k, area in pairs(self.cuttingAreas) do
                  local x, y, z = getWorldTranslation(area.start)
                  local x1, y1, z1 = getWorldTranslation(area.width)
                  local x2, y2, z2 = getWorldTranslation(area.height)
                  local area = Utils.getFruitArea(fruitType, x, z, x1, z1, x2, z2)
                  if 0 < area then
                    self.currentFruitType = outputFruitType
                    self.currentInputFruitType = fruitType
                    if self.currentInputFruitType ~= oldInputFruitType then
                      Cutter.updateExtraObjects(self)
                      if self.attacherVehicle ~= nil then
                        self.attacherVehicle:emptyGrainTankIfLowFillLevel()
                      end
                    end
                    foundFruitType = true
                    break
                  end
                end
                if foundFruitType then
                  break
                end
              end
            end
          end
          if self.currentFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
            local cuttingAreasSend = {}
            for k, area in pairs(self.cuttingAreas) do
              if self:getIsAreaActive(area) then
                local x, y, z = getWorldTranslation(area.start)
                local x1, y1, z1 = getWorldTranslation(area.width)
                local x2, y2, z2 = getWorldTranslation(area.height)
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
              local lastArea, realArea = CutterAreaEvent.runLocally(cuttingAreasSend, self.currentInputFruitType)
              self.lastArea = lastArea
              self.lastAreaBiggerZero = self.lastArea > 0
              if self.lastArea > 0 then
                g_server:broadcastEvent(CutterAreaEvent:new(cuttingAreasSend, self.currentInputFruitType))
              end
              if self.lastAreaBiggerZero ~= self.lastAreaBiggerZeroSent then
                self:raiseDirtyFlags(self.cutterGroundFlag)
                self.lastAreaBiggerZeroSent = self.lastAreaBiggerZero
              end
              local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
              local sqm = realArea * pixelToSqm
              local ha = sqm / 10000
              g_currentMission.missionStats.hectaresThreshedTotal = g_currentMission.missionStats.hectaresThreshedTotal + ha
              g_currentMission.missionStats.hectaresThreshedSession = g_currentMission.missionStats.hectaresThreshedSession + ha
            end
            g_currentMission.missionStats.threshingDurationTotal = g_currentMission.missionStats.threshingDurationTotal + dt / 60000
            g_currentMission.missionStats.threshingDurationSession = g_currentMission.missionStats.threshingDurationSession + dt / 60000
          end
        end
      else
        self.printRainWarning = true
      end
    end
  else
    self.speedViolationTimer = self.speedViolationMaxTime
  end
end
function Cutter:draw()
end
function Cutter:onDetach()
  if self.deactivateOnDetach then
    Cutter.onDeactivate(self)
  end
end
function Cutter:onLeave()
  if self.deactivateOnLeave then
    Cutter.onDeactivate(self)
  end
end
function Cutter:onDeactivate()
  self:onStopReel()
  Utils.setEmittingState(self.threshingParticleSystems, false)
  self.speedViolationTimer = self.speedViolationMaxTime
end
function Cutter:setReelSpeedSpace(speedScale)
  self.reelSpeedScale = speedScale
end
function Cutter:onStartReel()
  self.reelStarted = true
  for _, part in pairs(self.threshingUVScrollParts) do
    setShaderParameter(part.node, "uvScrollSpeed", part.speed[1], part.speed[2], 0, 0, false)
  end
end
function Cutter:onStopReel()
  self.reelStarted = false
  Utils.setEmittingState(self.threshingParticleSystems, false)
  self.speedViolationTimer = self.speedViolationMaxTime
  for _, part in pairs(self.threshingUVScrollParts) do
    setShaderParameter(part.node, "uvScrollSpeed", 0, 0, 0, 0, false)
  end
end
function Cutter:isReelStarted()
  return self.reelStarted
end
function Cutter:resetFruitType()
  self.currentFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.currentInputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastArea = 0
end
function Cutter:setFruitType(fruitType)
  if self.currentInputFruitType ~= fruitType then
    self.currentInputFruitType = fruitType
    self.currentFruitType = fruitType
    if self.convertedFruits[fruitType] ~= nil then
      self.currentFruitType = self.convertedFruits[fruitType]
    end
    self.lastArea = 0
    Cutter.updateExtraObjects(self)
  end
end
function Cutter:getUseLowSpeedLimit()
  if self.forceLowSpeed or self.attacherVehicle ~= nil and self.preferedCombineSize > self.attacherVehicle.combineSize then
    return true
  end
  return false
end
function Cutter:updateExtraObjects()
  if self.currentExtraObject ~= nil then
    setVisibility(self.currentExtraObject, false)
    self.currentExtraObject = nil
  end
  if self.currentInputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    local name = FruitUtil.fruitIndexToDesc[self.currentInputFruitType].name
    local extraObject = self.fruitExtraObjects[name]
    if extraObject ~= nil then
      setVisibility(extraObject, true)
      self.currentExtraObject = extraObject
    end
  end
end
function Cutter.allowThreshing(earlyWarning)
  if earlyWarning ~= nil and earlyWarning == true then
    if g_currentMission.environment.lastRainScale <= 0.02 and g_currentMission.environment.timeSinceLastRain > 20 then
      return true
    end
  elseif g_currentMission.environment.lastRainScale <= 0.1 and g_currentMission.environment.timeSinceLastRain > 20 then
    return true
  end
  return false
end
