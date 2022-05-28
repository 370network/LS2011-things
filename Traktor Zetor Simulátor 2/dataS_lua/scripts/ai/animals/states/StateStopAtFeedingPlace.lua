StateStopAtFeedingPlace = {}
Class(StateStopAtFeedingPlace, State)
StateRepository:addState(StateStopAtFeedingPlace)
function StateStopAtFeedingPlace:initialize()
  local name = "StopAtFeedingPlace"
  self.stoppedAtFeedingPlace = InjectionPrecondition:new("stoppedAtFeedingPlace", DefaultPreconditions.canEatFromFeedingPlace)
  local changeStateActionsList = {
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateEatFromFeedingPlace, self.stoppedAtFeedingPlace)
  }
  StateStopAtFeedingPlace:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateStopAtFeedingPlace:onEnter(animal)
  StateStopAtFeedingPlace:superClass().onEnter(self, animal)
  local feedingPlace = animal.stateData.target
  assert(feedingPlace, "The state does not know to which target entity to go to")
  feedingPlace:addAgent(animal)
  local finalPositionX, finalPositionY, finalPositionZ = feedingPlace.eatingPositionX, getTerrainHeightAtWorldPos(animal.herd.groundObjectId, feedingPlace.eatingPositionX, feedingPlace.eatingPositionY, feedingPlace.eatingPositionZ), feedingPlace.eatingPositionZ
  local speed = 1
  local useSpeed = true
  local stopHere = true
  ManualPath:initPath(animal, self, self.positionReached)
  ManualPath:addWaypoint(animal, finalPositionX, finalPositionY, finalPositionZ, feedingPlace.directionX, feedingPlace.directionY, feedingPlace.directionZ, speed * 0.5, useSpeed, stopHere)
  ManualPath:startPath(animal)
end
function StateStopAtFeedingPlace:onLeave(animal)
  animal.stateData.target:removeAgent(animal)
  ManualPath:stopPath(animal)
  StateStopAtFeedingPlace:superClass().onLeave(self, animal)
end
function StateStopAtFeedingPlace:positionReached(animal)
  animal.speed = 0
  local feedingPlace = animal.stateData.target
  Perception:injectPerception(animal, self.stoppedAtFeedingPlace, true, feedingPlace)
end
