SteeringEscape = SteeringBehavior:new("Escape", 1000)
function SteeringEscape:applyToAgent(agent, basicWeight)
  SteeringBehavior.applyToAgent(self, agent, basicWeight, agent.stateData.targetX, agent.stateData.targetY, agent.stateData.targetZ)
end
function SteeringEscape:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  local target = agent.stateData.target
  targetX, targetY, targetZ = target.positionX, target.positionY, target.positionZ
  local seekTargetX, seekTargetY, seekTargetZ = agent.positionX - (targetX - agent.positionX), agent.positionY - (targetY - agent.positionY), agent.positionZ - (targetZ - agent.positionZ)
  local forceX, forceY, forceZ, importance = SteeringSeek:calculateForce(agent, basicWeight, seekTargetX, seekTargetY, seekTargetZ)
  local maximumDistance = agent.farDistance - agent.closeDistance
  local distance = Utils.vector3Length(targetX - agent.positionX, targetY - agent.positionY, targetZ - agent.positionZ) - agent.closeDistance
  local importance = (1 - distance / maximumDistance) ^ 2
  return forceX, forceY, forceZ, importance
end
function SteeringEscape:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  return SteeringEscape:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
end
