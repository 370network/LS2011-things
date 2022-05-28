Animal = {}
local Animal_mt = Class(Animal, Agent)
function Animal:new(presets_hash)
  presets_hash = presets_hash or {}
  assert(presets_hash.herd, "You didn't specify the herd this animal belongs to")
  if self == Animal then
    self = setmetatable({}, Animal_mt)
  end
  presets_hash.name = presets_hash.name or "Animal" .. tostring(presets_hash.herd.uniqueHerdAnimalId)
  presets_hash.type = presets_hash.type or EntityType.ANIMAL
  Animal:superClass().new(self, presets_hash)
  self.herd = presets_hash.herd
  self.boundingBoxId = presets_hash.boundingBoxId
  self.mass = 1
  self.width = 1
  self.length = 2
  self.height = 1
  self[AnimalMotionData.SPEED_STAND] = 0
  self[AnimalMotionData.SPEED_WANDER] = presets_hash[AnimalMotionData.SPEED_WANDER] or presets_hash.speed or 0.5
  self[AnimalMotionData.SPEED_WALK] = presets_hash[AnimalMotionData.SPEED_WALK] or self[AnimalMotionData.SPEED_WANDER] * 2
  self[AnimalMotionData.SPEED_RACE] = presets_hash[AnimalMotionData.SPEED_RACE] or self[AnimalMotionData.SPEED_WALK] * 5
  self[AnimalMotionData.ACCELERATION_STAND] = 0
  self[AnimalMotionData.ACCELERATION_WANDER] = presets_hash[AnimalMotionData.ACCELERATION_WANDER] or presets_hash.acceleration or 0.5
  self[AnimalMotionData.ACCELERATION_WALK] = presets_hash[AnimalMotionData.ACCELERATION_WALK] or self[AnimalMotionData.ACCELERATION_WANDER] * 2
  self[AnimalMotionData.ACCELERATION_RACE] = presets_hash[AnimalMotionData.ACCELERATION_RACE] or self[AnimalMotionData.ACCELERATION_WALK] * 4
  self.closeDistance = 2
  self.nearDistance = 7
  self.mediumDistance = 15
  self.farDistance = 20
  if not self.herd then
  end
  local length = Utils.vector3Length(self.directionX, self.directionY, self.directionZ)
  if length == 0 then
    self.directionX, self.directionY, self.directionZ = 0, 0, 1
  else
    self.directionX, self.directionY, self.directionZ = self.directionX / length, self.directionY / length, self.directionZ / length
  end
  self.directionUpX, self.directionUpY, self.directionUpZ = 0, 1, 0
  self.directionSideX, self.directionSideY, self.directionSideZ = Utils.crossProduct(self.directionUpX, self.directionUpY, self.directionUpZ, self.directionX, self.directionY, self.directionZ)
  self.requestedAccelerationX, self.requestedAccelerationY, self.requestedAccelerationZ = 0, 0, 0
  self.rotationalSpeedX, self.rotationalSpeedY, self.rotationalSpeedZ = 0, 0, 0
  self.useAI = presets_hash.useAI or false
  self.useVisualization = presets_hash.useVisualization or false
  self.useUpdateToNetwork = presets_hash.useUpdateToNetwork or false
  self.useUpdateFromNetwork = presets_hash.useUpdateFromNetwork or false
  if self.useAI then
    self.attributes = AnimalAttributeData:new({animal = self})
    self.perceptionData = AnimalPerceptionData:new()
    self.stateData = AnimalStateData:new(self, presets_hash.initialState or StateIdle)
    self.steeringData = AnimalSteeringData:new(self)
    self.motionData = AnimalMotionData:new(self)
    MotionControl:prepare(self)
  end
  if self.useVisualization then
    self.bonesId = presets_hash.bonesId
    self.meshId = presets_hash.meshId
    self.animationId = presets_hash.animationId
    self.translationMarkerId = presets_hash.translationMarkerId
    AnimationControl.prepare(self, self.bonesId, self.meshId, self.animationId, self.translationMarkerId, self.useAI and self.stateData.currentState.name or StateIdle.name)
    AnimalSoundManager.prepareForAgent(self)
    self.appearanceId = presets_hash.appearanceId
    local mirrorY, offsetX, offsetY
    local tiling = 2
    if self.appearanceId then
      mirrorY = Utils.readBit(self.appearanceId, 0) and 1 or -1
      offsetX = Utils.readBit(self.appearanceId, 1) and 0 or 0.5
      offsetY = Utils.readBit(self.appearanceId, 2) and 0 or 0.5
    else
      mirrorY = math.random(0, 1) * 2 - 1
      offsetX = math.random(0, tiling - 1) / tiling
      offsetY = math.random(0, tiling - 1) / tiling
      self.appearanceId = Utils.packBits(mirrorY == 1, offsetX == 0, offsetY == 0)
    end
    setShaderParameter(self.meshId, "mirrorScaleAndOffsetUV", 1, mirrorY, 0, 0.5, false)
    setShaderParameter(self.meshId, "atlasInvSizeAndOffsetUV", 1 / tiling, 1 / tiling, offsetX, offsetY, false)
  end
  if self.useAI then
    self.stateData.currentState:onEnter(self)
    Perception:startPerception(self)
  end
  self:setUpdateAgentFunction()
  self.baseName = presets_hash.baseName
  self.baseNameCount = presets_hash.baseNameCount
  return self
end
function Animal:setUpdateAgentFunction()
  local functionString = "local f = function(self, dt) "
  if self.useAI then
    functionString = functionString .. "Perception:update(self, dt); "
    functionString = functionString .. "MotionControl:updatePosition(self, dt); "
    functionString = functionString .. "self.stateData.currentState:update(self, dt); "
  end
  if self.useUpdateFromNetwork then
    functionString = functionString .. "self:updateFromNetwork(); "
  end
  if self.useUpdateToNetwork then
    functionString = functionString .. "self:updateToNetwork(); "
  end
  functionString = functionString .. "end; "
  functionString = functionString .. "return f; "
  local updateAgentFunction = loadstring(functionString)()
  self.updateAgent = updateAgentFunction
end
function Animal:updateToNetwork()
end
function Animal:updateFromNetwork()
end
function Animal:getPosition()
  return self.positionX, self.positionY, self.positionZ
end
function Animal:setPosition(newPositionX, newPositionY, newPositionZ)
  self.positionX, self.positionY, self.positionZ = newPositionX, newPositionY, newPositionZ
end
function Animal:getDirection()
  return self.directionX, self.directionY, self.directionZ
end
function Animal:setDirection(newDirectionX, newDirectionY, newDirectionZ)
  local length = Utils.vector3Length(newDirectionX, newDirectionY, newDirectionZ)
  if 0 < length then
    self.directionX, self.directionY, self.directionZ = newDirectionX / length, newDirectionY / length, newDirectionZ / length
    setDirection(self.objectId, self.directionX, self.directionY, self.directionZ, self.directionUpX, self.directionUpY, self.directionUpZ)
    self.directionSideX, self.directionSideY, self.directionSideZ = Utils.crossProduct(self.directionUpX, self.directionUpY, self.directionUpZ, self.directionX, self.directionY, self.directionZ)
  end
end
function Animal:getBodyDimensionInDirection(directionOfInterestX, directionOfInterestY, directionOfInterestZ)
  return math.max(self.width, self.length) / 2
end
function Animal:getBodyDimensionAtAngle(angle)
  local factor = math.abs(angle)
  return (factor * self.length + (1 - factor) * self.width) * 0.5
end
function Animal:draw()
  local texts = {}
  if self.areStatusTextsRendered then
    local statusTexts = {
      "name : " .. self.name,
      "state : " .. self.stateData.currentState.name,
      "hunger : " .. string.format("%.3f", self.attributes[AnimalAttributeData.HUNGER].value),
      "thirst : " .. string.format("%.3f", self.attributes[AnimalAttributeData.THIRST].value),
      "energy : " .. string.format("%.3f", self.attributes[AnimalAttributeData.ENERGY].value),
      "milk : " .. string.format("%.3f", self.attributes[AnimalAttributeData.MILK].value)
    }
    self:renderStatusTexts(statusTexts)
  end
  setTextAlignment(RenderText.ALIGN_RIGHT)
  if next(texts) then
    self:renderStatusTexts(texts)
  end
  setTextAlignment(RenderText.ALIGN_LEFT)
  drawDebugArrow(self.positionX, self.positionY + 2, self.positionZ, self.directionX, self.directionY, self.directionZ, 0, 1, 0, 1, 1, 1)
end
function Animal:renderStatusTexts(texts)
  local screenPositionX, screenPositionY, screenPositionZ = project(self.positionX, self.positionY, self.positionZ)
  local textHeight = 0.03
  local maxIndex = #texts
  for i, text in ipairs(texts) do
    self:renderStatusText(screenPositionX, screenPositionY, textHeight, i, maxIndex, text)
  end
end
function Animal:renderStatusText(screenPositionX, screenPositionY, textHeight, index, maxIndex, text)
  renderText(screenPositionX, screenPositionY + textHeight * maxIndex * 0.5 - textHeight * index, textHeight, text)
end
function Animal:addChangeCallback(changeCallback, objectCalled)
  objectCalled = objectCalled or false
  self.changeCallbacks = self.changeCallbacks or {}
  self.changeCallbacks[changeCallback] = objectCalled
end
function Animal:removeChangeCallback(changeCallback)
  self.changeCallbacks = self.changeCallbacks or {}
  self.changeCallbacks[changeCallback] = nil
end
function Animal:animalChanged()
  self.changeCallbacks = self.changeCallbacks or {}
  for changeCallback, objectCalled in pairs(self.changeCallbacks) do
    if objectCalled then
      objectCalled:changeCallback()
    else
      changeCallback()
    end
  end
end
function Animal:initDebugPositionTrace(objectId)
  self.traceHeightAdjustement = 2.5
  self.traceLastX, self.traceLastY, self.traceLastZ = self.positionX, self.positionY, self.positionZ
  self.traceTangentLength = 0.1
  self.traceObjectId = objectId
  self.tracePositionsX = {}
  self.tracePositionsY = {}
  self.tracePositionsZ = {}
  self.traceTangentPositionsX = {}
  self.traceTangentPositionsY = {}
  self.traceTangentPositionsZ = {}
  self:debugPositionTraceAddPosition()
  self.traceStart = 2
end
function Animal:debugPositionTraceAddPosition()
  local positionX, positionY, positionZ, directionX, directionY, directionZ
  if self.traceObjectId then
    positionX, positionY, positionZ = getWorldTranslation(self.traceObjectId)
    directionX, directionY, directionZ = localDirectionToWorld(self.traceObjectId, 0, 0, 1)
  else
    positionX, positionY, positionZ = self.positionX, self.positionY, self.positionZ
    directionX, directionY, directionZ = self.directionX, self.directionY, self.directionZ
  end
  table.insert(self.tracePositionsX, positionX)
  table.insert(self.tracePositionsY, positionY + self.traceHeightAdjustement)
  table.insert(self.tracePositionsZ, positionZ)
  table.insert(self.traceTangentPositionsX, positionX + self.traceTangentLength * directionX)
  table.insert(self.traceTangentPositionsY, positionY + self.traceTangentLength * directionY + self.traceHeightAdjustement)
  table.insert(self.traceTangentPositionsZ, positionZ + self.traceTangentLength * directionZ)
end
function Animal:debugPositionTrace()
  self:debugPositionTraceAddPosition()
  for i = self.traceStart, table.getn(self.tracePositionsX) do
    drawDebugLine(self.tracePositionsX[i - 1], self.tracePositionsY[i - 1], self.tracePositionsZ[i - 1], 1, 1, 1, self.tracePositionsX[i], self.tracePositionsY[i], self.tracePositionsZ[i], 1, 1, 1)
    drawDebugLine(self.tracePositionsX[i], self.tracePositionsY[i], self.tracePositionsZ[i], 0, 0, 0, self.traceTangentPositionsX[i], self.traceTangentPositionsY[i], self.traceTangentPositionsZ[i], 0, 0, 0)
  end
  if table.getn(self.tracePositionsX) - self.traceStart > 125 then
    self.traceStart = self.traceStart + 1
  end
end
function Animal:delete()
  if self.useAI then
    self.stateData.currentState:onLeave(self)
  end
  if self.useVisualization then
    AnimalSoundManager.releaseFromAgent(self)
    AnimationControl.releaseAgent(self)
  end
  Animal:superClass().delete(self)
end
