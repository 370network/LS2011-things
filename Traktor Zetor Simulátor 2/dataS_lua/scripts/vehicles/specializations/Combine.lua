Combine = {}
source("dataS/scripts/vehicles/specializations/CombineSetPipeStateEvent.lua")
source("dataS/scripts/vehicles/specializations/CombineSetThreshingEnabledEvent.lua")
source("dataS/scripts/vehicles/specializations/CombinePipeParticleActivatedEvent.lua")
source("dataS/scripts/vehicles/specializations/CombineAreaEvent.lua")
source("dataS/scripts/vehicles/specializations/CombineSetStrawEnableEvent.lua")
source("dataS/scripts/vehicles/specializations/CombineSetChopperEnableEvent.lua")
function Combine.initSpecialization()
  Vehicle.registerJointType("cutter")
  Vehicle.registerJointType("trailerCombine")
end
function Combine.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Steerable, specializations)
end
function Combine:load(xmlFile)
  self.allowGrainTankFruitType = Combine.allowGrainTankFruitType
  self.emptyGrainTankIfLowFillLevel = Combine.emptyGrainTankIfLowFillLevel
  self.setGrainTankFillLevel = SpecializationUtil.callSpecializationsFunction("setGrainTankFillLevel")
  self.startThreshing = SpecializationUtil.callSpecializationsFunction("startThreshing")
  self.stopThreshing = SpecializationUtil.callSpecializationsFunction("stopThreshing")
  self.setIsThreshing = SpecializationUtil.callSpecializationsFunction("setIsThreshing")
  self.setPipeOpening = SpecializationUtil.callSpecializationsFunction("setPipeOpening")
  self.setPipeState = SpecializationUtil.callSpecializationsFunction("setPipeState")
  self.getFruitTypeAndFillLevelToUnload = Combine.getFruitTypeAndFillLevelToUnload
  self.findAutoAimTrailerToUnload = Combine.findAutoAimTrailerToUnload
  self.findTrailerToUnload = Combine.findTrailerToUnload
  self.findTrailerRaycastCallback = Combine.findTrailerRaycastCallback
  self.getIshreshingAllowed = Combine.getIshreshingAllowed
  if self.isClient then
    local threshingStartSound = getXMLString(xmlFile, "vehicle.threshingStartSound#file")
    if threshingStartSound ~= nil and threshingStartSound ~= "" then
      threshingStartSound = Utils.getFilename(threshingStartSound, self.baseDirectory)
      self.threshingStartSound = createSample("threshingStartSound")
      loadSample(self.threshingStartSound, threshingStartSound, false)
      self.threshingStartSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStartSound#pitchOffset"), 1)
      self.threshingStartSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStartSound#pitchScale"), 0)
      self.threshingStartSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStartSound#pitchMax"), 2)
    end
    self.threshingSoundActive = false
    local threshingSound = getXMLString(xmlFile, "vehicle.threshingSound#file")
    if threshingSound ~= nil and threshingSound ~= "" then
      threshingSound = Utils.getFilename(threshingSound, self.baseDirectory)
      self.threshingSound = createSample("threshingSound")
      loadSample(self.threshingSound, threshingSound, false)
      self.threshingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchOffset"), 1)
      self.threshingSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchScale"), 0)
      self.threshingSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchMax"), 2)
    end
    local threshingStopSound = getXMLString(xmlFile, "vehicle.threshingStopSound#file")
    if threshingStopSound ~= nil and threshingStopSound ~= "" then
      threshingStopSound = Utils.getFilename(threshingStopSound, self.baseDirectory)
      self.threshingStopSound = createSample("threshingStopSound")
      loadSample(self.threshingStopSound, threshingStopSound, false)
      self.threshingStopSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStopSound#pitchOffset"), 1)
      self.threshingStopSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStopSound#pitchScale"), 0)
      self.threshingStopSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStopSound#pitchMax"), 2)
    end
    local pipeSound = getXMLString(xmlFile, "vehicle.pipeSound#file")
    if pipeSound ~= nil and pipeSound ~= "" then
      pipeSound = Utils.getFilename(pipeSound, self.baseDirectory)
      self.pipeSound = createSample("pipeSound")
      loadSample(self.pipeSound, pipeSound, false)
      self.pipeSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipeSound#pitchOffset"), 1)
      self.pipeSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipeSound#pitchScale"), 0)
      self.pipeSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipeSound#pitchMax"), 2)
    end
  end
  self.chopperBlind = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.chopperBlind#index"))
  self.pipeParticleSystems = {}
  self.pipeNodes = {}
  self.numPipeStates = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.pipe#numStates"), 0)
  self.currentPipeState = 1
  self.targetPipeState = 1
  self.pipeStateIsUnloading = {}
  self.pipeStateIsAutoAiming = {}
  local unloadingPipeStates = Utils.getVectorNFromString(getXMLString(xmlFile, "vehicle.pipe#unloadingStates"))
  if unloadingPipeStates ~= nil then
    for i = 1, table.getn(unloadingPipeStates) do
      if unloadingPipeStates[i] ~= nil then
        self.pipeStateIsUnloading[unloadingPipeStates[i]] = true
      end
    end
  end
  local autoAimPipeStates = Utils.getVectorNFromString(getXMLString(xmlFile, "vehicle.pipe#autoAimStates"))
  if autoAimPipeStates ~= nil then
    for i = 1, table.getn(autoAimPipeStates) do
      if autoAimPipeStates[i] ~= nil then
        self.pipeStateIsAutoAiming[autoAimPipeStates[i]] = true
      end
    end
  end
  local i = 0
  while true do
    local key = string.format("vehicle.pipe.node(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    if node ~= nil then
      local entry = {}
      entry.node = node
      entry.autoAimXRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoAimXRotation"), false)
      entry.autoAimYRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoAimYRotation"), false)
      entry.autoAimInvertZ = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoAimInvertZ"), false)
      entry.states = {}
      for state = 1, self.numPipeStates do
        local stateKey = key .. string.format(".state%d", state)
        entry.states[state] = {}
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, stateKey .. "#translation"))
        if x == nil or y == nil or z == nil then
          x, y, z = getTranslation(node)
        end
        entry.states[state].translation = {
          x,
          y,
          z
        }
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, stateKey .. "#rotation"))
        if x == nil or y == nil or z == nil then
          x, y, z = getRotation(node)
        else
          x, y, z = math.rad(x), math.rad(y), math.rad(z)
        end
        entry.states[state].rotation = {
          x,
          y,
          z
        }
      end
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#translationSpeeds"))
      if x ~= nil and y ~= nil and z ~= nil then
        x, y, z = x * 0.001, y * 0.001, z * 0.001
        if x ~= 0 or y ~= 0 or z ~= 0 then
          entry.translationSpeeds = {
            x,
            y,
            z
          }
        end
      end
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rotationSpeeds"))
      if x ~= nil and y ~= nil and z ~= nil then
        x, y, z = math.rad(x) * 0.001, math.rad(y) * 0.001, math.rad(z) * 0.001
        if x ~= 0 or y ~= 0 or z ~= 0 then
          entry.rotationSpeeds = {
            x,
            y,
            z
          }
        end
      end
      local x, y, z = getTranslation(node)
      entry.curTranslation = {
        x,
        y,
        z
      }
      local x, y, z = getRotation(node)
      entry.curRotation = {
        x,
        y,
        z
      }
      table.insert(self.pipeNodes, entry)
    end
    i = i + 1
  end
  if table.getn(self.pipeNodes) == 0 then
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipe#index"))
    if node ~= nil then
      self.numPipeStates = 2
      local entry = {}
      entry.node = node
      entry.states = {}
      entry.states[1] = {}
      entry.states[2] = {}
      local x, y, z = getRotation(node)
      entry.states[1].rotation = {
        0,
        0,
        z
      }
      entry.states[2].rotation = {
        math.rad(10),
        math.rad(-90),
        z
      }
      entry.rotationSpeeds = {
        6.0E-5,
        6.0E-4,
        0
      }
      local x, y, z = getRotation(node)
      entry.curRotation = {
        x,
        y,
        z
      }
      table.insert(self.pipeNodes, entry)
      self.pipeStateIsUnloading[2] = true
    end
  end
  local pipeFlapLid = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipeFlapLid#index"))
  if pipeFlapLid ~= nil then
    if self.numPipeStates ~= 2 then
      print("Error: pipeFlapLid is only support with 2 pipe states in '" .. self.configFileName .. "'.")
    else
      local entry = {}
      entry.node = pipeFlapLid
      entry.states = {}
      entry.states[1] = {}
      entry.states[2] = {}
      entry.states[1].rotation = {
        0,
        0,
        0
      }
      entry.states[2].rotation = {
        0,
        math.rad(-90),
        0
      }
      entry.rotationSpeeds = {
        0,
        6.0E-4,
        0
      }
      local x, y, z = getRotation(pipeFlapLid)
      entry.curRotation = {
        x,
        y,
        z
      }
      table.insert(self.pipeNodes, entry)
    end
  end
  if 0 < table.getn(self.pipeNodes) then
    self.pipeRaycastNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipe#raycastNodeIndex"))
    local i = 0
    while true do
      local key = string.format("vehicle.pipeParticleSystems.pipeParticleSystem(%d)", i)
      local t = getXMLString(xmlFile, key .. "#type")
      if t == nil then
        break
      end
      local desc = FruitUtil.fruitTypes[t]
      if desc ~= nil then
        local currentPS = {}
        local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.components, false, "$data/vehicles/particleSystems/wheatParticleSystem.i3d", self.baseDirectory, self.pipeNodes[1].node)
        self.pipeParticleSystems[desc.index] = currentPS
        if self.defaultPipeParticleSystem == nil then
          self.defaultPipeParticleSystem = currentPS
        end
        if self.pipeRaycastNode == nil then
          self.pipeRaycastNode = particleNode
        end
      end
      i = i + 1
    end
    if self.pipeRaycastNode == nil then
      self.pipeRaycastNode = self.components[1].node
    end
  end
  self.pipeRaycastDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipe#raycastDistance"), 7)
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
  self.allowsThreshing = true
  self.pipeLight = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipeLight#index"))
  self.rotorFan = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.rotorFan#index"))
  self.grainTankCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankCapacity"), 200)
  self.grainTankUnloadingCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankUnloadingCapacity"), 10)
  self.grainTankCrowded = false
  self.allowThreshingDuringRain = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.allowThreshingDuringRain"), false)
  if self.isClient then
    self.grainTankPlanes = {}
    local i = 0
    while true do
      local key = string.format("vehicle.grainTankPlanes.grainTankPlane(%d)", i)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local grainTankPlane = {}
      grainTankPlane.nodes = {}
      local fruitType = getXMLString(xmlFile, key .. "#type")
      if fruitType ~= nil then
        local nodeI = 0
        while true do
          local nodeKey = key .. string.format(".node(%d)", nodeI)
          if not hasXMLProperty(xmlFile, nodeKey) then
            break
          end
          local node = Utils.indexToObject(self.components, getXMLString(xmlFile, nodeKey .. "#index"))
          if node ~= nil then
            local defaultX, defaultY, defaultZ = getTranslation(node)
            local defaultRX, defaultRY, defaultRZ = getRotation(node)
            setVisibility(node, false)
            local animCurve = AnimCurve:new(linearInterpolatorTransRotScale)
            local keyI = 0
            while true do
              local animKey = nodeKey .. string.format(".key(%d)", keyI)
              local keyTime = getXMLFloat(xmlFile, animKey .. "#time")
              local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#translation"))
              if y == nil then
                y = getXMLFloat(xmlFile, animKey .. "#y")
              end
              local rx, ry, rz = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#rotation"))
              local sx, sy, sz = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#scale"))
              if keyTime == nil then
                break
              end
              local x = Utils.getNoNil(x, defaultX)
              local y = Utils.getNoNil(y, defaultY)
              local z = Utils.getNoNil(z, defaultZ)
              local rx = Utils.getNoNil(rx, defaultRX)
              local ry = Utils.getNoNil(ry, defaultRY)
              local rz = Utils.getNoNil(rz, defaultRZ)
              local sx = Utils.getNoNil(sx, 1)
              local sy = Utils.getNoNil(sy, 1)
              local sz = Utils.getNoNil(sz, 1)
              animCurve:addKeyframe({
                x = x,
                y = y,
                z = z,
                rx = rx,
                ry = ry,
                rz = rz,
                sx = sx,
                sy = sy,
                sz = sz,
                time = keyTime
              })
              keyI = keyI + 1
            end
            if keyI == 0 then
              local minY, maxY = Utils.getVectorFromString(getXMLString(xmlFile, nodeKey .. "#minMaxY"))
              local minY = Utils.getNoNil(minY, defaultY)
              local maxY = Utils.getNoNil(maxY, defaultY)
              animCurve:addKeyframe({
                x = defaultX,
                y = minY,
                z = defaultZ,
                rx = defaultRX,
                ry = defaultRY,
                rz = defaultRZ,
                sx = 1,
                sy = 1,
                sz = 1,
                time = 0
              })
              animCurve:addKeyframe({
                x = defaultX,
                y = maxY,
                z = defaultZ,
                rx = defaultRX,
                ry = defaultRY,
                rz = defaultRZ,
                sx = 1,
                sy = 1,
                sz = 1,
                time = 1
              })
            end
            table.insert(grainTankPlane.nodes, {node = node, animCurve = animCurve})
          end
          nodeI = nodeI + 1
        end
        if 0 < table.getn(grainTankPlane.nodes) then
          if self.defaultGrainTankPlane == nil then
            self.defaultGrainTankPlane = grainTankPlane
          end
          self.grainTankPlanes[fruitType] = grainTankPlane
        end
      end
      i = i + 1
    end
    if self.defaultGrainTankPlane == nil then
      self.grainTankPlanes = nil
    end
    if self.grainTankPlanes == nil and hasXMLProperty(xmlFile, "vehicle.grainTankPlane.node") then
      print("Warning: '" .. self.configFileName .. "' uses old grainTankPlane format, which is not supported anymore.")
    end
    self.chopperParticleSystems = {}
    local i = 0
    while true do
      local key = string.format("vehicle.chopperParticleSystems.chopperParticleSystem(%d)", i)
      local t = getXMLString(xmlFile, key .. "#type")
      if t == nil then
        break
      end
      local desc = FruitUtil.fruitTypes[t]
      if desc ~= nil then
        local currentPS = {}
        local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.components, false, "$data/vehicles/particleSystems/threshingChopperParticleSystem.i3d", self.baseDirectory)
        self.chopperParticleSystems[desc.index] = currentPS
        if self.defaultChopperParticleSystem == nil then
          self.defaultChopperParticleSystem = currentPS
        end
      end
      i = i + 1
    end
    self.chopperToggleTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.chopperParticleSystems#toggleTime"), 2500)
    self.chopperEnableTime = nil
    self.chopperDisableTime = nil
    self.strawParticleSystems = {}
    local i = 0
    while true do
      local key = string.format("vehicle.strawParticleSystems.strawParticleSystem(%d)", i)
      local t = getXMLString(xmlFile, key .. "#type")
      if t == nil then
        break
      end
      local desc = FruitUtil.fruitTypes[t]
      if desc ~= nil then
        local currentPS = {}
        local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.components, false, "$data/vehicles/particleSystems/threshingStrawParticleSystem.i3d", self.baseDirectory)
        self.strawParticleSystems[desc.index] = currentPS
        if self.defaultStrawParticleSystem == nil then
          self.defaultStrawParticleSystem = currentPS
        end
      end
      i = i + 1
    end
  end
  self.strawToggleTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.strawParticleSystems#toggleTime"), 2500)
  self.strawEnableTime = nil
  self.strawDisableTime = nil
  self.strawEmitState = false
  self.combineSize = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.combineSize"), 1)
  local numStrawAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.strawAreas#count"), 0)
  self.strawAreas = {}
  for i = 1, numStrawAreas do
    local area = {}
    local areanamei = string.format("vehicle.strawAreas.strawArea%d", i)
    area.start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    area.width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    area.height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
    table.insert(self.strawAreas, area)
  end
  self.isThreshing = false
  self.chopperActivated = false
  self.defaultChopperState = false
  self.pipeIsUnloading = false
  self.pipeParticleActivated = false
  self.pipeParticleDeactivateTime = 0
  self.threshingScale = 1
  self.grainTankFruitTypes = {}
  self.grainTankFruitTypes[FruitUtil.FRUITTYPE_UNKNOWN] = true
  local fruitTypes = getXMLString(xmlFile, "vehicle.grainTankFruitTypes#fruitTypes")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        self.grainTankFruitTypes[desc.index] = true
      end
    end
  end
  self.currentGrainTankFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.grainTankFillLevel = 0
  self.grainTankTempFillLevel = 0
  self.grainTankTempFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.minThreshold = 0.05
  self.speedDisplayScale = 1
  self.drawFillLevel = true
  self.attachedCutters = {}
  self.numAttachedCutters = 0
  self.lastArea = 0
  self.lastInputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastValidInputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastValidFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastOutputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastValidOutputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.combineDirtyFlag = self:getNextDirtyFlag()
  self:setGrainTankFillLevel(0, FruitUtil.FRUITTYPE_UNKNOWN)
end
function Combine:delete()
  for k, v in pairs(self.pipeParticleSystems) do
    Utils.deleteParticleSystem(v)
  end
  for k, v in pairs(self.chopperParticleSystems) do
    Utils.deleteParticleSystem(v)
  end
  for k, v in pairs(self.strawParticleSystems) do
    Utils.deleteParticleSystem(v)
  end
  if self.threshingStartSound ~= nil then
    delete(self.threshingStartSound)
  end
  if self.threshingSoundActive then
    delete(self.threshingSound)
    self.threshingSoundActive = false
  end
  if self.threshingStopSound ~= nil then
    delete(self.threshingStopSound)
  end
  if self.pipeSound ~= nil then
    delete(self.pipeSound)
  end
end
function Combine:readStream(streamId, connection)
  local fillLevel = streamReadFloat32(streamId)
  local fillType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
  self.pipeParticleActived = streamReadBool(streamId)
  self.pipeIsUnloading = streamReadBool(streamId)
  local pipeState = streamReadUIntN(streamId, 3)
  local isThreshing = streamReadBool(streamId)
  self:setGrainTankFillLevel(fillLevel, fillType)
  self:setPipeState(pipeState, true)
  self:setIsThreshing(isThreshing, true)
  local chopperPSenabled = streamReadBool(streamId)
  local chopperPSFruitType
  streamReadUIntN(streamId, FruitUtil.sendNumBits)
  local strawPSenabled = streamReadBool(streamId)
  local strawPSFruitType
  streamReadUIntN(streamId, FruitUtil.sendNumBits)
  CombineSetChopperEnableEvent.execute(self, chopperPSenabled, chopperPSFruitType)
  CombineSetStrawEnableEvent.execute(self, strawPSenabled, strawPSFruitType)
  self.lastValidFruitType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
  self.lastValidOutputFruitType = self.lastValidFruitType
  if self.convertedFruits[self.lastValidFruitType] ~= nil then
    self.lastValidOutputFruitType = self.convertedFruits[self.lastValidFruitType]
  end
  if self.lastValidFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    local fruitDesc = FruitUtil.fruitIndexToDesc[self.lastValidFruitType]
    if fruitDesc.hasStraw then
      self.chopperActivated = false
    else
      self.chopperActivated = true
    end
  else
    self.chopperActivated = self.defaultChopperState
  end
end
function Combine:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.grainTankFillLevel)
  streamWriteUIntN(streamId, self.currentGrainTankFruitType, FruitUtil.sendNumBits)
  streamWriteBool(streamId, self.pipeParticleActived)
  streamWriteBool(streamId, self.pipeIsUnloading)
  streamWriteUIntN(streamId, self.targetPipeState, 3)
  streamWriteBool(streamId, self.isThreshing)
  streamWriteBool(streamId, self.chopperPSenabled)
  streamWriteUIntN(streamId, self.chopperPSFruitType, FruitUtil.sendNumBits)
  streamWriteBool(streamId, self.strawPSenabled)
  streamWriteUIntN(streamId, self.strawPSFruitType, FruitUtil.sendNumBits)
  streamWriteUIntN(streamId, self.lastValidFruitType, FruitUtil.sendNumBits)
end
function Combine:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() and streamReadBool(streamId) then
    local fillLevel = streamReadFloat32(streamId)
    local fillType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
    self:setGrainTankFillLevel(fillLevel, fillType)
    self.lastValidFruitType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
    self.lastValidOutputFruitType = self.lastValidFruitType
    if self.convertedFruits[self.lastValidFruitType] ~= nil then
      self.lastValidOutputFruitType = self.convertedFruits[self.lastValidFruitType]
    end
    if self.lastValidFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      local fruitDesc = FruitUtil.fruitIndexToDesc[self.lastValidFruitType]
      if fruitDesc.hasStraw then
        self.chopperActivated = false
      else
        self.chopperActivated = true
      end
    else
      self.chopperActivated = self.defaultChopperState
    end
  end
end
function Combine:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.combineDirtyFlag) ~= 0) then
    streamWriteFloat32(streamId, self.grainTankFillLevel)
    streamWriteUIntN(streamId, self.currentGrainTankFruitType, FruitUtil.sendNumBits)
    streamWriteUIntN(streamId, self.lastValidFruitType, FruitUtil.sendNumBits)
  end
end
function Combine:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local fillLevel = getXMLFloat(xmlFile, key .. "#grainTankFillLevel")
  local fruitType = getXMLString(xmlFile, key .. "#grainTankFruitType")
  if fillLevel ~= nil and fruitType ~= nil then
    local fruitTypeDesc = FruitUtil.fruitTypes[fruitType]
    if fruitTypeDesc ~= nil then
      self:setGrainTankFillLevel(fillLevel, fruitTypeDesc.index)
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Combine:getSaveAttributesAndNodes(nodeIdent)
  local fruitType = "unknown"
  if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    fruitType = FruitUtil.fruitIndexToDesc[self.currentGrainTankFruitType].name
  end
  local attributes = "grainTankFillLevel=\"" .. self.grainTankFillLevel .. "\" grainTankFruitType=\"" .. fruitType .. "\""
  return attributes, nil
end
function Combine:mouseEvent(posX, posY, isDown, isUp, button)
end
function Combine:keyEvent(unicode, sym, modifier, isDown)
end
function Combine:update(dt)
  if self:getIsActive() then
    if self.isClient and self.isThreshing and self:getIsActiveForSound() and not self.threshingSoundActive and self.threshingSound ~= nil and self.playThreshingSoundTime <= self.time then
      playSample(self.threshingSound, 0, 1, 0)
      self.threshingSoundActive = true
    end
    if self.isClient and self:getIsActiveForInput() then
      if (self.grainTankFillLevel < self.grainTankCapacity or 0 >= self.grainTankCapacity) and InputBinding.hasEvent(InputBinding.ACTIVATE_THRESHING) then
        self:setIsThreshing(not self.isThreshing)
      end
      if InputBinding.hasEvent(InputBinding.EMPTY_GRAIN) then
        local nextState = self.targetPipeState + 1
        if nextState > self.numPipeStates then
          nextState = 1
        end
        self:setPipeState(nextState)
      end
    end
    if self.isServer and self.grainTankFillLevel >= self.grainTankCapacity and 0 < self.grainTankCapacity then
      self:setIsThreshing(false)
    end
    if self.isThreshing and self.rotorFan ~= nil then
      rotate(self.rotorFan, dt * 0.005, 0, 0)
    end
    local chopperBlindRotationSpeed = 0.001
    local minRotX = -1.4485805555555555
    if self.chopperBlind ~= nil then
      local x, y, z = getRotation(self.chopperBlind)
      if self.chopperActivated then
        x = x - dt * chopperBlindRotationSpeed
        if minRotX > x then
          x = minRotX
        end
      else
        x = x + dt * chopperBlindRotationSpeed
        if 0 < x then
          x = 0
        end
      end
      setRotation(self.chopperBlind, x, y, z)
    end
    local doAutoAiming = self.pipeStateIsAutoAiming[self.currentPipeState]
    local targetTrailer
    if doAutoAiming then
      targetTrailer = self:findAutoAimTrailerToUnload(self.lastValidOutputFruitType)
      if targetTrailer == nil then
        doAutoAiming = false
      end
    end
    if (self.currentPipeState ~= self.targetPipeState or doAutoAiming) and self.targetPipeState <= self.numPipeStates then
      local autoAimX, autoAimY, autoAimZ
      if doAutoAiming then
        autoAimX, autoAimY, autoAimZ = getWorldTranslation(targetTrailer.fillAutoAimTargetNode)
      end
      local moved = false
      for i = 1, table.getn(self.pipeNodes) do
        local nodeMoved = false
        local pipeNode = self.pipeNodes[i]
        local state = pipeNode.states[self.targetPipeState]
        if pipeNode.translationSpeeds ~= nil then
          for i = 1, 3 do
            if pipeNode.curTranslation[i] ~= state.translation[i] then
              nodeMoved = true
              if pipeNode.curTranslation[i] < state.translation[i] then
                pipeNode.curTranslation[i] = math.min(pipeNode.curTranslation[i] + dt * pipeNode.translationSpeeds[i], state.translation[i])
              else
                pipeNode.curTranslation[i] = math.max(pipeNode.curTranslation[i] - dt * pipeNode.translationSpeeds[i], state.translation[i])
              end
            end
          end
          setTranslation(pipeNode.node, pipeNode.curTranslation[1], pipeNode.curTranslation[2], pipeNode.curTranslation[3])
        end
        if pipeNode.rotationSpeeds ~= nil then
          for i = 1, 3 do
            local targetRotation = state.rotation[i]
            if doAutoAiming then
              if pipeNode.autoAimXRotation and i == 1 then
                local x, y, z = getWorldTranslation(pipeNode.node)
                local x, y, z = worldDirectionToLocal(getParent(pipeNode.node), autoAimX - x, autoAimY - y, autoAimZ - z)
                targetRotation = -math.atan2(y, z)
                if pipeNode.autoAimInvertZ then
                  targetRotation = targetRotation + math.pi
                end
                targetRotation = Utils.normalizeRotationForShortestPath(targetRotation, pipeNode.curRotation[i])
              elseif pipeNode.autoAimYRotation and i == 2 then
                local x, y, z = getWorldTranslation(pipeNode.node)
                local x, y, z = worldDirectionToLocal(getParent(pipeNode.node), autoAimX - x, autoAimY - y, autoAimZ - z)
                targetRotation = math.atan2(x, z)
                if pipeNode.autoAimInvertZ then
                  targetRotation = targetRotation + math.pi
                end
                targetRotation = Utils.normalizeRotationForShortestPath(targetRotation, pipeNode.curRotation[i])
              end
            end
            if pipeNode.curRotation[i] ~= targetRotation then
              nodeMoved = true
              if targetRotation > pipeNode.curRotation[i] then
                pipeNode.curRotation[i] = math.min(pipeNode.curRotation[i] + dt * pipeNode.rotationSpeeds[i], targetRotation)
              else
                pipeNode.curRotation[i] = math.max(pipeNode.curRotation[i] - dt * pipeNode.rotationSpeeds[i], targetRotation)
              end
            end
          end
          setRotation(pipeNode.node, pipeNode.curRotation[1], pipeNode.curRotation[2], pipeNode.curRotation[3])
        end
        moved = moved or nodeMoved
        if nodeMoved and self.setMovingToolDirty ~= nil then
          self:setMovingToolDirty(pipeNode.node)
        end
      end
      if not moved then
        self.currentPipeState = self.targetPipeState
      end
    end
    if self.isClient then
      if self.motor ~= nil then
        if self.motor.speedLevel == 1 then
          self.speedDisplayScale = 0.7
        elseif self.motor.speedLevel == 2 or self.motor.speedLevel == 4 then
          self.speedDisplayScale = 0.75
        else
          self.speedDisplayScale = 1
        end
      end
      if self.currentPipeState ~= self.targetPipeState then
        if self.pipeSound ~= nil and not self.pipeSoundEnabled and self:getIsActiveForSound() then
          setSamplePitch(self.pipeSound, self.pipeSoundPitchOffset)
          playSample(self.pipeSound, 0, 1, 0)
          self.pipeSoundEnabled = true
        end
      elseif self.pipeSound ~= nil and self.pipeSoundEnabled then
        stopSample(self.pipeSound)
        self.pipeSoundEnabled = false
      end
    end
  end
end
function Combine:updateTick(dt)
  if self.isServer then
    if self.lastInputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      self.lastValidInputFruitType = self.lastInputFruitType
    end
    if self.lastFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      self.lastValidFruitType = self.lastFruitType
    end
    if self.lastOutputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      self.lastValidOutputFruitType = self.lastOutputFruitType
    end
    self.lastArea = 0
    self.lastInputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
    self.lastFruitType = FruitUtil.FRUITTYPE_UNKNOWN
    self.lastOutputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
    self.grainTankTempFillLevel = 0
    local disableChopperEmit = true
    local disableStrawEmit = true
    if self.isThreshing then
      local lastArea = 0
      local fruitType = FruitUtil.FRUITTYPE_UNKNOWN
      local inputFruitType = FruitUtil.FRUITTYPE_UNKNOWN
      for cutter, implement in pairs(self.attachedCutters) do
        if cutter.reelStarted and cutter.lastArea > 0 then
          for cutter1, implement in pairs(self.attachedCutters) do
            cutter1:setFruitType(cutter.currentInputFruitType)
          end
          self.currentGrainTankFruitType = cutter.currentFruitType
          fruitType = cutter.currentFruitType
          inputFruitType = cutter.currentInputFruitType
          lastArea = lastArea + cutter.lastArea
        end
      end
      self.lastArea = lastArea
      self.lastFruitType = fruitType
      self.lastInputFruitType = inputFruitType
      local outputFruitType = fruitType
      if self.convertedFruits[fruitType] ~= nil then
        outputFruitType = self.convertedFruits[fruitType]
      end
      self.lastOutputFruitType = outputFruitType
      if self.lastArea > 0 then
        local fruitDesc = FruitUtil.fruitIndexToDesc[fruitType]
        if fruitDesc.hasStraw then
          self.chopperActivated = false
        else
          self.chopperActivated = true
        end
        if self.chopperActivated then
          if self.chopperEnableTime == nil then
            self.chopperEnableTime = self.time + self.chopperToggleTime
          else
            self.chopperDisableTime = nil
          end
          self.chopperPSFruitType = fruitType
          disableChopperEmit = false
        else
          if self.strawEnableTime == nil then
            self.strawEnableTime = self.time + self.strawToggleTime
          else
            self.strawDisableTime = nil
          end
          self.strawPSFruitType = fruitType
          disableStrawEmit = false
        end
        local pixelToSqm = g_currentMission:getFruitPixelsToSqm() / g_currentMission.maxFruitValue
        local literPerSqm = 1
        if fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
          literPerSqm = FruitUtil.fruitIndexToDesc[fruitType].literPerSqm
          if outputFruitType ~= fruitType and outputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
            literPerSqm = literPerSqm * FruitUtil.fruitIndexToDesc[outputFruitType].literPerSqm
          end
        end
        local sqm = self.lastArea * pixelToSqm
        local deltaFillLevel = sqm * literPerSqm * self.threshingScale
        if 0 < self.grainTankCapacity then
          local newFillLevel = self.grainTankFillLevel + deltaFillLevel
          self:setGrainTankFillLevel(newFillLevel, outputFruitType)
        else
          self.grainTankTempFillLevel = deltaFillLevel
          self.grainTankTempFruitType = outputFruitType
        end
      end
    end
    if disableChopperEmit and self.chopperDisableTime == nil then
      self.chopperDisableTime = self.time + self.chopperToggleTime
    end
    if disableStrawEmit and self.strawDisableTime == nil then
      self.strawDisableTime = self.time + self.strawToggleTime
    end
    if self.chopperEnableTime ~= nil and self.chopperEnableTime <= self.time then
      self.chopperPSenabled = true
      self.chopperEnableTime = nil
    end
    if self.strawEnableTime ~= nil and self.strawEnableTime <= self.time then
      self.strawPSenabled = true
      self.strawEnableTime = nil
      self.strawEmitState = true
    end
    if self.strawEmitState then
      local cuttingAreasSend = {}
      for k, strawArea in pairs(self.strawAreas) do
        local x, y, z = getWorldTranslation(strawArea.start)
        local x1, y1, z1 = getWorldTranslation(strawArea.width)
        local x2, y2, z2 = getWorldTranslation(strawArea.height)
        local old, total = Utils.getFruitWindrowArea(self.strawPSFruitType, x, z, x1, z1, x2, z2)
        local value = 1 + math.floor(old / total + 0.7)
        value = math.min(value, g_currentMission.maxWindrowValue)
        table.insert(cuttingAreasSend, {
          x,
          z,
          x1,
          z1,
          x2,
          z2,
          value
        })
      end
      if 0 < table.getn(cuttingAreasSend) then
        CombineAreaEvent.runLocally(cuttingAreasSend, self.strawPSFruitType)
        g_server:broadcastEvent(CombineAreaEvent:new(cuttingAreasSend, self.strawPSFruitType))
      end
    end
    self.pipeIsUnloading = false
    self.pipeParticleActivated = false
    if self.pipeStateIsUnloading[self.currentPipeState] then
      local fruitType, fillLevel, useGrainTank = self:getFruitTypeAndFillLevelToUnload()
      if 0 < fillLevel then
        self.pipeParticleActivated = true
        self.pipeIsUnloading = true
        local trailer = self:findTrailerToUnload(fruitType)
        if trailer == nil then
          self.pipeIsUnloading = false
        else
          trailer:resetFillLevelIfNeeded(FruitUtil.fruitTypeToFillType[fruitType])
          local deltaLevel = fillLevel
          if useGrainTank then
            deltaLevel = self.grainTankUnloadingCapacity * dt / 1000
          end
          deltaLevel = math.min(deltaLevel, trailer.capacity - trailer.fillLevel)
          fillLevel = fillLevel - deltaLevel
          if fillLevel <= 0 then
            deltaLevel = deltaLevel + fillLevel
            fillLevel = 0
            self.pipeIsUnloading = false
          elseif deltaLevel == 0 then
            self.pipeIsUnloading = false
          end
          if useGrainTank then
            self:setGrainTankFillLevel(fillLevel, fruitType)
          end
          trailer:setFillLevel(trailer.fillLevel + deltaLevel, FruitUtil.fruitTypeToFillType[fruitType])
        end
        if not self.pipeIsUnloading and useGrainTank then
          self.pipeParticleActivated = false
        end
      end
    end
    if self.grainTankFillLevel ~= self.sentGrainTankFillLevel or self.currentGrainTankFruitType ~= self.sentGrainTankFruitType or self.lastValidFruitType ~= self.sentLastValidFruitType then
      self:raiseDirtyFlags(self.combineDirtyFlag)
      self.sentGrainTankFillLevel = self.grainTankFillLevel
      self.sentGrainTankFruitType = self.currentGrainTankFruitType
      self.sentLastValidFruitType = self.lastValidFruitType
    end
    if self.pipeParticleActivated ~= self.sentPipeParticleActivated or self.pipeIsUnloading ~= self.sentPipeIsUnloading then
      g_server:broadcastEvent(CombinePipeParticleActivatedEvent:new(self, self.pipeParticleActivated, self.pipeIsUnloading), nil, nil, self)
      self.sentPipeParticleActivated = self.pipeParticleActivated
      self.sentPipeIsUnloading = self.pipeIsUnloading
    end
    if self.chopperPSenabled ~= self.sentChopperPSenabled or self.chopperPSenabled and self.chopperPSFruitType ~= self.sentChopperPSFruitType then
      g_server:broadcastEvent(CombineSetChopperEnableEvent:new(self, self.chopperPSenabled, self.chopperPSFruitType), true, nil, self)
      self.sentChopperPSFruitType = self.chopperPSFruitType
      self.sentChopperPSenabled = self.chopperPSenabled
    end
    if self.strawPSenabled ~= self.sentStrawPSenabled or self.strawPSenabled and self.strawPSFruitType ~= self.sentStrawPSFruitType then
      g_server:broadcastEvent(CombineSetStrawEnableEvent:new(self, self.strawPSenabled, self.strawPSFruitType), true, nil, self)
      self.sentStrawPSFruitType = self.strawPSFruitType
      self.sentStrawPSenabled = self.strawPSenabled
    end
    if self.chopperDisableTime ~= nil and self.chopperDisableTime <= self.time then
      self.chopperPSenabled = false
      self.chopperDisableTime = nil
    end
    if self.strawDisableTime ~= nil and self.strawDisableTime <= self.time then
      self.strawPSenabled = false
      self.strawDisableTime = nil
      self.strawEmitState = false
    end
  end
  if self.pipeParticleActivated then
    self.pipeParticleDeactivateTime = self.time + 100
    local currentPipeParticleSystem = self.pipeParticleSystems[self.currentGrainTankFruitType]
    if currentPipeParticleSystem == nil then
      currentPipeParticleSystem = self.defaultPipeParticleSystem
    end
    if currentPipeParticleSystem ~= self.currentPipeParticleSystem and self.currentPipeParticleSystem ~= nil then
      Utils.setEmittingState(self.currentPipeParticleSystem, false)
    end
    self.currentPipeParticleSystem = currentPipeParticleSystem
    Utils.setEmittingState(self.currentPipeParticleSystem, true)
  elseif self.pipeParticleDeactivateTime <= self.time and self.currentPipeParticleSystem ~= nil then
    Utils.setEmittingState(self.currentPipeParticleSystem, false)
    self.currentPipeParticleSystem = nil
  end
end
function Combine:draw()
  if self.isClient then
    local percent = 0
    if 0 < self.grainTankCapacity then
      percent = self.grainTankFillLevel / self.grainTankCapacity * 100
      if self.currentPipeState == 2 and not self.pipeParticleActivated and 0 < self.grainTankFillLevel then
        g_currentMission:addExtraPrintText(g_i18n:getText("Move_the_pipe_over_a_trailer"))
      elseif self.grainTankFillLevel == self.grainTankCapacity then
        g_currentMission:addExtraPrintText(g_i18n:getText("Dump_corn_to_continue_threshing"))
      end
    end
    if self.drawFillLevel then
      self:drawGrainLevel(self.grainTankFillLevel, self.grainTankCapacity, 95)
    else
      self:drawGrainLevel(0, 0, 101)
    end
    if 0 < self.numAttachedCutters then
      if self.isThreshing then
        g_currentMission:addHelpButtonText(g_i18n:getText("Turn_off_cutter"), InputBinding.ACTIVATE_THRESHING)
      else
        g_currentMission:addHelpButtonText(g_i18n:getText("Turn_on_cutter"), InputBinding.ACTIVATE_THRESHING)
      end
    end
    if self.numPipeStates == 2 then
      if self.targetPipeState == 2 then
        g_currentMission:addHelpButtonText(g_i18n:getText("Pipe_in"), InputBinding.EMPTY_GRAIN)
      elseif 80 < percent then
        g_currentMission:addHelpButtonText(g_i18n:getText("Dump_corn"), InputBinding.EMPTY_GRAIN)
      end
    end
    if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      g_currentMission:setFruitOverlayFruitType(self.currentGrainTankFruitType)
    end
    local printRainWarning = false
    local printSpeedLevelWarning = false
    local speedLevelStr, speedLevelKeyStr
    local speedLevel = 10
    for _, implement in pairs(self.attachedCutters) do
      local cutter = implement.object
      printRainWarning = printRainWarning or cutter.printRainWarning
      if 2 < math.abs(cutter.speedViolationTimer - cutter.speedViolationMaxTime) then
        printSpeedLevelWarning = true
        if Cutter.getUseLowSpeedLimit(cutter) then
          if 1 < speedLevel then
            speedLevel = 1
            speedLevelStr = "1"
            speedLevelKeyStr = InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL1)
          end
        elseif 2 < speedLevel then
          speedLevel = 2
          speedLevelStr = "2"
          speedLevelKeyStr = InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)
        end
      end
    end
    if printRainWarning then
      g_currentMission:addWarning(g_i18n:getText("Dont_do_threshing_during_rain_or_hail"), 0.018, 0.033)
    end
    if printSpeedLevelWarning then
      g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), speedLevelStr, speedLevelKeyStr), 0.092, 0.048)
    end
  end
end
function Combine:onEnter(isControlling)
end
function Combine:onLeave()
  if self.deactivateOnLeave then
    Combine.onDeactivate(self)
  else
    Combine.onDeactivateSounds(self)
  end
end
function Combine:onDeactivate()
  self:stopThreshing()
  for k, v in pairs(self.chopperParticleSystems) do
    Utils.setEmittingState(v, false)
  end
  for k, v in pairs(self.strawParticleSystems) do
    Utils.setEmittingState(v, false)
  end
  self.chopperEnableTime = nil
  self.chopperDisableTime = nil
  self.strawEnableTime = nil
  self.strawDisableTime = nil
  self.strawEmitState = false
  Combine.onDeactivateSounds(self)
end
function Combine:onDeactivateSounds()
  if self.pipeSound ~= nil and self.pipeSoundEnabled then
    stopSample(self.pipeSound)
    self.pipeSoundEnabled = false
  end
  if self.threshingSoundActive then
    stopSample(self.threshingSound)
    self.threshingSoundActive = false
  end
end
function Combine:attachImplement(implement)
  local object = implement.object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER then
    self.attachedCutters[object] = implement
    self.numAttachedCutters = self.numAttachedCutters + 1
    object:setFruitType(self.currentGrainTankFruitType)
  end
end
function Combine:detachImplement(implementIndex)
  local object = self.attachedImplements[implementIndex].object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER then
    self.numAttachedCutters = self.numAttachedCutters - 1
    if self.numAttachedCutters == 0 then
      self:stopThreshing()
    end
    self.attachedCutters[object] = nil
  end
end
function Combine:allowGrainTankFruitType(fruitType)
  local allowed = false
  if self.grainTankFruitTypes[fruitType] then
    if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      if self.currentGrainTankFruitType ~= fruitType then
        if self.grainTankCapacity == 0 or self.grainTankFillLevel / self.grainTankCapacity <= self.minThreshold then
          allowed = true
        end
      else
        allowed = true
      end
    else
      allowed = true
    end
  end
  return allowed
end
function Combine:emptyGrainTankIfLowFillLevel()
  if self.grainTankCapacity == 0 or self.grainTankFillLevel / self.grainTankCapacity <= self.minThreshold then
    self.grainTankFillLevel = 0
  end
end
function Combine:setGrainTankFillLevel(fillLevel, fruitType)
  if not self:allowGrainTankFruitType(fruitType) then
    return
  end
  self.grainTankFillLevel = Utils.clamp(fillLevel, 0, self.grainTankCapacity)
  self.currentGrainTankFruitType = fruitType
  if self.isClient then
    if self.currentGrainTankPlane ~= nil then
      for _, node in ipairs(self.currentGrainTankPlane.nodes) do
        setVisibility(node.node, false)
      end
      self.currentGrainTankPlane = nil
    end
    if self.grainTankPlanes ~= nil and self.defaultGrainTankPlane ~= nil and fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      local fruitTypeName = FruitUtil.fruitIndexToDesc[fruitType].name
      local grainPlane = self.grainTankPlanes[fruitTypeName]
      if grainPlane == nil then
        grainPlane = self.defaultGrainTankPlane
      end
      local t = self.grainTankFillLevel / self.grainTankCapacity
      for _, node in ipairs(grainPlane.nodes) do
        local x, y, z, rx, ry, rz, sx, sy, sz = node.animCurve:get(t)
        setTranslation(node.node, x, y, z)
        setRotation(node.node, rx, ry, rz)
        setScale(node.node, sx, sy, sz)
        setVisibility(node.node, self.grainTankFillLevel > 0)
      end
      self.currentGrainTankPlane = grainPlane
    end
  end
  if self.grainTankFillLevel <= 0 then
    for cutter, implement in pairs(self.attachedCutters) do
      cutter:resetFruitType()
    end
    self.currentGrainTankFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  else
    for cutter, implement in pairs(self.attachedCutters) do
      cutter:setFruitType(self.currentGrainTankFruitType)
    end
  end
end
function Combine:startThreshing()
  if not self.isThreshing and self.numAttachedCutters > 0 then
    self.chopperActivated = self.defaultChopperState
    self.isThreshing = true
    for cutter, implement in pairs(self.attachedCutters) do
      self:setJointMoveDown(implement.jointDescIndex, true, true)
      cutter:setReelSpeedScale(1)
      cutter:onStartReel()
    end
    if self.isClient then
      local threshingSoundOffset = 0
      if self.threshingStartSound ~= nil then
        if self:getIsActiveForSound() then
          setSamplePitch(self.threshingStartSound, self.threshingStartSoundPitchOffset)
          playSample(self.threshingStartSound, 1, 1, 0)
        end
        threshingSoundOffset = getSampleDuration(self.threshingStartSound)
      end
      self.playThreshingSoundTime = self.time + threshingSoundOffset
    end
  end
end
function Combine:stopThreshing()
  if self.isThreshing then
    if self.isClient then
      if self.threshingSound ~= nil then
        stopSample(self.threshingSound)
      end
      if self.threshingStopSound ~= nil and self.threshingSoundActive and self:getIsActiveForSound() then
        setSamplePitch(self.threshingStopSound, self.threshingStopSoundPitchOffset)
        playSample(self.threshingStopSound, 1, 1, 0)
        self.threshingSoundActive = false
      end
    end
    self.chopperActivated = false
    self.isThreshing = false
    for cutter, implement in pairs(self.attachedCutters) do
      self:setJointMoveDown(implement.jointDescIndex, false, true)
      cutter:onStopReel()
    end
  end
end
function Combine:setPipeOpening(pipeOpening, noEventSend)
  if pipeOpening then
    self:setPipeState(2, noEventSend)
  else
    self:setPipeState(1, noEventSend)
  end
end
function Combine:setPipeState(pipeState, noEventSend)
  if self.targetPipeState ~= pipeState then
    if noEventSend == nil or noEventSend == false then
      if g_server ~= nil then
        g_server:broadcastEvent(CombineSetPipeStateEvent:new(self, pipeState))
      else
        g_client:getServerConnection():sendEvent(CombineSetPipeStateEvent:new(self, pipeState), nil, nil, self)
      end
    end
    self.targetPipeState = pipeState
    self.currentPipeState = 0
  end
end
function Combine:setIsThreshing(isThreshing, noEventSend)
  if isThreshing ~= self.isThreshing then
    if noEventSend == nil or noEventSend == false then
      if g_server ~= nil then
        g_server:broadcastEvent(CombineSetThreshingEnabledEvent:new(self, isThreshing), nil, nil, self)
      else
        g_client:getServerConnection():sendEvent(CombineSetThreshingEnabledEvent:new(self, isThreshing))
      end
    end
    if isThreshing then
      self:startThreshing()
    else
      self:stopThreshing()
    end
  end
end
function Combine:getIshreshingAllowed(earlyWarning)
  if self.allowThreshingDuringRain then
    return true
  end
  if earlyWarning ~= nil and earlyWarning == true then
    if g_currentMission.environment.lastRainScale <= 0.02 and g_currentMission.environment.timeSinceLastRain > 20 then
      return true
    end
  elseif g_currentMission.environment.lastRainScale <= 0.1 and g_currentMission.environment.timeSinceLastRain > 20 then
    return true
  end
  return false
end
function Combine:getFruitTypeAndFillLevelToUnload()
  local fillLevel = self.grainTankFillLevel
  local fruitType = self.currentGrainTankFruitType
  local useGrainTank = self.grainTankCapacity > 0
  if not useGrainTank then
    fillLevel = self.grainTankTempFillLevel
    fruitType = self.grainTankTempFruitType
  end
  return fruitType, fillLevel, useGrainTank
end
function Combine:findAutoAimTrailerToUnload(fruitType)
  local trailer, smallestTrailerId
  if self.trailersInRange ~= nil then
    for trailerInRange, pipeStage in pairs(self.trailersInRange) do
      if trailerInRange:allowFillType(FruitUtil.fruitTypeToFillType[fruitType]) and trailerInRange.allowFillFromAir and trailerInRange.fillLevel < trailerInRange.capacity then
        local id = networkGetObjectId(trailerInRange)
        if trailer == nil or smallestTrailerId > id then
          trailer = trailerInRange
          smallestTrailerId = id
        end
      end
    end
  end
  return trailer
end
function Combine:findTrailerToUnload(fruitType)
  local x, y, z = getWorldTranslation(self.pipeRaycastNode)
  local dx, dy, dz = localDirectionToWorld(self.pipeRaycastNode, 0, -1, 0)
  self.trailerFound = 0
  raycastAll(x, y, z, dx, dy, dz, "findTrailerRaycastCallback", self.pipeRaycastDistance, self)
  local trailer = g_currentMission.nodeToVehicle[self.trailerFound]
  if not (trailer ~= nil and trailer:allowFillType(FruitUtil.fruitTypeToFillType[fruitType]) and trailer.allowFillFromAir) or trailer.fillLevel >= trailer.capacity then
    return nil
  end
  return trailer
end
function Combine:findTrailerRaycastCallback(transformId, x, y, z, distance)
  local vehicle = g_currentMission.nodeToVehicle[transformId]
  if vehicle ~= nil and vehicle.exactFillRootNode == transformId then
    self.trailerFound = transformId
    return false
  end
  return true
end
