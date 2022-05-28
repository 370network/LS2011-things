EntityPerceptionSortingJob = {}
Class(EntityPerceptionSortingJob, Job)
function EntityPerceptionSortingJob:initialize(agent)
  agent.perceptionData[self] = {}
end
function EntityPerceptionSortingJob:release(agent)
  agent.perceptionData[self] = nil
end
function EntityPerceptionSortingJob:doJob(agent)
  agent.perceptionData[self].entityTypeToCheckNext = next(agent.perceptionData.perceptionEntitiesHash, agent.perceptionData[self].entityTypeToCheckNext)
  local entityTypeToCheck = agent.perceptionData[self].entityTypeToCheckNext
  local isJobFinished, shouldMoveJobToBack = not entityTypeToCheck, false
  if isJobFinished then
    return isJobFinished, shouldMoveJobToBack
  end
  local entityHashToCheck = agent.perceptionData.perceptionEntitiesHash[entityTypeToCheck]
  local entityListToCheck = agent.perceptionData.entityPerceptionLists[entityTypeToCheck]
  if not entityListToCheck then
    entityListToCheck = {}
    agent.perceptionData.entityPerceptionLists[entityTypeToCheck] = entityListToCheck
  end
  local newEntitiesHash = {}
  for entity, perceptionData in pairs(entityHashToCheck) do
    newEntitiesHash[entity] = perceptionData
  end
  local elementsRemoved = 0
  local listSize = #entityListToCheck
  for i = 1, listSize do
    local perceptionData = entityListToCheck[i]
    entityListToCheck[i] = nil
    if not newEntitiesHash[perceptionData.entity] then
      elementsRemoved = elementsRemoved + 1
    else
      if newEntitiesHash[perceptionData.entity] then
        newEntitiesHash[perceptionData.entity] = nil
      end
      entityListToCheck[i - elementsRemoved] = perceptionData
    end
  end
  listSize = listSize - elementsRemoved
  for _, perceptionData in pairs(newEntitiesHash) do
    listSize = listSize + 1
    entityListToCheck[listSize] = perceptionData
  end
  table.sort(entityListToCheck, function(perceptionData1, perceptionData2)
    return perceptionData1.distanceToEntity < perceptionData2.distanceToEntity
  end)
  return
end
function EntityPerceptionSortingJob:listSortedPerceptions(agent)
  for entityType, list in pairs(agent.perceptionData.entityPerceptionLists) do
    print(entityType)
    for i, perceptionData in ipairs(list) do
      print(tostring(i) .. ". : " .. perceptionData.entity.name .. " - " .. tostring(perceptionData.distanceToEntity))
    end
  end
end
function EntityPerceptionSortingJob:checkConsistency(agent)
  for entityType, hash in pairs(agent.perceptionData.perceptionEntitiesHash) do
    for entity, hashPerceptionData in pairs(hash) do
      local found = false
      for i, listPerceptionData in ipairs(agent.perceptionData.entityPerceptionLists[entityType]) do
        if listPerceptionData == hashPerceptionData then
          found = true
          break
        end
      end
      if not found then
        print("consistency error (1)")
        return false
      end
    end
    for i, perceptionData in ipairs(agent.perceptionData.entityPerceptionLists[entityType]) do
      if not hash[perceptionData.entity] or hash[perceptionData.entity] ~= perceptionData then
        print("consistency error (2) " .. perceptionData.entity.name)
        return false
      end
    end
  end
  return true
end
