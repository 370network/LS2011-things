SteeringStayClose = SteeringBehavior:new("StayClose", 500)
function SteeringStayClose:applyToAgent(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  targetPositionX, targetPositionY, targetPositionZ = agent.stateData.target.positionX, agent.stateData.target.positionY, agent.stateData.target.positionZ
  SteeringBehavior.applyToAgent(self, agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
end
function SteeringStayClose:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local target = agent.stateData.target
  local targetPositionX, targetPositionY, targetPositionZ = target.positionX, target.positionY, target.positionZ
  local targetDirectionX, targetDirectionY, targetDirectionZ = target.directionX, target.directionY, target.directionZ
  return 0, 0, 0, 0
end
function SteeringStayClose:calculateForce_Complex(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local target = agent.stateData.target
  local targetPositionX, targetPositionY, targetPositionZ = target.positionX, target.positionY, target.positionZ
  local targetDirectionX, targetDirectionY, targetDirectionZ = target.directionX, target.directionY, target.directionZ
  local force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ
  local importance = basicWeight
  local connectionToTargetX, connectionToTargetY, connectionToTargetZ = targetPositionX - agent.positionX, targetPositionY - agent.positionY, targetPositionZ - agent.positionZ
  local targetDistance = Utils.vector3Length(connectionToTargetX, connectionToTargetY, connectionToTargetZ)
  local distanceFactor = math.min(1, targetDistance / agent.closeDistance)
  if 0 < distanceFactor then
    local directionToTargetX, directionToTargetY, directionToTargetZ = connectionToTargetX / targetDistance, connectionToTargetY / targetDistance, connectionToTargetZ / targetDistance
    if targetDirectionX then
      local multiplier = 1.01 * distanceFactor
      directionX, directionY, directionZ = directionToTargetX * multiplier, directionToTargetY * multiplier, directionToTargetZ * multiplier
      local multiplier = 1 - distanceFactor
      local tempX, tempY, tempZ = directionX + targetDirectionX * multiplier, directionY + targetDirectionY * multiplier, directionZ + targetDirectionZ * multiplier
      local temptLength = Utils.vector3Length(tempX, tempY, tempZ)
      directionX, directionY, directionZ = tempX / temptLength, tempY / temptLength, tempZ / temptLength
      rotationX, rotationY, rotationZ = MotionControl:convertDirectionToRotation(agent, directionX, directionY, directionZ)
    else
      directionX, directionY, directionZ = directionToTargetX, directionToTargetY, directionToTargetZ
      rotationX, rotationY, rotationZ = MotionControl:convertDirectionToRotation(agent, directionX, directionY, directionZ)
    end
    local isInFront = 0 <= Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, directionToTargetX, directionToTargetY, directionToTargetZ)
    if isInFront then
      force = self.basicForce * distanceFactor
    elseif 0 < agent.speed then
      force = self.basicForce * distanceFactor * -1
    else
      force = 0
    end
  else
    force = 0
    directionX, directionY, directionZ = agent.directionX, agent.directionY, agent.directionZ
    rotationX, rotationY, rotationZ = 0, 0, 0
  end
  return force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ, importance
end
