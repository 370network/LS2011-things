StateDrinkFromWateringPlace = {}
Class(StateDrinkFromWateringPlace, StateInteract)
StateRepository:addState(StateDrinkFromWateringPlace)
function StateDrinkFromWateringPlace:initialize()
  local name = "DrinkFromWateringPlace"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateDrinkFromWateringPlace, PreconditionCollection:new("canDrinkMoreFromWateringPlace", 1, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isThirsty, EntityPreconditionCollection:new("isWateringPlaceStillAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isAtWateringPlace, DefaultPreconditions.isAvailable)), EffectCollection:new("lowerThirst", DefaultEffects.lowerThirstModerate)),
    ChangeStateAction:new():initialize(StateMoveAway, PreconditionCollection:new("isSaturatedByWateringPlace", 1, DefaultPreconditions.tenSecondsPassed), EffectCollection:new("lowerThirst", DefaultEffects.lowerThirstModerate))
  }
  StateDrinkFromWateringPlace:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WANDER, AnimalMotionData.ACCELERATION_WANDER)
end
