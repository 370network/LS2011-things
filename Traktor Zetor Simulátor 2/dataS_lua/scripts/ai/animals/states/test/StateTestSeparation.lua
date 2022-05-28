StateTestSeparation = {}
Class(StateTestSeparation, State)
StateRepository:addState(StateTestSeparation)
function StateTestSeparation:initialize()
  local name = "TestSeparation"
  local changeStateActionsList = {}
  StateTestSeparation:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateTestSeparation:onEnter(agent)
  StateTestSeparation:superClass().onEnter(self, agent)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringSeparation, 1.1)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringMoveForward)
end
