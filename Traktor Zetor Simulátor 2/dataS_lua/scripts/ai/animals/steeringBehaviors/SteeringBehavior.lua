SteeringBehavior = {}
local SteeringBehavior_mt = Class(SteeringBehavior)
function SteeringBehavior:new(name)
  if self == SteeringBehavior then
    self = setmetatable({}, SteeringBehavior_mt)
  end
  self.name = name
  return self
end
function SteeringBehavior:applyToAgent(agent, basicWeight, targetX, targetY, targetZ)
  agent.steeringData[self] = {}
  local steeringDataTable = agent.steeringData[self]
  steeringDataTable.basicWeight = basicWeight
  steeringDataTable.targetX = targetX
  steeringDataTable.targetY = targetY
  steeringDataTable.targetZ = targetZ
end
function SteeringBehavior:releaseFromAgent(agent)
  agent.steeringData[self] = nil
end
function SteeringBehavior:gatherForce(agent)
  local steeringDataTable = agent.steeringData[self]
  local basicWeight = steeringDataTable.basicWeight
  local targetX, targetY, targetZ = steeringDataTable.targetX, steeringDataTable.targetY, steeringDataTable.targetZ
  local forceX, forceY, forceZ, importance, complexity = self:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  importance = importance or 1
  complexity = complexity or 0
  return forceX, forceY, forceZ, basicWeight * importance, complexity
end
function SteeringBehavior:gatherForce_Complex(agent)
  local steeringDataTable = agent.steeringData[self]
  local basicWeight = steeringDataTable.basicWeight
  local targetX, targetY, targetZ = steeringDataTable.targetX, steeringDataTable.targetY, steeringDataTable.targetZ
  return self:calculateForce_Complex(agent, basicWeight, targetX, targetY, targetZ)
end
function SteeringBehavior:calculateForce(agent, basicWeight, targetX, targetY, targetZ)
  error("method has to get overwritten")
end
function SteeringBehavior:printLastCalculation(agent)
  local steeringDataTable = agent.steeringData[self]
  print("---------------------------------------------")
  print("calculations for : " .. self.name)
  print("force : " .. string.format("%.3f, %.3f, %.3f", steeringDataTable.lastCalculatedForceX, steeringDataTable.lastCalculatedForceY, steeringDataTable.lastCalculatedForceZ))
  print("importance : " .. tostring(steeringDataTable.lastCalculatedImportance))
  print("basic weight : " .. tostring(steeringDataTable.basicWeight))
  print("complexity : " .. tostring(steeringDataTable.lastCalculatedComplexity))
end
