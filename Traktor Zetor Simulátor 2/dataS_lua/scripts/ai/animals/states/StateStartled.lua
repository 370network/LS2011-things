StateStartled = {}
Class(StateStartled, StateEscape)
StateRepository:addState(StateStartled)
function StateStartled:initialize()
  local name = "Startled"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateMilkingEnter, EntityPreconditionCollection:new("canEnterMilkingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isMilkingPlace, DefaultPreconditions.isInteractionPlaceAvailable)),
    ChangeStateAction:new():initialize(StateWander, DefaultPreconditions.threeSecondsPassed)
  }
  State.initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_RACE, AnimalMotionData.ACCELERATION_RACE)
end
function StateStartled:onEnter(animal)
  StateEscape:superClass().onEnter(self, animal)
  assert(animal.stateData.target)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringEscape, 0.5)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringObstacleAvoidance, 0.5)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringNegativeCohesion, 0.1)
  AnimalSteeringData.addSteeringBehavior(animal, SteeringSeparation, 0.5)
end
