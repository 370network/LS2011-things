StateMoveAway = {}
Class(StateMoveAway, StateStand)
StateRepository:addState(StateMoveAway)
function StateMoveAway:initialize()
  local name = "MoveAway"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    ChangeStateAction:new():initialize(StateEscape, EntityPreconditionCollection:new("shouldEscapeFromPlayerWhileWandering", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateWander, PreconditionCollection:new("hasMovedAwayEnough", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.twentySecondsPassed))
  }
  StateMoveAway:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_WALK, AnimalMotionData.ACCELERATION_WALK)
end
function StateMoveAway:onEnter(agent)
  StateMoveAway:superClass().onEnter(self, agent)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringNegativeCohesion)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringSeparation, 10)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringObstacleAvoidance, 100)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringMoveForward)
  AnimalSteeringData.addSteeringBehavior(agent, SteeringAlignment)
end
