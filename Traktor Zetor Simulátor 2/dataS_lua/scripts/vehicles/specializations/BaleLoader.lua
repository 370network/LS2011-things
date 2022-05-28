source("dataS/scripts/vehicles/specializations/BaleLoaderStateEvent.lua")
BaleLoader = {}
function BaleLoader.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Fillable, specializations)
end
BaleLoader.GRAB_MOVE_UP = 1
BaleLoader.GRAB_MOVE_DOWN = 2
BaleLoader.GRAB_DROP_BALE = 3
BaleLoader.EMPTY_NONE = 1
BaleLoader.EMPTY_TO_WORK = 2
BaleLoader.EMPTY_ROTATE_PLATFORM = 3
BaleLoader.EMPTY_ROTATE1 = 4
BaleLoader.EMPTY_CLOSE_GRIPPERS = 5
BaleLoader.EMPTY_HIDE_PUSHER1 = 6
BaleLoader.EMPTY_HIDE_PUSHER2 = 7
BaleLoader.EMPTY_ROTATE2 = 8
BaleLoader.EMPTY_WAIT_TO_DROP = 9
BaleLoader.EMPTY_WAIT_TO_SINK = 10
BaleLoader.EMPTY_SINK = 11
BaleLoader.EMPTY_CANCEL = 12
BaleLoader.EMPTY_WAIT_TO_REDO = 13
BaleLoader.CHANGE_DROP_BALES = 1
BaleLoader.CHANGE_SINK = 2
BaleLoader.CHANGE_EMPTY_REDO = 3
BaleLoader.CHANGE_EMPTY_START = 4
BaleLoader.CHANGE_EMPTY_CANCEL = 5
BaleLoader.CHANGE_MOVE_TO_WORK = 6
BaleLoader.CHANGE_MOVE_TO_TRANSPORT = 7
BaleLoader.CHANGE_GRAB_BALE = 8
BaleLoader.CHANGE_GRAB_MOVE_UP = 9
BaleLoader.CHANGE_GRAB_DROP_BALE = 10
BaleLoader.CHANGE_GRAB_MOVE_DOWN = 11
BaleLoader.CHANGE_FRONT_PUSHER = 12
BaleLoader.CHANGE_ROTATE_PLATFORM = 13
BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM = 14
BaleLoader.CHANGE_EMPTY_ROTATE1 = 15
BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS = 16
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 = 17
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 = 18
BaleLoader.CHANGE_EMPTY_ROTATE2 = 19
BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP = 20
BaleLoader.CHANGE_EMPTY_STATE_NIL = 21
BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO = 22
BaleLoader.CHANGE_BUTTON_EMPTY = 23
BaleLoader.CHANGE_BUTTON_EMPTY_ABORT = 24
BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT = 25
function BaleLoader:load(xmlFile)
  self.doStateChange = BaleLoader.doStateChange
  self.balesToLoad = {}
  self.balesToMount = {}
  self.isInWorkPosition = false
  self.grabberIsMoving = false
  self.allowGrabbing = false
  self.rotatePlatformDirection = 0
  self.frontBalePusherDirection = 0
  self.emptyState = BaleLoader.EMPTY_NONE
  self.itemsToSave = {}
  self.fillLevel = 0
  self.fillLevelMax = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.capacity"), 0)
  self.baleGrabber = {}
  self.baleGrabber.grabNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.baleGrabber#grabNode"))
  self.startBalePlace = {}
  self.startBalePlace.bales = {}
  self.startBalePlace.node = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.balePlaces#startBalePlace"))
  if self.startBalePlace.node ~= nil then
    if getNumOfChildren(self.startBalePlace.node) < 4 then
      self.startBalePlace.node = nil
    else
      self.startBalePlace.origRot = {}
      self.startBalePlace.origTrans = {}
      for i = 1, 4 do
        local node = getChildAt(self.startBalePlace.node, i - 1)
        local x, y, z = getRotation(node)
        self.startBalePlace.origRot[i] = {
          x,
          y,
          z
        }
        local x, y, z = getTranslation(node)
        self.startBalePlace.origTrans[i] = {
          x,
          y,
          z
        }
      end
    end
  end
  self.startBalePlace.count = 0
  self.currentBalePlace = 1
  self.balePlaces = {}
  local i = 0
  while true do
    local key = string.format("vehicle.balePlaces.balePlace(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"))
    if node ~= nil then
      local entry = {}
      entry.node = node
      table.insert(self.balePlaces, entry)
    end
    i = i + 1
  end
  self.baleGrabSound = {}
  local baleGrabSoundFile = getXMLString(xmlFile, "vehicle.baleGrabSound#file")
  if baleGrabSoundFile ~= nil then
    self.baleGrabSound.sample = createSample("baleDropSound")
    loadSample(self.baleGrabSound.sample, baleGrabSoundFile, false)
    local pitch = getXMLFloat(xmlFile, "vehicle.baleDropSound#pitchOffset")
    if pitch ~= nil then
      setSamplePitch(self.baleGrabSound.sample, pitch)
    end
    self.baleGrabSound.volume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.baleGrabSound#volume"), 1)
  end
  self.baleGrabParticleSystems = {}
  local psName = "vehicle.baleGrabParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.baleGrabParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.baleGrabParticleSystemDisableTime = 0
  self.baleGrabParticleSystemDisableDuration = Utils.getNoNil(getXMLFloat(xmlFile, psName .. "#disableDuration"), 0.6) * 1000
  self.baleLoaderHydraulicSound = {}
  local baleLoaderHydraulicSoundFile = getXMLString(xmlFile, "vehicle.baleLoaderHydraulicSound#file")
  if baleLoaderHydraulicSoundFile ~= nil then
    self.baleLoaderHydraulicSound.sample = createSample("baleLoaderHydraulicSound")
    loadSample(self.baleLoaderHydraulicSound.sample, baleLoaderHydraulicSoundFile, false)
    local pitch = getXMLFloat(xmlFile, "vehicle.baleLoaderHydraulicSound#pitchOffset")
    if pitch ~= nil then
      setSamplePitch(self.baleLoaderHydraulicSound.sample, pitch)
    end
    self.baleLoaderHydraulicSound.volume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.baleLoaderHydraulicSound#volume"), 1)
    self.baleLoaderHydraulicSound.enabled = false
  end
  self.workTransportButton = InputBinding.IMPLEMENT_EXTRA
  self.emptyAbortButton = InputBinding.IMPLEMENT_EXTRA2
  self.emptyButton = InputBinding.IMPLEMENT_EXTRA3
  self.baleTypes = {}
  local i = 0
  while true do
    local key = string.format("vehicle.baleTypes.baleType(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local filename = getXMLString(xmlFile, key .. "#filename")
    if filename ~= nil then
      table.insert(self.baleTypes, filename)
    end
    i = i + 1
  end
  if table.getn(self.baleTypes) == 0 then
    table.insert(self.baleTypes, "data/maps/models/objects/strawbale/strawbaleBaler.i3d")
  end
end
function BaleLoader:delete()
  if self.baleGrabParticleSystems then
    Utils.deleteParticleSystem(self.baleGrabParticleSystems)
  end
  for i, balePlace in pairs(self.balePlaces) do
    if balePlace.bales ~= nil then
      for _, baleServerId in pairs(balePlace.bales) do
        local bale = networkGetObject(baleServerId)
        if bale ~= nil and bale.nodeId ~= 0 then
          unlink(bale.nodeId)
        end
      end
    end
  end
  for i, baleServerId in ipairs(self.startBalePlace.bales) do
    local bale = networkGetObject(baleServerId)
    if bale ~= nil and bale.nodeId ~= 0 then
      unlink(bale.nodeId)
    end
  end
  if self.baleGrabSound.sample ~= nil then
    delete(self.baleGrabSound.sample)
    self.baleGrabSound.sample = nil
  end
  if self.baleLoaderHydraulicSound.sample ~= nil then
    delete(self.baleLoaderHydraulicSound.sample)
    self.baleLoaderHydraulicSound.sample = nil
  end
end
function BaleLoader:readStream(streamId, connection)
  self.isInWorkPosition = streamReadBool(streamId)
  self.frontBalePusherDirection = streamReadIntN(streamId, 3)
  self.rotatePlatformDirection = streamReadIntN(streamId, 3)
  if self.isInWorkPosition then
    BaleLoader.moveToWorkPosition(self)
  end
  local emptyState = streamReadUIntN(streamId, 4)
  self.currentBalePlace = streamReadInt8(streamId)
  self.fillLevel = streamReadFloat32(streamId)
  if streamReadBool(streamId) then
    local baleServerId = streamReadInt32(streamId)
    self.baleGrabber.currentBale = baleServerId
    self.balesToMount[baleServerId] = {
      serverId = baleServerId,
      linkNode = self.baleGrabber.grabNode,
      trans = {
        0,
        0,
        0
      },
      rot = {
        0,
        0,
        0
      }
    }
  end
  self.startBalePlace.count = streamReadUIntN(streamId, 3)
  for i = 1, self.startBalePlace.count do
    local baleServerId = streamReadInt32(streamId)
    local attachNode = getChildAt(self.startBalePlace.node, i - 1)
    self.balesToMount[baleServerId] = {
      serverId = baleServerId,
      linkNode = attachNode,
      trans = {
        0,
        0,
        0
      },
      rot = {
        0,
        0,
        0
      }
    }
    table.insert(self.startBalePlace.bales, baleServerId)
  end
  for i = 1, table.getn(self.balePlaces) do
    local balePlace = self.balePlaces[i]
    local numBales = streamReadUIntN(streamId, 3)
    if 0 < numBales then
      balePlace.bales = {}
      for baleI = 1, numBales do
        local baleServerId = streamReadInt32(streamId, baleServerId)
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        table.insert(balePlace.bales, baleServerId)
        self.balesToMount[baleServerId] = {
          serverId = baleServerId,
          linkNode = balePlace.node,
          trans = {
            x,
            y,
            z
          },
          rot = {
            0,
            0,
            0
          }
        }
      end
    end
  end
  BaleLoader.updateBalePlacesAnimations(self)
  if emptyState >= BaleLoader.EMPTY_TO_WORK then
    self:doStateChange(BaleLoader.CHANGE_EMPTY_START)
    AnimatedVehicle.updateAnimations(self, 99999999)
    if emptyState >= BaleLoader.EMPTY_ROTATE_PLATFORM then
      self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM)
      AnimatedVehicle.updateAnimations(self, 99999999)
      if emptyState >= BaleLoader.EMPTY_ROTATE1 then
        self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE1)
        AnimatedVehicle.updateAnimations(self, 99999999)
        if emptyState >= BaleLoader.EMPTY_CLOSE_GRIPPERS then
          self:doStateChange(BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS)
          AnimatedVehicle.updateAnimations(self, 99999999)
          if emptyState >= BaleLoader.EMPTY_HIDE_PUSHER1 then
            self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1)
            AnimatedVehicle.updateAnimations(self, 99999999)
            if emptyState >= BaleLoader.EMPTY_HIDE_PUSHER2 then
              self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2)
              AnimatedVehicle.updateAnimations(self, 99999999)
              if emptyState >= BaleLoader.EMPTY_ROTATE2 then
                self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE2)
                AnimatedVehicle.updateAnimations(self, 99999999)
                if emptyState >= BaleLoader.EMPTY_WAIT_TO_DROP then
                  self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP)
                  AnimatedVehicle.updateAnimations(self, 99999999)
                  if emptyState == BaleLoader.EMPTY_CANCEL or emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
                    self:doStateChange(BaleLoader.CHANGE_EMPTY_CANCEL)
                    AnimatedVehicle.updateAnimations(self, 99999999)
                    if emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
                      self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO)
                      AnimatedVehicle.updateAnimations(self, 99999999)
                    end
                  elseif emptyState == BaleLoader.EMPTY_WAIT_TO_SINK or emptyState == BaleLoader.EMPTY_SINK then
                    self:doStateChange(BaleLoader.CHANGE_DROP_BALES)
                    AnimatedVehicle.updateAnimations(self, 99999999)
                    if emptyState == BaleLoader.EMPTY_SINK then
                      self:doStateChange(BaleLoader.CHANGE_SINK)
                      AnimatedVehicle.updateAnimations(self, 99999999)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  self.emptyState = emptyState
end
function BaleLoader:writeStream(streamId, connection)
  streamWriteBool(streamId, self.isInWorkPosition)
  streamWriteIntN(streamId, self.frontBalePusherDirection, 3)
  streamWriteIntN(streamId, self.rotatePlatformDirection, 3)
  streamWriteUIntN(streamId, self.emptyState, 4)
  streamWriteInt8(streamId, self.currentBalePlace)
  streamWriteFloat32(streamId, self.fillLevel)
  if streamWriteBool(streamId, self.baleGrabber.currentBale ~= nil) then
    streamWriteInt32(streamId, self.baleGrabber.currentBale)
  end
  streamWriteUIntN(streamId, self.startBalePlace.count, 3)
  for i = 1, self.startBalePlace.count do
    local baleServerId = self.startBalePlace.bales[i]
    streamWriteInt32(streamId, baleServerId)
  end
  for i = 1, table.getn(self.balePlaces) do
    local balePlace = self.balePlaces[i]
    local numBales = 0
    if balePlace.bales ~= nil then
      numBales = table.getn(balePlace.bales)
    end
    streamWriteUIntN(streamId, numBales, 3)
    if balePlace.bales ~= nil then
      for baleI = 1, numBales do
        local baleServerId = balePlace.bales[baleI]
        local bale = networkGetObject(baleServerId)
        local nodeId = bale.nodeId
        local x, y, z = getTranslation(nodeId)
        streamWriteInt32(streamId, baleServerId)
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
      end
    end
  end
end
function BaleLoader:updateBalePlacesAnimations()
  if self.currentBalePlace > 2 then
    self:playAnimation("moveBalePlaces", 20, 0, true)
    self:setAnimationStopTime("moveBalePlaces", (self.currentBalePlace - 2) / table.getn(self.balePlaces))
    AnimatedVehicle.updateAnimations(self, 99999999)
  end
  if self.startBalePlace.count >= 1 then
    self:playAnimation("bale1ToOtherSide", 20, nil, true)
    AnimatedVehicle.updateAnimations(self, 99999999)
    if 2 <= self.startBalePlace.count then
      self:playAnimation("balesToOtherRow", 20, nil, true)
      AnimatedVehicle.updateAnimations(self, 99999999)
      if self.startBalePlace.count >= 3 then
        self:playAnimation("bale3ToOtherSide", 20, nil, true)
        AnimatedVehicle.updateAnimations(self, 99999999)
        if self.startBalePlace.count >= 4 then
          BaleLoader.rotatePlatform(self)
        end
      end
    end
  end
end
function BaleLoader:mouseEvent(posX, posY, isDown, isUp, button)
end
function BaleLoader:draw()
  if self.emptyState == BaleLoader.EMPTY_NONE then
    if self.grabberMoveState == nil then
      if self.isInWorkPosition then
        g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_TRANSPORT"), self.workTransportButton)
      else
        g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_WORK"), self.workTransportButton)
      end
    end
    if BaleLoader.getAllowsStartUnloading(self) then
      g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_UNLOAD"), self.emptyButton)
    end
  elseif self.emptyState >= BaleLoader.EMPTY_TO_WORK and self.emptyState <= BaleLoader.EMPTY_ROTATE2 then
    g_currentMission:addExtraPrintText(g_i18n:getText("BALELOADER_UP"))
  elseif self.emptyState == BaleLoader.EMPTY_CANCEL or self.emptyState == BaleLoader.EMPTY_SINK then
    g_currentMission:addExtraPrintText(g_i18n:getText("BALELOADER_DOWN"))
  elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
    g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_READY"), self.emptyButton)
    g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_ABORT"), self.emptyAbortButton)
  elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
    g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_SINK"), self.emptyButton)
  elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
    g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_UNLOAD"), self.emptyButton)
  end
end
function BaleLoader:keyEvent(unicode, sym, modifier, isDown)
end
function BaleLoader:update(dt)
  if self.firstTimeRun then
    for k, v in pairs(self.balesToLoad) do
      local baleObject = Bale:new(self.isServer, self.isClient)
      local x, y, z = unpack(v.translation)
      local rx, ry, rz = unpack(v.rotation)
      baleObject:load(v.filename, x, y, z, rx, ry, rz)
      baleObject:mount(self, v.parentNode, x, y, z, rx, ry, rz)
      baleObject:register()
      table.insert(v.bales, networkGetObjectId(baleObject))
      self.balesToLoad[k] = nil
    end
    for k, baleToMount in pairs(self.balesToMount) do
      local bale = networkGetObject(baleToMount.serverId)
      if bale ~= nil then
        local x, y, z = unpack(baleToMount.trans)
        local rx, ry, rz = unpack(baleToMount.rot)
        bale:mount(self, baleToMount.linkNode, x, y, z, rx, ry, rz)
        self.balesToMount[k] = nil
      end
    end
  end
  if self:getIsActive() then
    if self:getIsActiveForInput() and self.isClient then
      if InputBinding.hasEvent(self.emptyButton) then
        g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
      elseif InputBinding.hasEvent(self.emptyAbortButton) then
        g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_EMPTY_ABORT))
      elseif InputBinding.hasEvent(self.workTransportButton) then
        g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT))
      end
    end
    if self.isClient and self.baleGrabParticleSystemDisableTime ~= 0 and self.baleGrabParticleSystemDisableTime < self.time then
      Utils.setEmittingState(self.baleGrabParticleSystems, false)
      self.baleGrabParticleSystemDisableTime = 0
    end
    if self.grabberIsMoving and not self:getIsAnimationPlaying("baleGrabberTransportToWork") then
      self.grabberIsMoving = false
    end
    self.allowGrabbing = false
    if self.isInWorkPosition and not self.grabberIsMoving and self.grabberMoveState == nil and self.startBalePlace.count < 4 and self.frontBalePusherDirection == 0 and self.rotatePlatformDirection == 0 and self.emptyState == BaleLoader.EMPTY_NONE and self.fillLevel < self.fillLevelMax then
      self.allowGrabbing = true
    end
    if self.isServer then
      if self.allowGrabbing and self.baleGrabber.grabNode ~= nil and self.baleGrabber.currentBale == nil then
        local nearestBale = BaleLoader.getBaleInRange(self, self.baleGrabber.grabNode)
        if nearestBale ~= nil then
          g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_BALE, networkGetObjectId(nearestBale)), true, nil, self)
        end
      end
      if self.grabberMoveState ~= nil then
        if self.grabberMoveState == BaleLoader.GRAB_MOVE_UP then
          if not self:getIsAnimationPlaying("baleGrabberWorkToDrop") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_MOVE_UP), true, nil, self)
          end
        elseif self.grabberMoveState == BaleLoader.GRAB_DROP_BALE then
          if not self:getIsAnimationPlaying("baleGrabberDropBale") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_DROP_BALE), true, nil, self)
          end
        elseif self.grabberMoveState == BaleLoader.GRAB_MOVE_DOWN and not self:getIsAnimationPlaying("baleGrabberWorkToDrop") then
          g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_MOVE_DOWN), true, nil, self)
        end
      end
      if self.frontBalePusherDirection ~= 0 and not self:getIsAnimationPlaying("frontBalePusher") then
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_FRONT_PUSHER), true, nil, self)
      end
      if self.rotatePlatformDirection ~= 0 and not self:getIsAnimationPlaying("rotatePlatform") then
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_ROTATE_PLATFORM), true, nil, self)
      end
      if self.emptyState ~= BaleLoader.EMPTY_NONE then
        if self.emptyState == BaleLoader.EMPTY_TO_WORK then
          if not self:getIsAnimationPlaying("baleGrabberTransportToWork") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_ROTATE_PLATFORM then
          if not self:getIsAnimationPlaying("rotatePlatform") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_ROTATE1), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_ROTATE1 then
          if not self:getIsAnimationPlaying("emptyRotate") and not self:getIsAnimationPlaying("moveBalePlacesToEmpty") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_CLOSE_GRIPPERS then
          if not self:getIsAnimationPlaying("closeGrippers") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_HIDE_PUSHER1 then
          if not self:getIsAnimationPlaying("emptyHidePusher1") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_HIDE_PUSHER2 then
          if self:getAnimationTime("moveBalePusherToEmpty") < 0.7 or not self:getIsAnimationPlaying("moveBalePusherToEmpty") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_ROTATE2 then
          if not self:getIsAnimationPlaying("emptyRotate") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_SINK then
          if not self:getIsAnimationPlaying("emptyRotate") and not self:getIsAnimationPlaying("moveBalePlacesToEmpty") and not self:getIsAnimationPlaying("emptyHidePusher1") and not self:getIsAnimationPlaying("rotatePlatform") then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_STATE_NIL), true, nil, self)
          end
        elseif self.emptyState == BaleLoader.EMPTY_CANCEL and not self:getIsAnimationPlaying("emptyRotate") then
          g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO), true, nil, self)
        end
      end
    end
    if self.isClient and self.baleLoaderHydraulicSound.sample ~= nil then
      local hasAnimationsPlaying = false
      for _, v in pairs(self.activeAnimations) do
        hasAnimationsPlaying = true
        break
      end
      if hasAnimationsPlaying then
        if not self.baleLoaderHydraulicSound.enabled and self:getIsActiveForSound() then
          playSample(self.baleLoaderHydraulicSound.sample, 0, self.baleLoaderHydraulicSound.volume, 0)
          self.baleLoaderHydraulicSound.enabled = true
        end
      elseif self.baleLoaderHydraulicSound.enabled then
        stopSample(self.baleLoaderHydraulicSound.sample)
        self.baleLoaderHydraulicSound.enabled = false
      end
    end
  end
end
function BaleLoader:getBaleInRange(refNode)
  local px, py, pz = getWorldTranslation(refNode)
  local nearestDistance = 3
  local nearestBale
  for index, item in pairs(g_currentMission.itemsToSave) do
    if item.item:isa(Bale) then
      for _, filename in pairs(self.baleTypes) do
        if item.item.i3dFilename == filename then
          local vx, vy, vz = getWorldTranslation(item.item.nodeId)
          local distance = Utils.vector3Length(px - vx, py - vy, pz - vz)
          if nearestDistance > distance then
            nearestDistance = distance
            nearestBale = item.item
          end
          break
        end
      end
    end
  end
  return nearestBale
end
function BaleLoader:onDetach()
  if self.deactivateOnDetach then
    BaleLoader.onDeactivate(self)
  else
    BaleLoader.onDeactivateSounds(self)
  end
end
function BaleLoader:onAttach()
end
function BaleLoader:onDeactivate()
  Utils.setEmittingState(self.baleGrabParticleSystems, false)
  BaleLoader.onDeactivateSounds(self)
end
function BaleLoader:onDeactivateSounds()
  if self.baleLoaderHydraulicSound.sample ~= nil then
    stopSample(self.baleLoaderHydraulicSound.sample)
  end
end
function BaleLoader:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  self.currentBalePlace = 1
  self.startBalePlace.count = 0
  local numBales = 0
  local i = 0
  while true do
    local baleKey = key .. string.format(".bale(%d)", i)
    if not hasXMLProperty(xmlFile, baleKey) then
      break
    end
    local filename = getXMLString(xmlFile, baleKey .. "#filename")
    if filename ~= nil then
      filename = Utils.convertFromNetworkFilename(filename)
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baleKey .. "#position"))
      local xRot, yRot, zRot = Utils.getVectorFromString(getXMLString(xmlFile, baleKey .. "#rotation"))
      local balePlace = getXMLInt(xmlFile, baleKey .. "#balePlace")
      local helper = getXMLInt(xmlFile, baleKey .. "#helper")
      if balePlace == nil or 0 < balePlace and (x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil) or balePlace < 1 and helper == nil then
        print("Warning: Corrupt savegame, bale " .. filename .. " could not be loaded")
      else
        local translation, rotation
        if 0 < balePlace then
          translation = {
            x,
            y,
            z
          }
          rotation = {
            xRot,
            yRot,
            zRot
          }
        else
          translation = {
            0,
            0,
            0
          }
          rotation = {
            0,
            0,
            0
          }
        end
        local parentNode, bales
        if balePlace < 1 then
          if helper <= getNumOfChildren(self.startBalePlace.node) then
            parentNode = getChildAt(self.startBalePlace.node, helper - 1)
            if self.startBalePlace.bales == nil then
              self.startBalePlace.bales = {}
            end
            bales = self.startBalePlace.bales
            self.startBalePlace.count = self.startBalePlace.count + 1
          end
        elseif balePlace <= table.getn(self.balePlaces) then
          self.currentBalePlace = math.max(self.currentBalePlace, balePlace + 1)
          parentNode = self.balePlaces[balePlace].node
          if self.balePlaces[balePlace].bales == nil then
            self.balePlaces[balePlace].bales = {}
          end
          bales = self.balePlaces[balePlace].bales
        end
        if parentNode ~= nil then
          numBales = numBales + 1
          table.insert(self.balesToLoad, {
            parentNode = parentNode,
            filename = filename,
            bales = bales,
            translation = translation,
            rotation = rotation
          })
        end
      end
    end
    i = i + 1
  end
  BaleLoader.updateBalePlacesAnimations(self)
  self.fillLevel = numBales
  return BaseMission.VEHICLE_LOAD_OK
end
function BaleLoader:getSaveAttributesAndNodes(nodeIdent)
  local attributes = ""
  local nodes = ""
  local baleNum = 0
  for i, balePlace in pairs(self.balePlaces) do
    if balePlace.bales ~= nil then
      for _, baleServerId in pairs(balePlace.bales) do
        local bale = networkGetObject(baleServerId)
        if bale ~= nil then
          local nodeId = bale.nodeId
          local x, y, z = getTranslation(nodeId)
          local rx, ry, rz = getRotation(nodeId)
          if 0 < baleNum then
            nodes = nodes .. "\n"
          end
          nodes = nodes .. nodeIdent .. "<bale filename=\"" .. Utils.encodeToHTML(Utils.convertToNetworkFilename(bale.i3dFilename)) .. "\" position=\"" .. x .. " " .. y .. " " .. z .. "\" rotation=\"" .. rx .. " " .. ry .. " " .. rz .. "\" balePlace=\"" .. i .. "\" />"
          baleNum = baleNum + 1
        end
      end
    end
  end
  for i, baleServerId in ipairs(self.startBalePlace.bales) do
    local bale = networkGetObject(baleServerId)
    if bale ~= nil then
      if 0 < baleNum then
        nodes = nodes .. "\n"
      end
      nodes = nodes .. nodeIdent .. "<bale filename=\"" .. Utils.encodeToHTML(Utils.convertToNetworkFilename(bale.i3dFilename)) .. "\" balePlace=\"0\" helper=\"" .. i .. "\"/>"
      baleNum = baleNum + 1
    end
  end
  return attributes, nodes
end
function BaleLoader:doStateChange(id, nearestBaleServerId)
  if id == BaleLoader.CHANGE_DROP_BALES then
    self.currentBalePlace = 1
    for _, balePlace in pairs(self.balePlaces) do
      if balePlace.bales ~= nil then
        for _, baleServerId in pairs(balePlace.bales) do
          local bale = networkGetObject(baleServerId)
          if bale ~= nil then
            bale:unmount()
          end
          self.balesToMount[baleServerId] = nil
        end
        balePlace.bales = nil
      end
    end
    self.fillLevel = 0
    self:playAnimation("closeGrippers", -1, nil, true)
    self.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK
  elseif id == BaleLoader.CHANGE_SINK then
    self:playAnimation("emptyRotate", -1, nil, true)
    self:playAnimation("moveBalePlacesToEmpty", -5, nil, true)
    self:playAnimation("emptyHidePusher1", -1, nil, true)
    self:playAnimation("rotatePlatform", -1, nil, true)
    if not self.isInWorkPosition then
      self:playAnimation("closeGrippers", 1, self:getAnimationTime("closeGrippers"), true)
      self:playAnimation("baleGrabberTransportToWork", -1, nil, true)
    end
    self.emptyState = BaleLoader.EMPTY_SINK
  elseif id == BaleLoader.CHANGE_EMPTY_REDO then
    self:playAnimation("emptyRotate", 1, nil, true)
    self.emptyState = BaleLoader.EMPTY_ROTATE2
  elseif id == BaleLoader.CHANGE_EMPTY_START then
    BaleLoader.moveToWorkPosition(self)
    self.emptyState = BaleLoader.EMPTY_TO_WORK
  elseif id == BaleLoader.CHANGE_EMPTY_CANCEL then
    self:playAnimation("emptyRotate", -1, nil, true)
    self.emptyState = BaleLoader.EMPTY_CANCEL
  elseif id == BaleLoader.CHANGE_MOVE_TO_TRANSPORT then
    if self.isInWorkPosition then
      self.grabberIsMoving = true
      self.isInWorkPosition = false
      BaleLoader.moveToTransportPosition(self)
    end
  elseif id == BaleLoader.CHANGE_MOVE_TO_WORK then
    if not self.isInWorkPosition then
      self.grabberIsMoving = true
      self.isInWorkPosition = true
      BaleLoader.moveToWorkPosition(self)
    end
  elseif id == BaleLoader.CHANGE_GRAB_BALE then
    local bale = networkGetObject(nearestBaleServerId)
    self.baleGrabber.currentBale = nearestBaleServerId
    if bale ~= nil then
      bale:mount(self, self.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
      self.balesToMount[nearestBaleServerId] = nil
    else
      self.balesToMount[nearestBaleServerId] = {
        serverId = nearestBaleServerId,
        linkNode = self.baleGrabber.grabNode,
        trans = {
          0,
          0,
          0
        },
        rot = {
          0,
          0,
          0
        }
      }
    end
    self.grabberMoveState = BaleLoader.GRAB_MOVE_UP
    self:playAnimation("baleGrabberWorkToDrop", 1, nil, true)
    if self.isClient then
      if self.baleGrabSound.sample ~= nil and self:getIsActiveForSound() then
        playSample(self.baleGrabSound.sample, 1, self.baleGrabSound.volume, 0)
      end
      Utils.setEmittingState(self.baleGrabParticleSystems, true)
      self.baleGrabParticleSystemDisableTime = self.time + self.baleGrabParticleSystemDisableDuration
    end
  elseif id == BaleLoader.CHANGE_GRAB_MOVE_UP then
    self:playAnimation("baleGrabberDropBale", 1, nil, true)
    if self.startBalePlace.count == 1 then
      self:playAnimation("bale1ToOtherSide", 1, nil, true)
    elseif self.startBalePlace.count == 3 then
      self:playAnimation("bale3ToOtherSide", 1, nil, true)
    end
    self.grabberMoveState = BaleLoader.GRAB_DROP_BALE
  elseif id == BaleLoader.CHANGE_GRAB_DROP_BALE then
    if self.startBalePlace.count < 4 and self.startBalePlace.node ~= nil then
      local attachNode = getChildAt(self.startBalePlace.node, self.startBalePlace.count)
      local bale = networkGetObject(self.baleGrabber.currentBale)
      if bale ~= nil then
        bale:mount(self, attachNode, 0, 0, 0, 0, 0, 0)
        self.balesToMount[self.baleGrabber.currentBale] = nil
      else
        self.balesToMount[self.baleGrabber.currentBale] = {
          serverId = self.baleGrabber.currentBale,
          linkNode = attachNode,
          trans = {
            0,
            0,
            0
          },
          rot = {
            0,
            0,
            0
          }
        }
      end
      self.startBalePlace.count = self.startBalePlace.count + 1
      table.insert(self.startBalePlace.bales, self.baleGrabber.currentBale)
      self.baleGrabber.currentBale = nil
      if self.startBalePlace.count == 2 then
        self.frontBalePusherDirection = 1
        self:playAnimation("balesToOtherRow", 1, nil, true)
        self:playAnimation("frontBalePusher", 1, nil, true)
      elseif self.startBalePlace.count == 4 then
        BaleLoader.rotatePlatform(self)
      end
      self.fillLevel = self.fillLevel + 1
      self:playAnimation("baleGrabberDropBale", -5, nil, true)
      self:playAnimation("baleGrabberWorkToDrop", -1, nil, true)
      self.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN
    end
  elseif id == BaleLoader.CHANGE_GRAB_MOVE_DOWN then
    self.grabberMoveState = nil
  elseif id == BaleLoader.CHANGE_FRONT_PUSHER then
    if 0 < self.frontBalePusherDirection then
      self:playAnimation("frontBalePusher", -1, nil, true)
      self.frontBalePusherDirection = -1
    else
      self.frontBalePusherDirection = 0
    end
  elseif id == BaleLoader.CHANGE_ROTATE_PLATFORM then
    if 0 < self.rotatePlatformDirection then
      local balePlace = self.balePlaces[self.currentBalePlace]
      self.currentBalePlace = self.currentBalePlace + 1
      for i = 1, table.getn(self.startBalePlace.bales) do
        local node = getChildAt(self.startBalePlace.node, i - 1)
        local x, y, z = getTranslation(node)
        local baleServerId = self.startBalePlace.bales[i]
        local bale = networkGetObject(baleServerId)
        if bale ~= nil then
          bale:mount(self, balePlace.node, x, y, z, 0, 0, 0)
          self.balesToMount[baleServerId] = nil
        else
          self.balesToMount[baleServerId] = {
            serverId = baleServerId,
            linkNode = balePlace.node,
            trans = {
              x,
              y,
              z
            },
            rot = {
              0,
              0,
              0
            }
          }
        end
      end
      balePlace.bales = self.startBalePlace.bales
      self.startBalePlace.bales = {}
      self.startBalePlace.count = 0
      for i = 1, 4 do
        local node = getChildAt(self.startBalePlace.node, i - 1)
        setRotation(node, unpack(self.startBalePlace.origRot[i]))
        setTranslation(node, unpack(self.startBalePlace.origTrans[i]))
      end
      if self.emptyState == BaleLoader.EMPTY_NONE then
        self.rotatePlatformDirection = -1
        self:playAnimation("rotatePlatform", -1, nil, true)
      else
        self.rotatePlatformDirection = 0
      end
    else
      self.rotatePlatformDirection = 0
    end
  elseif id == BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM then
    self.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM
    if self.startBalePlace.count == 0 then
      self:playAnimation("rotatePlatform", 1, nil, true)
    else
      BaleLoader.rotatePlatform(self)
    end
  elseif id == BaleLoader.CHANGE_EMPTY_ROTATE1 then
    self:playAnimation("emptyRotate", 1, nil, true)
    self:setAnimationStopTime("emptyRotate", 0.2)
    local balePlacesTime = self:getRealAnimationTime("moveBalePlaces")
    self:playAnimation("moveBalePlacesToEmpty", 1.5, balePlacesTime / self:getAnimationDuration("moveBalePlacesToEmpty"), true)
    self:playAnimation("moveBalePusherToEmpty", 1.5, balePlacesTime / self:getAnimationDuration("moveBalePusherToEmpty"), true)
    self.emptyState = BaleLoader.EMPTY_ROTATE1
  elseif id == BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS then
    self:playAnimation("closeGrippers", 1, nil, true)
    self.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS
  elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 then
    self:playAnimation("emptyHidePusher1", 1, nil, true)
    self.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1
  elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 then
    self:playAnimation("moveBalePusherToEmpty", -2, nil, true)
    self.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2
  elseif id == BaleLoader.CHANGE_EMPTY_ROTATE2 then
    self:playAnimation("emptyRotate", 1, self:getAnimationTime("emptyRotate"), true)
    self.emptyState = BaleLoader.EMPTY_ROTATE2
  elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP then
    self.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP
  elseif id == BaleLoader.CHANGE_EMPTY_STATE_NIL then
    self.emptyState = BaleLoader.EMPTY_NONE
  elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO then
    self.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO
  elseif id == BaleLoader.CHANGE_BUTTON_EMPTY then
    assert(self.isServer)
    if self.emptyState ~= BaleLoader.EMPTY_NONE then
      if self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_DROP_BALES), true, nil, self)
      elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_SINK), true, nil, self)
      elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_REDO), true, nil, self)
      end
    elseif BaleLoader.getAllowsStartUnloading(self) then
      g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_START), true, nil, self)
    end
  elseif id == BaleLoader.CHANGE_BUTTON_EMPTY_ABORT then
    assert(self.isServer)
    if self.emptyState ~= BaleLoader.EMPTY_NONE and self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
      g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_CANCEL), true, nil, self)
    end
  elseif id == BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT then
    assert(self.isServer)
    if self.emptyState == BaleLoader.EMPTY_NONE and self.grabberMoveState == nil then
      if self.isInWorkPosition then
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
      else
        g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
      end
    end
  end
end
function BaleLoader:getAllowsStartUnloading()
  return self.fillLevel > 0 and self.rotatePlatformDirection == 0 and self.frontBalePusherDirection == 0 and not self.grabberIsMoving and self.grabberMoveState == nil and self.emptyState == BaleLoader.EMPTY_NONE
end
function BaleLoader:rotatePlatform()
  self.rotatePlatformDirection = 1
  self:playAnimation("rotatePlatform", 1, nil, true)
  if self.startBalePlace.count > 0 then
    self:playAnimation("rotatePlatformMoveBales" .. self.startBalePlace.count, 1, nil, true)
  end
  if 1 < self.currentBalePlace then
    self:playAnimation("moveBalePlaces", 1, (self.currentBalePlace - 1) / table.getn(self.balePlaces), true)
    self:setAnimationStopTime("moveBalePlaces", self.currentBalePlace / table.getn(self.balePlaces))
  end
end
function BaleLoader:moveToWorkPosition()
  self:playAnimation("baleGrabberTransportToWork", 1, Utils.clamp(self:getAnimationTime("baleGrabberTransportToWork"), 0, 1), true)
  self:playAnimation("closeGrippers", -1, Utils.clamp(self:getAnimationTime("closeGrippers"), 0, 1), true)
  if self.startBalePlace.count == 1 then
    self:playAnimation("bale1ToOtherSide", -0.5, nil, true)
  elseif self.startBalePlace.count == 3 then
    self:playAnimation("bale3ToOtherSide", -0.5, nil, true)
  end
end
function BaleLoader:moveToTransportPosition()
  self:playAnimation("baleGrabberTransportToWork", -1, Utils.clamp(self:getAnimationTime("baleGrabberTransportToWork"), 0, 1), true)
  self:playAnimation("closeGrippers", 1, Utils.clamp(self:getAnimationTime("closeGrippers"), 0, 1), true)
  if self.startBalePlace.count == 1 then
    self:playAnimation("bale1ToOtherSide", 0.5, nil, true)
  elseif self.startBalePlace.count == 3 then
    self:playAnimation("bale3ToOtherSide", 0.5, nil, true)
  end
end
