SteeringNegativeCohesion = SteeringBehavior:new("NegativeCohesion", 100)
function SteeringNegativeCohesion:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  local connectionX, connectionY, connectionZ = agent.herd.positionX - agent.positionX, agent.herd.positionY - agent.positionY, agent.herd.positionZ - agent.positionZ
  local distanceToHerd = Utils.vector3Length(connectionX, connectionY, connectionZ)
  local minimumDistance = 5
  local maximumDistance = 20
  local forceX, forceY, forceZ = 0, 0, 0
  local importance = 0
  if distanceToHerd > minimumDistance then
    local distanceFactor = 1 - (math.min(distanceToHerd, maximumDistance) - minimumDistance) / (maximumDistance - minimumDistance)
    local directionX, directionY, directionZ = connectionX / distanceToHerd, connectionY / distanceToHerd, connectionZ / distanceToHerd
    forceX, forceY, forceZ = directionX * -1, directionY * -1, directionZ * -1
    importance = distanceFactor
  end
  return forceX, forceY, forceZ, importance
end
function SteeringNegativeCohesion:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  return SteeringNegativeCohesion:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
end
