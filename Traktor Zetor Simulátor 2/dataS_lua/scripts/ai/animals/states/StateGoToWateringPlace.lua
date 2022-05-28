StateGoToWateringPlace = {}
Class(StateGoToWateringPlace, StateGoTo)
StateRepository:addState(StateGoToWateringPlace)
function StateGoToWateringPlace:initialize()
  local name = "GoToWateringPlace"
  local precondition_stopWalkingToWateringPlaceBecauseNotAvailableAnymore = EntityPreconditionCollection:new("stopWalkingToWateringPlaceBecauseNotAvailableAnymore", 2, EntityType.OBJECT, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isInteractionPlaceNotAvailableAnymore)
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateArriveAtWateringPlace, EntityPreconditionCollection:new("canArriveAtWateringPlace", 2, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isAtArrivingDistance)),
    ChangeStateAction:new():initialize(StateGoToWateringPlace, PreconditionCollection:new("walkToOtherWateringPlaceBecauseNotAvailableAnymoreButStillVeryThirsty", 1, precondition_stopWalkingToWateringPlaceBecauseNotAvailableAnymore, DefaultPreconditions.isVeryThirsty, EntityPreconditionCollection:new("walkToOtherAvailableWateringPlace", 2, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isNotTargetedByEntity, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateGoToWateringPlace, PreconditionCollection:new("walkToOtherWateringPlaceBecauseNotAvailableAnymore", 1, precondition_stopWalkingToWateringPlaceBecauseNotAvailableAnymore, EntityPreconditionCollection:new("walkToOtherInRangeWateringPlace", 2, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isNotTargetedByEntity, DefaultPreconditions.isInRange, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateWander, precondition_stopWalkingToWateringPlaceBecauseNotAvailableAnymore)
  }
  StateGoToWateringPlace:superClass().initialize(self, name, changeStateActionsList)
end
