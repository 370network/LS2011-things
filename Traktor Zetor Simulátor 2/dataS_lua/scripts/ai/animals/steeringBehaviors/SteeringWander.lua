SteeringWander = SteeringBehavior:new("Wander", 300)
function SteeringWander:applyToAgent(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  SteeringBehavior.applyToAgent(self, agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local steeringDataTable = agent.steeringData[self]
  steeringDataTable.currentAngle = 0
end
function SteeringWander:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local steeringDataTable = agent.steeringData[self]
  local rand = function(max)
    return (math.random() * 2 - 1) * max
  end
  local maxChange = 0.02 * agent.motionData.timeBetweenCalculationUpdates / 1000
  local newAngle = steeringDataTable.currentAngle + rand(maxChange)
  local maxAngle = 0.3
  local absAngle = math.abs(newAngle)
  if 1.0E-4 < absAngle then
    newAngle = math.min(maxAngle, absAngle) * (newAngle / absAngle)
  end
  local wanderDirectionX, wanderDirectionY, wanderDirectionZ = MotionControl:getRotatedDirection(agent.directionX, agent.directionY, agent.directionZ, 0, newAngle, 0)
  local forceX, forceY, forceZ = wanderDirectionX, wanderDirectionY, wanderDirectionZ
  steeringDataTable.currentAngle = newAngle
  return forceX, forceY, forceZ
end
function SteeringWander:calculateForce_Complex(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  return SteeringWander:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
end
