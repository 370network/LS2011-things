Player = {}
Player_mt = Class(Player, Object)
InitStaticObjectClass(Player, "Player", ObjectIds.OBJECT_PLAYER)
Player.kinematicCollisionMask = 2148532228
Player.movementCollisionMask = 2148532255
Player.ANIM_STATE_IDLE = 1
Player.ANIM_STATE_WALK = 2
Player.ANIM_STATE_RUN = 3
function Player:new(isServer, isClient)
  local self = Object:new(isServer, isClient, Player_mt)
  self.className = "Player"
  self.history = {}
  self.index = 0
  self.isControlled = false
  self.controllerName = "Unknown"
  self.creatorConnection = nil
  self.isEntered = false
  self.isClient = isClient
  self.isServer = isServer
  self.height = 1.8
  self.gravity = -0.02
  self.walkingSpeed = 0.004
  self.gravity = -0.02
  self.runningFactor = 1
  self.lastJumpFactor = 0
  self.jumpFactor = 0
  self.jumpTime = 500
  self.mouseXLast = nil
  self.mouseYLast = nil
  self.rotX = 0
  self.rotY = 0
  self.graphicsRotY = 0
  self.targetGraphicsRotY = 0
  self.height = 1.75
  self.camera = 0
  self.time = 0
  self.walkStepSolidGround = {}
  self.numWalkStepSolidGround = 0
  self.currentWalkStep = 0
  self.walkStepSolidGroundDuration = {}
  self.walkStepSolidGroundTimestamp = 0
  self.lastXPos = 0
  self.lastZPos = 0
  self.lastYPos = 0
  self.walkStepDistance = 0
  self.lightNode = 0
  self.clipDistance = 500
  self.lastTranslation = {
    0,
    0,
    0
  }
  self.targetTranslation = {
    0,
    0,
    0
  }
  self.interpolationAlpha = 0
  self.nextInterpolationTime = 0
  self.positionIsDirty = false
  self.lastAnimPosX = 0
  self.lastAnimPosY = 0
  self.lastAnimPosZ = 0
  self.animCharSet = 0
  self.animState = Player.ANIM_STATE_IDLE
  self.idleWeight = 1
  self.walkWeight = 0
  self.runWeight = 0
  self.crossFadeToIdleTime = 300
  self.crossFadeToWalkTime = 200
  self.crossFadeToRunTime = 200
  self.walkDistance = 0
  self.animUpdateTime = 0
  self.walkClipName = "runSource"
  self.idleClipName = "idleSource"
  self.runClipName = "runFastSource"
  self.animWalkSpeed = 3.05
  self.animRunSpeed = 5.05
  self.isHatVisible = false
  self.playerDirtyFlag = self:getNextDirtyFlag()
  self.debugFlightMode = false
  self.debugFlightCoolDown = 0
  self.isFrozen = false
  addConsoleCommand("gsToggleFlightAndNoHUDMode", "Enables/disables the flight (J) and no HUD (O) toggle keys", "Player.consoleCommandToggleFlightAndNoHUDMode", nil)
  return self
end
function Player:load(filename, x, y, z, rotX, rotY, isAbsolute, controllerName, creatorConnection)
  self.filename = filename
  self.controllerName = controllerName
  self.creatorConnection = creatorConnection
  self.rootNode = createTransformGroup("PlayerCCT")
  link(getRootNode(), self.rootNode)
  local i3dNode = loadI3DFile(filename)
  self.graphicsRootNode = getChildAt(i3dNode, 0)
  link(getRootNode(), self.graphicsRootNode)
  delete(i3dNode)
  self.skeletonRootNode = getChild(self.graphicsRootNode, "hips")
  if self.skeletonRootNode == 0 then
    print("Error: Failed to find skeleton root node in '" .. filename .. "'")
  end
  self.animationRootNode = getChild(self.graphicsRootNode, "animationRootNode")
  if self.animationRootNode == 0 then
    print("Error: Failed to find animation root node in '" .. filename .. "'")
  end
  link(self.animationRootNode, self.skeletonRootNode)
  self.meshNode = getChild(self.graphicsRootNode, "playerMesh")
  if self.meshNode == 0 then
    print("Error: Failed to find player mesh in '" .. filename .. "'")
  else
    link(getRootNode(), self.meshNode)
  end
  self.cameraId = getChild(self.graphicsRootNode, "playerCamera")
  if self.cameraId == 0 then
    print("Error: Failed to find player camera in '" .. filename .. "'")
  end
  self.camX, self.camY, self.camZ = getTranslation(self.cameraId)
  self.hatNode = getChild(self.meshNode, "playerHat")
  self.hairNode = getChild(self.meshNode, "playerHair")
  self.isHatVisible = false
  if self.hatNode ~= 0 and self.hairNode ~= 0 then
    local v = math.random(2)
    local hatVisible = false
    if v == 1 then
      hatVisible = true
    end
    self.isHatVisible = hatVisible
    setVisibility(self.hatNode, hatVisible)
    setVisibility(self.hairNode, not hatVisible)
  end
  self.animCharSet = getAnimCharacterSet(self.skeletonRootNode)
  if self.animCharSet ~= 0 then
    enableAnimTrack(self.animCharSet, 0)
    enableAnimTrack(self.animCharSet, 1)
    enableAnimTrack(self.animCharSet, 2)
    assignAnimTrackClip(self.animCharSet, 0, getAnimClipIndex(self.animCharSet, self.walkClipName))
    assignAnimTrackClip(self.animCharSet, 1, getAnimClipIndex(self.animCharSet, self.idleClipName))
    assignAnimTrackClip(self.animCharSet, 2, getAnimClipIndex(self.animCharSet, self.runClipName))
    setAnimTrackSpeedScale(self.animCharSet, 0, 0)
    setAnimTrackSpeedScale(self.animCharSet, 1, 1)
    setAnimTrackSpeedScale(self.animCharSet, 2, 0)
    setAnimTrackLoopState(self.animCharSet, 0, true)
    setAnimTrackLoopState(self.animCharSet, 1, true)
    setAnimTrackLoopState(self.animCharSet, 2, true)
    setAnimTrackTime(self.animCharSet, 0, 0)
    setAnimTrackTime(self.animCharSet, 1, 0)
    setAnimTrackTime(self.animCharSet, 2, 0)
    setAnimTrackBlendWeight(self.animCharSet, 0, self.walkWeight)
    setAnimTrackBlendWeight(self.animCharSet, 1, self.idleWeight)
    setAnimTrackBlendWeight(self.animCharSet, 2, self.runWeight)
  end
  if 0 < getNumOfChildren(self.cameraId) then
    self.lightNode = getChildAt(self.cameraId, 0)
    setVisibility(self.lightNode, false)
  end
  if rotX ~= nil and rotY ~= nil then
    self.rotX = rotX
    self.rotY = rotY
  else
    self.rotX = 0
    self.rotY = 0
  end
  if isAbsolute then
    self:moveToAbsolute(x, y, z)
  else
    self:moveTo(x, y, z)
  end
  self.mouseXLast = nil
  self.mouseYLast = nil
  self.swimPos = 0
  self.walkStepSolidGround[0] = createSample("walkStepSolidGround01")
  loadSample(self.walkStepSolidGround[0], "data/maps/sounds/walkStepSolidGround01.wav", false)
  self.walkStepSolidGroundDuration[0] = getSampleDuration(self.walkStepSolidGround[0])
  self.walkStepSolidGround[1] = createSample("walkStepSolidGround02")
  loadSample(self.walkStepSolidGround[1], "data/maps/sounds/walkStepSolidGround02.wav", false)
  self.walkStepSolidGroundDuration[1] = getSampleDuration(self.walkStepSolidGround[1])
  self.walkStepSolidGround[2] = createSample("walkStepSolidGround03")
  loadSample(self.walkStepSolidGround[2], "data/maps/sounds/walkStepSolidGround03.wav", false)
  self.walkStepSolidGroundDuration[2] = getSampleDuration(self.walkStepSolidGround[2])
  self.walkStepSolidGround[3] = createSample("walkStepSolidGround04")
  loadSample(self.walkStepSolidGround[3], "data/maps/sounds/walkStepSolidGround04.wav", false)
  self.walkStepSolidGroundDuration[3] = getSampleDuration(self.walkStepSolidGround[3])
  self.numWalkStepSolidGround = 4
  self.oceanWavesSample = createSample("oceanWaves")
  loadSample(self.oceanWavesSample, "data/maps/sounds/oceanWaves.wav", false)
  self.oceanWavesSamplePlaying = false
  local mass = 80
  self.controllerIndex = createCCT(self.rootNode, 0.2, self.height - 0.4, 0.6, 45, 0.1, Player.kinematicCollisionMask, mass)
end
function Player:delete()
  removeCCT(self.controllerIndex)
  delete(self.graphicsRootNode)
  delete(self.meshNode)
  delete(self.rootNode)
  delete(self.walkStepSolidGround[0])
  delete(self.walkStepSolidGround[1])
  delete(self.walkStepSolidGround[2])
  delete(self.walkStepSolidGround[3])
  delete(self.oceanWavesSample)
  self:deleteStartleAnimalData()
  self.mouseXLast = nil
  self.mouseYLast = nil
  self.lightNode = 0
end
function Player:readStream(streamId, connection)
  Player:superClass().readStream(self, streamId)
  local filename = Utils.convertFromNetworkFilename(streamReadString(streamId))
  local x = streamReadFloat32(streamId)
  local y = streamReadFloat32(streamId)
  local z = streamReadFloat32(streamId)
  local rotX = streamReadFloat32(streamId)
  local rotY = streamReadFloat32(streamId)
  local controllerName = streamReadString(streamId)
  local isControlled = streamReadBool(streamId)
  local isHatVisible = streamReadBool(streamId)
  if self.filename == nil then
    self:load(filename, x, y, z, rotX, rotY, true, controllerName, connection)
  else
    self:moveToAbsolute(x, y, z)
    self.rotY = rotY
    self.targetGraphicsRotY = rotY
    self.graphicsRotY = rotY
    setRotation(self.graphicsRootNode, 0, self.graphicsRotY, 0)
  end
  self.isHatVisible = isHatVisible
  if self.hatNode ~= 0 and self.hairNode ~= 0 then
    setVisibility(self.hatNode, isHatVisible)
    setVisibility(self.hairNode, not isHatVisible)
  end
  if isControlled then
    self:onEnter(false)
  end
end
function Player:writeStream(streamId, connection)
  Player:superClass().writeStream(self, streamId)
  streamWriteString(streamId, Utils.convertToNetworkFilename(self.filename))
  local x, y, z = getTranslation(self.rootNode)
  streamWriteFloat32(streamId, x)
  streamWriteFloat32(streamId, y)
  streamWriteFloat32(streamId, z)
  streamWriteFloat32(streamId, self.rotX)
  streamWriteFloat32(streamId, self.rotY)
  streamWriteString(streamId, self.controllerName)
  streamWriteBool(streamId, self.isControlled)
  streamWriteBool(streamId, self.isHatVisible)
end
function Player:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    local rotY = Utils.readCompressedAngle(streamId)
    local index = streamReadInt32(streamId)
    if not self.isEntered then
      self.rotY = rotY
      setTranslation(self.rootNode, x, y, z)
    else
      while self.history[1] ~= nil do
        if index >= self.history[1].index then
          table.remove(self.history, 1)
        else
          break
        end
      end
      setCCTPosition(self.controllerIndex, x, y, z)
      for i = 1, table.getn(self.history) do
        moveCCT(self.controllerIndex, self.history[i].movementX, self.history[i].movementY, self.history[i].movementZ, Player.movementCollisionMask, 0.4)
      end
      x, y, z = getTranslation(self.rootNode)
    end
    self.targetTranslation[1] = x
    self.targetTranslation[2] = y
    self.targetTranslation[3] = z
    local x, y, z = getTranslation(self.graphicsRootNode)
    self.lastTranslation[1] = x
    self.lastTranslation[2] = y
    self.lastTranslation[3] = z
    self.interpolationAlpha = 0
    self.positionIsDirty = true
  else
    local movementX = streamReadFloat32(streamId)
    local movementY = streamReadFloat32(streamId)
    local movementZ = streamReadFloat32(streamId)
    local rotY = Utils.readCompressedAngle(streamId)
    self.index = streamReadInt32(streamId)
    moveCCT(self.controllerIndex, movementX, movementY, movementZ, Player.movementCollisionMask)
    self.rotY = rotY
    local x, y, z = getTranslation(self.rootNode)
    self.targetTranslation[1] = x
    self.targetTranslation[2] = y
    self.targetTranslation[3] = z
    local x, y, z = getTranslation(self.graphicsRootNode)
    self.lastTranslation[1] = x
    self.lastTranslation[2] = y
    self.lastTranslation[3] = z
    self.interpolationAlpha = 0
    self.positionIsDirty = true
  end
end
function Player:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    local x, y, z = getTranslation(self.rootNode)
    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)
    Utils.writeCompressedAngle(streamId, self.rotY)
    streamWriteInt32(streamId, self.sendIndex)
  else
    streamWriteFloat32(streamId, self.movementX)
    streamWriteFloat32(streamId, self.movementY)
    streamWriteFloat32(streamId, self.movementZ)
    Utils.writeCompressedAngle(streamId, self.rotY)
    streamWriteInt32(streamId, self.index)
  end
end
function Player:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isEntered and self.isClient and self.mouseXLast ~= nil and self.mouseYLast ~= nil then
    self.rotX = self.rotX - (self.mouseYLast - posY)
    self.rotY = self.rotY - (posX - self.mouseXLast)
    self.mouseXLast = posX
    self.mouseYLast = posY
  end
end
function Player:update(dt)
  self.time = self.time + dt
  if self.isFrozen then
    return
  end
  if self.isEntered and self.isClient and g_gui.currentGui == nil then
    local inputZ = InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_LEFTRIGHT_PLAYER)
    local inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_UPDOWN_PLAYER)
    if InputBinding.isAxisZero(inputZ) then
      inputZ = InputBinding.getAnalogInputAxis(InputBinding.AXIS_LOOK_LEFTRIGHT_PLAYER)
    end
    if InputBinding.isAxisZero(inputW) then
      inputW = InputBinding.getAnalogInputAxis(InputBinding.AXIS_LOOK_UPDOWN_PLAYER)
    end
    local rotSpeed = 0.001 * dt
    self.rotX = self.rotX - rotSpeed * inputW
    self.rotY = self.rotY - rotSpeed * inputZ
    self.rotX = math.min(1.2, math.max(-1.5, self.rotX))
    setRotation(self.cameraId, self.rotX, 0, 0)
    setRotation(self.graphicsRootNode, 0, self.rotY, 0)
    wrapMousePosition(0.5, 0.5)
    self.mouseXLast = 0.5
    self.mouseYLast = 0.5
    local _, _, isOnGround = getCCTCollisionFlags(self.controllerIndex)
    if InputBinding.hasEvent(InputBinding.JUMP) and self.jumpFactor == 0 and isOnGround then
      self.lastJumpFactor = 0
      self.jumpFactor = self.jumpFactor + dt / self.jumpTime
    end
    if self.lightNode ~= 0 and InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
      setVisibility(self.lightNode, not getVisibility(self.lightNode))
    end
  end
  if self.isClient and self.isControlled then
    if self.positionIsDirty and self.nextInterpolationTime < self.time then
      self.interpolationAlpha = math.min(self.interpolationAlpha + dt / 55, 1)
      if self.interpolationAlpha == 1 then
        self.positionIsDirty = false
      end
      local x = self.lastTranslation[1] * (1 - self.interpolationAlpha) + self.targetTranslation[1] * self.interpolationAlpha
      local y = self.lastTranslation[2] * (1 - self.interpolationAlpha) + self.targetTranslation[2] * self.interpolationAlpha
      local z = self.lastTranslation[3] * (1 - self.interpolationAlpha) + self.targetTranslation[3] * self.interpolationAlpha
      setTranslation(self.graphicsRootNode, x, y, z)
    end
    if not self.isEntered then
      if g_gui.currentGui == nil then
        local x, y, z = getTranslation(self.rootNode)
        local x1, y1, z1 = getWorldTranslation(getCamera())
        local diffX = x - x1
        local diffY = y - y1
        local diffZ = z - z1
        dist = Utils.vector3LengthSq(diffX, diffY, diffZ)
        if dist <= 10000 then
          y = y + 1
          local sx, sy, sz = project(x, y, z)
          if sz <= 1 then
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextBold(false)
            setTextColor(0, 0, 0, 0.75)
            renderText(sx, sy - 0.0015, 0.02, self.controllerName)
            setTextColor(0.5, 1, 0.5, 1)
            renderText(sx, sy, 0.02, self.controllerName)
            setTextAlignment(RenderText.ALIGN_LEFT)
          end
        end
      end
      local animDt = 60
      self.animUpdateTime = self.animUpdateTime + dt
      if animDt < self.animUpdateTime and self.animCharSet ~= 0 then
        local x, y, z = getTranslation(self.graphicsRootNode)
        local dirX, dirZ = -math.sin(self.rotY), -math.cos(self.rotY)
        local dx, _, dz = x - self.lastAnimPosX, y - self.lastAnimPosY, z - self.lastAnimPosZ
        local movementDist = dx * dirX + dz * dirZ
        if dx * dx + dz * dz < 0.001 then
          self.targetGraphicsRotY = self.rotY
        elseif -0.001 < movementDist then
          self.targetGraphicsRotY = math.atan2(-dx, -dz)
        else
          self.targetGraphicsRotY = math.atan2(dx, dz)
        end
        local dirX, dirZ = -math.sin(self.targetGraphicsRotY), -math.cos(self.targetGraphicsRotY)
        local dx, _, dz = x - self.lastAnimPosX, y - self.lastAnimPosY, z - self.lastAnimPosZ
        local movementDist = dx * dirX + dz * dirZ
        movementDist = self.walkDistance * 0.2 + movementDist * 0.8
        self.walkDistance = movementDist
        local walkSpeed = movementDist / (animDt * 0.001 * self.animWalkSpeed)
        local runSpeed = movementDist / (animDt * 0.001 * self.animRunSpeed)
        if math.abs(walkSpeed) < 0.1 then
          walkSpeed = 0
          runSpeed = 0
          self.animState = Player.ANIM_STATE_IDLE
        elseif math.abs(walkSpeed) > 1.9 then
          self.animState = Player.ANIM_STATE_RUN
        else
          self.animState = Player.ANIM_STATE_WALK
        end
        setAnimTrackSpeedScale(self.animCharSet, 0, walkSpeed)
        setAnimTrackSpeedScale(self.animCharSet, 2, runSpeed)
        if self.animState == Player.ANIM_STATE_IDLE then
          self.idleWeight = math.min(self.idleWeight + animDt / self.crossFadeToIdleTime, 1)
          if self.runWeight > 1.0E-4 then
            self.walkWeight = (1 - self.idleWeight) / (1 + self.walkWeight / self.runWeight)
          else
            self.walkWeight = 1 - self.idleWeight
          end
          self.runWeight = 1 - self.walkWeight - self.idleWeight
        elseif self.animState == Player.ANIM_STATE_WALK then
          self.walkWeight = math.min(self.walkWeight + animDt / self.crossFadeToWalkTime, 1)
          if self.runWeight > 1.0E-4 then
            self.idleWeight = (1 - self.walkWeight) / (1 + self.idleWeight / self.runWeight)
          else
            self.idleWeight = 1 - self.walkWeight
          end
          self.runWeight = 1 - self.walkWeight - self.idleWeight
        elseif self.animState == Player.ANIM_STATE_RUN then
          self.runWeight = math.min(self.runWeight + animDt / self.crossFadeToRunTime, 1)
          if 1.0E-4 < self.walkWeight then
            self.idleWeight = (1 - self.runWeight) / (1 + self.idleWeight / self.walkWeight)
          else
            self.idleWeight = 1 - self.runWeight
          end
          self.walkWeight = 1 - self.runWeight - self.idleWeight
        end
        setAnimTrackBlendWeight(self.animCharSet, 0, self.walkWeight)
        setAnimTrackBlendWeight(self.animCharSet, 1, self.idleWeight)
        setAnimTrackBlendWeight(self.animCharSet, 2, self.runWeight)
        self.lastAnimPosX = x
        self.lastAnimPosY = y
        self.lastAnimPosZ = z
        while animDt < self.animUpdateTime do
          self.animUpdateTime = self.animUpdateTime - animDt
        end
      end
      local maxDeltaRotY = math.rad(0.5) * dt
      self.targetGraphicsRotY = Utils.normalizeRotationForShortestPath(self.targetGraphicsRotY, self.graphicsRotY)
      self.graphicsRotY = math.min(math.max(self.targetGraphicsRotY, self.graphicsRotY - maxDeltaRotY), self.graphicsRotY + maxDeltaRotY)
      setRotation(self.graphicsRootNode, 0, self.graphicsRotY, 0)
    end
  end
end
function Player:updateTick(dt)
  if self.isEntered and self.isClient and g_gui.currentGui == nil then
    if self.isFrozen then
      return
    end
    self.movementX = 0
    self.movementY = self.gravity * dt
    self.movementZ = 0
    local inputX = InputBinding.getDigitalInputAxis(InputBinding.AXIS_MOVE_SIDE_PLAYER)
    local inputY = InputBinding.getDigitalInputAxis(InputBinding.AXIS_MOVE_FORWARD_PLAYER)
    if InputBinding.isAxisZero(inputX) then
      inputX = InputBinding.getAnalogInputAxis(InputBinding.AXIS_MOVE_SIDE_PLAYER)
    end
    if InputBinding.isAxisZero(inputY) then
      inputY = InputBinding.getAnalogInputAxis(InputBinding.AXIS_MOVE_FORWARD_PLAYER)
    end
    local len = Utils.vector2Length(inputX, inputY)
    if 1 < len then
      inputX = inputX / len
      inputY = inputY / len
    end
    if InputBinding.isPressed(InputBinding.RUN) and inputY <= 0 then
      if g_isDevelopmentVersion then
        self.runningFactor = 16
      else
        self.runningFactor = 2
      end
    else
      self.runningFactor = 1
    end
    if 0 < self.jumpFactor then
      self.lastJumpFactor = self.jumpFactor
      self.jumpFactor = self.jumpFactor + dt / self.jumpTime
      if 1 <= self.jumpFactor then
        self.jumpFactor = 0
      end
    end
    if 0 < self.jumpFactor then
      local value1 = self.jumpFactor
      local value2 = self.lastJumpFactor
      local i1 = value1 - value1 * value1 / 2
      local i2 = value2 - value2 * value2 / 2
      local currentJumpMovement = (i1 - i2) * 18
      self.movementY = self.movementY + currentJumpMovement
    end
    if self.debugFlightCoolDown == 0 then
      if g_flightAndNoHUDKeysEnabled and Input.isKeyPressed(Input.KEY_j) then
        self.debugFlightMode = not self.debugFlightMode
        self.debugFlightCoolDown = 10
      end
    else
      self.debugFlightCoolDown = self.debugFlightCoolDown - 1
    end
    if self.debugFlightMode then
      self.movementY = 0
      if Input.isKeyPressed(Input.KEY_q) then
        self.movementY = 0.5 * self.walkingSpeed * dt * self.runningFactor
      end
      if Input.isKeyPressed(Input.KEY_e) then
        self.movementY = -0.5 * self.walkingSpeed * dt * self.runningFactor
      end
    end
    local dz = inputY * self.walkingSpeed * dt * self.runningFactor
    local dx = inputX * self.walkingSpeed * dt * self.runningFactor
    self.movementX = math.sin(self.rotY) * dz + math.cos(self.rotY) * dx
    self.movementZ = math.cos(self.rotY) * dz - math.sin(self.rotY) * dx
    local xt, yt, zt = getTranslation(self.rootNode)
    local swimYoffset = 0
    local waterY = g_currentMission.waterY
    local deltaWater = yt - waterY
    local wavesMax = 2
    local wavesMin = -4
    if deltaWater < wavesMax then
      if not self.oceanWavesSamplePlaying then
        playSample(self.oceanWavesSample, 0, 0, 0)
        self.oceanWavesSamplePlaying = true
      end
      local volume = 0.5
      if 0 < deltaWater then
        volume = (wavesMax - deltaWater) / wavesMax * 0.5
      else
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.lastXPos, 0, self.lastZPos) - waterY
        if wavesMin > height then
          volume = 0
        else
          volume = (wavesMin - height) / wavesMin
        end
      end
      setSampleVolume(self.oceanWavesSample, volume)
    elseif self.oceanWavesSamplePlaying then
      stopSample(self.oceanWavesSample)
      self.oceanWavesSamplePlaying = false
    end
    if deltaWater < 0 then
      if deltaWater < -0.6 then
        deltaWater = -0.6
        setTranslation(self.rootNode, xt, waterY + deltaWater, zt)
      end
      self.movementY = 0
      self.swimPos = self.swimPos + Utils.vector2Length(dx, dz)
      swimYoffset = math.sin(self.swimPos) * 0.27 + math.sin(self.time * 0.003) * 0.06
      if deltaWater < -0.1 then
        self.movementY = -self.gravity * 0.08 * dt * deltaWater * deltaWater
      end
    end
    local dist = 0.5
    if deltaWater < dist and 0 <= deltaWater then
      swimYoffset = swimYoffset * ((dist - deltaWater) / dist)
    end
    setTranslation(self.cameraId, self.camX, self.camY + swimYoffset, self.camZ)
    self.walkStepDistance = self.walkStepDistance + Utils.vector2Length(self.lastXPos - xt, self.lastZPos - zt)
    local walkStepVolume = 0.35
    if 0 <= deltaWater and 2 < self.walkStepDistance and self.walkStepSolidGroundTimestamp < self.time then
      local pitch = math.random(0.8, 1.1)
      local volume = math.random(0.75, 1)
      local delay = math.random(0, 30)
      setSamplePitch(self.walkStepSolidGround[self.currentWalkStep], pitch)
      playSample(self.walkStepSolidGround[self.currentWalkStep], 1, volume * walkStepVolume, delay)
      self.walkStepDistance = 0
      self.walkStepSolidGroundTimestamp = self.time + self.walkStepSolidGroundDuration[self.currentWalkStep] * pitch + delay
      local last = self.currentWalkStep
      while last == self.currentWalkStep do
        self.currentWalkStep = math.floor(math.random(0, self.numWalkStepSolidGround - 1.00001))
      end
    end
    local x, y, z = getTranslation(self.graphicsRootNode)
    self.lastTranslation[1] = x
    self.lastTranslation[2] = y
    self.lastTranslation[3] = z
    self.targetTranslation[1] = xt
    self.targetTranslation[2] = yt
    self.targetTranslation[3] = zt
    self.interpolationAlpha = 0
    self.positionIsDirty = true
    self.lastXPos = xt
    self.lastYPos = yt
    self.lastZPos = zt
    moveCCT(self.controllerIndex, self.movementX, self.movementY, self.movementZ, 1048607, 0.4)
    self.index = self.index + 1
    table.insert(self.history, {
      index = self.index,
      movementX = self.movementX,
      movementY = self.movementY,
      movementZ = self.movementZ
    })
    if table.getn(self.history) > 200 then
      for i = 100, 1, -1 do
        table.remove(self.history, i)
      end
    end
    self:raiseDirtyFlags(self.playerDirtyFlag)
  elseif self.isServer and self.index ~= -1 then
    self.sendIndex = self.index
    self:raiseDirtyFlags(self.playerDirtyFlag)
    self.index = -1
  end
end
function Player:moveTo(x, yOffset, z)
  local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z)
  local y = terrainHeight + yOffset + self.height * 0.5
  self:moveToAbsoluteInternal(x, y, z)
end
function Player:moveToAbsolute(x, y, z)
  self:moveToAbsoluteInternal(x, y + self.height * 0.5, z)
end
function Player:moveToAbsoluteInternal(x, y, z)
  setTranslation(self.rootNode, x, y, z)
  setTranslation(self.graphicsRootNode, x, y, z)
  self.lastTranslation = {
    x,
    y,
    z
  }
  self.targetTranslation = {
    x,
    y,
    z
  }
  self.interpolationAlpha = 0
  self.nextInterpolationTime = self.time + 100
  self.positionIsDirty = false
  self.lastXPos = x
  self.lastYPos = y
  self.lastZPos = z
  self.lastAnimPosX = x
  self.lastAnimPosY = y
  self.lastAnimPosZ = z
  self.walkDistance = 0
end
function Player:draw()
end
function Player:onEnter(isControlling)
  self.isControlled = true
  if isControlling then
    setCamera(self.cameraId)
    self.isEntered = true
    self:setVisibility(false)
  else
    self:setVisibility(true)
  end
end
function Player:onLeave()
  self.isControlled = false
  self.isEntered = false
  self:setVisibility(false)
  if self.lightNode ~= 0 then
    setVisibility(self.lightNode, false)
  end
  self:moveToAbsolute(0, -200, 0)
  if self.oceanWavesSamplePlaying then
    stopSample(self.oceanWavesSample)
    self.oceanWavesSamplePlaying = false
  end
end
function Player:setVisibility(visibility)
  setVisibility(self.meshNode, visibility)
  setVisibility(self.animationRootNode, visibility)
end
function Player:moveToExitPoint(exitVehicle)
  local x, y, z = getWorldTranslation(exitVehicle.exitPoint)
  local dx, dy, dz = localDirectionToWorld(exitVehicle.exitPoint, 0, 0, 1)
  y = y + 0.9
  self:moveToAbsolute(x, y, z)
  self.rotY = Utils.getYRotationFromDirection(dx, dz) + math.pi
  self.targetGraphicsRotY = self.rotY
  self.graphicsRotY = self.rotY
  setRotation(self.graphicsRootNode, 0, self.graphicsRotY, 0)
end
function Player:testScope(x, y, z, coeff)
  local x1, y1, z1 = getTranslation(self.rootNode)
  local dist = Utils.vector3Length(x1 - x, y1 - y, z1 - z)
  local clipDist = self.clipDistance
  if dist < clipDist * clipDist then
    return true
  else
    return false
  end
end
function Player:onGhostRemove()
  self:delete()
end
function Player:onGhostAdd()
end
function Player:getUpdatePriority(skipCount, x, y, z, coeff, connection)
  if self.owner == connection then
    return 50
  end
  local x1, y1, z1 = getTranslation(self.rootNode)
  local dist = Utils.vector3Length(x1 - x, y1 - y, z1 - z)
  local clipDist = self.clipDistance
  return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end
function Player.consoleCommandToggleFlightAndNoHUDMode(unusedSelf)
  g_flightAndNoHUDKeysEnabled = not g_flightAndNoHUDKeysEnabled
  return "PlayerFlightAndNoHUDMode = " .. tostring(g_flightAndNoHUDKeysEnabled)
end
function Player:playStartleAnimalSound(use3DSound)
  if self.startleAnimalSoundNode then
    return
  end
  local availableSounds = AnimalHusbandry.startleAnimalSounds
  local playerNode = self.rootNode
  local soundCount = table.getn(availableSounds)
  if 0 < soundCount then
    local soundData = availableSounds[math.random(soundCount)]
    local soundFilenameToPlay = soundData.filename
    local volume = math.random() * (soundData.maxVolume - soundData.minVolume) + soundData.minVolume
    local pitch = math.random() * (soundData.maxPitch - soundData.minPitch) + soundData.minPitch
    local sample
    if use3DSound then
      local outerRadius = 25
      local innerRadius = 5
      self.startleAnimalSoundNode = createAudioSource(soundFilenameToPlay, soundFilenameToPlay, outerRadius, innerRadius, volume, 1)
      sample = getAudioSourceSample(startleAnimalSoundNode)
      setSamplePitch(sample, pitch)
      link(playerNode, self.startleAnimalSoundNode)
    else
      sample = createSample(soundFilenameToPlay)
      self.startleAnimalSoundNode = sample
      loadSample(self.startleAnimalSoundNode, soundFilenameToPlay, false)
      setSamplePitch(self.startleAnimalSoundNode, pitch)
      playSample(self.startleAnimalSoundNode, 1, volume, 0)
    end
    local sampleDuration = getSampleDuration(sample)
    if 0.5 < pitch then
      sampleDuration = sampleDuration * (1 / pitch)
    end
    self.startleAnimalSoundTimerId = addTimer(sampleDuration, "deleteStartleAnimalSound", self)
  end
end
function Player:deleteStartleAnimalData()
  if self.startleAnimalSoundTimerId then
    removeTimer(self.startleAnimalSoundTimerId)
    self.startleAnimalSoundTimerId = nil
  end
  self:deleteStartleAnimalSound()
end
function Player:deleteStartleAnimalSound()
  if self.startleAnimalSoundNode then
    stopSample(self.startleAnimalSoundNode)
    delete(self.startleAnimalSoundNode)
    self.startleAnimalSoundNode = nil
  end
  self.startleAnimalSoundTimerId = nil
end
