StateStopAtWateringPlace = {}
Class(StateStopAtWateringPlace, State)
StateRepository:addState(StateStopAtWateringPlace)
function StateStopAtWateringPlace:initialize()
  local name = "StopAtWateringPlace"
  self.stoppedAtWateringPlace = InjectionPrecondition:new("stoppedAtWateringPlace", DefaultPreconditions.canDrinkFromWateringPlace)
  local changeStateActionsList = {
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateDrinkFromWateringPlace, self.stoppedAtWateringPlace)
  }
  StateStopAtWateringPlace:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateStopAtWateringPlace:onEnter(animal)
  StateStopAtWateringPlace:superClass().onEnter(self, animal)
  local wateringPlace = animal.stateData.target
  assert(wateringPlace, "The state does not know to which target entity to go to")
  wateringPlace:addAgent(animal)
  local finalPositionX, finalPositionY, finalPositionZ = wateringPlace.drinkingPositionX, getTerrainHeightAtWorldPos(animal.herd.groundObjectId, wateringPlace.drinkingPositionX, wateringPlace.drinkingPositionY, wateringPlace.drinkingPositionZ), wateringPlace.drinkingPositionZ
  local speed = 1
  local useSpeed = true
  local stopHere = true
  ManualPath:initPath(animal, self, self.positionReached)
  ManualPath:addWaypoint(animal, finalPositionX, finalPositionY, finalPositionZ, wateringPlace.directionX, wateringPlace.directionY, wateringPlace.directionZ, speed * 0.5, useSpeed, stopHere)
  ManualPath:startPath(animal)
end
function StateStopAtWateringPlace:onLeave(animal)
  animal.stateData.target:removeAgent(animal)
  ManualPath:stopPath(animal)
  StateStopAtWateringPlace:superClass().onLeave(self, animal)
end
function StateStopAtWateringPlace:positionReached(animal)
  animal.speed = 0
  local wateringPlace = animal.stateData.target
  Perception:injectPerception(animal, self.stoppedAtWateringPlace, true, wateringPlace)
end
