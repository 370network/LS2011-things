SteeringSeek = SteeringBehavior:new("Seek", 1000)
function SteeringSeek:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local directConnectionX, directConnectionY, directConnectionZ = targetPositionX - agent.positionX, targetPositionY - agent.positionY, targetPositionZ - agent.positionZ
  local directConnectionLength = Utils.vector3Length(directConnectionX, directConnectionY, directConnectionZ)
  local forceX, forceY, forceZ
  if 0 < directConnectionLength then
    local directDirectionX, directDirectionY, directDirectionZ = directConnectionX / directConnectionLength, directConnectionY / directConnectionLength, directConnectionZ / directConnectionLength
    local currentDirectionX, currentDirectionY, currentDirectionZ = agent.directionX, agent.directionY, agent.directionZ
    local seekConnectionX, seekConnectionY, seekConnectionZ = directDirectionX - currentDirectionX * 0.99, directDirectionY - currentDirectionY * 0.99, directDirectionZ - currentDirectionZ * 0.99
    local connectionDistance = Utils.vector3Length(seekConnectionX, seekConnectionY, seekConnectionZ)
    local seekDirectionX, seekDirectionY, seekDirectionZ = seekConnectionX / connectionDistance, seekConnectionY / connectionDistance, seekConnectionZ / connectionDistance
    local angleToTarget = Utils.dotProduct(currentDirectionX, currentDirectionY, currentDirectionZ, directDirectionX, directDirectionY, directDirectionZ)
    local influenceAngle = 1
    if angleToTarget > 1 - influenceAngle then
      local angleFactor = (angleToTarget - (1 - influenceAngle)) * (1 / influenceAngle)
      angleFactor = angleFactor * angleFactor
      if angleFactor == 1 then
        seekDirectionX, seekDirectionY, seekDirectionZ = currentDirectionX, currentDirectionY, currentDirectionZ
      else
        local tempDirectionX, tempDirectionY, tempDirectionZ = currentDirectionX * angleFactor, currentDirectionY * angleFactor, currentDirectionZ * angleFactor
        local multiplier = 1 - angleFactor
        seekConnectionX, seekConnectionY, seekConnectionZ = tempDirectionX + seekDirectionX * multiplier, tempDirectionY + seekDirectionY * multiplier, tempDirectionZ + seekDirectionZ * multiplier
        connectionDistance = Utils.vector3Length(seekConnectionX, seekConnectionY, seekConnectionZ)
        if 0 < connectionDistance then
          seekDirectionX, seekDirectionY, seekDirectionZ = seekConnectionX / connectionDistance, seekConnectionY / connectionDistance, seekConnectionZ / connectionDistance
        end
      end
    end
    forceX, forceY, forceZ = seekDirectionX, seekDirectionY, seekDirectionZ
  else
    forceX, forceY, forceZ = 0, 0, 0
  end
  return forceX, forceY, forceZ
end
function SteeringSeek:calculateForce_Complex(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local directConnectionX, directConnectionY, directConnectionZ = targetPositionX - agent.positionX, targetPositionY - agent.positionY, targetPositionZ - agent.positionZ
  local directConnectionLength = Utils.vector3Length(directConnectionX, directConnectionY, directConnectionZ)
  local force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ
  local importance = basicWeight
  if 0 < directConnectionLength then
    local directDirectionX, directDirectionY, directDirectionZ = directConnectionX / directConnectionLength, directConnectionY / directConnectionLength, directConnectionZ / directConnectionLength
    local currentDirectionX, currentDirectionY, currentDirectionZ = agent.directionX, agent.directionY, agent.directionZ
    local seekConnectionX, seekConnectionY, seekConnectionZ = directDirectionX - currentDirectionX * 0.99, directDirectionY - currentDirectionY * 0.99, directDirectionZ - currentDirectionZ * 0.99
    local connectionDistance = Utils.vector3Length(seekConnectionX, seekConnectionY, seekConnectionZ)
    local seekDirectionX, seekDirectionY, seekDirectionZ = seekConnectionX / connectionDistance, seekConnectionY / connectionDistance, seekConnectionZ / connectionDistance
    local angle = Utils.dotProduct(currentDirectionX, currentDirectionY, currentDirectionZ, directDirectionX, directDirectionY, directDirectionZ)
    angle = 1 - (angle + 1) / 2
    local angleFactor = math.max(0, math.min(1, angle / 0.1))
    force = self.basicForce
    directionX, directionY, directionZ = seekDirectionX, seekDirectionY, seekDirectionZ
    rotationX, rotationY, rotationZ = MotionControl:convertDirectionToRotation(agent, seekDirectionX, seekDirectionY, seekDirectionZ)
    rotationX, rotationY, rotationZ = rotationX * angleFactor, rotationY * angleFactor, rotationZ * angleFactor
    return force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ, importance
  else
    local forceX, forceY, forceZ = 0, 0, 0
    return forceX, forceY, forceZ, importance
  end
end
