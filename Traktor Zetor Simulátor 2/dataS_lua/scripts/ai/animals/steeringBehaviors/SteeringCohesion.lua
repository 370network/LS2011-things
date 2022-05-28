SteeringCohesion = SteeringBehavior:new("Cohesion", 100)
function SteeringCohesion:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  local connectionX, connectionY, connectionZ = agent.herd.positionX - agent.positionX, agent.herd.positionY - agent.positionY, agent.herd.positionZ - agent.positionZ
  local distanceToHerd = Utils.vector3Length(connectionX, connectionY, connectionZ)
  local minimumDistance = 5
  local maximumDistance = 20
  local forceX, forceY, forceZ = 0, 0, 0
  local importance = 0
  if distanceToHerd > minimumDistance then
    local distanceFactor = (math.min(distanceToHerd, maximumDistance) - minimumDistance) / (maximumDistance - minimumDistance)
    local directionX, directionY, directionZ = connectionX / distanceToHerd, connectionY / distanceToHerd, connectionZ / distanceToHerd
    forceX, forceY, forceZ = directionX, directionY, directionZ
    importance = distanceFactor
  end
  return forceX, forceY, forceZ, importance
end
function SteeringCohesion:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  return SteeringCohesion:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
end
