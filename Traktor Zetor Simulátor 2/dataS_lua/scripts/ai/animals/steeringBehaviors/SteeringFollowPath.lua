SteeringFollowPath = SteeringBehavior:new("FollowPath", 500)
SteeringFollowPath.distanceToPathNormal = 3
SteeringFollowPath.distanceToPathMaximum = 10
SteeringFollowPath.allowedTimeOffTrack = 5000
function SteeringFollowPath:applyToAgent(agent, basicWeight, targetX, targetY, targetZ)
  local motionDataTable = agent.motionData
  local currentPositionX, currentPositionY, currentPositionZ = motionDataTable.lastCalculationUpdateValidPositionX, motionDataTable.lastCalculationUpdateValidPositionY, motionDataTable.lastCalculationUpdateValidPositionZ
  local navPathId = createNavPath("NavPath")
  buildNavPath(navPathId, agent.stateData.currentNavMeshId, currentPositionX, currentPositionY, currentPositionZ, targetX, targetY, targetZ)
  local waypointCount = getNavPathNumOfWaypoints(navPathId)
  local waypointList = {}
  for i = 0, waypointCount - 1 do
    local waypoint = {}
    waypoint.x, waypoint.y, waypoint.z = getNavPathWaypoint(navPathId, i)
    waypointList[i + 1] = waypoint
  end
  SteeringBehavior.applyToAgent(self, agent, basicWeight, targetX, targetY, targetZ)
  SteeringFollowPath:checkPath(waypointList)
  waypointCount = #waypointList
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  steeringBehaviorTable.waypointList = waypointList
  steeringBehaviorTable.waypointCount = waypointCount
  steeringBehaviorTable.lastWaypointId = 0
  local lastWaypoint = waypointList[steeringBehaviorTable.lastWaypointId + 1]
  steeringBehaviorTable.lastWaypointX, steeringBehaviorTable.lastWaypointY, steeringBehaviorTable.lastWaypointZ = lastWaypoint.x, lastWaypoint.y, lastWaypoint.z
  steeringBehaviorTable.currentWaypointId = 1
  local currentWaypoint = waypointList[steeringBehaviorTable.currentWaypointId + 1]
  steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ = currentWaypoint.x, currentWaypoint.y, currentWaypoint.z
  SteeringFollowPath:updateCurrentSegmentData(agent)
  SteeringFollowPath:updatePositionOnPath(agent)
end
function SteeringFollowPath:releaseFromAgent(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  SteeringBehavior.releaseFromAgent(self, agent)
end
function SteeringFollowPath:checkPath(waypointList)
  for i = 2, #waypointList do
    local lastWaypoint = waypointList[i - 1]
    local currentWaypoint = waypointList[i]
    local accuracy = 0.1
    if accuracy > math.abs(lastWaypoint.x - currentWaypoint.x) and accuracy > math.abs(lastWaypoint.y - currentWaypoint.y) and accuracy > math.abs(lastWaypoint.z - currentWaypoint.z) then
      table.remove(waypointList, i)
      return SteeringFollowPath:checkPath(waypointList)
    end
    if accuracy > math.abs(lastWaypoint.x - currentWaypoint.x) and accuracy > math.abs(lastWaypoint.z - currentWaypoint.z) then
      if i == #waypointList then
        table.remove(waypointList, i)
      else
        table.remove(waypointList, i - 1)
      end
      return SteeringFollowPath:checkPath(waypointList)
    end
    if i == #waypointList then
      return
    end
    local nextWaypoint = waypointList[i + 1]
    if accuracy > math.abs(currentWaypoint.x - nextWaypoint.x) and accuracy > math.abs(currentWaypoint.y - nextWaypoint.y) and accuracy > math.abs(currentWaypoint.z - nextWaypoint.z) then
      table.remove(waypointList, i)
      return SteeringFollowPath:checkPath(waypointList)
    end
    local lastConnectionX, lastConnectionY, lastConnectionZ = currentWaypoint.x - lastWaypoint.x, currentWaypoint.y - lastWaypoint.y, currentWaypoint.z - lastWaypoint.z
    local lastDistance = Utils.vector3Length(lastConnectionX, lastConnectionY, lastConnectionZ)
    local lastDirectionX, lastDirectionY, lastDirectionZ = lastConnectionX / lastDistance, lastConnectionY / lastDistance, lastConnectionZ / lastDistance
    local currentConnectionX, currentConnectionY, currentConnectionZ = nextWaypoint.x - currentWaypoint.x, nextWaypoint.y - currentWaypoint.y, nextWaypoint.z - currentWaypoint.z
    local currentDistance = Utils.vector3Length(currentConnectionX, currentConnectionY, currentConnectionZ)
    local currentDirectionX, currentDirectionY, currentDirectionZ = currentConnectionX / currentDistance, currentConnectionY / currentDistance, currentConnectionZ / currentDistance
    if accuracy > math.abs(lastDirectionX - currentDirectionX) and accuracy > math.abs(lastDirectionY - currentDirectionY) and accuracy > math.abs(lastDirectionZ - currentDirectionZ) then
      table.remove(waypointList, i)
      return SteeringFollowPath:checkPath(waypointList)
    end
  end
end
function SteeringFollowPath:updateCurrentSegmentData(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  steeringBehaviorTable.currentSegmentConnectionX, steeringBehaviorTable.currentSegmentConnectionY, steeringBehaviorTable.currentSegmentConnectionZ = steeringBehaviorTable.currentWaypointX - steeringBehaviorTable.lastWaypointX, steeringBehaviorTable.currentWaypointY - steeringBehaviorTable.lastWaypointY, steeringBehaviorTable.currentWaypointZ - steeringBehaviorTable.lastWaypointZ
  steeringBehaviorTable.currentSegmentDistance = Utils.vector3Length(steeringBehaviorTable.currentSegmentConnectionX, steeringBehaviorTable.currentSegmentConnectionY, steeringBehaviorTable.currentSegmentConnectionZ)
  steeringBehaviorTable.currentSegmentDirectionX, steeringBehaviorTable.currentSegmentDirectionY, steeringBehaviorTable.currentSegmentDirectionZ = steeringBehaviorTable.currentSegmentConnectionX / steeringBehaviorTable.currentSegmentDistance, steeringBehaviorTable.currentSegmentConnectionY / steeringBehaviorTable.currentSegmentDistance, steeringBehaviorTable.currentSegmentConnectionZ / steeringBehaviorTable.currentSegmentDistance
end
function SteeringFollowPath:updatePositionOnPath(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  local agentConnectionX, agentConnectionY, agentConnectionZ = agent.positionX - steeringBehaviorTable.lastWaypointX, agent.positionY - steeringBehaviorTable.lastWaypointY, agent.positionZ - steeringBehaviorTable.lastWaypointZ
  steeringBehaviorTable.currentSegmentFactor = Utils.dotProduct(steeringBehaviorTable.currentSegmentDirectionX, steeringBehaviorTable.currentSegmentDirectionY, steeringBehaviorTable.currentSegmentDirectionZ, agentConnectionX, agentConnectionY, agentConnectionZ) / steeringBehaviorTable.currentSegmentDistance
  local multiplier = steeringBehaviorTable.currentSegmentFactor * steeringBehaviorTable.currentSegmentDistance
  steeringBehaviorTable.currentPositionOnPathX, steeringBehaviorTable.currentPositionOnPathY, steeringBehaviorTable.currentPositionOnPathZ = steeringBehaviorTable.lastWaypointX + steeringBehaviorTable.currentSegmentDirectionX * multiplier, steeringBehaviorTable.lastWaypointY + steeringBehaviorTable.currentSegmentDirectionY * multiplier, steeringBehaviorTable.lastWaypointZ + steeringBehaviorTable.currentSegmentDirectionZ * multiplier
  steeringBehaviorTable.currentDistanceToPath = Utils.vector3Length(steeringBehaviorTable.currentPositionOnPathX - agent.positionX, steeringBehaviorTable.currentPositionOnPathY - agent.positionY, steeringBehaviorTable.currentPositionOnPathZ - agent.positionZ)
  local currentTargetOnPathSegmentLength = steeringBehaviorTable.currentSegmentFactor * steeringBehaviorTable.currentSegmentDistance + 2 + steeringBehaviorTable.currentDistanceToPath * 3
  steeringBehaviorTable.currentTargetOnPathX, steeringBehaviorTable.currentTargetOnPathY, steeringBehaviorTable.currentTargetOnPathZ = steeringBehaviorTable.lastWaypointX + steeringBehaviorTable.currentSegmentDirectionX * currentTargetOnPathSegmentLength, steeringBehaviorTable.lastWaypointY + steeringBehaviorTable.currentSegmentDirectionY * currentTargetOnPathSegmentLength, steeringBehaviorTable.lastWaypointZ + steeringBehaviorTable.currentSegmentDirectionZ * currentTargetOnPathSegmentLength
  steeringBehaviorTable.currentTargetOnPathSegmentFactor = currentTargetOnPathSegmentLength / steeringBehaviorTable.currentSegmentDistance
end
function SteeringFollowPath:isCurrentWaypointReached(agent)
  return agent.steeringData[SteeringFollowPath].currentSegmentFactor >= 1
end
function SteeringFollowPath:isCurrentWaypointPathTarget(agent)
  return agent.steeringData[SteeringFollowPath].currentWaypointId == agent.steeringData[SteeringFollowPath].waypointCount - 1
end
function SteeringFollowPath:getCurrentWaypoint(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ, steeringBehaviorTable.currentWaypointId
end
function SteeringFollowPath:getNextWaypoint(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  local nextWaypointId = (steeringBehaviorTable.currentWaypointId + 1) % steeringBehaviorTable.waypointCount
  local nextWaypointIndex = nextWaypointId + 1
  return steeringBehaviorTable.waypointList[nextWaypointIndex].x, steeringBehaviorTable.waypointList[nextWaypointIndex].y, steeringBehaviorTable.waypointList[nextWaypointIndex].z, nextWaypointId
end
function SteeringFollowPath:swapToNextSegment(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  steeringBehaviorTable.lastWaypointX, steeringBehaviorTable.lastWaypointY, steeringBehaviorTable.lastWaypointZ = steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ
  steeringBehaviorTable.lastWaypointId = steeringBehaviorTable.currentWaypointId
  steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ, steeringBehaviorTable.currentWaypointId = SteeringFollowPath:getNextWaypoint(agent)
  SteeringFollowPath:updateCurrentSegmentData(agent)
  SteeringFollowPath:updatePositionOnPath(agent)
end
function SteeringFollowPath:calculateForce(agent, basicWeight)
  SteeringFollowPath:updatePath(agent)
  if SteeringFollowPath:isCurrentWaypointPathTarget(agent) and agent.steeringData[SteeringFollowPath].currentTargetOnPathSegmentFactor > 1 then
    return SteeringFollowPath:calculateForceToFinalWaypoint(agent, basicWeight)
  else
    return SteeringFollowPath:calculateForceToNonfinalWaypoint(agent, basicWeight)
  end
end
function SteeringFollowPath:calculateForceToFinalWaypoint(agent, basicWeight)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringArrival:calculateForce(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
function SteeringFollowPath:calculateForceToNonfinalWaypoint(agent, basicWeight)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringSeek:calculateForce(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
function SteeringFollowPath:calculateForce_Complex(agent, basicWeight)
  SteeringFollowPath:updatePath(agent)
  if SteeringFollowPath:isCurrentWaypointPathTarget(agent) and agent.steeringData[SteeringFollowPath].currentTargetOnPathSegmentFactor > 1 then
    return SteeringFollowPath:calculateForceToFinalWaypoint_Complex(agent, basicWeight)
  else
    return SteeringFollowPath:calculateForceToNonfinalWaypoint_Complex(agent, basicWeight)
  end
end
function SteeringFollowPath:calculateForceToFinalWaypoint_Complex(agent, basicWeight)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringArrival:calculateForce_Complex(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
function SteeringFollowPath:calculateForceToNonfinalWaypoint_Complex(agent, basicWeight)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringSeek:calculateForce_Complex(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
function SteeringFollowPath:updatePath(agent)
  SteeringFollowPath:updatePositionOnPath(agent)
  if SteeringFollowPath:isCurrentWaypointReached(agent) then
    SteeringFollowPath:swapToNextSegment(agent)
  end
  SteeringFollowPath:controlPathAbandonment(agent)
end
function SteeringFollowPath:controlPathAbandonment(agent)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  if steeringBehaviorTable.currentDistanceToPath > SteeringFollowPath.distanceToPathNormal then
    if not steeringBehaviorTable.timeWhenPathWillBeAbandoned then
      steeringBehaviorTable.timeWhenPathWillBeAbandoned = ClockWrapper.currentTicks + SteeringFollowPath.allowedTimeOffTrack
    end
    if steeringBehaviorTable.currentDistanceToPath > SteeringFollowPath.distanceToPathMaximum or ClockWrapper.currentTicks >= steeringBehaviorTable.timeWhenPathWillBeAbandoned then
      local usedBasicWeight = steeringBehaviorTable.basicWeight
      local usedTargetX, usedTargetY, usedTargetZ = steeringBehaviorTable.targetX, steeringBehaviorTable.targetY, steeringBehaviorTable.targetZ
      SteeringFollowPath:releaseFromAgent(agent)
      SteeringFollowPath:applyToAgent(agent, usedBasicWeight, usedTargetX, usedTargetY, usedTargetZ)
    end
  else
    steeringBehaviorTable.timeWhenPathWillBeAbandoned = nil
  end
end
