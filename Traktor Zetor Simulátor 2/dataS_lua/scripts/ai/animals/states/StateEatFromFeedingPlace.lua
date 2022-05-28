StateEatFromFeedingPlace = {}
Class(StateEatFromFeedingPlace, StateInteract)
StateRepository:addState(StateEatFromFeedingPlace)
function StateEatFromFeedingPlace:initialize()
  local name = "EatFromFeedingPlace"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateEatFromFeedingPlace, PreconditionCollection:new("canEatMoreFromFeedingPlace", 1, DefaultPreconditions.tenSecondsPassed, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isFeedingPlaceStillAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isAtFeedingPlace, DefaultPreconditions.isAvailable)), EffectCollection:new("lowerHungerRaiseThirst", DefaultEffects.lowerHungerModerate, DefaultEffects.raiseThirstABit)),
    ChangeStateAction:new():initialize(StateMoveAway, PreconditionCollection:new("isSaturatedByFeedingPlace", 1, DefaultPreconditions.tenSecondsPassed), EffectCollection:new("lowerHungerRaiseThirst", DefaultEffects.lowerHungerModerate, DefaultEffects.raiseThirstABit))
  }
  StateEatFromFeedingPlace:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WANDER, AnimalMotionData.ACCELERATION_WANDER)
end
