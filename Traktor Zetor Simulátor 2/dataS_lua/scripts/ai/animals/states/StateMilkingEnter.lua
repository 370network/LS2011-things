StateMilkingEnter = {}
Class(StateMilkingEnter, State)
StateRepository:addState(StateMilkingEnter)
function StateMilkingEnter:initialize()
  local name = "MilkingEnter"
  self.arrivedAtMilkingPlacePrecondition = InjectionPrecondition:new("arrivedAtMilkingPlace", EntityPreconditionCollection:new("canInteractWithMilkingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isMilkingPlace))
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateMilkingInteract, self.arrivedAtMilkingPlacePrecondition)
  }
  StateMilkingEnter:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WANDER, AnimalMotionData.ACCELERATION_WANDER)
end
function StateMilkingEnter:onEnter(agent)
  StateMilkingEnter:superClass().onEnter(self, agent)
  assert(agent.stateData.target)
  local milkingPlace = agent.stateData.target
  milkingPlace.positionX, milkingPlace.positionY, milkingPlace.positionZ = milkingPlace.tempPositionX, milkingPlace.tempPositionY, milkingPlace.tempPositionZ
  agent.stateData.target:addAgent(agent)
  agent.stateData.target:enter(agent)
  ManualPath:initPath(agent, self, StateMilkingEnter.pathCompletedCallback)
  ManualPath:addWaypoint(agent, milkingPlace.entrancePositionX, getTerrainHeightAtWorldPos(agent.herd.groundObjectId, milkingPlace.entrancePositionX, milkingPlace.entrancePositionY, milkingPlace.entrancePositionZ), milkingPlace.entrancePositionZ, milkingPlace.entranceDirectionX, milkingPlace.entranceDirectionY, milkingPlace.entranceDirectionZ, 1, true)
  ManualPath:addWaypoint(agent, milkingPlace.positionX, getTerrainHeightAtWorldPos(agent.herd.groundObjectId, milkingPlace.positionX, milkingPlace.positionY, milkingPlace.positionZ), milkingPlace.positionZ, milkingPlace.directionX, milkingPlace.directionY, milkingPlace.directionZ, 1, true, true)
  ManualPath:startPath(agent)
end
function StateMilkingEnter:onLeave(agent)
  agent.stateData.target:removeAgent(agent)
  StateMilkingEnter:superClass().onLeave(self, agent)
end
function StateMilkingEnter:pathCompletedCallback(agent)
  agent.speed = 0
  local milkingPlace = agent.stateData.target
  Perception:injectPerception(agent, self.arrivedAtMilkingPlacePrecondition, true, milkingPlace)
end
