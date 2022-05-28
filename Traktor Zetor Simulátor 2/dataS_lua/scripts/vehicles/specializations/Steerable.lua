Steerable = {}
source("dataS/scripts/vehicles/specializations/SteerableSetSpeedLevelEvent.lua")
source("dataS/scripts/vehicles/specializations/SteerableToggleLightEvent.lua")
source("dataS/scripts/vehicles/specializations/SteerableToggleRefuelEvent.lua")
function Steerable.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Motorized, specializations)
end
function Steerable:load(xmlFile)
  self.onEnter = SpecializationUtil.callSpecializationsFunction("onEnter")
  self.onLeave = SpecializationUtil.callSpecializationsFunction("onLeave")
  self.setLights = SpecializationUtil.callSpecializationsFunction("setLights")
  self.drawGrainLevel = SpecializationUtil.callSpecializationsFunction("drawGrainLevel")
  self.isControlled = false
  self.enterReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.enterReferenceNode#index"))
  self.exitPoint = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.exitPoint#index"))
  self.steering = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.steering#index"))
  if self.steering ~= nil then
    self.steeringSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.steering#rotationSpeed"), 0)
  end
  self.numCameras = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cameras#count"), 0)
  if self.numCameras == 0 then
    print("Error: No cameras in xml file: " .. self.configFileName)
  end
  self.cameras = {}
  for i = 1, self.numCameras do
    local cameranamei = string.format("vehicle.cameras.camera%d", i)
    local camera = VehicleCamera:new(self)
    if camera:loadFromXML(xmlFile, cameranamei) then
      table.insert(self.cameras, camera)
    end
  end
  self.numCameras = table.getn(self.cameras)
  self.camIndex = 1
  self.tipCamera = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.tipCamera#index"))
  self.characterNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.characterNode#index"))
  if self.characterNode ~= nil then
    self.characterCameraMinDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.characterNode#cameraMinDistance"), 1.5)
    setVisibility(self.characterNode, false)
  end
  self.nicknameRenderNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.nicknameRenderNode#index"))
  self.nicknameRenderNodeOffset = Utils.getVectorNFromString(getXMLString(xmlFile, "vehicle.nicknameRenderNode#offset"), 3)
  if self.nicknameRenderNode == nil then
    if self.characterNode ~= nil then
      self.nicknameRenderNode = self.characterNode
      if self.nicknameRenderNodeOffset == nil then
        self.nicknameRenderNodeOffset = {
          0,
          1.5,
          0
        }
      end
    else
      self.nicknameRenderNode = self.components[1].node
    end
  end
  if self.nicknameRenderNodeOffset == nil then
    self.nicknameRenderNodeOffset = {
      0,
      4,
      0
    }
  end
  self.speedRotScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.speedRotScale#scale"), 80)
  self.speedRotScaleOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.speedRotScale#offset"), 0.7)
  self.maxRotatedTimeSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.maxRotatedTimeSpeed#value"), 2) * 0.001
  self.maxAccelerationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.accelerationSpeed#maxAcceleration"), 2) * 0.001
  self.decelerationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.accelerationSpeed#deceleration"), 0.5) * 0.001
  self.backwardMaxAccelerationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.accelerationSpeed#backwardMaxAcceleration"), self.maxAccelerationSpeed * 1000) * 0.001
  self.backwardDecelerationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.accelerationSpeed#backwardDeceleration"), self.decelerationSpeed * 1000) * 0.001
  self.lastAcceleration = 0
  self.lastRealAcceleration = 0
  self.isEntered = false
  self.controllerName = "Unknown"
  self.steeringEnabled = true
  self.stopMotorOnLeave = true
  self.disableCharacterOnLeave = true
  self.deactivateOnLeave = true
  self.deactivateLightsOnLeave = true
  self.showWaterWarning = false
  self.waterSplashSample = nil
  self.axisForward = 0
  self.axisForwardIsAnalog = false
  self.axisSide = 0
  self.axisSideIsAnalog = false
  self.hudBasePosX = 0.7543
  self.hudBasePosY = 0.01238
  self.hudBaseWidth = 0.2371
  self.hudBaseHeight = 0.1581
  self.hudBarWidth = 0.205
  self.hudBarHeight = 0.0219
  self.hudBarOffsetX = 0.023571
  self.hudBarStartOffsetY = 0.0085714
  self.hudBarOffsetY = 0.0395
  self.hudBackgroundOverlay = Overlay:new("hudBackgroundOverlay", "dataS2/menu/hud/vehicleHUD_background.png", self.hudBasePosX, self.hudBasePosY, self.hudBaseWidth, self.hudBaseHeight)
  self.hudFramesOverlay = Overlay:new("hudFramesOverlay", "dataS2/menu/hud/vehicleHUD_frames.png", self.hudBasePosX, self.hudBasePosY, self.hudBaseWidth, self.hudBaseHeight)
  self.hudBarGreenOverlay = Overlay:new("hudBarGreenOverlay", "dataS2/menu/hud/vehicleHUD_barGreen.png", self.hudBasePosX + self.hudBarOffsetX, self.hudBasePosY + self.hudBarStartOffsetY, self.hudBarWidth, self.hudBarHeight)
  self.hudBarGoldOverlay = Overlay:new("hudBarGoldOverlay", "dataS2/menu/hud/vehicleHUD_barGold.png", self.hudBasePosX + self.hudBarOffsetX, self.hudBasePosY + self.hudBarStartOffsetY + 1 * self.hudBarOffsetY, self.hudBarWidth, self.hudBarHeight)
  self.hudBarRedOverlay = Overlay:new("hudBarRedOverlay", "dataS2/menu/hud/vehicleHUD_barRed.png", self.hudBasePosX + self.hudBarOffsetX, self.hudBasePosY + self.hudBarStartOffsetY + 3 * self.hudBarOffsetY, self.hudBarWidth, self.hudBarHeight)
  self.steerableGroundFlag = self.nextDirtyFlag
  self.nextDirtyFlag = self.steerableGroundFlag * 2
end
function Steerable:delete()
  for _, camera in ipairs(self.cameras) do
    camera:delete()
  end
  if self.waterSplashSample ~= nil then
    delete(self.waterSplashSample)
  end
  if self.toggleLightsSound ~= nil then
    delete(self.toggleLightsSound)
  end
  if self.hudBackgroundOverlay then
    self.hudBackgroundOverlay:delete()
  end
  if self.hudFramesOverlay then
    self.hudFramesOverlay:delete()
  end
end
function Steerable:readStream(streamId, connection)
  local isControlled = streamReadBool(streamId)
  if isControlled then
    self.controllerName = streamReadString(streamId)
    self:onEnter(false)
  end
end
function Steerable:writeStream(streamId, connection)
  if streamWriteBool(streamId, self.isControlled) then
    streamWriteString(streamId, self.controllerName)
  end
end
function Steerable:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
  else
    local hasSteerableUpdate = streamReadBool(streamId)
    if hasSteerableUpdate then
      local axisForwardIsAnalog = streamReadBool(streamId)
      local axisSideIsAnalog = streamReadBool(streamId)
      local axisForward = streamReadFloat32(streamId)
      local axisSide = streamReadFloat32(streamId)
      local dt = streamReadFloat32(streamId)
      if self.steeringEnabled then
        Steerable.updateVehiclePhysics(self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt)
      end
    end
  end
end
function Steerable:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
  elseif bitAND(dirtyMask, self.steerableGroundFlag) ~= 0 then
    streamWriteBool(streamId, true)
    streamWriteBool(streamId, self.axisForwardIsAnalog)
    streamWriteBool(streamId, self.axisSideIsAnalog)
    streamWriteFloat32(streamId, self.axisForward)
    streamWriteFloat32(streamId, self.axisSide)
    streamWriteFloat32(streamId, self.tickDt)
  else
    streamWriteBool(streamId, false)
  end
end
function Steerable:mouseEvent(posX, posY, isDown, isUp, button)
  self.cameras[self.camIndex]:mouseEvent(posX, posY, isDown, isUp, button)
end
function Steerable:keyEvent(unicode, sym, modifier, isDown)
end
function Steerable:update(dt)
  if self:getIsActive() then
    if self.steering ~= nil then
      setRotation(self.steering, 0, self.rotatedTime * self.steeringSpeed, 0)
    end
    local xt, yt, zt = getTranslation(self.components[1].node)
    local deltaWater = yt - g_currentMission.waterY + 2.5
    if deltaWater < 0 then
      self.isBroken = true
      g_currentMission:onSunkVehicle(self)
      if self.isEntered then
        g_currentMission:onLeaveVehicle()
        if self:getIsActiveForSound() then
          local volume = math.min(1, self.lastSpeed * 3600 / 30)
          if self.waterSplashSample == nil then
            self.waterSplashSample = createSample("waterSplashSample")
            loadSample(self.waterSplashSample, "data/maps/sounds/waterSplash.wav", false)
          end
          playSample(self.waterSplashSample, 1, volume, 0)
        end
      end
    end
    self.showWaterWarning = deltaWater < 2
    if self.isClient and self.isControlled and not self.isEntered and g_gui.currentGui == nil then
      local x, y, z = getWorldTranslation(self.nicknameRenderNode)
      local x1, y1, z1 = getWorldTranslation(getCamera())
      local distSq = Utils.vector3LengthSq(x - x1, y - y1, z - z1)
      if distSq <= 10000 then
        x = x + self.nicknameRenderNodeOffset[1]
        y = y + self.nicknameRenderNodeOffset[2]
        z = z + self.nicknameRenderNodeOffset[3]
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
    if self.isServer and not self:getIsHired() and 0 < self.lastMovedDistance then
      local fuelUsed = self.lastMovedDistance * self.fuelUsage
      self:setFuelFillLevel(self.fuelFillLevel - fuelUsed)
      g_currentMission.missionStats.fuelUsageTotal = g_currentMission.missionStats.fuelUsageTotal + fuelUsed
      g_currentMission.missionStats.fuelUsageSession = g_currentMission.missionStats.fuelUsageSession + fuelUsed
      g_currentMission.missionStats.traveledDistanceTotal = g_currentMission.missionStats.traveledDistanceTotal + self.lastMovedDistance * 0.001
      g_currentMission.missionStats.traveledDistanceSession = g_currentMission.missionStats.traveledDistanceSession + self.lastMovedDistance * 0.001
    end
  end
  if self:getIsActiveForInput() and self.isClient then
    setCamera(self.cameras[self.camIndex].cameraNode)
    self.cameras[self.camIndex]:update(dt)
    if InputBinding.hasEvent(InputBinding.SWITCH_IMPLEMENT) then
      local selected = self.selectedImplement
      local numImplements = table.getn(self.attachedImplements)
      if selected ~= 0 and 1 < numImplements then
        selected = selected + 1
        if numImplements < selected then
          selected = 1
        end
        self:setSelectedImplement(selected)
      end
    end
    if InputBinding.hasEvent(InputBinding.CAMERA_SWITCH) then
      self.cameras[self.camIndex]:onDeactivate()
      self.camIndex = self.camIndex + 1
      if self.camIndex > self.numCameras then
        self.camIndex = 1
      end
      self.cameras[self.camIndex]:onActivate()
    end
    if self.cameras[self.camIndex].allowTranslation then
      if InputBinding.isPressed(InputBinding.CAMERA_ZOOM_IN) then
        if InputBinding.getInputTypeOfDigitalAction(InputBinding.CAMERA_ZOOM_IN) == InputBinding.INPUTTYPE_MOUSE_WHEEL then
          self.cameras[self.camIndex]:zoomSmoothly(-0.6)
        else
          self.cameras[self.camIndex]:zoomSmoothly(-0.005 * dt)
        end
      elseif InputBinding.isPressed(InputBinding.CAMERA_ZOOM_OUT) then
        if InputBinding.getInputTypeOfDigitalAction(InputBinding.CAMERA_ZOOM_OUT) == InputBinding.INPUTTYPE_MOUSE_WHEEL then
          self.cameras[self.camIndex]:zoomSmoothly(0.6)
        else
          self.cameras[self.camIndex]:zoomSmoothly(0.005 * dt)
        end
      end
    end
    if InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
      if not self.toggleLightsSound then
        self.toggleLightsSound = createSample("toggleLightsSound")
        loadSample(self.toggleLightsSound, "dataS2/sounds/switchFlashlight.wav", false)
        setSamplePitch(self.toggleLightsSound, 0.5)
      end
      playSample(self.toggleLightsSound, 1, 1, 0)
      self:setLightsVisibility(not self.lightsActive)
    end
    if InputBinding.hasEvent(InputBinding.TOGGLE_BEACON_LIGHTS) then
      self:setBeaconLightsVisibility(not self.beaconLightsActive)
    end
    local speedLevel = 0
    if InputBinding.hasEvent(InputBinding.SPEED_LEVEL1) then
      speedLevel = 1
    elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL2) then
      speedLevel = 2
    elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL3) then
      speedLevel = 3
    elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL4) then
      speedLevel = 4
    end
    if speedLevel ~= 0 then
      Steerable.setSpeedLevel(self, speedLevel)
      if not self.isServer then
        g_client:getServerConnection():sendEvent(SteerableSetSpeedLevelEvent:new(self, speedLevel))
      end
    end
    if InputBinding.hasEvent(InputBinding.ATTACH) then
      self:handleAttachEvent()
    end
    if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
      self:handleLowerImplementEvent()
    end
    if self.characterNode ~= nil then
      local cx, cy, cz = getWorldTranslation(self.characterNode)
      local x, y, z = getWorldTranslation(getCamera())
      local dist = Utils.vector3Length(cx - x, cy - y, cz - z)
      if dist < self.characterCameraMinDistance then
        setVisibility(self.characterNode, false)
      else
        setVisibility(self.characterNode, true)
      end
    end
  end
end
function Steerable:updateTick(dt)
  if self.isEntered and self.isClient then
    self.axisForward = InputBinding.getDigitalInputAxis(InputBinding.AXIS_MOVE_FORWARD_VEHICLE)
    self.axisForwardIsAnalog = false
    if InputBinding.isAxisZero(self.axisForward) then
      self.axisForward = InputBinding.getAnalogInputAxis(InputBinding.AXIS_MOVE_FORWARD_VEHICLE)
      self.axisForwardIsAnalog = true
    end
    self.axisSide = InputBinding.getDigitalInputAxis(InputBinding.AXIS_MOVE_SIDE_VEHICLE)
    self.axisSideIsAnalog = false
    if InputBinding.isAxisZero(self.axisSide) then
      self.axisSide = InputBinding.getAnalogInputAxis(InputBinding.AXIS_MOVE_SIDE_VEHICLE)
      self.axisSideIsAnalog = true
    end
    if self.isServer then
      if self.steeringEnabled then
        Steerable.updateVehiclePhysics(self, self.axisForward, self.axisForwardIsAnalog, self.axisSide, self.axisSideIsAnalog, dt)
      end
    else
      if self.steeringEnabled and math.abs(self.axisForward) > 0.8 then
        self.motor:setSpeedLevel(0, true)
      end
      self.motor:computeMotorRpm(self.wheelRpm, self.axisForward)
      self:raiseDirtyFlags(self.steerableGroundFlag)
    end
  end
end
function Steerable:calculateRealAcceleration(acceleration, dt)
  local maxAccelerationSpeed = self.maxAccelerationSpeed
  local decelerationSpeed = self.decelerationSpeed
  if self.movingDirection < 0 then
    maxAccelerationSpeed = self.backwardMaxAccelerationSpeed
    decelerationSpeed = self.backwardDecelerationSpeed
  end
  if math.abs(acceleration) > 1.0E-4 then
    if Utils.sign(acceleration) ~= Utils.sign(self.lastAcceleration) then
      self.lastAcceleration = 0
    end
    acceleration = math.min(math.max(acceleration, self.lastAcceleration - dt * maxAccelerationSpeed), self.lastAcceleration + dt * maxAccelerationSpeed)
    self.lastAcceleration = acceleration
  elseif 0 < self.lastAcceleration then
    self.lastAcceleration = math.max(self.lastAcceleration - dt * decelerationSpeed, 0)
  elseif 0 > self.lastAcceleration then
    self.lastAcceleration = math.min(self.lastAcceleration + dt * decelerationSpeed, 0)
  end
  self.lastRealAcceleration = acceleration
  return acceleration
end
function Steerable:updateVehiclePhysics(axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt)
  local acceleration = 0
  if self.isMotorStarted and self.motorStartTime <= self.time then
    acceleration = -axisForward
    if math.abs(acceleration) > 0.8 then
      if self.motor.speedLevel ~= 0 then
        self.lastAcceleration = self.lastAcceleration * 0.5
      end
      self.motor:setSpeedLevel(0, true)
    end
    if self.motor.speedLevel ~= 0 then
      acceleration = self.motor.accelerations[self.motor.speedLevel]
    end
  end
  if self.fuelFillLevel == 0 then
    acceleration = 0
  end
  acceleration = Steerable.calculateRealAcceleration(self, acceleration, dt)
  local inputAxisX = axisSide
  if axisSideIsAnalog then
    local targetRotatedTime = 0
    if inputAxisX < 0 then
      targetRotatedTime = math.min(-self.maxRotTime * inputAxisX, self.maxRotTime)
    else
      targetRotatedTime = math.max(self.minRotTime * inputAxisX, self.minRotTime)
    end
    local maxTime = self.maxRotatedTimeSpeed * dt
    if maxTime < math.abs(targetRotatedTime - self.rotatedTime) then
      if targetRotatedTime > self.rotatedTime then
        self.rotatedTime = self.rotatedTime + maxTime
      else
        self.rotatedTime = self.rotatedTime - maxTime
      end
    else
      self.rotatedTime = targetRotatedTime
    end
  else
    local rotScale = math.min(1 / (self.lastSpeed * self.speedRotScale + self.speedRotScaleOffset), 1)
    if inputAxisX < 0 then
      self.rotatedTime = math.min(self.rotatedTime - dt / 1000 * inputAxisX * rotScale, self.maxRotTime)
    elseif 0 < inputAxisX then
      self.rotatedTime = math.max(self.rotatedTime - dt / 1000 * inputAxisX * rotScale, self.minRotTime)
    elseif self.autoRotateBackSpeed ~= 0 then
      if 0 < self.rotatedTime then
        self.rotatedTime = math.max(self.rotatedTime - dt / 1000 * self.autoRotateBackSpeed * rotScale, 0)
      else
        self.rotatedTime = math.min(self.rotatedTime + dt / 1000 * self.autoRotateBackSpeed * rotScale, 0)
      end
    end
  end
  if self.firstTimeRun then
    WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeed, acceleration, false, self.requiredDriveMode)
  end
end
function Steerable:draw()
  local kmh = math.min(100, math.max(0, self.lastSpeed * self.speedDisplayScale * 3600))
  self.hudBackgroundOverlay:render()
  setTextBold(true)
  setTextColor(1, 1, 1, 1)
  setTextAlignment(RenderText.ALIGN_CENTER)
  local maxSpeed = 80
  setTextColor(0, 0, 0, 1)
  renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.005 + 0.11880000000000002, 0.024, string.format("%2d " .. g_i18n:getText("speedometer"), kmh))
  setTextColor(1, 1, 1, 1)
  renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.008 + 0.11880000000000002, 0.024, string.format("%2d " .. g_i18n:getText("speedometer"), kmh))
  self.hudBarRedOverlay.width = self.hudBarWidth * math.min(1, kmh / maxSpeed)
  setOverlayUVs(self.hudBarRedOverlay.overlayId, 0, 0.05, 0, 1, math.min(1, kmh / maxSpeed), 0.05, math.min(1, kmh / maxSpeed), 1)
  self.hudBarRedOverlay:render()
  setTextColor(0, 0, 0, 1)
  renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.005 + 0.0792, 0.024, string.format("%1.0f " .. g_i18n:getText("Currency_symbol"), g_currentMission.missionStats.money))
  setTextColor(1, 1, 1, 1)
  renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.008 + 0.0792, 0.024, string.format("%1.0f " .. g_i18n:getText("Currency_symbol"), g_currentMission.missionStats.money))
  local currentFuelPercentage = 0
  local fuelWarnPercentage = 20
  if 0 < self.fuelCapacity then
    currentFuelPercentage = (self.fuelFillLevel / self.fuelCapacity + 1.0E-4) * 100
  end
  setTextColor(0, 0, 0, 1)
  renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.005, 0.024, string.format("%d " .. g_i18n:getText("fluid_unit_long"), self.fuelFillLevel))
  if fuelWarnPercentage > currentFuelPercentage then
    setTextColor(1, 0, 0, 1)
  else
    setTextColor(1, 1, 1, 1)
  end
  renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.008, 0.024, string.format("%d " .. g_i18n:getText("fluid_unit_long"), self.fuelFillLevel))
  if fuelWarnPercentage > currentFuelPercentage then
    setTextColor(1, 1, 1, 1)
  end
  self.hudBarGreenOverlay.width = self.hudBarWidth * (self.fuelFillLevel / self.fuelCapacity)
  setOverlayUVs(self.hudBarGreenOverlay.overlayId, 0, 0.05, 0, 1, self.fuelFillLevel / self.fuelCapacity, 0.05, self.fuelFillLevel / self.fuelCapacity, 1)
  self.hudBarGreenOverlay:render()
  local trailerFillLevel, trailerCapacity = self:getAttachedTrailersFillLevelAndCapacity()
  if trailerFillLevel ~= nil and trailerCapacity ~= nil and 0 < trailerCapacity then
    self:drawGrainLevel(trailerFillLevel, trailerCapacity, 101)
  elseif self.grainTankFillLevel == nil then
    self.hudFramesOverlay:render()
  end
  setTextAlignment(RenderText.ALIGN_LEFT)
  setTextBold(false)
  if self.showWaterWarning then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_depth_into_the_water"), 0.05, 0.032)
  end
  if 1 < table.getn(self.attachedImplements) then
    g_currentMission:addHelpButtonText(g_i18n:getText("Change_tools"), InputBinding.SWITCH_IMPLEMENT)
  end
  if Vehicle.debugRendering then
    renderText(0.5, 0.1, 0.025, string.format(" real acc: %1.2f", self.lastRealAcceleration))
    renderText(0.5, 0.13, 0.025, string.format("      acc: %1.2f", self.lastAcceleration))
    renderText(0.5, 0.16, 0.025, string.format("motor rpm: %1.2f", self.motor.lastMotorRpm))
    renderText(0.5, 0.19, 0.025, string.format("wheel rpm: %1.2f", self.wheelRpm))
  end
end
function Steerable:onEnter(isControlling)
  self.isControlled = true
  if isControlling then
    self.isEntered = true
    self.camIndex = 1
    self.cameras[self.camIndex]:onActivate()
  end
  self:startMotor(true)
  self:onActivateAttachements()
  if self.characterNode ~= nil then
    setVisibility(self.characterNode, true)
  end
end
function Steerable:onLeave()
  self.isControlled = false
  self.cameras[self.camIndex]:onDeactivate()
  if self.deactivateLightsOnLeave then
    self:setLightsVisibility(false, true)
  end
  self:setBeaconLightsVisibility(false, true)
  if self.characterNode ~= nil then
    if self.disableCharacterOnLeave then
      setVisibility(self.characterNode, false)
    else
      setVisibility(self.characterNode, true)
    end
  end
  if self.stopMotorOnLeave then
    self.lastAcceleration = 0
    self:stopMotor(true)
  else
    Motorized.stopSounds(self)
  end
  if self.deactivateOnLeave then
    self.lastAcceleration = 0
    if self.isServer then
      for k, wheel in pairs(self.wheels) do
        setWheelShapeProps(wheel.node, wheel.wheelShape, 0, self.motor.brakeForce, 0)
      end
    end
    self:onDeactivateAttachements()
  else
    if self.deactivateLightsOnLeave then
      self:onDeactivateAttachementsLights()
    end
    self:onDeactivateAttachementsSounds()
  end
  self.isEntered = false
end
function Steerable:drawGrainLevel(level, capacity, warnPercent)
  local percent = 0
  if 0 < capacity then
    percent = level / capacity * 100
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextColor(0, 0, 0, 1)
    renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.005 + 0.0396, 0.024, string.format("%d (%d%%)", level, percent))
    if warnPercent <= percent then
      setTextColor(1, 1, 1, 1)
    else
      setTextColor(1, 1, 1, 1)
    end
    renderText(self.hudBasePosX + self.hudBaseWidth / 2 + 0.002, self.hudBasePosY + 0.008 + 0.0396, 0.024, string.format("%d (%d%%)", level, percent))
    if warnPercent <= percent then
      setTextColor(1, 1, 1, 1)
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    self.hudBarGoldOverlay.width = self.hudBarWidth * (level / capacity)
    setOverlayUVs(self.hudBarGoldOverlay.overlayId, 0, 0.05, 0, 1, level / capacity, 0.05, level / capacity, 1)
    self.hudBarGoldOverlay:render()
  end
  self.hudFramesOverlay:render()
end
function Steerable:setSpeedLevel(speedLevel)
  self.lastAcceleration = self.lastAcceleration * 0.5
  self.motor:setSpeedLevel(speedLevel, false)
end
