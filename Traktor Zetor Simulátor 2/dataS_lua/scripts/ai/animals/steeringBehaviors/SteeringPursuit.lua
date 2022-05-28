SteeringPursuit = SteeringBehavior:new("Pursuit", 500)
function SteeringPursuit:applyToAgent(agent, basicWeight)
  SteeringBehavior.applyToAgent(self, agent, basicWeight, agent.stateData.target.positionX, agent.stateData.target.positionY, agent.stateData.target.positionZ)
end
function SteeringPursuit:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  local target = agent.stateData.target
  targetX, targetY, targetZ = target.positionX, target.positionY, target.positionZ
  local futurePositionOfTargetX, futurePositionOfTargetY, futurePositionOfTargetZ
  local agentSpeed = math.max(1, agent.speed)
  local timeToTarget = Utils.vector3Length(targetX - agent.positionX, targetY - agent.positionY, targetZ - agent.positionZ) / agentSpeed
  local targetSpeed = target.speed or 0
  futurePositionOfTargetX, futurePositionOfTargetY, futurePositionOfTargetZ = targetX + target.directionX * targetSpeed, targetY + target.directionY * targetSpeed, targetZ + target.directionZ * targetSpeed
  return SteeringArrival.calculateForce(self, agent, basicWeight, futurePositionOfTargetX, futurePositionOfTargetY, futurePositionOfTargetZ)
end
function SteeringPursuit:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
  return SteeringPursuit:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
end
