StateArriveAtWateringPlace = {}
Class(StateArriveAtWateringPlace, State)
StateRepository:addState(StateArriveAtWateringPlace)
function StateArriveAtWateringPlace:initialize()
  local name = "ArriveAtWateringPlace"
  self.readyToStopAtWateringPlace = InjectionPrecondition:new("readyToStopAtWateringPlace", DefaultPreconditions.canDrinkFromWateringPlace)
  local changeStateActionsList = {
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateStopAtWateringPlace, self.readyToStopAtWateringPlace)
  }
  StateArriveAtWateringPlace:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateArriveAtWateringPlace:onEnter(animal)
  StateArriveAtWateringPlace:superClass().onEnter(self, animal)
  local wateringPlace = animal.stateData.target
  assert(wateringPlace, "The state does not know to which target entity to go to")
  wateringPlace:addAgent(animal)
  local finalPositionX, finalPositionY, finalPositionZ = wateringPlace.drinkingPositionX, getTerrainHeightAtWorldPos(animal.herd.groundObjectId, wateringPlace.drinkingPositionX, wateringPlace.drinkingPositionY, wateringPlace.drinkingPositionZ), wateringPlace.drinkingPositionZ
  local approachingPositionX, approachingPositionY, approachingPositionZ = wateringPlace.approachingPositionX, getTerrainHeightAtWorldPos(animal.herd.groundObjectId, wateringPlace.approachingPositionX, wateringPlace.approachingPositionY, wateringPlace.approachingPositionZ), wateringPlace.approachingPositionZ
  local inbetweenPositionX, inbetweenPositionY, inbetweenPositionZ = approachingPositionX + (finalPositionX - approachingPositionX) * 0.25, approachingPositionY + (finalPositionY - approachingPositionY) * 0.25, approachingPositionZ + (finalPositionZ - approachingPositionZ) * 0.25
  local speed = 1
  local useSpeed = true
  ManualPath:initPath(animal, self, self.positionReached)
  ManualPath:addWaypoint(animal, inbetweenPositionX, inbetweenPositionY, inbetweenPositionZ, wateringPlace.directionX, wateringPlace.directionY, wateringPlace.directionZ, speed, useSpeed)
  ManualPath:startPath(animal)
end
function StateArriveAtWateringPlace:onLeave(animal)
  animal.stateData.target:removeAgent(animal)
  ManualPath:stopPath(animal)
  StateArriveAtWateringPlace:superClass().onLeave(self, animal)
end
function StateArriveAtWateringPlace:positionReached(animal)
  local wateringPlace = animal.stateData.target
  Perception:injectPerception(animal, self.readyToStopAtWateringPlace, true, wateringPlace)
end
