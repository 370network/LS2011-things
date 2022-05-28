source("dataS/scripts/vehicles/specializations/FoldableSetFoldDirectionEvent.lua")
Foldable = {}
function Foldable.prerequisitesPresent(specializations)
  return true
end
function Foldable:load(xmlFile)
  self.setFoldDirection = SpecializationUtil.callSpecializationsFunction("setFoldDirection")
  self.getIsAreaActive = Utils.overwrittenFunction(self.getIsAreaActive, Foldable.getIsAreaActive)
  self.posDirectionText = Utils.getNoNil(getXMLString(xmlFile, "vehicle.foldingParts#posDirectionText"), "fold_OBJECT")
  self.negDirectionText = Utils.getNoNil(getXMLString(xmlFile, "vehicle.foldingParts#negDirectionText"), "unfold_OBJECT")
  local startMoveDirection = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.foldingParts#startMoveDirection"), 0)
  self.startAnimTime = 0
  if 0.1 < startMoveDirection then
    self.startAnimTime = 1
  end
  local foldInputButtonStr = getXMLString(xmlFile, "vehicle.foldingParts#foldInputButton")
  if foldInputButtonStr ~= nil then
    self.foldInputButton = InputBinding[foldInputButtonStr]
  end
  self.foldInputButton = Utils.getNoNil(self.foldInputButton, InputBinding.IMPLEMENT_EXTRA2)
  self.foldAnimTime = 0
  self.maxFoldAnimDuration = 1.0E-4
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
  end
  self.foldingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.foldingParts.foldingPart(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local isValid = false
    local entry = {}
    entry.speedScale = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#speedScale"), 1)
    local componentJointIndex = getXMLInt(xmlFile, baseName .. "#componentJointIndex")
    if componentJointIndex ~= nil then
      local componentJoint = self.componentJoints[componentJointIndex + 1]
      if componentJoint ~= nil then
        entry.componentJoint = componentJoint
        entry.anchorActor = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#anchorActor"), 0)
        entry.animCharSet = 0
        local rootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#rootNode"))
        if rootNode ~= nil then
          local animCharSet = getAnimCharacterSet(rootNode)
          if animCharSet ~= 0 then
            local clip = getAnimClipIndex(animCharSet, getXMLString(xmlFile, baseName .. "#animationClip"))
            if 0 <= clip then
              isValid = true
              entry.animCharSet = animCharSet
              assignAnimTrackClip(entry.animCharSet, 0, clip)
              setAnimTrackLoopState(entry.animCharSet, 0, false)
              entry.animDuration = getAnimClipDuration(entry.animCharSet, clip)
            end
          end
        end
        if not isValid and self.playAnimation ~= nil and self.animations ~= nil then
          local animationName = getXMLString(xmlFile, baseName .. "#animationName")
          if animationName ~= nil and self.animations[animationName] ~= nil then
            isValid = true
            entry.animDuration = self:getAnimationDuration(animationName)
            entry.animationName = animationName
          end
        end
        if isValid then
          self.maxFoldAnimDuration = math.max(self.maxFoldAnimDuration, entry.animDuration)
          local node = self.components[componentJoint.componentIndices[(entry.anchorActor + 1) % 2 + 1]].node
          entry.x, entry.y, entry.z = worldToLocal(componentJoint.jointNode, getWorldTranslation(node))
          entry.upX, entry.upY, entry.upZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 1, 0))
          entry.dirX, entry.dirY, entry.dirZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 0, 1))
          table.insert(self.foldingParts, entry)
        end
      end
    end
    i = i + 1
  end
  self.foldMoveDirection = startMoveDirection
  Foldable.setAnimTime(self, self.startAnimTime)
end
function Foldable:delete()
end
function Foldable:readStream(streamId, connection)
  local direction = streamReadUIntN(streamId, 2) - 1
  local animTime = streamReadFloat32(streamId)
  Foldable.setAnimTime(self, animTime)
  self:setFoldDirection(direction, true)
end
function Foldable:writeStream(streamId, connection)
  local direction = Utils.sign(self.foldMoveDirection) + 1
  streamWriteUIntN(streamId, direction, 2)
  streamWriteFloat32(streamId, self.foldAnimTime)
end
function Foldable:readUpdateStream(streamId, timestamp, connection)
end
function Foldable:writeUpdateStream(streamId, connection, dirtyMask)
end
function Foldable:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  Foldable.setAnimTime(self, self.startAnimTime)
  return BaseMission.VEHICLE_LOAD_OK
end
function Foldable:setRelativePosition(positionX, offsetY, positionZ, yRot)
  Foldable.setAnimTime(self, self.startAnimTime)
end
function Foldable:mouseEvent(posX, posY, isDown, isUp, button)
end
function Foldable:keyEvent(unicode, sym, modifier, isDown)
end
function Foldable:update(dt)
  if self:getIsActive() and math.abs(self.foldMoveDirection) > 0.1 then
    local isInvalid = false
    local foldAnimTime = 0
    if self.foldMoveDirection < -0.1 then
      foldAnimTime = 1
    end
    for k, foldingPart in pairs(self.foldingParts) do
      local charSet = foldingPart.animCharSet
      if self.foldMoveDirection > 0.1 then
        local animTime = 0
        if charSet ~= 0 then
          animTime = getAnimTrackTime(charSet, 0)
        else
          animTime = self:getRealAnimationTime(foldingPart.animationName)
        end
        if animTime < foldingPart.animDuration then
          isInvalid = true
        end
        foldAnimTime = math.max(foldAnimTime, animTime / self.maxFoldAnimDuration)
      elseif self.foldMoveDirection < -0.1 then
        local animTime = 0
        if charSet ~= 0 then
          animTime = getAnimTrackTime(charSet, 0)
        else
          animTime = self:getRealAnimationTime(foldingPart.animationName)
        end
        if 0 < animTime then
          isInvalid = true
        end
        foldAnimTime = math.min(foldAnimTime, animTime / self.maxFoldAnimDuration)
      end
    end
    self.foldAnimTime = Utils.clamp(foldAnimTime, 0, 1)
    if isInvalid and self.isServer then
      for k, foldingPart in pairs(self.foldingParts) do
        setJointFrame(foldingPart.componentJoint.jointIndex, foldingPart.anchorActor, foldingPart.componentJoint.jointNode)
      end
    end
  end
  if self.isClient and self:getIsActiveForInput() and InputBinding.hasEvent(self.foldInputButton) then
    if self.foldMoveDirection > 0.1 or self.foldMoveDirection == 0 and self.foldAnimTime > 0.5 then
      self:setFoldDirection(-1)
    else
      self:setFoldDirection(1)
    end
  end
end
function Foldable:updateTick(dt)
end
function Foldable:draw()
  if table.getn(self.foldingParts) > 0 then
    if self.foldMoveDirection > 0.1 or self.foldMoveDirection == 0 and self.foldAnimTime > 0.5 then
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.negDirectionText), self.typeDesc), self.foldInputButton)
    else
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.posDirectionText), self.typeDesc), self.foldInputButton)
    end
  end
end
function Foldable:onDetach()
  if self.deactivateOnDetach then
    Foldable.onDeactivate(self)
  end
end
function Foldable:onLeave()
  if self.deactivateOnLeave then
    Foldable.onDeactivate(self)
  end
end
function Foldable:onDeactivate()
  self:setFoldDirection(0, true)
end
function Foldable:setFoldDirection(direction, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(FoldableSetFoldDirectionEvent:new(self, direction), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent:new(self, direction))
    end
  end
  self.foldMoveDirection = direction
  for k, foldingPart in pairs(self.foldingParts) do
    local speedScale
    if self.foldMoveDirection > 0.1 then
      speedScale = foldingPart.speedScale
    elseif self.foldMoveDirection < -0.1 then
      speedScale = -foldingPart.speedScale
    end
    local charSet = foldingPart.animCharSet
    if charSet ~= 0 then
      if speedScale ~= nil then
        if 0 < speedScale then
          if 0 > getAnimTrackTime(charSet, 0) then
            setAnimTrackTime(charSet, 0, 0)
          end
        elseif getAnimTrackTime(charSet, 0) > foldingPart.animDuration then
          setAnimTrackTime(charSet, 0, foldingPart.animDuration)
        end
        setAnimTrackSpeedScale(charSet, 0, speedScale)
        enableAnimTrack(charSet, 0)
      else
        disableAnimTrack(charSet, 0)
      end
    elseif speedScale ~= nil then
      local animTime = self.foldAnimTime * self.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)
      self:playAnimation(foldingPart.animationName, speedScale, animTime, true)
    else
      self:stopAnimation(foldingPart.animationName, true)
    end
  end
end
function Foldable:getIsAreaActive(superFunc, area)
  if self.foldAnimTime > area.foldMaxLimit or self.foldAnimTime < area.foldMinLimit then
    return false
  end
  if superFunc ~= nil then
    return superFunc(self, area)
  end
  return true
end
function Foldable:setAnimTime(animTime)
  self.foldAnimTime = animTime
  for k, foldingPart in pairs(self.foldingParts) do
    if foldingPart.animCharSet ~= 0 then
      enableAnimTrack(foldingPart.animCharSet, 0)
      setAnimTrackTime(foldingPart.animCharSet, 0, animTime * foldingPart.animDuration, true)
      disableAnimTrack(foldingPart.animCharSet, 0)
    else
      local currentTime = self:getAnimationTime(foldingPart.animationName)
      local speed = 1
      if currentTime > self.foldAnimTime then
        speed = -1
      end
      self:playAnimation(foldingPart.animationName, speed, currentTime, true)
      self:setAnimationStopTime(foldingPart.animationName, self.foldAnimTime)
      AnimatedVehicle.updateAnimations(self, 99999999)
    end
  end
  if self.isServer then
    for k, foldingPart in pairs(self.foldingParts) do
      local componentJoint = foldingPart.componentJoint
      local node = self.components[componentJoint.componentIndices[(foldingPart.anchorActor + 1) % 2 + 1]].node
      local x, y, z = localToWorld(componentJoint.jointNode, foldingPart.x, foldingPart.y, foldingPart.z)
      local upX, upY, upZ = localDirectionToWorld(componentJoint.jointNode, foldingPart.upX, foldingPart.upY, foldingPart.upZ)
      local dirX, dirY, dirZ = localDirectionToWorld(componentJoint.jointNode, foldingPart.dirX, foldingPart.dirY, foldingPart.dirZ)
      Utils.setWorldTranslation(node, x, y, z)
      Utils.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
      setJointFrame(componentJoint.jointIndex, foldingPart.anchorActor, componentJoint.jointNode)
    end
  end
end
