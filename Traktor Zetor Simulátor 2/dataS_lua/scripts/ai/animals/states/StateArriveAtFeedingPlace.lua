StateArriveAtFeedingPlace = {}
Class(StateArriveAtFeedingPlace, State)
StateRepository:addState(StateArriveAtFeedingPlace)
function StateArriveAtFeedingPlace:initialize()
  local name = "ArriveAtFeedingPlace"
  self.readyToStopAtFeedingPlace = InjectionPrecondition:new("readyToStopAtFeedingPlace", DefaultPreconditions.canEatFromFeedingPlace)
  local changeStateActionsList = {
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateStopAtFeedingPlace, self.readyToStopAtFeedingPlace)
  }
  StateArriveAtFeedingPlace:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateArriveAtFeedingPlace:onEnter(animal)
  StateArriveAtFeedingPlace:superClass().onEnter(self, animal)
  local feedingPlace = animal.stateData.target
  assert(feedingPlace, "The state does not know to which target entity to go to")
  feedingPlace:addAgent(animal)
  local finalPositionX, finalPositionY, finalPositionZ = feedingPlace.eatingPositionX, getTerrainHeightAtWorldPos(animal.herd.groundObjectId, feedingPlace.eatingPositionX, feedingPlace.eatingPositionY, feedingPlace.eatingPositionZ), feedingPlace.eatingPositionZ
  local approachingPositionX, approachingPositionY, approachingPositionZ = feedingPlace.approachingPositionX, getTerrainHeightAtWorldPos(animal.herd.groundObjectId, feedingPlace.approachingPositionX, feedingPlace.approachingPositionY, feedingPlace.approachingPositionZ), feedingPlace.approachingPositionZ
  local inbetweenPositionX, inbetweenPositionY, inbetweenPositionZ = approachingPositionX + (finalPositionX - approachingPositionX) * 0.25, approachingPositionY + (finalPositionY - approachingPositionY) * 0.25, approachingPositionZ + (finalPositionZ - approachingPositionZ) * 0.25
  local speed = 1
  local useSpeed = true
  ManualPath:initPath(animal, self, self.positionReached)
  ManualPath:addWaypoint(animal, inbetweenPositionX, inbetweenPositionY, inbetweenPositionZ, feedingPlace.directionX, feedingPlace.directionY, feedingPlace.directionZ, speed, useSpeed)
  ManualPath:startPath(animal)
end
function StateArriveAtFeedingPlace:onLeave(animal)
  animal.stateData.target:removeAgent(animal)
  ManualPath:stopPath(animal)
  StateArriveAtFeedingPlace:superClass().onLeave(self, animal)
end
function StateArriveAtFeedingPlace:positionReached(animal)
  local feedingPlace = animal.stateData.target
  Perception:injectPerception(animal, self.readyToStopAtFeedingPlace, true, feedingPlace)
end
