AnimalSteeringData = {}
local AnimalSteeringData_mt = Class(AnimalSteeringData)
function AnimalSteeringData:new(animal)
  self = setmetatable({}, AnimalSteeringData_mt)
  self.steeringBehaviorsList = {}
  return self
end
function AnimalSteeringData.addSteeringBehavior(agent, newSteeringBehavior, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  basicWeight = basicWeight or 1
  if targetPositionX == nil then
    local target = agent.stateData.target
    if target then
      targetPositionX, targetPositionY, targetPositionZ = target.positionX, target.positionY, target.positionZ
    end
  end
  table.insert(agent.steeringData.steeringBehaviorsList, newSteeringBehavior)
  newSteeringBehavior:applyToAgent(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
end
function AnimalSteeringData.reset(agent)
  for _, steeringBehavior in ipairs(agent.steeringData.steeringBehaviorsList) do
    steeringBehavior:releaseFromAgent(agent)
  end
  agent.steeringData.steeringBehaviorsList = {}
end
function AnimalSteeringData:printLastCalculations(agent)
  print("---------------------------------------------------------------------")
  print("printing last calculations from current steering behaviors ...")
  print("---------------------------------------------------------------------")
  for _, steeringBehavior in ipairs(agent.steeringData.steeringBehaviorsList) do
    steeringBehavior:printLastCalculation(agent)
  end
  print("---------------------------------------------")
  print("---------------------------------------------")
  print("finally requested accelerations : ")
  print("linear acceleration : " .. tostring(agent.motionData.requestedLinearAcceleration))
  print("rotational acceleration : " .. string.format("%.3f, %.3f, %.3f", agent.motionData.requestedRotationalAccelerationX, agent.motionData.requestedRotationalAccelerationY, agent.motionData.requestedRotationalAccelerationZ))
  print("complexity : " .. tostring(agent.motionData.situationComplexity))
  print("---------------------------------------------------------------------")
  print("... finished printing last calculations")
  print("---------------------------------------------------------------------")
end
