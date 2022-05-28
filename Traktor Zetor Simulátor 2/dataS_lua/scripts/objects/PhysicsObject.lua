PhysicsObject = {}
PhysicsObject_mt = Class(PhysicsObject, Object)
InitStaticObjectClass(PhysicsObject, "PhysicsObject", ObjectIds.OBJECT_PHYSIC_OBJECT)
function PhysicsObject:new(isServer, isClient, customMt)
  local mt = customMt
  if mt == nil then
    mt = PhysicsObject_mt
  end
  local self = Object:new(isServer, isClient, mt)
  self.nodeId = 0
  self.currentPosition = {}
  self.targetPosition = {}
  self.forcedClipDistance = 30
  self.interpolationTime = 0
  self.className = "PhysicsObject"
  self.physicsObjectDirtyFlag = self:getNextDirtyFlag()
  return self
end
function PhysicsObject:delete()
  g_currentMission:removeNodeObject(self.nodeId)
  delete(self.nodeId)
  self.nodeId = 0
  PhysicsObject:superClass().delete(self)
end
function PhysicsObject:loadOnCreate(nodeId)
  self:setNodeId(nodeId)
  if not self.isServer then
    self:onGhostRemove()
  end
end
function PhysicsObject:setNodeId(nodeId)
  self.nodeId = nodeId
  local x, y, z = getTranslation(self.nodeId)
  local x_rot, y_rot, z_rot = getRotation(self.nodeId)
  self.sendPosX, self.sendPosY, self.sendPosZ = x, y, z
  self.sendRotX, self.sendRotY, self.sendRotZ = x_rot, y_rot, z_rot
  local currentPosition = self.currentPosition
  local targetPosition = self.targetPosition
  currentPosition.x, currentPosition.y, currentPosition.z = x, y, z
  targetPosition.x, targetPosition.y, targetPosition.z = x, y, z
  currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot = mathEulerToQuaternion(x_rot, y_rot, z_rot)
  targetPosition.x_rot, targetPosition.y_rot, targetPosition.z_rot, targetPosition.w_rot = currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot
  g_currentMission:addNodeObject(self.nodeId, self)
end
function PhysicsObject:readStream(streamId, connection)
  assert(self.nodeId ~= 0)
  if connection:getIsServer() then
    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    local x_rot = Utils.readCompressedAngle(streamId)
    local y_rot = Utils.readCompressedAngle(streamId)
    local z_rot = Utils.readCompressedAngle(streamId)
    local currentPosition = self.currentPosition
    local targetPosition = self.targetPosition
    currentPosition.x, currentPosition.y, currentPosition.z = x, y, z
    targetPosition.x, targetPosition.y, targetPosition.z = x, y, z
    currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot = mathEulerToQuaternion(x_rot, y_rot, z_rot)
    targetPosition.x_rot, targetPosition.y_rot, targetPosition.z_rot, targetPosition.w_rot = currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot
  end
end
function PhysicsObject:writeStream(streamId, connection)
  if not connection:getIsServer() then
    local x, y, z = getTranslation(self.nodeId)
    local x_rot, y_rot, z_rot = getRotation(self.nodeId)
    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)
    Utils.writeCompressedAngle(streamId, x_rot)
    Utils.writeCompressedAngle(streamId, y_rot)
    Utils.writeCompressedAngle(streamId, z_rot)
  end
end
function PhysicsObject:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    local hasUpdate = streamReadBool(streamId)
    if hasUpdate then
      local targetPosition = self.targetPosition
      local currentPosition = self.currentPosition
      targetPosition.x = streamReadFloat32(streamId)
      targetPosition.y = streamReadFloat32(streamId)
      targetPosition.z = streamReadFloat32(streamId)
      local x_rot = Utils.readCompressedAngle(streamId)
      local y_rot = Utils.readCompressedAngle(streamId)
      local z_rot = Utils.readCompressedAngle(streamId)
      targetPosition.x_rot, targetPosition.y_rot, targetPosition.z_rot, targetPosition.w_rot = mathEulerToQuaternion(x_rot, y_rot, z_rot)
      local dx, dy, dz = targetPosition.x - currentPosition.x, targetPosition.y - currentPosition.y, targetPosition.z - currentPosition.z
      if 2.25 < dx * dx + dy * dy + dz * dz then
        print("snapping, diff: " .. math.sqrt(dx * dx + dy * dy + dz * dz))
        currentPosition.x = targetPosition.x
        currentPosition.y = targetPosition.y
        currentPosition.z = targetPosition.z
        currentPosition.x_rot = targetPosition.x_rot
        currentPosition.y_rot = targetPosition.y_rot
        currentPosition.z_rot = targetPosition.z_rot
        currentPosition.w_rot = targetPosition.w_rot
      end
    end
  end
end
function PhysicsObject:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    if bitAND(dirtyMask, self.physicsObjectDirtyFlag) ~= 0 then
      streamWriteBool(streamId, true)
      streamWriteFloat32(streamId, self.sendPosX)
      streamWriteFloat32(streamId, self.sendPosY)
      streamWriteFloat32(streamId, self.sendPosZ)
      Utils.writeCompressedAngle(streamId, self.sendRotX)
      Utils.writeCompressedAngle(streamId, self.sendRotY)
      Utils.writeCompressedAngle(streamId, self.sendRotZ)
    else
      streamWriteBool(streamId, false)
    end
  end
end
function PhysicsObject:update(dt)
  if self.isClient and not self.isServer then
    local currentPosition = self.currentPosition
    local targetPosition = self.targetPosition
    self.interpolationTime = self.interpolationTime + dt
    while self.interpolationTime > 10 do
      self.interpolationTime = self.interpolationTime - 10
      currentPosition.x = currentPosition.x + (targetPosition.x - currentPosition.x) * 0.25
      currentPosition.y = currentPosition.y + (targetPosition.y - currentPosition.y) * 0.25
      currentPosition.z = currentPosition.z + (targetPosition.z - currentPosition.z) * 0.25
      currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot = Utils.nlerpQuaternionShortestPath(currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot, targetPosition.x_rot, targetPosition.y_rot, targetPosition.z_rot, targetPosition.w_rot, 0.25)
    end
    setTranslation(self.nodeId, currentPosition.x, currentPosition.y, currentPosition.z)
    setQuaternion(self.nodeId, currentPosition.x_rot, currentPosition.y_rot, currentPosition.z_rot, currentPosition.w_rot)
  end
end
function PhysicsObject:updateTick(dt)
  if self.isServer then
    local x, y, z = getTranslation(self.nodeId)
    local x_rot, y_rot, z_rot = getRotation(self.nodeId)
    local hasMoved = math.abs(self.sendPosX - x) > 0.001 or 0.001 < math.abs(self.sendPosY - y) or 0.001 < math.abs(self.sendPosZ - z) or 0.001 < math.abs(self.sendRotX - x_rot) or 0.001 < math.abs(self.sendRotY - y_rot) or 0.001 < math.abs(self.sendRotZ - z_rot)
    if hasMoved then
      self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
      self.sendPosX, self.sendPosY, self.sendPosZ = x, y, z
      self.sendRotX, self.sendRotY, self.sendRotZ = x_rot, y_rot, z_rot
    end
  end
end
function PhysicsObject:testScope(x, y, z, coeff)
  local x1, y1, z1 = getWorldTranslation(self.nodeId)
  local dist = (x1 - x) * (x1 - x) + (y1 - y) * (y1 - y) + (z1 - z) * (z1 - z)
  local clipDist = math.min(getClipDistance(self.nodeId) * coeff, self.forcedClipDistance)
  if dist < clipDist * clipDist then
    return true
  else
    return false
  end
end
function PhysicsObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
  local x1, y1, z1 = getWorldTranslation(self.nodeId)
  local dist = math.sqrt((x1 - x) * (x1 - x) + (y1 - y) * (y1 - y) + (z1 - z) * (z1 - z))
  local clipDist = math.min(getClipDistance(self.nodeId) * coeff, self.forcedClipDistance)
  return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end
function PhysicsObject:onGhostRemove()
  setVisibility(self.nodeId, false)
  removeFromPhysics(self.nodeId)
end
function PhysicsObject:onGhostAdd()
  setVisibility(self.nodeId, true)
  addToPhysics(self.nodeId)
end
