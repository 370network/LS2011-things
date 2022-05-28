StateMilkingLeave = {}
Class(StateMilkingLeave, State)
StateRepository:addState(StateMilkingLeave)
function StateMilkingLeave:initialize()
  local name = "MilkingLeave"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateWander, DefaultPreconditions.threeSecondsPassed)
  }
  StateMilkingLeave:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateMilkingLeave:onEnter(agent)
  local milkingPlace = agent.stateData.target
  agent.stateData.nextStateTarget = milkingPlace
  StateMilkingLeave:superClass().onEnter(self, agent)
  agent.stateData.target:addAgent(agent)
  agent.stateData.target:endInteraction(agent)
  local speed = 1
  local useSpeed = true
  ManualPath:initPath(agent, self, StateMilkingLeave.pathCompletedCallback)
  ManualPath:addWaypoint(agent, milkingPlace.exitPositionX, getTerrainHeightAtWorldPos(agent.herd.groundObjectId, milkingPlace.exitPositionX, milkingPlace.exitPositionY, milkingPlace.exitPositionZ), milkingPlace.exitPositionZ, nil, nil, nil, speed, useSpeed)
  ManualPath:startPath(agent)
end
function StateMilkingLeave:onLeave(agent)
  ManualPath:stopPath(agent)
  agent.stateData.target:removeAgent(agent)
  agent.stateData.target:leave(agent)
  StateMilkingLeave:superClass().onLeave(self, agent)
end
