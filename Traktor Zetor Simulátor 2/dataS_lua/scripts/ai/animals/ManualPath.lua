ManualPath = {
  agents = {}
}
function ManualPath:initPath(agent, pathCompletedCallbackObject, pathCompletedCallbackFunction, pathInterruptedCallbackObject, pathInterruptedCallbackFunction)
  local pathData = self.agents[agent] or {}
  pathData.waypointList = {}
  pathData.currentIndex = 1
  pathData.pathCompletedCallbackObject = pathCompletedCallbackObject
  pathData.pathCompletedCallbackFunction = pathCompletedCallbackFunction
  pathData.pathInterruptedCallbackObject = pathInterruptedCallbackObject
  pathData.pathInterruptedCallbackFunction = pathInterruptedCallbackFunction
  self.agents[agent] = pathData
end
function ManualPath:addWaypoint(agent, positionX, positionY, positionZ, directionX, directionY, directionZ, timeOrSpeed, useSpeed, stopAtWaypoint)
  local pathData = self.agents[agent]
  local lastPositionX, lastPositionY, lastPositionZ, connectionX, connectionY, connectionZ, distance
  local waypointCount = table.getn(pathData.waypointList)
  if 0 < waypointCount then
    lastPositionX, lastPositionY, lastPositionZ = pathData.waypointList[waypointCount].positionX, pathData.waypointList[waypointCount].positionY, pathData.waypointList[waypointCount].positionZ
  else
    lastPositionX, lastPositionY, lastPositionZ = agent.positionX, agent.positionY, agent.positionZ
  end
  connectionX, connectionY, connectionZ = positionX - lastPositionX, positionY - lastPositionY, positionZ - lastPositionZ
  distance = Utils.vector3Length(connectionX, connectionY, connectionZ)
  if not directionX then
    local waypointCount = table.getn(pathData.waypointList)
    if 0 < waypointCount then
      if 0 < distance then
        directionX, directionY, directionZ = connectionX / distance, connectionY / distance, connectionZ / distance
      else
        directionX, directionY, directionZ = pathData.waypointList[waypointCount].directionX, pathData.waypointList[waypointCount].directionY, pathData.waypointList[waypointCount].directionZ
      end
    else
      directionX, directionY, directionZ = agent.directionX, agent.directionY, agent.directionZ
    end
  end
  local availableTime
  if useSpeed then
    local speedToUse = timeOrSpeed
    if 0 < speedToUse then
      availableTime = distance / speedToUse * 1000
    else
      availableTime = 0
    end
  else
    availableTime = timeOrSpeed
  end
  table.insert(pathData.waypointList, {
    positionX = positionX,
    positionY = positionY,
    positionZ = positionZ,
    directionX = directionX,
    directionY = directionY,
    directionZ = directionZ,
    availableTime = availableTime,
    stopAtWaypoint = stopAtWaypoint
  })
end
function ManualPath:startPath(agent)
  local pathData = self.agents[agent]
  local currentWaypoint = pathData.waypointList[pathData.currentIndex]
  if currentWaypoint then
    local targetPositionX, targetPositionY, targetPositionZ = currentWaypoint.positionX, currentWaypoint.positionY, currentWaypoint.positionZ
    local targetDirectionX, targetDirectionY, targetDirectionZ = currentWaypoint.directionX, currentWaypoint.directionY, currentWaypoint.directionZ
    local availableTime = currentWaypoint.availableTime
    return self:startManualPositionOverride(agent, targetPositionX, targetPositionY, targetPositionZ, targetDirectionX, targetDirectionY, targetDirectionZ, availableTime, currentWaypoint.stopAtWaypoint, self, self.positionReachedCallbackFunction)
  elseif pathData.pathCompletedCallbackFunction then
    return pathData.pathCompletedCallbackFunction(pathData.pathCompletedCallbackObject, agent)
  else
    return
  end
end
function ManualPath:positionReachedCallbackFunction(agent)
  local pathData = self.agents[agent]
  pathData.currentIndex = pathData.currentIndex + 1
  return self:startPath(agent)
end
function ManualPath:startManualPositionOverride(agent, targetPositionX, targetPositionY, targetPositionZ, targetDirectionX, targetDirectionY, targetDirectionZ, availableTime, isStop, positionReachedCallbackObject, positionReachedCallbackFunction)
  local motionDataTable = agent.motionData
  local minDistance = 0.1
  local minAngle = 0.1
  local currentPositionX, currentPositionY, currentPositionZ = agent.positionX, agent.positionY, agent.positionZ
  local currentDirectionX, currentDirectionY, currentDirectionZ = agent.directionX, agent.directionY, agent.directionZ
  local connectionToTargetX, connectionToTargetY, connectionToTargetZ = targetPositionX - agent.positionX, targetPositionY - agent.positionY, targetPositionZ - agent.positionZ
  local connectionLength = Utils.vector3Length(connectionToTargetX, connectionToTargetY, connectionToTargetZ)
  local directionToTargetX, directionToTargetY, directionToTargetZ
  if minDistance >= connectionLength then
    connectionLength = 0
    directionToTargetX, directionToTargetY, directionToTargetZ = currentDirectionX, currentDirectionY, currentDirectionZ
  else
    directionToTargetX, directionToTargetY, directionToTargetZ = connectionToTargetX / connectionLength, connectionToTargetY / connectionLength, connectionToTargetZ / connectionLength
  end
  local angleToRotate = math.acos(math.min(1, math.max(-1, Utils.dotProduct(currentDirectionX, currentDirectionY, currentDirectionZ, targetDirectionX, targetDirectionY, targetDirectionZ))))
  local isRight = 0 < Utils.dotProduct(targetDirectionX, targetDirectionY, targetDirectionZ, agent.directionSideX, agent.directionSideY, agent.directionSideZ)
  angleToRotate = angleToRotate * (isRight and -1 or 1)
  if minDistance >= connectionLength and minAngle >= math.abs(angleToRotate) then
    if positionReachedCallbackFunction then
      if positionReachedCallbackObject then
        return positionReachedCallbackObject.positionReachedCallbackFunction(positionReachedCallbackObject, agent)
      else
        return positionReachedCallbackFunction(agent)
      end
    end
    return
  end
  local storageTable = MotionControl.startManualPositionOverride(agent, self)
  storageTable.startPositionX, storageTable.startPositionY, storageTable.startPositionZ = currentPositionX, currentPositionY, currentPositionZ
  storageTable.targetPositionX, storageTable.targetPositionY, storageTable.targetPositionZ = targetPositionX, targetPositionY, targetPositionZ
  storageTable.connectionToTargetX, storageTable.connectionToTargetY, storageTable.connectionToTargetZ = connectionToTargetX, connectionToTargetY, connectionToTargetZ
  storageTable.directionToTargetX, storageTable.directionToTargetY, storageTable.directionToTargetZ = directionToTargetX, directionToTargetY, directionToTargetZ
  storageTable.startDirectionX, storageTable.startDirectionY, storageTable.startDirectionZ = currentDirectionX, currentDirectionY, currentDirectionZ
  storageTable.targetDirectionX, storageTable.targetDirectionY, storageTable.targetDirectionZ = targetDirectionX, targetDirectionY, targetDirectionZ
  storageTable.angleToRotate = angleToRotate
  storageTable.availableTime = availableTime
  storageTable.spentTime = 0
  storageTable.positionReachedCallbackObject = positionReachedCallbackObject
  storageTable.positionReachedCallbackFunction = positionReachedCallbackFunction
  storageTable.isStop = isStop
end
function ManualPath:updatePosition(agent, dt, motionDataTable, storageTable)
  local spendTime = storageTable.spentTime
  spendTime = spendTime + dt
  local factor
  if storageTable.availableTime > 0 then
    factor = spendTime / storageTable.availableTime
  else
    factor = 1
  end
  local updateFinished = false
  if 1 <= factor then
    updateFinished = true
    factor = 1
  end
  if storageTable.isStop then
    local remainingFactor = 1 - factor
    factor = 1 - remainingFactor * remainingFactor * remainingFactor
  end
  agent.positionX, agent.positionY, agent.positionZ = storageTable.startPositionX + storageTable.connectionToTargetX * factor, storageTable.startPositionY + storageTable.connectionToTargetY * factor, storageTable.startPositionZ + storageTable.connectionToTargetZ * factor
  agent.directionX, agent.directionY, agent.directionZ = MotionControl:getRotatedDirection(storageTable.startDirectionX, storageTable.startDirectionY, storageTable.startDirectionZ, 0, factor * storageTable.angleToRotate, 0)
  if updateFinished then
    self:endManualPositionOverride(agent, storageTable)
  else
    storageTable.spentTime = spendTime
  end
end
function ManualPath:endManualPositionOverride(agent, storageTable)
  MotionControl.stopManualPositionOverride(agent)
  if storageTable.positionReachedCallbackFunction then
    return storageTable.positionReachedCallbackFunction(storageTable.positionReachedCallbackObject, agent)
  end
end
function ManualPath:stopPath(agent)
  local pathData = self.agents[agent]
  local currentWaypoint = pathData.waypointList[pathData.currentIndex]
  if currentWaypoint then
    self:endManualPositionOverride(agent, pathData)
    if pathData.pathInterruptedCallbackFunction then
      return pathData.pathInterruptedCallbackFunction(pathData.pathInterruptedCallbackObject, agent)
    else
      return
    end
  end
end
