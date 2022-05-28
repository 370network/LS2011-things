StateMilkingInteract = {}
Class(StateMilkingInteract, State)
StateRepository:addState(StateMilkingInteract)
function StateMilkingInteract:initialize()
  local name = "MilkingInteract"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateMilkingLeave, PreconditionCollection:new("canLeaveMilkingPlace", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.tenSecondsPassed), DefaultEffects.lowerMilkCompletely)
  }
  StateMilkingInteract:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateMilkingInteract:onEnter(agent)
  StateMilkingInteract:superClass().onEnter(self, agent)
  assert(agent.stateData.target)
  agent.stateData.target:addAgent(agent)
  agent.stateData.target:startInteraction(agent)
end
function StateMilkingInteract:onLeave(agent)
  agent.stateData.target:removeAgent(agent)
  StateMilkingInteract:superClass().onLeave(self, agent)
end
