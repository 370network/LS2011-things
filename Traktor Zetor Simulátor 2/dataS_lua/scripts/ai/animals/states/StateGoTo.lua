StateGoTo = {TARGET_ARRIVE_DISPLACEMENT = 4}
Class(StateGoTo, State)
function StateGoTo:initialize(name, changeStateActionsList)
  assert(name)
  assert(changeStateActionsList)
  table.insert(changeStateActionsList, 1, DefaultChangeStateActions.startToEscapeFromPlayer)
  table.insert(changeStateActionsList, ChangeStateAction:new():initialize(StateWander, PreconditionCollection:new("isInGoToStateTooLong", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.threeMinutesPassed)))
  table.insert(changeStateActionsList, 1, ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped))
  StateGoTo:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateGoTo:onEnter(animal)
  StateGoTo:superClass().onEnter(self, animal)
  local target = animal.stateData.target
  assert(target, "The state does not know to which target entitiy to go to")
  target:addAgent(animal)
  local targetApproachingPositionX, targetApproachingPositionY, targetApproachingPositionZ = target.approachingPositionX, target.approachingPositionY, target.approachingPositionZ
  AnimalSteeringData.addSteeringBehavior(animal, SteeringGoTo, 1, targetApproachingPositionX, targetApproachingPositionY, targetApproachingPositionZ)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringSeparation, 0.5)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringObstacleAvoidance, 1)
end
function StateGoTo:onLeave(animal)
  animal.stateData.target:removeAgent(animal)
  StateGoTo:superClass().onLeave(self, animal)
end
function StateGoTo:updateAgentAttributeData(animal, dt)
  local attributes_hash = animal.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-0.002 * (dt / 1000))
end
