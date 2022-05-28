StateGoToMilkingPlace = {}
Class(StateGoToMilkingPlace, StateGoTo)
StateRepository:addState(StateGoToMilkingPlace)
function StateGoToMilkingPlace:initialize()
  local name = "GoToMilkingPlace"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateMilkingEnter, EntityPreconditionCollection:new("canEnterMilkingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isMilkingPlace)),
    ChangeStateAction:new():initialize(StateWander, EntityPreconditionCollection:new("stopWalkingToMilkingPlaceBecauseNotAvailableAnymore", 2, EntityType.OBJECT, DefaultPreconditions.isTargetedByEntity, DefaultPreconditions.isInteractionPlaceNotAvailableAnymore))
  }
  StateGoToMilkingPlace:superClass().initialize(self, name, changeStateActionsList)
end
function StateGoToMilkingPlace:onEnter(agent)
  local milkingPlace = agent.stateData.nextStateTarget
  print("onEnter")
  print(agent.name)
  print(string.format("milking position %.2f %.2f %.2f", milkingPlace.positionX, milkingPlace.positionY, milkingPlace.positionZ))
  milkingPlace.positionX, milkingPlace.positionY, milkingPlace.positionZ = milkingPlace.entrancePositionX, milkingPlace.entrancePositionY, milkingPlace.entrancePositionZ
  StateGoToMilkingPlace:superClass().onEnter(self, agent)
end
function StateGoToMilkingPlace:onLeave(agent)
  local milkingPlace = agent.stateData.target
  milkingPlace.positionX, milkingPlace.positionY, milkingPlace.positionZ = milkingPlace.tempPositionX, milkingPlace.tempPositionY, milkingPlace.tempPositionZ
  print("onleave")
  print(agent.name)
  print(string.format("milking position %.2f %.2f %.2f", milkingPlace.positionX, milkingPlace.positionY, milkingPlace.positionZ))
  StateGoToMilkingPlace:superClass().onLeave(self, agent)
end
