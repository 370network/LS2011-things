source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/BalerSetIsUnloadingBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/BalerSetBaleTimeEvent.lua")
source("dataS/scripts/vehicles/specializations/BalerCreateBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/BalerAreaEvent.lua")
Baler = {}
Baler.UNLOADING_CLOSED = 1
Baler.UNLOADING_OPENING = 2
Baler.UNLOADING_OPEN = 3
Baler.UNLOADING_CLOSING = 4
function Baler.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Fillable, specializations)
end
function Baler:load(xmlFile)
  self.setIsTurnedOn = SpecializationUtil.callSpecializationsFunction("setIsTurnedOn")
  self.getTimeFromLevel = Baler.getTimeFromLevel
  self.moveBales = SpecializationUtil.callSpecializationsFunction("moveBales")
  self.moveBale = SpecializationUtil.callSpecializationsFunction("moveBale")
  self.allowFillType = Baler.allowFillType
  self.allowPickingUp = Baler.allowPickingUp
  self.setIsUnloadingBale = Baler.setIsUnloadingBale
  self.fillScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillScale#value"), 1)
  local firstBaleMarker = getXMLFloat(xmlFile, "vehicle.baleAnimation#firstBaleMarker")
  if firstBaleMarker ~= nil then
    local baleAnimCurve = AnimCurve:new(linearInterpolatorN)
    local keyI = 0
    while true do
      local key = string.format("vehicle.baleAnimation.key(%d)", keyI)
      local t = getXMLFloat(xmlFile, key .. "#time")
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#pos"))
      if x == nil or y == nil or z == nil then
        break
      end
      local rx, ry, rz = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rot"))
      rx = math.rad(Utils.getNoNil(rx, 0))
      ry = math.rad(Utils.getNoNil(ry, 0))
      rz = math.rad(Utils.getNoNil(rz, 0))
      baleAnimCurve:addKeyframe({
        v = {
          x,
          y,
          z,
          rx,
          ry,
          rz
        },
        time = t
      })
      keyI = keyI + 1
    end
    if 0 < keyI then
      self.baleAnimCurve = baleAnimCurve
      self.firstBaleMarker = firstBaleMarker
    end
  end
  self.baleAnimRoot = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.baleAnimation#node")), self.components[1].node)
  if self.firstBaleMarker == nil then
    local unloadAnimationName = getXMLString(xmlFile, "vehicle.baleAnimation#unloadAnimationName")
    local closeAnimationName = getXMLString(xmlFile, "vehicle.baleAnimation#closeAnimationName")
    local unloadAnimationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.baleAnimation#unloadAnimationSpeed"), 1)
    local closeAnimationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.baleAnimation#closeAnimationSpeed"), 1)
    if unloadAnimationName ~= nil and closeAnimationName ~= nil then
      if self.playAnimation ~= nil and self.animations ~= nil then
        if self.animations[unloadAnimationName] ~= nil and self.animations[closeAnimationName] ~= nil then
          self.baleUnloadAnimationName = unloadAnimationName
          self.baleUnloadAnimationSpeed = unloadAnimationSpeed
          self.baleCloseAnimationName = closeAnimationName
          self.baleCloseAnimationSpeed = closeAnimationSpeed
          self.baleDropAnimTime = getXMLFloat(xmlFile, "vehicle.baleAnimation#baleDropAnimTime")
          if self.baleDropAnimTime == nil then
            self.baleDropAnimTime = self:getAnimationDuration(self.baleUnloadAnimationName)
          else
            self.baleDropAnimTime = self.baleDropAnimTime * 1000
          end
        else
          print("Error: Failed to find unload animations '" .. unloadAnimationName .. "' and '" .. closeAnimationName .. "' in '" .. self.configFileName .. "'.")
        end
      else
        print("Error: There is an unload animation in '" .. self.configFileName .. "' but it is not a AnimatedVehicle. Change to a vehicle type which has the AnimatedVehicle specialization.")
      end
    end
  end
  self.baleTypes = {}
  local i = 0
  while true do
    local key = string.format("vehicle.baleTypes.baleType(%d)", i)
    local t = getXMLString(xmlFile, key .. "#fruitType")
    local filename = getXMLString(xmlFile, key .. "#filename")
    if t == nil or filename == nil then
      break
    end
    local entry = {}
    entry.filename = filename
    local desc = FruitUtil.fruitTypes[t]
    if desc ~= nil then
      self.baleTypes[desc.index] = entry
      if self.defaultBaleType == nil then
        self.defaultBaleType = entry
      end
    end
    i = i + 1
  end
  if self.defaultBaleType == nil then
    self.baleTypes = nil
  end
  local balerSound = getXMLString(xmlFile, "vehicle.balerSound#file")
  if balerSound ~= nil and balerSound ~= "" then
    balerSound = Utils.getFilename(balerSound, self.baseDirectory)
    self.balerSound = createSample("balerSound")
    self.balerSoundEnabled = false
    loadSample(self.balerSound, balerSound, false)
    self.balerSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerSound#pitchOffset"), 1)
    self.balerSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerSound#volume"), 1)
  end
  local balerAlarm = getXMLString(xmlFile, "vehicle.balerAlarm#file")
  if balerAlarm ~= nil and balerAlarm ~= "" then
    balerAlarm = Utils.getFilename(balerAlarm, self.baseDirectory)
    self.balerAlarm = createSample("balerAlarm")
    self.balerAlarmEnabled = false
    loadSample(self.balerAlarm, balerAlarm, false)
    self.balerAlarmPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerAlarm#pitchOffset"), 1)
    self.balerAlarmVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerAlarm#volume"), 1)
  end
  local balerBaleEject = getXMLString(xmlFile, "vehicle.balerBaleEject#file")
  if balerBaleEject ~= nil and balerBaleEject ~= "" then
    balerBaleEject = Utils.getFilename(balerBaleEject, self.baseDirectory)
    self.balerBaleEject = createSample("balerBaleEject")
    self.balerBaleEjectEnabled = false
    loadSample(self.balerBaleEject, balerBaleEject, false)
    self.balerBaleEjectPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerBaleEject#pitchOffset"), 1)
    self.balerBaleEjectVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerBaleEject#volume"), 1)
  end
  local balerDoor = getXMLString(xmlFile, "vehicle.balerDoor#file")
  if balerDoor ~= nil and balerDoor ~= "" then
    balerDoor = Utils.getFilename(balerDoor, self.baseDirectory)
    self.balerDoor = createSample("balerDoor")
    self.balerDoorEnabled = false
    loadSample(self.balerDoor, balerDoor, false)
    self.balerDoorPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerDoor#pitchOffset"), 1)
    self.balerDoorVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerDoor#volume"), 1)
  end
  local balerKnotCleaning = getXMLString(xmlFile, "vehicle.balerKnotCleaning#file")
  if balerKnotCleaning ~= nil and balerKnotCleaning ~= "" then
    balerKnotCleaning = Utils.getFilename(balerKnotCleaning, self.baseDirectory)
    self.balerKnotCleaning = createSample("balerKnotCleaning")
    self.balerKnotCleaningEnabled = false
    self.balerKnotCleaningTime = 100000
    loadSample(self.balerKnotCleaning, balerKnotCleaning, false)
    self.balerKnotCleaningPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerKnotCleaning#pitchOffset"), 1)
    self.balerKnotCleaningVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerKnotCleaning#volume"), 1)
  end
  self.balerUVScrollParts = {}
  local i = 0
  while true do
    local key = string.format("vehicle.balerUVScrollParts.balerUVScrollPart(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    local speed = Utils.getVectorNFromString(getXMLString(xmlFile, key .. "#speed"), 2)
    if node ~= nil and speed then
      table.insert(self.balerUVScrollParts, {node = node, speed = speed})
    end
    i = i + 1
  end
  self.pickupAnimationName = Utils.getNoNil(getXMLString(xmlFile, "vehicle.pickupAnimation#name"), "")
  if self.playAnimation == nil or self.getIsAnimationPlaying == nil then
    self.pickupAnimationName = ""
  end
  self.pickupAnimationLowerSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pickupAnimation#lowerSpeed"), 1)
  self.pickupAnimationLiftSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pickupAnimation#liftSpeed"), -self.pickupAnimationLowerSpeed)
  self.baleLastPositionTime = 0
  self.balerUnloadingState = Baler.UNLOADING_CLOSED
  self.bales = {}
  self.wasToFast = false
  self.isTurnedOn = false
end
function Baler:delete()
  if self.balerSound ~= nil then
    delete(self.balerSound)
    self.balerSoundEnabled = false
  end
  if self.balerAlarm ~= nil then
    delete(self.balerAlarm)
    self.balerAlarmEnabled = false
  end
  if self.balerBaleEject ~= nil then
    delete(self.balerBaleEject)
    self.balerBaleEjectEnabled = false
  end
  if self.balerDoor ~= nil then
    delete(self.balerDoor)
    self.balerDoorEnabled = false
  end
  if self.balerKnotCleaning ~= nil then
    delete(self.balerKnotCleaning)
    self.balerKnotCleaningEnabled = false
  end
end
function Baler:readStream(streamId, connection)
  local turnedOn = streamReadBool(streamId)
  self:setIsTurnedOn(turnedOn, true)
  local numBales = streamReadInt16(streamId)
  for i = 1, numBales do
    local fruitType = streamReadInt8(streamId)
    Baler.createBale(self, fruitType)
    if self.baleAnimCurve ~= nil then
      local baleTime = streamReadFloat32(streamId)
      Baler.setBaleTime(self, i, baleTime)
    end
  end
end
function Baler:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isTurnedOn)
  streamWriteInt16(streamId, table.getn(self.bales))
  for i = 1, table.getn(self.bales) do
    local bale = self.bales[i]
    streamWriteInt8(streamId, bale.fruitType)
    if self.baleAnimCurve ~= nil then
      streamWriteFloat32(streamId, bale.time)
    end
  end
end
function Baler:readUpdateStream(streamId, timestamp, connection)
end
function Baler:writeUpdateStream(streamId, connection, dirtyMask)
end
function Baler:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local numBales = getXMLInt(xmlFile, key .. "#numBales")
  if numBales ~= nil then
    for i = 1, numBales do
      local baleKey = key .. string.format(".bale(%d)", i - 1)
      local fruitType = getXMLString(xmlFile, baleKey .. "#fruitType")
      local baleTime = getXMLFloat(xmlFile, baleKey .. "#baleTime")
      if fruitType ~= nil and (baleTime ~= nil or self.baleAnimCurve == nil) then
        local fruitTypeDesc = FruitUtil.fruitTypes[fruitType]
        if fruitTypeDesc ~= nil then
          Baler.createBale(self, fruitTypeDesc.index)
          if self.baleAnimCurve ~= nil then
            Baler.setBaleTime(self, table.getn(self.bales), baleTime)
          end
        end
      end
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Baler:getSaveAttributesAndNodes(nodeIdent)
  local attributes = "numBales=\"" .. table.getn(self.bales) .. "\""
  local nodes = ""
  local baleNum = 0
  for i = 1, table.getn(self.bales) do
    local bale = self.bales[i]
    local fruitType = "unknown"
    if bale.fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      fruitType = FruitUtil.fruitIndexToDesc[bale.fruitType].name
    end
    if 0 < baleNum then
      nodes = nodes .. "\n"
    end
    nodes = nodes .. nodeIdent .. "<bale fruitType=\"" .. fruitType .. "\""
    if self.baleAnimCurve ~= nil then
      nodes = nodes .. " baleTime=\"" .. bale.time .. "\""
    end
    nodes = nodes .. " />"
    baleNum = baleNum + 1
  end
  return attributes, nodes
end
function Baler:mouseEvent(posX, posY, isDown, isUp, button)
end
function Baler:keyEvent(unicode, sym, modifier, isDown)
end
function Baler:update(dt)
  if self:getIsActiveForInput() then
    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
      self:setIsTurnedOn(not self.isTurnedOn)
    end
    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) and self.baleUnloadAnimationName ~= nil then
      if self.balerUnloadingState == Baler.UNLOADING_CLOSED then
        if table.getn(self.bales) > 0 then
          self:setIsUnloadingBale(true)
        end
      elseif self.balerUnloadingState == Baler.UNLOADING_OPEN then
        self:setIsUnloadingBale(false)
      end
    end
  end
end
function Baler:updateTick(dt)
  self.wasToFast = false
  if self:getIsActive() then
    if self.isTurnedOn then
      local toFast = self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 30
      if not toFast and self.isServer and self:allowPickingUp() then
        local totalArea = 0
        local usedFruitType = FruitUtil.FRUITTYPE_UNKNOWN
        local fruitTypes = {}
        for fillType, enabled in pairs(self.fillTypes) do
          if enabled then
            local fruitType = FruitUtil.fillTypeToFruitType[fillType]
            if fruitType ~= nil and fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
              table.insert(fruitTypes, fruitType)
            end
          end
        end
        if 0 < table.getn(fruitTypes) then
          local cuttingAreasSend = {}
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
            totalArea, usedFruitType = BalerAreaEvent.runLocally(cuttingAreasSend, fruitTypes)
            if 0 < totalArea and 0 < table.getn(cuttingAreasSend) then
              g_server:broadcastEvent(BalerAreaEvent:new(cuttingAreasSend, fruitTypes))
            end
          end
        end
        if 0 < totalArea then
          local literPerPixel = g_currentMission:getFruitPixelsToSqm() * g_strawLitersPerSqm
          local deltaLevel = totalArea * literPerPixel * self.fillScale
          if self.baleUnloadAnimationName == nil then
            local deltaTime = self:getTimeFromLevel(deltaLevel)
            self:moveBales(deltaTime)
          end
          local usedFillType = FruitUtil.fruitTypeToFillType[usedFruitType]
          local oldFillLevel = self.fillLevel
          self:setFillLevel(self.fillLevel + deltaLevel, usedFillType)
          if self.fillLevel == self.capacity and self.baleTypes ~= nil then
            if self.baleAnimCurve ~= nil then
              local restDeltaFillLevel = deltaLevel - (self.fillLevel - oldFillLevel)
              self:setFillLevel(restDeltaFillLevel, usedFillType)
              Baler.createBale(self, usedFruitType)
              local numBales = table.getn(self.bales)
              local bale = self.bales[numBales]
              self:moveBale(numBales, self:getTimeFromLevel(restDeltaFillLevel), true)
              g_server:broadcastEvent(BalerCreateBaleEvent:new(self, usedFruitType, bale.time), nil, nil, self)
            elseif self.baleUnloadAnimationName ~= nil then
              Baler.createBale(self, usedFruitType)
              g_server:broadcastEvent(BalerCreateBaleEvent:new(self, usedFruitType, 0), nil, nil, self)
            end
          end
        end
      end
      if self.isClient then
        if self.balerKnotCleaning ~= nil and self.balerKnotCleaningTime <= self.time and self:getIsActiveForSound() then
          playSample(self.balerKnotCleaning, 1, self.balerKnotCleaningVolume, 0)
          setSamplePitch(self.balerKnotCleaning, self.balerKnotCleaningPitchOffset)
          self.balerKnotCleaningTime = self.time + 120000
          self.balerKnotCleaningEnabled = true
        end
        if not self.balerSoundEnabled and self:getIsActiveForSound() then
          setSamplePitch(self.balerSound, self.balerSoundPitchOffset)
          playSample(self.balerSound, 0, self.balerSoundVolume, 0)
          self.balerSoundEnabled = true
        end
      end
      self.wasToFast = toFast
    end
    if self.isClient and not self.isTurnedOn and self.balerSoundEnabled then
      stopSample(self.balerSound)
      self.balerSoundEnabled = false
    end
    if self.isTurnedOn and self.fillLevel > self.capacity * 0.93 and self.fillLevel < self.capacity then
      if not self.balerAlarmEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.balerAlarm, self.balerAlarmPitchOffset)
        playSample(self.balerAlarm, 0, self.balerAlarmVolume, 0)
        self.balerAlarmEnabled = true
      end
    elseif self.balerAlarmEnabled then
      stopSample(self.balerAlarm)
      self.balerAlarmEnabled = false
    end
    if self.balerUnloadingState == Baler.UNLOADING_OPENING then
      if not self.balerBaleEjectEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.balerBaleEject, self.balerBaleEjectPitchOffset)
        playSample(self.balerBaleEject, 1, self.balerBaleEjectVolume, 0)
        self.balerBaleEjectEnabled = true
      end
      if not self.balerDoorEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.balerDoor, self.balerDoorPitchOffset)
        playSample(self.balerDoor, 1, self.balerDoorVolume, 0)
        self.balerDoorEnabled = true
      end
      local isPlaying = self:getIsAnimationPlaying(self.baleUnloadAnimationName)
      local animTime = self:getRealAnimationTime(self.baleUnloadAnimationName)
      if not isPlaying or animTime >= self.baleDropAnimTime then
        if 0 < table.getn(self.bales) then
          Baler.dropBale(self, 1)
          if self.isServer then
            self:setFillLevel(0, self.currentFillType)
          end
        end
        if not isPlaying then
          self.balerUnloadingState = Baler.UNLOADING_OPEN
          if self.balerBaleEjectEnabled then
            stopSample(self.balerBaleEject)
            self.balerBaleEjectEnabled = false
          end
          if self.balerDoorEnabled then
            stopSample(self.balerDoor)
            self.balerDoorEnabled = false
          end
        end
      end
    elseif self.balerUnloadingState == Baler.UNLOADING_CLOSING then
      if not self.balerDoorEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.balerDoor, self.balerDoorPitchOffset)
        playSample(self.balerDoor, 1, self.balerDoorVolume, 0)
        self.balerDoorEnabled = true
      end
      if not self:getIsAnimationPlaying(self.baleCloseAnimationName) then
        self.balerUnloadingState = Baler.UNLOADING_CLOSED
      end
      if not self.balerDoorEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.balerDoor, self.balerDoorPitchOffset)
        playSample(self.balerDoor, 1, self.balerDoorVolume, 0)
        self.balerDoorEnabled = true
      end
    elseif self.balerUnloadingState == Baler.UNLOADING_CLOSING and self.balerDoorEnabled then
      stopSample(self.balerDoor)
      self.balerDoorEnabled = false
    end
    if self.isServer and self.time > self.baleLastPositionTime + 100 then
      for i = 1, table.getn(self.bales) do
        local bale = self.bales[i]
        bale.lastX, bale.lastY, bale.lastZ = getWorldTranslation(bale.id)
      end
      self.baleLastPositionTime = self.time
    end
  end
end
function Baler:draw()
  if self.isClient then
    if self.wasToFast then
      g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
    end
    if self.isTurnedOn then
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    else
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    end
    if self.baleUnloadAnimationName ~= nil then
      if self.balerUnloadingState == Baler.UNLOADING_CLOSED then
        if table.getn(self.bales) > 0 then
          g_currentMission:addHelpButtonText(g_i18n:getText("baler_unload"), InputBinding.IMPLEMENT_EXTRA2)
        end
      elseif self.balerUnloadingState == Baler.UNLOADING_OPEN then
        g_currentMission:addHelpButtonText(g_i18n:getText("baler_unload_stop"), InputBinding.IMPLEMENT_EXTRA2)
      end
    end
  end
end
function Baler:onDetach()
  if self.deactivateOnDetach then
    Baler.onDeactivate(self)
  else
    Baler.onDeactivateSounds(self)
  end
end
function Baler:onLeave()
  if self.deactivateOnLeave then
    Baler.onDeactivate(self)
  else
    Baler.onDeactivateSounds(self)
  end
end
function Baler:onDeactivate()
  for _, part in pairs(self.balerUVScrollParts) do
    setShaderParameter(part.node, "uvScrollSpeed", 0, 0, 0, 0, false)
  end
  self.wasToFast = false
  self.isTurnedOn = false
  Baler.onDeactivateSounds(self)
end
function Baler:onDeactivateSounds()
  if self.balerSoundEnabled then
    stopSample(self.balerSound)
    self.balerSoundEnabled = false
  end
  if self.balerAlarmEnabled then
    stopSample(self.balerAlarm)
    self.balerAlarmEnabled = false
  end
  if self.balerBaleEjectEnabled then
    stopSample(self.balerBaleEject)
    self.balerBaleEjectEnabled = false
  end
  if self.balerDoorEnabled then
    stopSample(self.balerDoor)
    self.balerDoorEnabled = false
  end
  if self.balerKnotCleaningEnabled then
    stopSample(self.balerKnotCleaning)
    self.balerKnotCleaningEnabled = false
  end
end
function Baler:setIsTurnedOn(isTurnedOn, noEventSend)
  SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
  self.isTurnedOn = isTurnedOn
  for _, part in pairs(self.balerUVScrollParts) do
    if self.isTurnedOn then
      setShaderParameter(part.node, "uvScrollSpeed", part.speed[1], part.speed[2], 0, 0, false)
    else
      setShaderParameter(part.node, "uvScrollSpeed", 0, 0, 0, 0, false)
    end
  end
  if self.pickupAnimationName ~= "" then
    local animTime
    if self:getIsAnimationPlaying(self.pickupAnimationName) then
      animTime = self:getAnimationTime(self.pickupAnimationName)
    end
    if isTurnedOn then
      self:playAnimation(self.pickupAnimationName, self.pickupAnimationLowerSpeed, animTime, true)
    else
      self:playAnimation(self.pickupAnimationName, self.pickupAnimationLiftSpeed, animTime, true)
    end
  end
end
function Baler:setIsUnloadingBale(isUnloadingBale, noEventSend)
  if self.baleUnloadAnimationName ~= nil then
    if isUnloadingBale then
      if self.balerUnloadingState ~= Baler.UNLOADING_OPENING then
        BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
        self.balerUnloadingState = Baler.UNLOADING_OPENING
        self:playAnimation(self.baleUnloadAnimationName, self.baleUnloadAnimationSpeed, nil, true)
      end
    elseif self.balerUnloadingState ~= Baler.UNLOADING_CLOSING then
      BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
      self.balerUnloadingState = Baler.UNLOADING_CLOSING
      self:playAnimation(self.baleCloseAnimationName, self.baleCloseAnimationSpeed, nil, true)
    end
  end
end
function Baler:getTimeFromLevel(level)
  if self.firstBaleMarker ~= nil then
    return level / self.capacity * self.firstBaleMarker
  end
  return 0
end
function Baler:moveBales(dt)
  for i = table.getn(self.bales), 1, -1 do
    self:moveBale(i, dt)
  end
end
function Baler:moveBale(i, dt, noEventSend)
  local bale = self.bales[i]
  Baler.setBaleTime(self, i, bale.time + dt, noEventSend)
end
function Baler:setBaleTime(i, baleTime, noEventSend)
  if self.baleAnimCurve ~= nil then
    local bale = self.bales[i]
    bale.time = baleTime
    local v = self.baleAnimCurve:get(bale.time)
    setTranslation(bale.id, v[1], v[2], v[3])
    setRotation(bale.id, v[4], v[5], v[6])
    if bale.time >= 1 then
      Baler.dropBale(self, i)
    end
    if self.isServer and (noEventSend == nil or not noEventSend) then
      g_server:broadcastEvent(BalerSetBaleTimeEvent:new(self, i, bale.time), nil, nil, self)
    end
  end
end
function Baler:allowFillType(fillType)
  return self.fillTypes[fillType] == true
end
function Baler:allowPickingUp()
  if self.baleUnloadAnimationName == nil then
    return true
  end
  return table.getn(self.bales) == 0 and self.balerUnloadingState == Baler.UNLOADING_CLOSED
end
function Baler:createBale(usedFruitType)
  local baleType = self.baleTypes[usedFruitType]
  if baleType == nil then
    baleType = self.defaultBaleType
  end
  local baleRoot = Utils.loadSharedI3DFile(baleType.filename, self.baseDirectory)
  local baleId = getChildAt(baleRoot, 0)
  setRigidBodyType(baleId, "None")
  link(self.baleAnimRoot, baleId)
  delete(baleRoot)
  local bale = {}
  bale.id = baleId
  bale.time = 0
  bale.fruitType = usedFruitType
  bale.filename = Utils.getFilename(baleType.filename, self.baseDirectory)
  bale.lastX, bale.lastY, bale.lastZ = getWorldTranslation(bale.id)
  table.insert(self.bales, bale)
  local i = table.getn(self.bales)
end
function Baler:dropBale(baleIndex)
  local bale = self.bales[baleIndex]
  local deltaRealTime = (self.time - self.baleLastPositionTime) / 1000
  local x, y, z = getWorldTranslation(bale.id)
  local rx, ry, rz = getWorldRotation(bale.id)
  if self.isServer then
    local baleObject = Bale:new(self.isServer, self.isClient)
    baleObject:load(bale.filename, x, y, z, rx, ry, rz)
    baleObject:register()
    local lx, ly, lz = bale.lastX, bale.lastY, bale.lastZ
    setLinearVelocity(baleObject.nodeId, (x - lx) / deltaRealTime, (y - ly) / deltaRealTime, (z - lz) / deltaRealTime)
  end
  delete(bale.id)
  table.remove(self.bales, baleIndex)
  if g_currentMission.baleCount ~= nil then
    g_currentMission.baleCount = g_currentMission.baleCount + 1
  end
end
