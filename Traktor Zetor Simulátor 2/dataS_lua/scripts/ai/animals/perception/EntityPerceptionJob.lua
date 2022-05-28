EntityPerceptionJob = {}
Class(EntityPerceptionJob, Job)
function EntityPerceptionJob:initialize(agent)
  self.entitiesHash = g_agentManager.worldState.entitiesHash
  agent.perceptionData[self] = {}
  agent.perceptionData[self].entityToCheckNext = next(self.entitiesHash)
  assert(agent.perceptionData[self].entityToCheckNext)
end
function EntityPerceptionJob:doJob(agent, currentTicks)
  local entityToCheck = agent.perceptionData[self].entityToCheckNext
  local perceptionEntitiesHash = agent.perceptionData.perceptionEntitiesHash
  local perceptionPassiveEntitiesHash = agent.perceptionData.perceptionPassiveEntitiesHash
  if not perceptionEntitiesHash[entityToCheck.type] then
    perceptionEntitiesHash[entityToCheck.type] = {}
    perceptionPassiveEntitiesHash[entityToCheck.type] = {}
  end
  if perceptionEntitiesHash[entityToCheck.type][entityToCheck] then
    perceptionEntitiesHash[entityToCheck.type][entityToCheck]:update(agent, currentTicks)
  elseif perceptionPassiveEntitiesHash[entityToCheck.type][entityToCheck] then
    perceptionPassiveEntitiesHash[entityToCheck.type][entityToCheck]:update(agent, currentTicks)
  else
    EntityPerceptionData:new(agent, entityToCheck, currentTicks)
  end
  agent.perceptionData[self].entityToCheckNext = next(self.entitiesHash, entityToCheck)
  local isJobFinished, shouldMoveJobToBack = not agent.perceptionData[self].entityToCheckNext, false
  return isJobFinished, shouldMoveJobToBack
end
