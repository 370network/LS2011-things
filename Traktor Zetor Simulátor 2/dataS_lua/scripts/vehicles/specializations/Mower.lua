source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/MowerAreaEvent.lua")
Mower = {}
function Mower.prerequisitesPresent(specializations)
  return true
end
function Mower:load(xmlFile)
  self.setIsTurnedOn = SpecializationUtil.callSpecializationsFunction("setIsTurnedOn")
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  if self.groundReferenceNode == nil then
    self.groundReferenceNode = self.components[1].node
  end
  if self.isClient then
    local mowerSound = getXMLString(xmlFile, "vehicle.mowerSound#file")
    if mowerSound ~= nil and mowerSound ~= "" then
      mowerSound = Utils.getFilename(mowerSound, self.baseDirectory)
      self.mowerSound = createSample("mowerSound")
      self.mowerSoundEnabled = false
      loadSample(self.mowerSound, mowerSound, false)
      self.mowerSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.mowerSound#pitchOffset"), 1)
      self.mowerSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.mowerSound#volume"), 1)
    end
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
  end
  self.isTurnedOn = false
  self.wasToFast = false
  self.mowerGroundFlag = self.nextDirtyFlag
  self.nextDirtyFlag = self.mowerGroundFlag * 2
end
function Mower:delete()
  if self.mowerSound ~= nil then
    delete(self.mowerSound)
  end
end
function Mower:readStream(streamId, connection)
  local turnedOn = streamReadBool(streamId)
  self:setIsTurnedOn(turnedOn, true)
end
function Mower:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isTurnedOn)
end
function Mower:readUpdateStream(streamId, timestamp, connection)
end
function Mower:writeUpdateStream(streamId, connection, dirtyMask)
end
function Mower:mouseEvent(posX, posY, isDown, isUp, button)
end
function Mower:keyEvent(unicode, sym, modifier, isDown)
end
function Mower:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setIsTurnedOn(not self.isTurnedOn)
  end
end
function Mower:updateTick(dt)
  self.wasToFast = false
  if self:getIsActive() then
    if self.isTurnedOn then
      local toFast = self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 31
      if not toFast and self.isServer then
        local x, y, z = getWorldTranslation(self.groundReferenceNode)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        if y <= terrainHeight + self.groundReferenceThreshold then
          local foldAnimTime = self.foldAnimTime
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
            MowerAreaEvent.runLocally(cuttingAreasSend)
            g_server:broadcastEvent(MowerAreaEvent:new(cuttingAreasSend))
          end
        end
      end
      if self.isClient and not self.mowerSoundEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.mowerSound, self.mowerSoundPitchOffset)
        playSample(self.mowerSound, 0, self.mowerSoundVolume, 0)
        self.mowerSoundEnabled = true
      end
      self.wasToFast = toFast
    elseif self.isClient and self.mowerSoundEnabled then
      stopSample(self.mowerSound)
      self.mowerSoundEnabled = false
    end
  end
end
function Mower:draw()
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
function Mower:onDetach()
  if self.deactivateOnDetach then
    Mower.onDeactivate(self)
  else
    Mower.onDeactivateSounds(self)
  end
end
function Mower:onLeave()
  if self.deactivateOnLeave then
    Mower.onDeactivate(self)
  else
    Mower.onDeactivateSounds(self)
  end
end
function Mower:onDeactivate()
  Mower.onDeactivateSounds(self)
  self.isTurnedOn = false
end
function Mower:onDeactivateSounds()
  if self.isClient and self.mowerSoundEnabled then
    stopSample(self.mowerSound)
    self.mowerSoundEnabled = false
  end
end
function Mower:setIsTurnedOn(turnedOn, noEventSend)
  SetTurnedOnEvent.sendEvent(self, turnedOn, noEventSend)
  self.isTurnedOn = turnedOn
end
