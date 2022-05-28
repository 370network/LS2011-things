StatePursuit = {}
Class(StatePursuit, State)
StateRepository:addState(StatePursuit)
function StatePursuit:initialize()
  local name = "Pursuit"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseItGotRefilled", 1, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isEatableGotRefilledAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.gotRefilled, DefaultPreconditions.isAvailable))),
    ChangeStateAction:new():initialize(StateWander, DefaultPreconditions.isPlayerOutOfRange),
    ChangeStateAction:new():initialize(StateWander, EntityPreconditionCollection:new("isPlayerNear", 2, EntityType.PLAYER, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateWander, DefaultPreconditions.tenSecondsPassed)
  }
  StatePursuit:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StatePursuit:onEnter(animal)
  StatePursuit:superClass().onEnter(self, animal)
  assert(animal.stateData.target)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringPursuit, 1)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringSeparation, 0.8)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringObstacleAvoidance, 0.9)
end
function StatePursuit:updateAgentAttributeData(animal, dt)
  local attributes_hash = animal.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-0.002 * (dt / 1000))
end
