SteeringObstacleAvoidance = SteeringBehavior:new("ObstacleAvoidance", 1000)
function SteeringObstacleAvoidance:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  local basicMaximumDistance = agent.mediumDistance
  local functionResult = getNavMeshDistanceToWall(agent.stateData.currentNavMeshId, agent.positionX, agent.positionY, agent.positionZ, basicMaximumDistance, "obstacleAccelerationCallback", self)
  local obstaclePositionX, obstaclePositionY, obstaclePositionZ = self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ
  self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ = nil, nil, nil
  local obstacleNormalX, obstacleNormalY, obstacleNormalZ = self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ
  self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ = nil, nil, nil
  local distanceToObstacle = self.distance
  self.distance = nil
  if distanceToObstacle < 0 or functionResult == basicMaximumDistance then
    distanceToObstacle = basicMaximumDistance + 1
  end
  local forceX, forceY, forceZ = 0, 0, 0
  local importance = 0
  local complexity = 0
  if basicMaximumDistance <= distanceToObstacle then
    return forceX, forceY, forceZ, importance, complexity
  end
  local obstacleConnectionX, obstacleConnectionY, obstacleConnectionZ = obstaclePositionX - agent.positionX, obstaclePositionY - agent.positionY, obstaclePositionZ - agent.positionZ
  local obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ
  if 0 < distanceToObstacle then
    obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ = obstacleConnectionX / distanceToObstacle, obstacleConnectionY / distanceToObstacle, obstacleConnectionZ / distanceToObstacle
  else
    obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ = agent.directionX, agent.directionY, agent.directionZ
  end
  local angleToObstacle = Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ)
  local distanceModification = agent:getBodyDimensionInDirection(obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ)
  local maximumDistance = basicMaximumDistance - distanceModification
  local minimumDistance = distanceModification
  local distance = distanceToObstacle - distanceModification
  distance = math.min(distance, maximumDistance)
  distance = math.max(distance, 0.01)
  local distanceFactor = distance / maximumDistance
  forceX, forceY, forceZ = obstacleNormalX, obstacleNormalY, obstacleNormalZ
  local angleFactor = (angleToObstacle + 1) / 2
  local importance = 1 - distanceFactor
  importance = importance * importance
  importance = importance * angleFactor
  complexity = importance
  return forceX, forceY, forceZ, importance, complexity
end
function SteeringObstacleAvoidance:obstacleAccelerationCallback(distance, positionX, positionY, positionZ, normalX, normalY, normalZ)
  self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ = positionX, positionY, positionZ
  self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ = normalX, normalY, normalZ
  self.distance = distance
end
function SteeringObstacleAvoidance:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  local basicMaximumDistance = agent.nearDistance
  local distanceToWall = getNavMeshDistanceToWall(agent.stateData.currentNavMeshId, agent.positionX, 0, agent.positionZ, basicMaximumDistance, "obstacleAccelerationCallback", self)
  local obstaclePositionX, obstaclePositionY, obstaclePositionZ = self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ
  self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ = nil, nil, nil
  local obstacleNormalX, obstacleNormalY, obstacleNormalZ = self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ
  self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ = nil, nil, nil
  local distanceToWall = math.max(1.0E-4, self.distance - agent.length)
  self.distance = nil
  local force = 0
  local directionX, directionY, directionZ = 0, 0, 0
  local rotationX, rotationY, rotationZ = 0, 0, 0
  local importance = 0
  if 0 < distanceToWall then
    do
      local obstacleConnectionX, obstacleConnectionY, obstacleConnectionZ = obstaclePositionX - agent.positionX, obstaclePositionY - agent.positionY, obstaclePositionZ - agent.positionZ
      local obstacleDistance = Utils.vector3Length(obstacleConnectionX, obstacleConnectionY, obstacleConnectionZ)
      local obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ = obstacleConnectionX / obstacleDistance, obstacleConnectionY / obstacleDistance, obstacleConnectionZ / obstacleDistance
      local angleToObstacle = Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, obstacleDirectionX, obstacleDirectionY, obstacleDirectionZ)
      local distanceFactor = 1 - distanceToWall / basicMaximumDistance
      local isClose = distanceToWall < 1
      local isNear = distanceToWall < 2
      local isWallInFront = 0.25 < angleToObstacle
      local function rotateAwayFromWall()
        local directionX, directionY, directionZ = obstacleDirectionX * -1, obstacleDirectionY * -1, obstacleDirectionZ * -1
        local rotationX, rotationY, rotationZ = MotionControl:convertDirectionToRotation(agent, directionX, directionY, directionZ)
        return directionX, directionY, directionZ, rotationX, rotationY, rotationZ
      end
      local function decelerate()
        local force = self.basicForce * -1 * distanceFactor
        return force
      end
      local function accelerate()
        local force = self.basicForce * distanceFactor
        return force
      end
      if isClose and isWallInFront then
        force = decelerate()
        directionX, directionY, directionZ, rotationX, rotationY, rotationZ = rotateAwayFromWall()
      elseif isClose and not isWallInFront then
        force = accelerate()
        directionX, directionY, directionZ, rotationX, rotationY, rotationZ = rotateAwayFromWall()
      elseif isNear and isWallInFront then
        force = accelerate()
        directionX, directionY, directionZ, rotationX, rotationY, rotationZ = rotateAwayFromWall()
      elseif isNear and not isWallInFront then
        force = accelerate()
        directionX, directionY, directionZ, rotationX, rotationY, rotationZ = rotateAwayFromWall()
      elseif isWallInFront then
        directionX, directionY, directionZ, rotationX, rotationY, rotationZ = rotateAwayFromWall()
      elseif not isWallInFront then
      end
      local standardDistance = basicMaximumDistance
      importance = math.max(0, basicWeight / distanceToWall - basicWeight / standardDistance)
    end
  end
  return force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ, importance
end
