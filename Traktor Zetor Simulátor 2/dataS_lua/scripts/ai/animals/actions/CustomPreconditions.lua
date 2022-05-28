CheckIfNewStateIsAccessiblePrecondition = {}
local CheckIfNewStateIsAccessiblePrecondition_mt = Class(CheckIfNewStateIsAccessiblePrecondition, BasicPrecondition)
function CheckIfNewStateIsAccessiblePrecondition:new(targetState, flagToUse, subPrecondition)
  if self == CheckIfNewStateIsAccessiblePrecondition then
    self = setmetatable({}, CheckIfNewStateIsAccessiblePrecondition_mt)
  end
  CheckIfNewStateIsAccessiblePrecondition:superClass().new(self, flagToUse, 1)
  self.targetState = targetState
  self.subPrecondition = subPrecondition
  return self
end
function CheckIfNewStateIsAccessiblePrecondition:preparePreconditionFlag(agent)
  CheckIfNewStateIsAccessiblePrecondition:superClass().preparePreconditionFlag(self, agent)
  self.subPrecondition:preparePreconditionFlag(agent)
end
function CheckIfNewStateIsAccessiblePrecondition:preparePerceptionPredicate(agent)
  CheckIfNewStateIsAccessiblePrecondition:superClass().preparePerceptionPredicate(self, agent)
  self.subPrecondition:preparePerceptionPredicate(agent)
end
function CheckIfNewStateIsAccessiblePrecondition:checkPerception(agent, entity, ...)
  local result, resultingEntity = self.subPrecondition:perceive(agent, entity, ...)
  return result, resultingEntity
end
function CheckIfNewStateIsAccessiblePrecondition:checkPrecondition(agent, entity, ...)
  local resultingEntity = self.subPrecondition:checkPrecondition(agent, entity, ...)
  if not resultingEntity then
    return false
  end
  local navMesh = agent.herd.navMeshByStateHash[self.targetState]
  if not navMesh then
    print("Error: Specified target state has no nav mesh assigned")
    return false
  end
  local motionDataTable = agent.motionData
  local positionX, positionY, positionZ = motionDataTable.lastCalculationUpdateValidPositionX, motionDataTable.lastCalculationUpdateValidPositionY, motionDataTable.lastCalculationUpdateValidPositionZ
  if isInsideNavMesh(navMesh, positionX, positionY, positionZ) then
    return resultingEntity
  else
    return false
  end
end
