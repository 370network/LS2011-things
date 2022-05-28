StateTestObstacleAvoidance = {}
Class(StateTestObstacleAvoidance, State)
StateRepository:addState(StateTestObstacleAvoidance)
function StateTestObstacleAvoidance:initialize()
  local name = "TestObstacleAvoidance"
  local changeStateActionsList = {}
  StateTestObstacleAvoidance:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateTestObstacleAvoidance:onEnter(agent)
  StateTestObstacleAvoidance:superClass().onEnter(self, agent)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringObstacleAvoidance)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringMoveForward)
end
