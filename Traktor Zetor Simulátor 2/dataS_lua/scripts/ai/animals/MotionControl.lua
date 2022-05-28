MotionControl = {}
Class(MotionControl)
function MotionControl:prepare(agent)
  self:putAnimalOnGround(agent)
  local motionDataTable = agent.motionData
  local heightAdjustment = motionDataTable.positionAdjustmentYPerMS * motionDataTable.timeBetweenCalculationUpdates
  agent.positionY = agent.positionY + heightAdjustment
  motionDataTable.lastCalculationUpdateValidPositionX, motionDataTable.lastCalculationUpdateValidPositionY, motionDataTable.lastCalculationUpdateValidPositionZ = agent.positionX, agent.positionY, agent.positionZ
end
function MotionControl:convertDirectionToRotation(agent, directionX, directionY, directionZ)
  local up = agent.directionUp
  local forwardX, forwardY, forwardZ = agent.directionX, agent.directionY, agent.directionZ
  local sideX, sideY, sideZ = agent.directionSideX, agent.directionSideY, agent.directionSideZ
  local rotationX, rotationY, rotationZ = 0, 0, 0
  rotationY = Utils.dotProduct(forwardX, 0, forwardZ, directionX, directionY, directionZ)
  rotationY = (1 - (rotationY + 1) / 2) * math.pi
  if 0 < Utils.dotProduct(sideX, sideY, sideZ, directionX, directionY, directionZ) then
    rotationY = rotationY * -1
  end
  return rotationX, rotationY, rotationZ
end
function MotionControl:forceFullPositionUpdate(agent)
  local motionDataTable = agent.motionData
  motionDataTable.timeToNextCalculationUpdate = 0
  motionDataTable.lastCalculationUpdateAccelerationX = 0
  motionDataTable.lastCalculationUpdateAccelerationY = 0
  motionDataTable.lastCalculationUpdateAccelerationZ = 0
end
function MotionControl.startManualPositionOverride(agent, overrideObject)
  local motionDataTable = agent.motionData
  motionDataTable.isManualPositionOverrideActive = true
  motionDataTable.manualPositionOverrideObject = overrideObject
  local storageTable = {}
  motionDataTable.manualPositionOverrideStorage = storageTable
  return storageTable
end
function MotionControl.stopManualPositionOverride(agent)
  local motionDataTable = agent.motionData
  motionDataTable.isManualPositionOverrideActive = false
  motionDataTable.manualPositionOverrideObject = nil
  motionDataTable.manualPositionOverrideStorage = nil
  MotionControl:updatePositionValidity(agent)
end
function MotionControl:updatePosition(agent, dt)
  local dt_s = dt / 1000
  local motionDataTable = agent.motionData
  if motionDataTable.isManualPositionOverrideActive then
    motionDataTable.manualPositionOverrideObject:updatePosition(agent, dt, motionDataTable, motionDataTable.manualPositionOverrideStorage)
    return
  end
  agent.positionY = agent.positionY + dt * motionDataTable.positionAdjustmentYPerMS
  if motionDataTable.isPositionCorrectionActive then
    agent.positionX = agent.positionX + dt * motionDataTable.positionAdjustmentXPerMS
    agent.positionZ = agent.positionZ + dt * motionDataTable.positionAdjustmentZPerMS
    agent.directionX, agent.directionY, agent.directionZ = MotionControl:getRotatedDirection(agent.directionX, agent.directionY, agent.directionZ, 0, dt * motionDataTable.directionAdjustmentAnglePerMS, 0)
  end
  motionDataTable.timeToNextCalculationUpdate = motionDataTable.timeToNextCalculationUpdate - dt
  if 0 >= motionDataTable.timeToNextCalculationUpdate then
    motionDataTable.timeToNextCalculationUpdate = motionDataTable.timeToNextCalculationUpdate + motionDataTable.timeBetweenCalculationUpdates
    motionDataTable.lastCalculationUpdateTime = ClockWrapper.currentTicks
    self:updatePositionByCalculation(agent, dt, dt_s)
  else
    if motionDataTable.isPositionCorrectionActive then
      return
    end
    self:updatePositionByInterpolation(agent, dt, dt_s)
  end
end
function MotionControl:updatePositionByInterpolation(agent, dt, dt_s)
  local motionDataTable = agent.motionData
  local allowedForwardAcceleration, allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ = self:limitSteering(agent, agent.speed, motionDataTable.requestedLinearAcceleration, agent.rotationalSpeedX, agent.rotationalSpeedY, agent.rotationalSpeedZ, motionDataTable.requestedRotationalAccelerationX, motionDataTable.requestedRotationalAccelerationY, motionDataTable.requestedRotationalAccelerationZ, motionDataTable.situationComplexity, dt_s)
  MotionControl:updateAgentData(agent, allowedForwardAcceleration, allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ, dt, dt_s)
  MotionControl:dampenAgentMotionData(agent, dt, dt_s)
end
function MotionControl:calculateAccelerations(agent, dt_s)
  local finalForceX, finalForceY, finalForceZ, compoundComplexity = ForceMixer.calculateSteeringForce(agent)
  local forceStrength = Utils.vector3Length(finalForceX, finalForceY, finalForceZ)
  local linearAcceleration, rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ, complexity
  if 0 < forceStrength then
    local forceDirectionX, forceDirectionY, forceDirectionZ = finalForceX / forceStrength, finalForceY / forceStrength, finalForceZ / forceStrength
    local angleToTarget = Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, forceDirectionX, forceDirectionY, forceDirectionZ)
    local isInFront = 0 <= angleToTarget
    linearAcceleration = agent.stateData.accelerationLimit
    rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ = MotionControl:convertDirectionToRotation(agent, forceDirectionX, forceDirectionY, forceDirectionZ)
    local divisor = dt_s * dt_s
    if 0 < divisor then
      rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ = rotationalAccelerationX / divisor, rotationalAccelerationY / divisor, rotationalAccelerationZ / divisor
    else
      rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ = 0, 0, 0
    end
    local influenceAngle = 0.25
    if angleToTarget > 1 - influenceAngle then
      local angleFactor = math.max(0, (angleToTarget - (1 - influenceAngle)) * (1 / influenceAngle))
      angleFactor = angleFactor ^ 2
      local multiplier = 1 - angleFactor
      rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ = rotationalAccelerationX * multiplier, rotationalAccelerationY * multiplier, rotationalAccelerationZ * multiplier
    end
    complexity = math.min(1, compoundComplexity)
  else
    linearAcceleration, rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ, complexity = 0, 0, 0, 0, 1
  end
  return linearAcceleration, rotationalAccelerationX, rotationalAccelerationY, rotationalAccelerationZ, complexity
end
function MotionControl:updatePositionByCalculation(agent, dt, dt_s)
  local motionDataTable = agent.motionData
  MotionControl:updatePositionValidity(agent, dt, dt_s)
  motionDataTable.requestedLinearAcceleration, motionDataTable.requestedRotationalAccelerationX, motionDataTable.requestedRotationalAccelerationY, motionDataTable.requestedRotationalAccelerationZ, motionDataTable.situationComplexity = MotionControl:calculateAccelerations(agent, dt_s)
  if motionDataTable.isPositionCorrectionActive then
    return
  end
  local allowedForwardAcceleration, allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ = self:limitSteering(agent, agent.speed, motionDataTable.requestedLinearAcceleration, agent.rotationalSpeedX, agent.rotationalSpeedY, agent.rotationalSpeedZ, motionDataTable.requestedRotationalAccelerationX, motionDataTable.requestedRotationalAccelerationY, motionDataTable.requestedRotationalAccelerationZ, motionDataTable.situationComplexity, dt_s)
  MotionControl:updateAgentData(agent, allowedForwardAcceleration, allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ, dt, dt_s)
  MotionControl:dampenAgentMotionData(agent, dt, dt_s)
end
function MotionControl:updatePositionValidity(agent)
  local motionDataTable = agent.motionData
  local isPositionAllowed = self:putAnimalOnGround(agent)
  local lastValidPositionX, lastValidPositionY, lastValidPositionZ = motionDataTable.lastCalculationUpdateValidPositionX, motionDataTable.lastCalculationUpdateValidPositionY, motionDataTable.lastCalculationUpdateValidPositionZ
  local targetPositionX, targetPositionY, targetPositionZ = agent.positionX, agent.positionY, agent.positionZ
  local distanceToWall = getNavMeshDistanceToWall(agent.stateData.currentNavMeshId, targetPositionX, targetPositionY, targetPositionZ, 10, "")
  isPositionAllowed = isPositionAllowed and 0.01 < distanceToWall
  local isDistanceValid, hitDistance = navMeshRaycast(agent.stateData.currentNavMeshId, lastValidPositionX, lastValidPositionY, lastValidPositionZ, targetPositionX, targetPositionY, targetPositionZ)
  isPositionAllowed = isPositionAllowed and hitDistance == 1
  if not isPositionAllowed then
    local distanceToWall = getNavMeshDistanceToWall(agent.stateData.currentNavMeshId, lastValidPositionX, lastValidPositionY, lastValidPositionZ, 10, "navMeshObstacleCallback", self)
    local directionToPositionX, directionToPositionY, directionToPositionZ = agent.positionX - lastValidPositionX, agent.positionY - lastValidPositionY, agent.positionZ - lastValidPositionZ
    local wallNormalX, wallNormalY, wallNormalZ = MotionControl.obstacleNormalX, 0, MotionControl.obstacleNormalZ
    local normalLength = Utils.vector3Length(wallNormalX, wallNormalY, wallNormalZ)
    if 0 < normalLength then
      wallNormalX, wallNormalY, wallNormalZ = wallNormalX / normalLength, wallNormalY / normalLength, wallNormalZ / normalLength
    else
      wallNormalX, wallNormalY, wallNormalZ = agent.directionX, agent.directionY, agent.directionZ
    end
    local wallSideDirectionX, wallSideDirectionY, wallSideDirectionZ = Utils.crossProduct(wallNormalX, wallNormalY, wallNormalZ, 0, 1, 0)
    local distanceOnRay = Utils.dotProduct(directionToPositionX, directionToPositionY, directionToPositionZ, wallSideDirectionX, wallSideDirectionY, wallSideDirectionZ)
    local finalPositionX, finalPositionY, finalPositionZ = lastValidPositionX + wallSideDirectionX * distanceOnRay, lastValidPositionY + wallSideDirectionY * distanceOnRay, lastValidPositionZ + wallSideDirectionZ * distanceOnRay
    local finalDistanceToWall = getNavMeshDistanceToWall(agent.stateData.currentNavMeshId, finalPositionX, finalPositionY, finalPositionZ, 10, "")
    local obstacleHit = finalDistanceToWall <= 0.01
    local isDistanceValid, hitDistance = navMeshRaycast(agent.stateData.currentNavMeshId, lastValidPositionX, lastValidPositionY, lastValidPositionZ, finalPositionX, finalPositionY, finalPositionZ)
    obstacleHit = obstacleHit or hitDistance ~= 1
    if obstacleHit then
      agent.velocityX, agent.velocityY, agent.velocityZ = 0, 0, 0
      agent.speed = 0
      motionDataTable.requestedLinearAcceleration = 0
    else
      motionDataTable.lastCalculationUpdateValidPositionX, motionDataTable.lastCalculationUpdateValidPositionY, motionDataTable.lastCalculationUpdateValidPositionZ = finalPositionX, finalPositionY, finalPositionZ
    end
    local targetConnectionX, targetConnectionY, targetConnectionZ = motionDataTable.lastCalculationUpdateValidPositionX - agent.positionX, motionDataTable.lastCalculationUpdateValidPositionY - agent.positionY, motionDataTable.lastCalculationUpdateValidPositionZ - agent.positionZ
    motionDataTable.positionAdjustmentXPerMS = targetConnectionX / motionDataTable.timeBetweenCalculationUpdates
    motionDataTable.positionAdjustmentZPerMS = targetConnectionZ / motionDataTable.timeBetweenCalculationUpdates
    local connectionLength = Utils.vector3Length(targetConnectionX, targetConnectionY, targetConnectionZ)
    local angle
    if 0 < connectionLength then
      local targetDirectionX, targetDirectionY, targetDirectionZ = wallNormalX, wallNormalY, wallNormalZ
      angle = math.acos(math.min(1, math.max(-1, Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, targetDirectionX, targetDirectionY, targetDirectionZ))))
      local isRight = 0 < Utils.dotProduct(targetDirectionX, targetDirectionY, targetDirectionZ, agent.directionSideX, agent.directionSideY, agent.directionSideZ)
      angle = angle * (isRight and -1 or 1)
      angle = angle * 0.5
    else
      angle = 0
    end
    motionDataTable.directionAdjustmentAnglePerMS = angle / motionDataTable.timeBetweenCalculationUpdates
    motionDataTable.isPositionCorrectionActive = true
    MotionControl.obstaclePositionX, MotionControl.obstaclePositionY, MotionControl.obstaclePositionZ = nil, nil, nil
    MotionControl.obstacleNormalX, MotionControl.obstacleNormalY, MotionControl.obstacleNormalZ = nil, nil, nil
    MotionControl.distance = nil
  else
    motionDataTable.lastCalculationUpdateValidPositionX, motionDataTable.lastCalculationUpdateValidPositionY, motionDataTable.lastCalculationUpdateValidPositionZ = agent.positionX, agent.positionY, agent.positionZ
    motionDataTable.positionAdjustmentXPerMS = 0
    motionDataTable.positionAdjustmentZPerMS = 0
    motionDataTable.directionAdjustmentAnglePerMS = 0
    motionDataTable.isPositionCorrectionActive = false
  end
end
function MotionControl:navMeshObstacleCallback(distance, positionX, positionY, positionZ, normalX, normalY, normalZ)
  MotionControl.obstaclePositionX, MotionControl.obstaclePositionY, MotionControl.obstaclePositionZ = positionX, positionY, positionZ
  MotionControl.obstacleNormalX, MotionControl.obstacleNormalY, MotionControl.obstacleNormalZ = normalX, normalY, normalZ
  MotionControl.distance = distance
end
function MotionControl:updateAgentData(agent, allowedForwardAcceleration, allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ, dt, dt_s)
  agent.rotationalSpeedX, agent.rotationalSpeedY, agent.rotationalSpeedZ = agent.rotationalSpeedX + allowedRotationalAccelerationX * dt_s, agent.rotationalSpeedY + allowedRotationalAccelerationY * dt_s, agent.rotationalSpeedZ + allowedRotationalAccelerationZ * dt_s
  agent.speed = agent.speed + allowedForwardAcceleration * dt_s
  agent.directionX, agent.directionY, agent.directionZ = self:getRotatedDirection(agent.directionX, agent.directionY, agent.directionZ, agent.rotationalSpeedX * dt_s, agent.rotationalSpeedY * dt_s, agent.rotationalSpeedZ * dt_s)
  agent.directionSideX, agent.directionSideY, agent.directionSideZ = Utils.crossProduct(agent.directionUpX, agent.directionUpY, agent.directionUpZ, agent.directionX, agent.directionY, agent.directionZ)
  agent.velocityX, agent.velocityY, agent.velocityZ = agent.directionX * agent.speed, agent.directionY * agent.speed, agent.directionZ * agent.speed
  local positionChangeX, positionChangeY, positionChangeZ = agent.velocityX * dt_s, agent.velocityY * dt_s, agent.velocityZ * dt_s
  agent.positionX, agent.positionY, agent.positionZ = agent.positionX + positionChangeX, agent.positionY + positionChangeY, agent.positionZ + positionChangeZ
end
function MotionControl:dampenAgentMotionData(agent, dt, dt_s)
  local damping = 0.3
  agent.speed = agent.speed * damping ^ dt_s
  local damping = 0.1
  local multiplier = damping ^ dt_s
  agent.rotationalSpeedX, agent.rotationalSpeedY, agent.rotationalSpeedZ = agent.rotationalSpeedX * multiplier, agent.rotationalSpeedY * multiplier, agent.rotationalSpeedZ * multiplier
end
function MotionControl:putAnimalOnGround(agent)
  local motionDataTable = agent.motionData
  local terrainHeight = getTerrainHeightAtWorldPos(agent.herd.groundObjectId, agent.positionX, agent.positionY, agent.positionZ)
  local heightDisplacement = terrainHeight - agent.positionY
  motionDataTable.positionAdjustmentYPerMS = heightDisplacement / motionDataTable.timeBetweenCalculationUpdates
  return true
end
function MotionControl:getRotatedDirection(currentDirectionX, currentDirectionY, currentDirectionZ, rotationAngleX, rotationAngleY, rotationAngleZ)
  local rotationAngle = rotationAngleY
  return Utils.vector3Transformation(currentDirectionX, currentDirectionY, currentDirectionZ, math.cos(rotationAngle), 0, math.sin(rotationAngle), 0, 1, 0, -math.sin(rotationAngle), 0, math.cos(rotationAngle))
end
function MotionControl:limitSteering(agent, presentLinearSpeed, requestedLinearAcceleration, presentRotationalSpeedX, presentRotationalSpeedY, presentRotationalSpeedZ, requestedRotationalAccelerationX, requestedRotationalAccelerationY, requestedRotationalAccelerationZ, situationComplexity, dt_s)
  local allowedLinearAcceleration = 0
  local allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ = 0, 0, 0
  local complexityFactor = 1 - situationComplexity ^ 2
  local linearAccelerationMax = complexityFactor * agent.stateData.accelerationLimit
  local linearAccelerationMin = linearAccelerationMax * -0.5
  local linearSpeedMax = complexityFactor * agent.stateData.speedLimit
  local linearSpeedMin = agent.speedWander * -0.3
  local rotationalAccelerationMax = 0
  local speedOfBestMobility = agent.speedWander
  if 0 < agent.stateData.speedLimit then
    if presentLinearSpeed < 0 then
      local factor = presentLinearSpeed / linearSpeedMin
      rotationalAccelerationMax = (factor * 0.5 + 0.2) * 0.5
    elseif presentLinearSpeed <= speedOfBestMobility then
      local factor = presentLinearSpeed / speedOfBestMobility
      rotationalAccelerationMax = (factor * 0.3 + 0.2) * 0.5
    else
      local factor = 1
      rotationalAccelerationMax = (factor * 0.3 + 0.2) * 0.5
    end
  end
  rotationalAccelerationMax = rotationalAccelerationMax * 3 * agent.stateData.accelerationLimit
  if 0 < dt_s then
    allowedLinearAcceleration = requestedLinearAcceleration
    allowedLinearAcceleration = math.min(allowedLinearAcceleration, (linearSpeedMax - presentLinearSpeed) / dt_s)
    allowedLinearAcceleration = math.max(allowedLinearAcceleration, (linearSpeedMin - presentLinearSpeed) / dt_s)
    allowedLinearAcceleration = math.min(allowedLinearAcceleration, linearAccelerationMax)
    allowedLinearAcceleration = math.max(allowedLinearAcceleration, linearAccelerationMin)
  end
  if math.abs(requestedRotationalAccelerationY) > 1.0E-4 then
    allowedRotationalAccelerationY = math.min(rotationalAccelerationMax, math.abs(requestedRotationalAccelerationY)) * (requestedRotationalAccelerationY / math.abs(requestedRotationalAccelerationY))
  end
  return allowedLinearAcceleration, allowedRotationalAccelerationX, allowedRotationalAccelerationY, allowedRotationalAccelerationZ
end
function MotionControl.printAgentPositionData(agent)
  print(string.format("position : %.2f %.2f %.2f", agent.positionX, agent.positionY, agent.positionZ))
  print(string.format("direction : %.2f %.2f %.2f", agent.directionX, agent.directionY, agent.directionZ))
  print(string.format("velocity : %.2f %.2f %.2f", agent.velocityX, agent.velocityY, agent.velocityZ))
  print(string.format("speed : %.2f", agent.speed))
  print(string.format("rotationalSpeed : %.2f %.2f %.2f", agent.rotationalSpeedX, agent.rotationalSpeedY, agent.rotationalSpeedZ))
end
