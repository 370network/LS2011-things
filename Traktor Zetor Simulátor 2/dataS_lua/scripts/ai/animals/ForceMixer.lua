ForceMixer = {}
Class(ForceMixer)
function ForceMixer.calculateSteeringForce(agent)
  local steeringDataList = {}
  local steeringDataListIndex = 1
  for _, steeringBehavior in ipairs(agent.steeringData.steeringBehaviorsList) do
    local forceX, forceY, forceZ, importance, complexity = steeringBehavior:gatherForce(agent)
    local steeringData = {
      forceX = forceX,
      forceY = forceY,
      forceZ = forceZ,
      importance = importance,
      complexity = complexity
    }
    steeringDataList[steeringDataListIndex] = steeringData
    steeringDataListIndex = steeringDataListIndex + 1
  end
  return ForceMixer.calculateFinalForce(agent, steeringDataList)
end
function ForceMixer.calculateFinalForce(agent, steeringDataList)
  local compoundImportance = 0
  for _, steeringData in ipairs(steeringDataList) do
    local forceImportance = steeringData.importance
    compoundImportance = compoundImportance + forceImportance
  end
  local finalForceX, finalForceY, finalForceZ = 0, 0, 0
  local finalComplexity = 0
  if compoundImportance == 0 then
    return finalForceX, finalForceY, finalForceZ, finalComplexity
  end
  for i, steeringData in ipairs(steeringDataList) do
    local forceX, forceY, forceZ = steeringData.forceX, steeringData.forceY, steeringData.forceZ
    local forceImportance = steeringData.importance
    local forceComplexity = steeringData.complexity
    local multiplier = forceImportance / compoundImportance
    finalForceX, finalForceY, finalForceZ = finalForceX + forceX * multiplier, finalForceY + forceY * multiplier, finalForceZ + forceZ * multiplier
    finalComplexity = math.max(finalComplexity, forceComplexity)
  end
  return finalForceX, finalForceY, finalForceZ, finalComplexity
end
