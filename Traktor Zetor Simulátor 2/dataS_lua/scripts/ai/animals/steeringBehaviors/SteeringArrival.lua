SteeringArrival = SteeringBehavior:new("Arrival", 500)
function SteeringArrival:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  local forceX, forceY, forceZ, importance = SteeringSeek:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  importance = importance or 1
  local directConnectionX, directConnectionY, directConnectionZ = targetX - agent.positionX, targetY - agent.positionY, targetZ - agent.positionZ
  local directConnectionLength = Utils.vector3Length(directConnectionX, directConnectionY, directConnectionZ)
  local arrivalInfluenceRadius = agent.length * 5
  if directConnectionLength <= arrivalInfluenceRadius then
    local arrivalFactor = (directConnectionLength / arrivalInfluenceRadius) ^ 4
    importance = importance * arrivalFactor
  end
  return forceX, forceY, forceZ, importance
end
function SteeringArrival:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  local force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ, importance = SteeringSeek:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  local directConnectionX, directConnectionY, directConnectionZ = targetX - agent.positionX, targetY - agent.positionY, targetZ - agent.positionZ
  local directConnectionLength = Utils.vector3Length(directConnectionX, directConnectionY, directConnectionZ)
  local arrivalInfluenceRadius = agent.length * 5
  if directConnectionLength <= arrivalInfluenceRadius then
    local arrivalFactor = (directConnectionLength / arrivalInfluenceRadius) ^ 4
    force = force * arrivalFactor
  end
  return force, directionX, directionY, directionZ, rotationX, rotationY, rotationZ, importance
end
