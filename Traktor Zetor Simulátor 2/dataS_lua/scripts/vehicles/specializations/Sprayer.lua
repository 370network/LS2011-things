source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/SprayerAreaEvent.lua")
source("dataS/scripts/vehicles/specializations/SprayerSetIsFillingEvent.lua")
Sprayer = {}
Sprayer.SPRAYTYPE_UNKNOWN = 0
Sprayer.NUM_SPRAYTYPES = 0
Sprayer.sprayTypes = {}
Sprayer.sprayTypeIndexToDesc = {}
Sprayer.sprayTypeToFillType = {}
Sprayer.fillTypeToSprayType = {}
function Sprayer.registerSprayType(name, pricePerLiter, litersPerSqmPerSecond, hudOverlayFilename)
  local key = "SPRAYTYPE_" .. string.upper(name)
  if Sprayer[key] == nil then
    Sprayer.NUM_SPRAYTYPES = Sprayer.NUM_SPRAYTYPES + 1
    Sprayer[key] = Sprayer.NUM_SPRAYTYPES
    local desc = {
      name = name,
      index = Sprayer.NUM_SPRAYTYPES
    }
    desc.pricePerLiter = pricePerLiter
    desc.litersPerSqmPerSecond = litersPerSqmPerSecond
    desc.hudOverlayFilename = hudOverlayFilename
    Sprayer.sprayTypes[name] = desc
    Sprayer.sprayTypeIndexToDesc[Sprayer.NUM_SPRAYTYPES] = desc
    local fillType = Fillable.registerFillType(name)
    Sprayer.sprayTypeToFillType[Sprayer.NUM_SPRAYTYPES] = fillType
    Sprayer.fillTypeToSprayType[fillType] = Sprayer.NUM_SPRAYTYPES
  end
end
Sprayer.registerSprayType("fertilizer", 0.3, 0.5, "")
Sprayer.registerSprayType("manure", 0.01, 0.5, "")
Sprayer.registerSprayType("liquidManure", 0.01, 0.5, "")
function Sprayer.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Fillable, specializations)
end
function Sprayer:load(xmlFile)
  assert(self.setIsTurnedOn == nil, "Sprayer needs to be the first specialization which implements setIsTurnedOn")
  self.setIsTurnedOn = Sprayer.setIsTurnedOn
  self.getIsTurnedOnAllowed = Sprayer.getIsTurnedOnAllowed
  assert(self.setIsSprayerFilling == nil, "Sprayer needs to be the first specialization which implements setIsSprayerFilling")
  self.setIsSprayerFilling = Sprayer.setIsSprayerFilling
  self.addSprayerFillTrigger = Sprayer.addSprayerFillTrigger
  self.removeSprayerFillTrigger = Sprayer.removeSprayerFillTrigger
  self.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillLitersPerSecond"), 500)
  self.isSprayerFilling = false
  self.sprayLitersPerSecond = {}
  local i = 0
  while true do
    local key = string.format("vehicle.sprayUsages.sprayUsage(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local fillType = getXMLString(xmlFile, key .. "#fillType")
    local litersPerSecond = getXMLFloat(xmlFile, key .. "#litersPerSecond")
    if fillType ~= nil and litersPerSecond ~= nil then
      local fillTypeInt = Fillable.fillTypeNameToInt[fillType]
      if fillTypeInt ~= nil then
        self.sprayLitersPerSecond[fillTypeInt] = litersPerSecond
        if self.defaultSprayLitersPerSecond == nil then
          self.defaultSprayLitersPerSecond = litersPerSecond
        end
      else
        print("Warning: Invalid spray usage fill type '" .. fillType .. "' in '" .. self.configFileName .. "'")
      end
    end
    i = i + 1
  end
  if self.defaultSprayLitersPerSecond == nil then
    print("Warning: No spray usage specified for '" .. self.configFileName .. "'. This sprayer will not use any spray.")
    self.defaultSprayLitersPerSecond = 0
  end
  self.sprayValves = {}
  if self.isClient then
    local psFile = getXMLString(xmlFile, "vehicle.sprayParticleSystem#file")
    if psFile ~= nil then
      local i = 0
      while true do
        local baseName = string.format("vehicle.sprayValves.sprayValve(%d)", i)
        local node = getXMLString(xmlFile, baseName .. "#index")
        if node == nil then
          break
        end
        node = Utils.indexToObject(self.components, node)
        if node ~= nil then
          local sprayValve = {}
          sprayValve.particleSystems = {}
          Utils.loadParticleSystem(xmlFile, sprayValve.particleSystems, "vehicle.sprayParticleSystem", node, false, nil, self.baseDirectory)
          table.insert(self.sprayValves, sprayValve)
        end
        i = i + 1
      end
    end
    local spraySound = getXMLString(xmlFile, "vehicle.spraySound#file")
    if spraySound ~= nil and spraySound ~= "" then
      spraySound = Utils.getFilename(spraySound, self.baseDirectory)
      self.spraySound = createSample("spraySound")
      self.spraySoundEnabled = false
      loadSample(self.spraySound, spraySound, false)
      self.spraySoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spraySound#pitchOffset"), 1)
      self.spraySoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spraySound#volume"), 1)
    end
  end
  self.sprayerFillTriggers = {}
  self.sprayerFillActivatable = SprayerFillActivatable:new(self)
  self.isTurnedOn = false
  self.speedViolationMaxTime = 1000
  self.speedViolationTimer = self.speedViolationMaxTime
end
function Sprayer:delete()
  g_currentMission:removeActivatableObject(self.sprayerFillActivatable)
  for k, sprayValve in pairs(self.sprayValves) do
    Utils.deleteParticleSystem(sprayValve.particleSystems)
  end
  if self.spraySound ~= nil then
    delete(self.spraySound)
  end
end
function Sprayer:readStream(streamId, connection)
  local turnedOn = streamReadBool(streamId)
  local isSprayerFilling = streamReadBool(streamId)
  self:setIsTurnedOn(turnedOn, true)
  self:setIsSprayerFilling(isSprayerFilling, true)
end
function Sprayer:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isTurnedOn)
  streamWriteBool(streamId, self.isSprayerFilling)
end
function Sprayer:readUpdateStream(streamId, timestamp, connection)
end
function Sprayer:writeUpdateStream(streamId, connection, dirtyMask)
end
function Sprayer:mouseEvent(posX, posY, isDown, isUp, button)
end
function Sprayer:keyEvent(unicode, sym, modifier, isDown)
end
function Sprayer:update(dt)
  if self.isClient and self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setIsTurnedOn(not self.isTurnedOn)
  end
end
function Sprayer:updateTick(dt)
  if self:getIsActive() then
    if self.isTurnedOn then
      self.lastSprayingArea = 0
      if self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 31 then
        self.speedViolationTimer = self.speedViolationTimer - dt
      else
        self.speedViolationTimer = self.speedViolationMaxTime
      end
      if self.isServer and 0 < self.speedViolationTimer then
        local litersPerSecond = self.sprayLitersPerSecond[self.currentFillType]
        if litersPerSecond == nil then
          litersPerSecond = self.defaultSprayLitersPerSecond
        end
        local usage = litersPerSecond * dt * 0.001
        local hasSpray = false
        if self.capacity == 0 or self:getIsHired() then
          hasSpray = true
          local sprayType = Sprayer.fillTypeToSprayType[self.currentFillType]
          if sprayType ~= nil then
            local sprayTypeDesc = Sprayer.sprayTypeIndexToDesc[sprayType]
            local delta = usage * sprayTypeDesc.pricePerLiter
            g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta
            g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta
            g_currentMission:addSharedMoney(-delta)
          end
        elseif 0 < self.fillLevel then
          hasSpray = true
          self:setFillLevel(self.fillLevel - usage, self.currentFillType)
        end
        if hasSpray then
          local cuttingAreasSend = {}
          for k, cuttingArea in pairs(self.cuttingAreas) do
            if self:getIsAreaActive(cuttingArea) then
              local x, y, z = getWorldTranslation(cuttingArea.start)
              local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
              local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
              local sqm = math.abs((z1 - z) * (x2 - x) - (x1 - x) * (z2 - z))
              self.lastSprayingArea = self.lastSprayingArea + sqm
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
            SprayerAreaEvent.runLocally(cuttingAreasSend)
            g_server:broadcastEvent(SprayerAreaEvent:new(cuttingAreasSend))
          end
        end
      end
      if self.isClient and not self.spraySoundEnabled and self:getIsActiveForSound() then
        playSample(self.spraySound, 0, self.spraySoundVolume, 0)
        setSamplePitch(self.spraySound, self.spraySoundPitchOffset)
        self.spraySoundEnabled = true
      end
      if 0 >= self.fillLevel and self.capacity ~= 0 then
        self:setIsTurnedOn(false, true)
      end
    else
      self.speedViolationTimer = self.speedViolationMaxTime
    end
  end
  if self.isSprayerFilling and self.isServer then
    local disableFilling = false
    if self:allowFillType(self.sprayerFillingFillType, false) then
      local oldFillLevel = self.fillLevel
      local delta = self.fillLitersPerSecond * dt * 0.001
      local silo = g_currentMission:getSiloAmount(self.sprayerFillingFillType)
      if self.sprayerFillingIsSiloTrigger then
        if silo <= 0 then
          disableFilling = true
        end
        delta = math.min(delta, silo)
      end
      self:setFillLevel(self.fillLevel + delta, self.sprayerFillingFillType, true)
      local delta = self.fillLevel - oldFillLevel
      if 0 < delta then
        if self.sprayerFillingIsSiloTrigger then
          g_currentMission:setSiloAmount(self.sprayerFillingFillType, silo - delta)
        else
          local sprayType = Sprayer.fillTypeToSprayType[self.sprayerFillingFillType]
          if sprayType ~= nil then
            local sprayTypeDesc = Sprayer.sprayTypeIndexToDesc[sprayType]
            local price = delta * sprayTypeDesc.pricePerLiter
            g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
            g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
            g_currentMission:addSharedMoney(-price)
          end
        end
      elseif self.fillLevel == self.capacity then
        disableFilling = true
      end
    else
      disableFilling = true
    end
    if disableFilling then
      self:setIsSprayerFilling(false)
    end
  end
end
function Sprayer:draw()
  if self.isClient then
    if self.fillLevel <= 0 and self.capacity ~= 0 then
      g_currentMission:addExtraPrintText(g_i18n:getText("FirstFillTheTool"))
    end
    if self.isTurnedOn then
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    else
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    end
    if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
      g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
    end
  end
end
function Sprayer:onDetach()
  if self.deactivateOnDetach then
    Sprayer.onDeactivate(self)
  else
    Sprayer.onDeactivateSounds(self)
  end
end
function Sprayer:onLeave()
  if self.deactivateOnLeave then
    Sprayer.onDeactivate(self)
  else
    Sprayer.onDeactivateSounds(self)
  end
end
function Sprayer:onDeactivate()
  self.speedViolationTimer = self.speedViolationMaxTime
  self:setIsTurnedOn(false, true)
  Sprayer.onDeactivateSounds(self)
end
function Sprayer:onDeactivateSounds()
  if self.spraySoundEnabled then
    stopSample(self.spraySound)
    self.spraySoundEnabled = false
  end
end
function Sprayer:getIsTurnedOnAllowed(isTurnedOn)
  if not isTurnedOn or self.fillLevel > 0 or self.capacity == 0 then
    return true
  end
end
function Sprayer:setIsTurnedOn(isTurnedOn, noEventSend)
  if isTurnedOn ~= self.isTurnedOn and self:getIsTurnedOnAllowed(isTurnedOn) then
    SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
    self.isTurnedOn = isTurnedOn
    if self.isClient then
      for k, sprayValve in pairs(self.sprayValves) do
        Utils.setEmittingState(sprayValve.particleSystems, self.isTurnedOn)
      end
      if not self.isTurnedOn and self.spraySoundEnabled then
        stopSample(self.spraySound)
        self.spraySoundEnabled = false
      end
    end
    self.speedViolationTimer = self.speedViolationMaxTime
  end
end
function Sprayer:setIsSprayerFilling(isFilling, fillType, isSiloTrigger, noEventSend)
  SprayerSetIsFillingEvent.sendEvent(self, isFilling, fillType, isSiloTrigger, noEventSend)
  if self.isSprayerFilling ~= isFilling then
    self.isSprayerFilling = isFilling
    self.sprayerFillingFillType = fillType
    self.sprayerFillingIsSiloTrigger = isSiloTrigger
  end
end
function Sprayer:addSprayerFillTrigger(trigger)
  if table.getn(self.sprayerFillTriggers) == 0 then
    g_currentMission:addActivatableObject(self.sprayerFillActivatable)
  end
  table.insert(self.sprayerFillTriggers, trigger)
end
function Sprayer:removeSprayerFillTrigger(trigger)
  for i = 1, table.getn(self.sprayerFillTriggers) do
    if self.sprayerFillTriggers[i] == trigger then
      table.remove(self.sprayerFillTriggers, i)
      break
    end
  end
  if table.getn(self.sprayerFillTriggers) == 0 then
    if self.isServer then
      self:setIsSprayerFilling(false)
    end
    g_currentMission:removeActivatableObject(self.sprayerFillActivatable)
  end
end
SprayerFillActivatable = {}
local SprayerFillActivatable_mt = Class(SprayerFillActivatable)
function SprayerFillActivatable:new(sprayer)
  local self = {}
  setmetatable(self, SprayerFillActivatable_mt)
  self.sprayer = sprayer
  self.activateText = "unknown"
  self.currentTrigger = nil
  return self
end
function SprayerFillActivatable:getIsActivatable()
  self.currentTrigger = nil
  if not self.sprayer:getIsActiveForInput() or self.sprayer.fillLevel == self.sprayer.capacity then
    return false
  end
  for i = 1, table.getn(self.sprayer.sprayerFillTriggers) do
    local trigger = self.sprayer.sprayerFillTriggers[i]
    if trigger:getIsActivatable(self.sprayer) then
      self.currentTrigger = trigger
      self:updateActivateText()
      return true
    end
  end
  return false
end
function SprayerFillActivatable:onActivateObject()
  self.sprayer:setIsSprayerFilling(not self.sprayer.isSprayerFilling, self.currentTrigger.fillType, self.currentTrigger.isSiloTrigger)
  self:updateActivateText()
  g_currentMission:addActivatableObject(self)
end
function SprayerFillActivatable:drawActivate()
end
function SprayerFillActivatable:updateActivateText()
  if self.sprayer.isSprayerFilling then
    self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), self.sprayer.typeDesc)
  else
    self.activateText = string.format(g_i18n:getText("refill_OBJECT"), self.sprayer.typeDesc)
  end
end
