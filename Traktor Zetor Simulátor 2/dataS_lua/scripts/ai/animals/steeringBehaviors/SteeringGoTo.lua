SteeringGoTo = SteeringFollowPath:copy()
SteeringGoTo.name = "GoTo"
function SteeringGoTo:calculateForceToFinalWaypoint(agent, basicWeight, target)
  agent.steeringData[SteeringObstacleAvoidance].basicWeight = 0
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringArrival:calculateForce(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
function SteeringGoTo:calculateForceToFinalWaypoint_Complex(agent, basicWeight, target)
  agent.steeringData[SteeringObstacleAvoidance].basicWeight = 0
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringArrival:calculateForce_Complex(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
function SteeringGoTo:calculateForceToNonfinalWaypoint_Complex(agent, basicWeight, target)
  local steeringBehaviorTable = agent.steeringData[SteeringFollowPath]
  return SteeringSeek:calculateForce_Complex(agent, basicWeight, steeringBehaviorTable.currentWaypointX, steeringBehaviorTable.currentWaypointY, steeringBehaviorTable.currentWaypointZ)
end
