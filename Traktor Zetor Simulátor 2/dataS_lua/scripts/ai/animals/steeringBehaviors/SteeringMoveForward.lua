SteeringMoveForward = SteeringBehavior:new("MoveForward", 300)
function SteeringMoveForward:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local forceX, forceY, forceZ
  forceX, forceY, forceZ = agent.directionX, agent.directionY, agent.directionZ
  return forceX, forceY, forceZ
end
function SteeringMoveForward:calculateForce_Complex(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  return SteeringMoveForward:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
end
