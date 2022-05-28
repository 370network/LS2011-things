StateIdle = {}
local StateIdle_mt = Class(StateIdle, StateStand)
StateRepository:addState(StateIdle)
function StateIdle:initialize()
  local name = "Idle"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    ChangeStateAction:new():initialize(StateEscape, EntityPreconditionCollection:new("shouldEscapeFromPlayerWhileIdling", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseVeryHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryHungry, EntityPreconditionCollection:new("isEatableAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateGoToWateringPlace, PreconditionCollection:new("shouldWalkToWateringPlaceBecauseVeryThirsty", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryThirsty, EntityPreconditionCollection:new("isDrinkableAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isAvailable))),
    ChangeStateAction:new():initialize(StateLayDown, PreconditionCollection:new("shouldLayDownToSleepBecauseVeryExhausted", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryExhausted)),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseItGotRefilled", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isEatableGotRefilledAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.gotRefilled, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StatePursuit, PreconditionCollection:new("shouldPursuitPlayerBecauseHungryAndInRange", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isInRangeButNotNear", 2, EntityType.PLAYER, DefaultPreconditions.isInRange, DefaultPreconditions.isNotNear))),
    ChangeStateAction:new():initialize(StateEatGrass, PreconditionCollection:new("shouldEatGrassBecauseHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isHungry)),
    ChangeStateAction:new():initialize(StateLayDown, PreconditionCollection:new("shouldLayDownToTakeANapBecauseExhausted", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isExhausted)),
    ChangeStateAction:new():initialize(StateLayDown, PreconditionCollection:new("shouldLayDownToSleepBecauseNight", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isNight)),
    ChangeStateAction:new():initialize(StateWander, PreconditionCollection:new("shouldStartToWanderAroundAgain", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.twentySecondsPassed))
  }
  StateIdle:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateIdle:onEnter(agent)
  StateIdle:superClass().onEnter(self, agent)
end
