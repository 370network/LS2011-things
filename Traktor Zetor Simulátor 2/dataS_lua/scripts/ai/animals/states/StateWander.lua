StateWander = {}
local StateWander_mt = Class(StateWander, StateStand)
StateRepository:addState(StateWander)
function StateWander:initialize()
  local name = "Wander"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateMilkingEnter, EntityPreconditionCollection:new("canEnterMilkingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isMilkingPlace, DefaultPreconditions.isInteractionPlaceAvailable)),
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    ChangeStateAction:new():initialize(StateEscape, EntityPreconditionCollection:new("shouldEscapeFromPlayerWhileWandering", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseVeryHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isVeryHungry, EntityPreconditionCollection:new("isEatableAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateStop, PreconditionCollection:new("shouldStopToSleepBecauseVeryExhausted", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isVeryExhausted)),
    ChangeStateAction:new():initialize(StateGoToWateringPlace, PreconditionCollection:new("shouldWalkToWateringPlaceBecauseVeryThirsty", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isVeryThirsty, EntityPreconditionCollection:new("isDrinkableAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseHungryAndInRange", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isEatableInRangeAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isInRange, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseItGotRefilled", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isEatableGotRefilledAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.gotRefilled, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StatePursuit, PreconditionCollection:new("shouldPursuitPlayerBecauseHungryAndInRange", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isInRangeButNotNear", 2, EntityType.PLAYER, DefaultPreconditions.isInRange, DefaultPreconditions.isNotNear))),
    ChangeStateAction:new():initialize(StateStop, PreconditionCollection:new("shouldStopToEatGrassBecauseHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isHungry, DefaultPreconditions.isStandingOnGrass)),
    ChangeStateAction:new():initialize(StateStop, PreconditionCollection:new("shouldStopToTakeANapBecauseExhausted", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isExhausted)),
    ChangeStateAction:new():initialize(StateStop, PreconditionCollection:new("shouldStopToSleepBecauseNight", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isNight)),
    ChangeStateAction:new():initialize(StateStop, PreconditionCollection:new("shouldStopBecauseWanderedTooLong", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.thirtySecondsPassed))
  }
  StateWander:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WANDER, AnimalMotionData.ACCELERATION_WANDER)
end
function StateWander:onEnter(agent)
  StateWander:superClass().onEnter(self, agent)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringNegativeCohesion)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringSeparation, 3)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringObstacleAvoidance, 10)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringWander)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringAlignment)
end
function StateWander:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-0.001 * (dt / 1000))
end
