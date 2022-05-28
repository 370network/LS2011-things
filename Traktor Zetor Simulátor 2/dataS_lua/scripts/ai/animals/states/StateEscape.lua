StateEscape = {}
Class(StateEscape, State)
StateRepository:addState(StateEscape)
function StateEscape:initialize()
  local name = "Escape"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateWander, PreconditionCollection:new("timePassedToCalmDown", 1, DefaultPreconditions.tenSecondsPassed, NegatePrecondition:new("canCalmDown", EntityPreconditionCollection:new("playerIsInRange", 2, EntityType.PLAYER, DefaultPreconditions.isInRange), 1)))
  }
  StateEscape:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_RACE, AnimalMotionData.ACCELERATION_RACE)
end
function StateEscape:onEnter(animal)
  StateEscape:superClass().onEnter(self, animal)
  assert(animal.stateData.target)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringEscape, 0.75)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringObstacleAvoidance, 1)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringNegativeCohesion, 0.1)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringSeparation, 0.5)
end
function StateEscape:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-0.005 * (dt / 1000))
end
