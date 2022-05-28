source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/SowingMachineAreaEvent.lua")
source("dataS/scripts/vehicles/specializations/SowingMachineSetIsFillingEvent.lua")
source("dataS/scripts/vehicles/specializations/SowingMachineSetSeedIndex.lua")
SowingMachine = {}
function SowingMachine.initSpecialization()
  Fillable.registerFillType("seeds")
end
function SowingMachine.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Fillable, specializations)
end
function SowingMachine:load(xmlFile)
  self.setIsTurnedOn = SpecializationUtil.callSpecializationsFunction("setIsTurnedOn")
  self.setSeedFruitType = SpecializationUtil.callSpecializationsFunction("setSeedFruitType")
  self.setSeedIndex = SpecializationUtil.callSpecializationsFunction("setSeedIndex")
  self.groundContactReport = SpecializationUtil.callSpecializationsFunction("groundContactReport")
  assert(self.setIsSowingMachineFilling == nil, "SowingMachine needs to be the first specialization which implements setIsSowingMachineFilling")
  self.setIsSowingMachineFilling = SowingMachine.setIsSowingMachineFilling
  self.addSowingMachineFillTrigger = SowingMachine.addSowingMachineFillTrigger
  self.removeSowingMachineFillTrigger = SowingMachine.removeSowingMachineFillTrigger
  self.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillLitersPerSecond"), 500)
  self.isSowingMachineFilling = false
  self.sowingMachineFillTriggers = {}
  self.sowingMachineFillActivatable = SowingMachineFillActivatable:new(self)
  self.fillTypes[Fillable.FILLTYPE_SEEDS] = true
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
  local drumNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.drum#index"))
  if drumNode ~= nil then
    print("Warning: vehicle.drum is no longer used, use speedRotatingParts\n")
  end
  self.contactReportNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.contactReportNode#index"))
  if self.contactReportNode == nil then
    self.contactReportNode = self.components[1].node
  end
  self.contactReportNodes = {}
  local contactReportNodeFound = false
  local i = 0
  while true do
    local baseName = string.format("vehicle.contactReportNodes.contactReportNode(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      local entry = {}
      entry.node = node
      entry.hasGroundContact = false
      self.contactReportNodes[node] = entry
      contactReportNodeFound = true
    end
    i = i + 1
  end
  if not contactReportNodeFound then
    local entry = {}
    entry.node = self.contactReportNode
    entry.hasGroundContact = false
    self.contactReportNodes[entry.node] = entry
  end
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
  end
  self.hasGroundContact = false
  self.maxSpeedLevel = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.maxSpeedLevel#value"), 1)
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
  self.seeds = {}
  for k, fruitType in pairs(FruitUtil.fruitTypes) do
    if fruitType.allowsSeeding then
      table.insert(self.seeds, fruitType.index)
    end
  end
  self.groundParticleSystems = {}
  local psName = "vehicle.groundParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.groundParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.groundParticleSystemActive = false
  self.newGroundParticleSystems = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.groundParticleSystems.groundParticleSystem(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local entry = {}
    entry.ps = {}
    Utils.loadParticleSystem(xmlFile, entry.ps, baseName, self.components, false, nil, self.baseDirectory)
    if 0 < table.getn(entry.ps) then
      entry.isActive = false
      table.insert(self.newGroundParticleSystems, entry)
    end
    i = i + 1
  end
  self.isTurnedOn = false
  self.needsActivation = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.needsActivation#value"), false)
  self.aiTerrainDetailChannel1 = g_currentMission.cultivatorChannel
  self.aiTerrainDetailChannel2 = g_currentMission.ploughChannel
  if self.isClient then
    local sowingSound = getXMLString(xmlFile, "vehicle.sowingSound#file")
    if sowingSound ~= nil and sowingSound ~= "" then
      sowingSound = Utils.getFilename(sowingSound, self.baseDirectory)
      self.sowingSound = createSample("sowingSound")
      loadSample(self.sowingSound, sowingSound, false)
      self.sowingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.sowingSound#pitchOffset"), 0)
      self.sowingSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.sowingSound#volume"), 1)
      self.sowingSoundEnabled = false
    end
    local changeSeedInputButtonStr = getXMLString(xmlFile, "vehicle.changeSeedInputButton")
    if changeSeedInputButtonStr ~= nil then
      self.changeSeedInputButton = InputBinding[changeSeedInputButtonStr]
    end
    self.changeSeedInputButton = Utils.getNoNil(self.changeSeedInputButton, InputBinding.IMPLEMENT_EXTRA3)
  end
  self.lastSowingArea = 0
  self.currentSeed = 1
  self.allowsSeedChanging = true
  self.sowingMachineContactReportsActive = false
  self.sowingMachineGroundContactFlag = self:getNextDirtyFlag()
end
function SowingMachine:delete()
  Utils.deleteParticleSystem(self.groundParticleSystems)
  for _, v in pairs(self.newGroundParticleSystems) do
    Utils.deleteParticleSystem(v.ps)
  end
  SowingMachine.removeContactReports(self)
  if self.sowingSound ~= nil then
    delete(self.sowingSound)
  end
end
function SowingMachine:readStream(streamId, connection)
  local seedIndex = streamReadUInt8(streamId)
  local turnedOn = streamReadBool(streamId)
  local isSowingMachineFilling = streamReadBool(streamId)
  self:setSeedIndex(seedIndex, true)
  self:setIsTurnedOn(turnedOn, true)
  self:setIsSowingMachineFilling(isSowingMachineFilling, true)
end
function SowingMachine:writeStream(streamId, connection)
  streamWriteUInt8(streamId, self.currentSeed)
  streamWriteBool(streamId, self.isTurnedOn)
  streamWriteBool(streamId, self.isSowingMachineFilling)
end
function SowingMachine:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    self.sowingMachineHasGroundContact = streamReadBool(streamId)
  end
end
function SowingMachine:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.sowingMachineHasGroundContact)
  end
end
function SowingMachine:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local selectedSeedFruitType = getXMLString(xmlFile, key .. "#selectedSeedFruitType")
  if selectedSeedFruitType ~= nil then
    local fruitTypeDesc = FruitUtil.fruitTypes[selectedSeedFruitType]
    if fruitTypeDesc ~= nil then
      self:setSeedFruitType(fruitTypeDesc.index, true)
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function SowingMachine:getSaveAttributesAndNodes(nodeIdent)
  local selectedSeedFruitTypeName = "unknown"
  local selectedSeedFruitType = self.seeds[self.currentSeed]
  if selectedSeedFruitType ~= nil and selectedSeedFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    selectedSeedFruitTypeName = FruitUtil.fruitIndexToDesc[selectedSeedFruitType].name
  end
  local attributes = "selectedSeedFruitType=\"" .. selectedSeedFruitTypeName .. "\""
  return attributes, nil
end
function SowingMachine:mouseEvent(posX, posY, isDown, isUp, button)
end
function SowingMachine:keyEvent(unicode, sym, modifier, isDown)
end
function SowingMachine:update(dt)
  if self:getIsActiveForInput() then
    if InputBinding.hasEvent(self.changeSeedInputButton) and self.allowsSeedChanging then
      local seed = self.currentSeed + 1
      if seed > table.getn(self.seeds) then
        seed = 1
      end
      self:setSeedIndex(seed)
    end
    if self.needsActivation and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
      self:setIsTurnedOn(not self.isTurnedOn)
    end
  end
end
function SowingMachine:updateTick(dt)
  if self:getIsActive() then
    local hasGroundContact = false
    self.lastSowingArea = 0
    if not hasGroundContact then
      if self.isServer then
        for k, v in pairs(self.contactReportNodes) do
          if v.hasGroundContact then
            hasGroundContact = true
            break
          end
        end
        for k, v in pairs(self.wheels) do
          if v.hasGroundContact then
            hasGroundContact = true
            break
          end
        end
        if not hasGroundContact and self.groundReferenceNode ~= nil then
          local x, y, z = getWorldTranslation(self.groundReferenceNode)
          local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
          if y <= terrainHeight + self.groundReferenceThreshold then
            hasGroundContact = true
          end
        end
        if self.sowingMachineHasGroundContact ~= hasGroundContact then
          self:raiseDirtyFlags(self.sowingMachineGroundContactFlag)
        end
      end
      self.sowingMachineHasGroundContact = hasGroundContact
    end
    local hasGroundContact = self.sowingMachineHasGroundContact
    local foldAnimTime = self.foldAnimTime
    if 0 < self.movingDirection and hasGroundContact then
      local enableGroundParticleSystems = false
      if not self.needsActivation or self.isTurnedOn then
        if self.lastSpeed * 3600 > 5 then
          enableGroundParticleSystems = true
        end
        if self.isServer then
          local hasSeeds = 0 < self.fillLevel
          local useFillLevel = true
          if self.capacity == 0 or self:getIsHired() then
            useFillLevel = false
            hasSeeds = true
          end
          if hasSeeds then
            self.cuttingAreasSend = {}
            for k, cuttingArea in pairs(self.cuttingAreas) do
              local ps = self.newGroundParticleSystems[k]
              if self:getIsAreaActive(cuttingArea) then
                local x, y, z = getWorldTranslation(cuttingArea.start)
                local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
                local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
                table.insert(self.cuttingAreasSend, {
                  x,
                  z,
                  x1,
                  z1,
                  x2,
                  z2
                })
                if ps ~= nil and enableGroundParticleSystems and not ps.isActive then
                  ps.isActive = true
                  Utils.setEmittingState(ps.ps, true)
                end
              elseif ps ~= nil and ps.isActive then
                ps.isActive = false
                Utils.setEmittingState(ps.ps, false)
              end
            end
            if 0 < table.getn(self.cuttingAreasSend) then
              local area = SowingMachineAreaEvent.runLocally(self.cuttingAreasSend, self.seeds[self.currentSeed])
              if 0 < area then
                local fruitDesc = FruitUtil.fruitIndexToDesc[self.seeds[self.currentSeed]]
                local pixelToSqm = g_currentMission:getTerrainDetailPixelsToSqm()
                local sqm = area * pixelToSqm
                local ha = sqm / 10000
                self.lastSowingArea = sqm
                local usage = fruitDesc.seedUsagePerSqm * sqm
                g_currentMission.missionStats.seedUsageTotal = g_currentMission.missionStats.seedUsageTotal + usage
                g_currentMission.missionStats.seedUsageSession = g_currentMission.missionStats.seedUsageSession + usage
                g_currentMission.missionStats.hectaresSeededTotal = g_currentMission.missionStats.hectaresSeededTotal + ha
                g_currentMission.missionStats.hectaresSeededSession = g_currentMission.missionStats.hectaresSeededSession + ha
                if useFillLevel then
                  self:setFillLevel(self.fillLevel - usage, self.currentFillType)
                else
                  local delta = usage * g_seedsPricePerLiter
                  g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta
                  g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta
                  g_currentMission:addSharedMoney(-delta)
                end
                g_server:broadcastEvent(SowingMachineAreaEvent:new(self.cuttingAreasSend, self.seeds[self.currentSeed]))
              end
            end
          end
        end
        g_currentMission.missionStats.seedingDurationTotal = g_currentMission.missionStats.seedingDurationTotal + dt / 60000
        g_currentMission.missionStats.seedingDurationSession = g_currentMission.missionStats.seedingDurationSession + dt / 60000
        local speedLimit = 20
        if self.maxSpeedLevel == 2 then
          speedLimit = 30
        elseif self.maxSpeedLevel == 3 then
          speedLimit = 100
        end
        if self:doCheckSpeedLimit() and speedLimit < self.lastSpeed * 3600 then
          self.speedViolationTimer = self.speedViolationTimer - dt
          if self.isServer and 0 > self.speedViolationTimer and self.attacherVehicle ~= nil then
            self.attacherVehicle:detachImplementByObject(self)
          end
        else
          self.speedViolationTimer = self.speedViolationMaxTime
        end
      else
        self.speedViolationTimer = self.speedViolationMaxTime
      end
      if self.isClient then
        if enableGroundParticleSystems and not self.groundParticleSystemActive then
          self.groundParticleSystemActive = true
          Utils.setEmittingState(self.groundParticleSystems, true)
        end
        if not enableGroundParticleSystems and self.groundParticleSystemActive then
          self.groundParticleSystemActive = false
          Utils.setEmittingState(self.groundParticleSystems, false)
        end
        if not enableGroundParticleSystems then
          for k, ps in pairs(self.newGroundParticleSystems) do
            if ps.isActive then
              ps.isActive = false
              Utils.setEmittingState(ps.ps, false)
            end
          end
        end
        if enableGroundParticleSystems then
          for k, cuttingArea in pairs(self.cuttingAreas) do
            local ps = self.newGroundParticleSystems[k]
            if self:getIsAreaActive(cuttingArea) then
              if ps ~= nil and not ps.isActive then
                ps.isActive = true
                Utils.setEmittingState(ps.ps, true)
              end
            elseif ps ~= nil and ps.isActive then
              ps.isActive = false
              Utils.setEmittingState(ps.ps, false)
            end
          end
        end
        if self.sowingSound ~= nil then
          if self.lastSpeed * 3600 > 3 and (not self.needsActivation or self.isTurnedOn) then
            if not self.sowingSoundEnabled and self:getIsActiveForSound() then
              playSample(self.sowingSound, 0, self.sowingSoundVolume, 0)
              setSamplePitch(self.sowingSound, self.sowingSoundPitchOffset)
              self.sowingSoundEnabled = true
            end
          elseif self.sowingSoundEnabled then
            self.sowingSoundEnabled = false
            stopSample(self.sowingSound)
          end
        end
      end
      for k, v in pairs(self.speedRotatingParts) do
        if foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit then
          rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
        end
      end
    else
      if self.isClient then
        if self.groundParticleSystemActive then
          self.groundParticleSystemActive = false
          Utils.setEmittingState(self.groundParticleSystems, false)
        end
        for k, ps in pairs(self.newGroundParticleSystems) do
          if ps.isActive then
            ps.isActive = false
            Utils.setEmittingState(ps.ps, false)
          end
        end
      end
      self.speedViolationTimer = self.speedViolationMaxTime
      SowingMachine.onDeactivateSounds(self)
    end
  end
  if self.isSowingMachineFilling and self.isServer then
    local disableFilling = false
    if self:allowFillType(Fillable.FILLTYPE_SEEDS, false) then
      local oldFillLevel = self.fillLevel
      local delta = self.fillLitersPerSecond * dt * 0.001
      local silo = g_currentMission:getSiloAmount(Fillable.FILLTYPE_SEEDS)
      self:setFillLevel(self.fillLevel + delta, Fillable.FILLTYPE_SEEDS, true)
      local delta = self.fillLevel - oldFillLevel
      if 0 < delta then
        local price = delta * g_seedsPricePerLiter
        g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
        g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
        g_currentMission:addSharedMoney(-price)
      elseif self.fillLevel == self.capacity then
        disableFilling = true
      end
    else
      disableFilling = true
    end
    if disableFilling then
      self:setIsSowingMachineFilling(false)
    end
  end
end
function SowingMachine:draw()
  if self.isClient then
    if self.fillLevel <= 0 and self.capacity ~= 0 then
      g_currentMission:addExtraPrintText(g_i18n:getText("FirstFillTheTool"))
    end
    g_currentMission:setFruitOverlayFruitType(self.seeds[self.currentSeed])
    if self.allowsSeedChanging then
      g_currentMission:addHelpButtonText(g_i18n:getText("ChooseSeed"), self.changeSeedInputButton)
    end
    if self.needsActivation then
      if self.isTurnedOn then
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
      elseif self.fillLevel > 0 or self.capacity == 0 then
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
      end
    end
    if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
      local buttonName = InputBinding.SPEED_LEVEL1
      if self.maxSpeedLevel == 2 then
        buttonName = InputBinding.SPEED_LEVEL2
      elseif self.maxSpeedLevel == 3 then
        buttonName = InputBinding.SPEED_LEVEL3
      end
      g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), tostring(self.maxSpeedLevel), InputBinding.getKeyNamesOfDigitalAction(buttonName)), 0.092, 0.048)
    end
  end
end
function SowingMachine:onAttach(attacherVehicle)
  SowingMachine.onActivate(self)
  SowingMachine.addContactReports(self)
end
function SowingMachine:onDetach()
  if self.deactivateOnDetach then
    SowingMachine.onDeactivate(self)
    SowingMachine.removeContactReports(self)
  else
    SowingMachine.onDeactivateSounds(self)
  end
end
function SowingMachine:onEnter(isControlling)
  if isControlling then
    SowingMachine.onActivate(self)
    SowingMachine.addContactReports(self)
  end
end
function SowingMachine:onLeave()
  if self.deactivateOnLeave then
    SowingMachine.onDeactivate(self)
    SowingMachine.removeContactReports(self)
  end
end
function SowingMachine:onActivate()
end
function SowingMachine:onDeactivate()
  self.speedViolationTimer = self.speedViolationMaxTime
  if self.groundParticleSystemActive then
    self.groundParticleSystemActive = false
    Utils.setEmittingState(self.groundParticleSystems, false)
  end
  for k, ps in pairs(self.newGroundParticleSystems) do
    if ps.isActive then
      ps.isActive = false
      Utils.setEmittingState(ps.ps, false)
    end
  end
  self:setIsTurnedOn(false, true)
  SowingMachine.onDeactivateSounds(self)
end
function SowingMachine:setIsTurnedOn(turnedOn, noEventSend)
  SetTurnedOnEvent.sendEvent(self, turnedOn, noEventSend)
  self.isTurnedOn = turnedOn
end
function SowingMachine:onDeactivateSounds()
  if self.sowingSoundEnabled then
    stopSample(self.sowingSound)
    self.sowingSoundEnabled = false
  end
end
function SowingMachine:setSeedIndex(seedIndex, noEventSend)
  SowingMachineSetSeedIndex.sendEvent(self, seedIndex, noEventSend)
  self.currentSeed = math.min(math.max(seedIndex, 1), table.getn(self.seeds))
end
function SowingMachine:setSeedFruitType(fruitType, noEventSend)
  for i, v in ipairs(self.seeds) do
    if v == fruitType then
      self:setSeedIndex(i, noEventSend)
      break
    end
  end
end
function SowingMachine:aiTurnOn()
  self.isTurnedOn = true
end
function SowingMachine:aiLower()
  self.isTurnedOn = true
end
function SowingMachine:aiRaise()
  self.isTurnedOn = false
end
function SowingMachine:addContactReports()
  if not self.sowingMachineContactReportsActive then
    for k, v in pairs(self.contactReportNodes) do
      addContactReport(v.node, 1.0E-4, "groundContactReport", self)
    end
    self.sowingMachineContactReportsActive = true
  end
end
function SowingMachine:removeContactReports()
  if self.sowingMachineContactReportsActive then
    for k, v in pairs(self.contactReportNodes) do
      removeContactReport(v.node)
      v.hasGroundContact = false
    end
    self.sowingMachineContactReportsActive = false
  end
end
function SowingMachine:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)
  if otherObjectId == g_currentMission.terrainRootNode then
    local entry = self.contactReportNodes[objectId]
    if entry ~= nil then
      entry.hasGroundContact = isStart or 0 < normalForce or 0 < tangentialForce
    end
  end
end
function SowingMachine:setIsSowingMachineFilling(isFilling, noEventSend)
  SowingMachineSetIsFillingEvent.sendEvent(self, isFilling, noEventSend)
  if self.isSowingMachineFilling ~= isFilling then
    self.isSowingMachineFilling = isFilling
  end
end
function SowingMachine:addSowingMachineFillTrigger(trigger)
  if table.getn(self.sowingMachineFillTriggers) == 0 then
    g_currentMission:addActivatableObject(self.sowingMachineFillActivatable)
  end
  table.insert(self.sowingMachineFillTriggers, trigger)
end
function SowingMachine:removeSowingMachineFillTrigger(trigger)
  for i = 1, table.getn(self.sowingMachineFillTriggers) do
    if self.sowingMachineFillTriggers[i] == trigger then
      table.remove(self.sowingMachineFillTriggers, i)
      break
    end
  end
  if table.getn(self.sowingMachineFillTriggers) == 0 then
    if self.isServer then
      self:setIsSowingMachineFilling(false)
    end
    g_currentMission:removeActivatableObject(self.sowingMachineFillActivatable)
  end
end
SowingMachineFillActivatable = {}
local SowingMachineFillActivatable_mt = Class(SowingMachineFillActivatable)
function SowingMachineFillActivatable:new(sowingMachine)
  local self = {}
  setmetatable(self, SowingMachineFillActivatable_mt)
  self.sowingMachine = sowingMachine
  self.activateText = "unknown"
  self.currentTrigger = nil
  return self
end
function SowingMachineFillActivatable:getIsActivatable()
  self.currentTrigger = nil
  if not self.sowingMachine:getIsActiveForInput() or self.sowingMachine.fillLevel == self.sowingMachine.capacity then
    return false
  end
  if table.getn(self.sowingMachine.sowingMachineFillTriggers) > 0 then
    self.currentTrigger = self.sowingMachine.sowingMachineFillTriggers[1]
    self:updateActivateText()
    return true
  end
  return false
end
function SowingMachineFillActivatable:onActivateObject()
  self.sowingMachine:setIsSowingMachineFilling(not self.sowingMachine.isSowingMachineFilling, self.currentTrigger.fillType, self.currentTrigger.isSiloTrigger)
  self:updateActivateText()
  g_currentMission:addActivatableObject(self)
end
function SowingMachineFillActivatable:drawActivate()
end
function SowingMachineFillActivatable:updateActivateText()
  if self.sowingMachine.isSowingMachineFilling then
    self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), self.sowingMachine.typeDesc)
  else
    self.activateText = string.format(g_i18n:getText("refill_OBJECT"), self.sowingMachine.typeDesc)
  end
end
