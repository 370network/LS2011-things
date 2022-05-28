StateTest = {}
Class(StateTest, State)
StateRepository:addState(StateTest)
function StateTest:initialize()
  local name = "Test"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateEscape, DefaultChangeStateActions.startToEscapeFromPlayer),
    ChangeStateAction:new():initialize(StateTest, DefaultPreconditions.fiveSecondsPassed)
  }
  StateTest:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateTest:onEnter(agent)
  StateWander:superClass().onEnter(self, agent)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringNegativeCohesion)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringSeparation, 3)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringObstacleAvoidance, 10)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringWander)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringAlignment)
end
function StateTest:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-0.001 * (dt / 1000))
end
