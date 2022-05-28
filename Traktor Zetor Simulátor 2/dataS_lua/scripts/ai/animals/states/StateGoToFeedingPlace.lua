StateGoToFeedingPlace = {}
Class(StateGoToFeedingPlace, StateGoTo)
StateRepository:addState(StateGoToFeedingPlace)
function StateGoToFeedingPlace:initialize()
  local name = "GoToFeedingPlace"
  local precondition_stopWalkingToFeedingPlaceBecauseNotAvailableAnymore = EntityPreconditionCollection:new("stopWalkingToFeedingPlaceBecauseNotAvailableAnymore", 2, EntityType.OBJECT, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isInteractionPlaceNotAvailableAnymore)
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateArriveAtFeedingPlace, EntityPreconditionCollection:new("canArriveAtFeedingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isAtArrivingDistance)),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("walkToOtherFeedingPlaceBecauseNotAvailableAnymoreButStillVeryHungry", 1, precondition_stopWalkingToFeedingPlaceBecauseNotAvailableAnymore, DefaultPreconditions.isVeryHungry, EntityPreconditionCollection:new("walkToOtherAvailableFeedingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isNotTargetedByEntity, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("walkToOtherFeedingPlaceBecauseNotAvailableAnymoreButStillGotRefilled", 1, precondition_stopWalkingToFeedingPlaceBecauseNotAvailableAnymore, EntityPreconditionCollection:new("walkToOtherRefilledFeedingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isNotTargetedByEntity, DefaultPreconditions.gotRefilled, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateGoToFeedingPlace, PreconditionCollection:new("walkToOtherFeedingPlaceBecauseNotAvailableAnymore", 1, precondition_stopWalkingToFeedingPlaceBecauseNotAvailableAnymore, EntityPreconditionCollection:new("walkToOtherInRangeFeedingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isNotTargetedByEntity, DefaultPreconditions.isInRange, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateWander, precondition_stopWalkingToFeedingPlaceBecauseNotAvailableAnymore)
  }
  StateGoToFeedingPlace:superClass().initialize(self, name, changeStateActionsList)
end
