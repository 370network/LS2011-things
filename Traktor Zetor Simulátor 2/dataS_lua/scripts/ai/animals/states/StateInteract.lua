StateInteract = {}
Class(StateInteract, State)
function StateInteract:initialize(name, changeStateActionsList)
  assert(name)
  assert(changeStateActionsList)
  StateInteract:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WANDER, AnimalMotionData.ACCELERATION_WANDER)
end
function StateInteract:onEnter(animal)
  StateInteract:superClass().onEnter(self, animal)
  assert(animal.stateData.target)
  animal.stateData.target:addAgent(animal)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringStayClose)
end
function StateInteract:onLeave(animal)
  animal.stateData.target:removeAgent(animal)
  StateInteract:superClass().onLeave(self, animal)
end
function StateInteract:updateAgentAttributeData(animal, dt)
  local attributes_hash = animal.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-2.0E-4 * (dt / 1000))
end
