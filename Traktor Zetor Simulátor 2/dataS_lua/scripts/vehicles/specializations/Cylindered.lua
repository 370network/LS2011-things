Cylindered = {}
function Cylindered.prerequisitesPresent(specializations)
  return true
end
function Cylindered:load(xmlFile)
  local cylinderedHydraulicSound = getXMLString(xmlFile, "vehicle.cylinderedHydraulicSound#file")
  if cylinderedHydraulicSound ~= nil and cylinderedHydraulicSound ~= "" then
    cylinderedHydraulicSound = Utils.getFilename(cylinderedHydraulicSound, self.baseDirectory)
    self.cylinderedHydraulicSound = createSample("cylinderedHydraulicSound")
    self.cylinderedHydraulicSoundEnabled = false
    loadSample(self.cylinderedHydraulicSound, cylinderedHydraulicSound, false)
    self.cylinderedHydraulicSoundPitch = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.cylinderedHydraulicSound#pitchOffset"), 1)
    self.cylinderedHydraulicSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.cylinderedHydraulicSound#volume"), 1)
    setSamplePitch(self.cylinderedHydraulicSound, self.cylinderedHydraulicSoundPitch)
  else
    self.cylinderedHydraulicSoundPitch = 1
    self.cylinderedHydraulicSoundVolume = 1
  end
  self.direction = 1
  self.setMovingToolDirty = SpecializationUtil.callSpecializationsFunction("setMovingToolDirty")
  local referenceNodes = {}
  self.movingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.movingParts.movingPart(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local referencePoint = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#referencePoint"))
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#index"))
    local referenceFrame = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#referenceFrame"))
    if referencePoint ~= nil and node ~= nil and referenceFrame ~= nil then
      local entry = {}
      entry.referencePoint = referencePoint
      entry.node = node
      entry.referenceFrame = referenceFrame
      entry.invertZ = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invertZ"), false)
      entry.scaleZ = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#scaleZ"), false)
      local localReferencePoint = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#localReferencePoint"))
      local refX, refY, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))
      if localReferencePoint ~= nil then
        local x, y, z = worldToLocal(node, getWorldTranslation(localReferencePoint))
        entry.referenceDistance = Utils.vector3Length(refX - x, refY - y, refZ - z)
        entry.localReferencePoint = {
          x,
          y,
          z
        }
      else
        entry.referenceDistance = 0
        entry.localReferencePoint = {
          refX,
          refY,
          refZ
        }
      end
      local refLen = Utils.vector3Length(unpack(entry.localReferencePoint))
      entry.dirCorrection = {
        entry.localReferencePoint[1] / refLen,
        entry.localReferencePoint[2] / refLen,
        entry.localReferencePoint[3] / refLen - 1
      }
      entry.localReferenceDistance = Utils.vector2Length(entry.localReferencePoint[2], entry.localReferencePoint[3])
      entry.isDirty = false
      Cylindered.loadTranslatingParts(self, xmlFile, baseName, entry)
      if referenceNodes[referencePoint] == nil then
        referenceNodes[referencePoint] = {}
      end
      table.insert(referenceNodes[referencePoint], entry)
      if referenceNodes[node] == nil then
        referenceNodes[node] = {}
      end
      table.insert(referenceNodes[node], entry)
      Cylindered.loadDependentParts(self, xmlFile, baseName, entry)
      Cylindered.loadComponentJoints(self, xmlFile, baseName, entry)
      Cylindered.loadAttacherJoints(self, xmlFile, baseName, entry)
      table.insert(self.movingParts, entry)
    end
    i = i + 1
  end
  for _, part in pairs(self.movingParts) do
    part.dependentParts = {}
    for _, ref in pairs(part.dependentPartNodes) do
      if referenceNodes[ref] ~= nil then
        for _, p in pairs(referenceNodes[ref]) do
          part.dependentParts[p] = p
        end
      end
    end
  end
  function hasDependentPart(w1, w2)
    if w1.dependentParts[w2] ~= nil then
      return true
    else
      for _, v in pairs(w1.dependentParts) do
        if hasDependentPart(v, w2) then
          return true
        end
      end
    end
    return false
  end
  function movingPartsSort(w1, w2)
    if hasDependentPart(w1, w2) then
      return true
    end
  end
  table.sort(self.movingParts, movingPartsSort)
  self.nodesToMovingTools = {}
  self.movingTools = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.movingTools.movingTool(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#index"))
    if node ~= nil then
      local entry = {}
      entry.node = node
      local rotSpeed = getXMLFloat(xmlFile, baseName .. "#rotSpeed")
      if rotSpeed ~= nil then
        entry.rotSpeed = math.rad(rotSpeed) / 1000
      end
      local rotAcceleration = getXMLFloat(xmlFile, baseName .. "#rotAcceleration")
      if rotAcceleration ~= nil then
        entry.rotAcceleration = math.rad(rotAcceleration) / 1000000
      end
      entry.lastRotSpeed = 0
      local rotMax = getXMLFloat(xmlFile, baseName .. "#rotMax")
      if rotMax ~= nil then
        entry.rotMax = math.rad(rotMax)
      end
      local rotMin = getXMLFloat(xmlFile, baseName .. "#rotMin")
      if rotMin ~= nil then
        entry.rotMin = math.rad(rotMin)
      end
      local transSpeed = getXMLFloat(xmlFile, baseName .. "#transSpeed")
      if transSpeed ~= nil then
        entry.transSpeed = transSpeed / 1000
      end
      local transAcceleration = getXMLFloat(xmlFile, baseName .. "#transAcceleration")
      if transAcceleration ~= nil then
        entry.transAcceleration = transAcceleration / 1000000
      end
      entry.lastTransSpeed = 0
      entry.transMax = getXMLFloat(xmlFile, baseName .. "#transMax")
      entry.transMin = getXMLFloat(xmlFile, baseName .. "#transMin")
      entry.axis = getXMLString(xmlFile, baseName .. "#axis")
      entry.invertAxis = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invertAxis"), false)
      entry.mouseAxis = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#mouseAxis"), "")
      entry.invertMouseAxis = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invertMouseAxis"), false)
      entry.speedFactor = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#speedFactor"), 1)
      entry.isDirty = false
      entry.rotationAxis = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#rotationAxis"), 1)
      entry.translationAxis = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#translationAxis"), 3)
      local x, y, z = getRotation(node)
      entry.curRot = {
        x,
        y,
        z
      }
      local x, y, z = getTranslation(node)
      entry.curTrans = {
        x,
        y,
        z
      }
      if referenceNodes[node] == nil then
        referenceNodes[node] = {}
      end
      table.insert(referenceNodes[node], entry)
      Cylindered.loadDependentParts(self, xmlFile, baseName, entry)
      Cylindered.loadComponentJoints(self, xmlFile, baseName, entry)
      Cylindered.loadAttacherJoints(self, xmlFile, baseName, entry)
      table.insert(self.movingTools, entry)
      self.nodesToMovingTools[node] = entry
    end
    i = i + 1
  end
  for _, part in pairs(self.movingTools) do
    part.dependentParts = {}
    for _, ref in pairs(part.dependentPartNodes) do
      if referenceNodes[ref] ~= nil then
        for _, p in pairs(referenceNodes[ref]) do
          part.dependentParts[p] = p
        end
      end
    end
  end
  self.cylinderedDirtyFlag = self.nextDirtyFlag
  self.nextDirtyFlag = self.cylinderedDirtyFlag * 2
end
function Cylindered:delete()
  if self.cylinderedHydraulicSound ~= nil then
    delete(self.cylinderedHydraulicSound)
  end
end
function Cylindered:readStream(streamId, connection)
  for i = 1, table.getn(self.movingTools) do
    local tool = self.movingTools[i]
    local changed = false
    if tool.transSpeed ~= nil then
      local newTrans = streamReadFloat32(streamId)
      if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 1.0E-4 then
        tool.curTrans[tool.translationAxis] = newTrans
        setTranslation(tool.node, unpack(tool.curTrans))
        changed = true
      end
    end
    if tool.rotSpeed ~= nil then
      local newRot = streamReadFloat32(streamId)
      if 1.0E-4 < math.abs(newRot - tool.curRot[tool.rotationAxis]) then
        tool.curRot[tool.rotationAxis] = newRot
        setRotation(tool.node, unpack(tool.curRot))
        changed = true
      end
    end
    if changed then
      Cylindered.setDirty(self, tool)
    end
  end
end
function Cylindered:writeStream(streamId, connection)
  for i = 1, table.getn(self.movingTools) do
    local tool = self.movingTools[i]
    if tool.transSpeed ~= nil then
      streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
    end
    if tool.rotSpeed ~= nil then
      streamWriteFloat32(streamId, tool.curRot[tool.rotationAxis])
    end
  end
end
function Cylindered:readUpdateStream(streamId, timestamp, connection)
  local hasUpdate = streamReadBool(streamId)
  if hasUpdate then
    for i = 1, table.getn(self.movingTools) do
      local tool = self.movingTools[i]
      local changed = false
      if tool.transSpeed ~= nil then
        local newTrans = streamReadFloat32(streamId)
        if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 1.0E-4 then
          tool.curTrans[tool.translationAxis] = newTrans
          setTranslation(tool.node, unpack(tool.curTrans))
          changed = true
        end
      end
      if tool.rotSpeed ~= nil then
        local newRot = streamReadFloat32(streamId)
        if 1.0E-4 < math.abs(newRot - tool.curRot[tool.rotationAxis]) then
          tool.curRot[tool.rotationAxis] = newRot
          setRotation(tool.node, unpack(tool.curRot))
          changed = true
        end
      end
      if changed then
        Cylindered.setDirty(self, tool)
      end
    end
    if not connection:getIsServer() then
      self:raiseDirtyFlags(self.cylinderedDirtyFlag)
    end
  end
end
function Cylindered:writeUpdateStream(streamId, connection, dirtyMask)
  if bitAND(dirtyMask, self.cylinderedDirtyFlag) ~= 0 and (connection:getIsServer() or connection ~= self.owner) then
    streamWriteBool(streamId, true)
    for i = 1, table.getn(self.movingTools) do
      local tool = self.movingTools[i]
      if tool.transSpeed ~= nil then
        streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
      end
      if tool.rotSpeed ~= nil then
        streamWriteFloat32(streamId, tool.curRot[tool.rotationAxis])
      end
    end
  else
    streamWriteBool(streamId, false)
  end
end
function Cylindered:loadDependentParts(xmlFile, baseName, entry)
  entry.dependentPartNodes = {}
  local j = 0
  while true do
    local refBaseName = baseName .. string.format(".dependentPart(%d)", j)
    if not hasXMLProperty(xmlFile, refBaseName) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#index"))
    if node ~= nil then
      table.insert(entry.dependentPartNodes, node)
    end
    j = j + 1
  end
end
function Cylindered:loadComponentJoints(xmlFile, baseName, entry)
  local indices = Utils.getVectorNFromString(getXMLString(xmlFile, baseName .. "#componentJointIndex"))
  local actors = Utils.getNoNil(Utils.getVectorNFromString(getXMLString(xmlFile, baseName .. "#anchorActor")), {})
  if indices ~= nil then
    local componentJoints = {}
    for i = 1, table.getn(indices) do
      local componentJoint = self.componentJoints[indices[i] + 1]
      if componentJoint ~= nil then
        table.insert(componentJoints, {
          componentJoint = componentJoint,
          anchorActor = Utils.getNoNil(actors[i], 0)
        })
      end
    end
    if table.getn(componentJoints) > 0 then
      entry.componentJoints = componentJoints
    end
  end
end
function Cylindered:loadAttacherJoints(xmlFile, baseName, entry)
  local indices = Utils.getVectorNFromString(getXMLString(xmlFile, baseName .. "#attacherJointIndices"))
  if indices ~= nil then
    local attacherJoints = {}
    for i = 1, table.getn(indices) do
      local attacherJoint = self.attacherJoints[indices[i] + 1]
      if attacherJoint ~= nil then
        table.insert(attacherJoints, attacherJoint)
      end
    end
    if table.getn(attacherJoints) > 0 then
      entry.attacherJoints = attacherJoints
    end
  end
end
function Cylindered:loadTranslatingParts(xmlFile, baseName, entry)
  entry.translatingParts = {}
  local j = 0
  while true do
    local refBaseName = baseName .. string.format(".translatingPart(%d)", j)
    if not hasXMLProperty(xmlFile, refBaseName) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#index"))
    if node ~= nil then
      local transEntry = {}
      transEntry.node = node
      local x, y, z = getTranslation(node)
      transEntry.startPos = {
        x,
        y,
        z
      }
      local x, y, z = worldToLocal(entry.node, getWorldTranslation(entry.referencePoint))
      transEntry.length = z
      table.insert(entry.translatingParts, transEntry)
    end
    j = j + 1
  end
end
function Cylindered:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  return BaseMission.VEHICLE_LOAD_OK
end
function Cylindered:getSaveAttributesAndNodes(nodeIdent)
end
function Cylindered:mouseEvent(posX, posY, isDown, isUp, button)
end
function Cylindered:keyEvent(unicode, sym, modifier, isDown)
end
function Cylindered:update(dt)
end
function Cylindered:updateTick(dt)
  if self:getIsActive() and self:getIsActiveForInput() and self.isClient then
    for i = 1, table.getn(self.movingTools) do
      local tool = self.movingTools[i]
      if tool.rotSpeed ~= nil or tool.transSpeed ~= nil then
        local move = 0
        if tool.axis ~= nil then
          local neededActivationAxesMet = true
          if neededActivationAxesMet then
            move = InputBinding.getDigitalInputAxis(InputBinding[tool.axis])
            if InputBinding.isAxisZero(move) then
              move = InputBinding.getAnalogInputAxis(InputBinding[tool.axis])
            end
            if tool.invertAxis then
              move = -move
            end
          end
        end
        local invertedMouseAxis = 1
        if tool.invertMouseAxis then
          invertedMouseAxis = -1
        end
        if self.mouseButton ~= MouseControlsVehicle.BUTTON_NONE and tool.mouseAxis ~= "" then
          if self.mouseControlAxisX == tool.mouseAxis then
            move = self.mouseDirectionX * invertedMouseAxis * tool.speedFactor
          elseif self.mouseControlAxisY == tool.mouseAxis then
            move = self.mouseDirectionY * invertedMouseAxis * tool.speedFactor
          end
        end
        local rotSpeed = 0
        local transSpeed = 0
        if not InputBinding.isAxisZero(move) then
          if tool.rotSpeed ~= nil then
            rotSpeed = move * tool.rotSpeed
            if tool.rotAcceleration ~= nil and math.abs(rotSpeed - tool.lastRotSpeed) >= tool.rotAcceleration * dt then
              if rotSpeed > tool.lastRotSpeed then
                rotSpeed = tool.lastRotSpeed + tool.rotAcceleration * dt
              else
                rotSpeed = tool.lastRotSpeed - tool.rotAcceleration * dt
              end
            end
          end
          if tool.transSpeed ~= nil then
            transSpeed = move * tool.transSpeed
            if tool.transAcceleration ~= nil and math.abs(transSpeed - tool.lastTransSpeed) >= tool.transAcceleration * dt then
              if transSpeed > tool.lastTransSpeed then
                transSpeed = tool.lastTransSpeed + tool.transAcceleration * dt
              else
                transSpeed = tool.lastTransSpeed - tool.transAcceleration * dt
              end
            end
          end
        else
          if tool.rotAcceleration ~= nil then
            if 0 > tool.lastRotSpeed then
              rotSpeed = math.min(tool.lastRotSpeed + tool.rotAcceleration * dt, 0)
            else
              rotSpeed = math.max(tool.lastRotSpeed - tool.rotAcceleration * dt, 0)
            end
          end
          if tool.transAcceleration ~= nil then
            if 0 > tool.lastTransSpeed then
              transSpeed = math.min(tool.lastTransSpeed + tool.transAcceleration * dt, 0)
            else
              transSpeed = math.max(tool.lastTransSpeed - tool.transAcceleration * dt, 0)
            end
          end
        end
        local changed = false
        if rotSpeed ~= 0 then
          local newRot = tool.curRot[tool.rotationAxis] + rotSpeed * dt
          if tool.rotMax ~= nil then
            newRot = math.min(newRot, tool.rotMax)
          elseif newRot > 2 * math.pi then
            newRot = newRot - 2 * math.pi
          end
          if tool.rotMin ~= nil then
            newRot = math.max(newRot, tool.rotMin)
          elseif newRot < 0 then
            newRot = newRot + 2 * math.pi
          end
          tool.lastRotSpeed = rotSpeed
          if math.abs(newRot - tool.curRot[tool.rotationAxis]) > 1.0E-4 then
            tool.curRot[tool.rotationAxis] = newRot
            setRotation(tool.node, unpack(tool.curRot))
            changed = true
          end
        else
          tool.lastRotSpeed = 0
        end
        if transSpeed ~= 0 then
          local newTrans = tool.curTrans[tool.translationAxis] + transSpeed * dt
          if tool.transMax ~= nil then
            newTrans = math.min(newTrans, tool.transMax)
          end
          if tool.transMin ~= nil then
            newTrans = math.max(newTrans, tool.transMin)
          end
          tool.lastTransSpeed = transSpeed
          if 1.0E-4 < math.abs(newTrans - tool.curTrans[tool.translationAxis]) then
            tool.curTrans[tool.translationAxis] = newTrans
            setTranslation(tool.node, unpack(tool.curTrans))
            changed = true
          end
        else
          tool.lastTransSpeed = 0
        end
        if changed then
          Cylindered.setDirty(self, tool)
          self:raiseDirtyFlags(self.cylinderedDirtyFlag)
        end
      end
    end
  end
  for _, tool in pairs(self.movingTools) do
    if tool.isDirty then
      if self.isServer then
        Cylindered.updateComponentJoints(self, tool)
      end
      tool.isDirty = false
    end
  end
  for i, part in ipairs(self.movingParts) do
    if part.isDirty then
      Cylindered.updateMovingPart(self, part)
      if self:getIsActiveForSound() and not self.cylinderedHydraulicSoundEnabled then
        self.cylinderedHydraulicSoundPartNumber = i
        playSample(self.cylinderedHydraulicSound, 0, self.cylinderedHydraulicSoundVolume, 0)
        self.cylinderedHydraulicSoundEnabled = true
      end
    elseif self.cylinderedHydraulicSoundEnabled and self.cylinderedHydraulicSoundPartNumber == i then
      stopSample(self.cylinderedHydraulicSound)
      self.cylinderedHydraulicSoundEnabled = false
    end
  end
end
function Cylindered:draw()
end
function Cylindered:setMovingToolDirty(node)
  local tool = self.nodesToMovingTools[node]
  if tool ~= nil then
    Cylindered.setDirty(self, tool)
  end
end
function Cylindered:setDirty(part)
  if not part.isDirty then
    part.isDirty = true
    if self.isServer and part.attacherJoints ~= nil then
      for _, joint in ipairs(part.attacherJoints) do
        if joint.jointIndex ~= 0 then
          setJointFrame(joint.jointIndex, 0, joint.jointTransform)
        end
      end
    end
    for _, v in pairs(part.dependentParts) do
      Cylindered.setDirty(self, v)
    end
  end
end
function Cylindered:updateMovingPart(part)
  local refX, refY, refZ = getWorldTranslation(part.referencePoint)
  local dirX, dirY, dirZ = 0, 0, 0
  if part.referenceDistance == 0 then
    local x, y, z = getWorldTranslation(part.node)
    dirX, dirY, dirZ = refX - x, refY - y, refZ - z
  else
    local r1 = part.localReferenceDistance
    local r2 = part.referenceDistance
    local lx, ly, lz = worldToLocal(part.node, refX, refY, refZ)
    local ix, iy, i2x, i2y = Utils.getCircleCircleIntersection(0, 0, r1, ly, lz, r2)
    if ix ~= nil then
      if i2x ~= nil and math.abs(i2y) > math.abs(iy) then
        iy = i2y
        ix = i2x
      end
      dirX, dirY, dirZ = localDirectionToWorld(part.node, 0, ix, iy)
    end
  end
  if dirX ~= 0 or dirY ~= 0 or dirZ ~= 0 then
    local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
    if part.invertZ then
      dirX = -dirX
      dirY = -dirY
      dirZ = -dirZ
    end
    Utils.setWorldDirection(part.node, dirX, dirY, dirZ, upX, upY, upZ)
    if part.scaleZ then
      local len = Utils.vector3Length(dirX, dirY, dirZ)
      setScale(part.node, 1, 1, len / part.localReferenceDistance)
    end
  end
  if part.translatingParts[1] ~= nil then
    local translatingPart = part.translatingParts[1]
    local _, _, dist = worldToLocal(part.node, refX, refY, refZ)
    local newZ = dist - translatingPart.length + translatingPart.startPos[3]
    setTranslation(part.translatingParts[1].node, translatingPart.startPos[1], translatingPart.startPos[2], newZ)
  end
  if self.isServer then
    Cylindered.updateComponentJoints(self, part)
  end
  part.isDirty = false
end
function Cylindered:updateComponentJoints(entry)
  if entry.componentJoints ~= nil then
    for _, joint in ipairs(entry.componentJoints) do
      setJointFrame(joint.componentJoint.jointIndex, joint.anchorActor, joint.componentJoint.jointNode)
    end
  end
end
function Cylindered:onLeave()
  if self.deactivateOnLeave then
    Cylindered.onDeactivate(self)
  else
    Cylindered.onDeactivateSounds(self)
  end
end
function Cylindered:onDeactivate()
  Cylindered.onDeactivateSounds(self)
end
function Cylindered:onDeactivateSounds()
  if self.cylinderedHydraulicSoundEnabled then
    stopSample(self.cylinderedHydraulicSound)
    self.cylinderedHydraulicSoundEnabled = false
  end
end
