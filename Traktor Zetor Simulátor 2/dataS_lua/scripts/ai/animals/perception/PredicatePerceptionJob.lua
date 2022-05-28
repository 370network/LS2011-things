PredicatePerceptionJob = {}
Class(PredicatePerceptionJob, Job)
function PredicatePerceptionJob:initialize(agent)
  local perceptionFunction = function(agent)
    for perceptionExtractor, _ in pairs(agent.perceptionData.perceptionExtractorsHash) do
      if perceptionExtractor:perceive(agent) then
      end
    end
  end
  agent.perceptionData[self] = {}
  agent.perceptionData[self].perceptionCoroutine = coroutine.create(perceptionFunction)
end
function PredicatePerceptionJob:doJob(agent)
  local result, errorMessage = coroutine.resume(agent.perceptionData[self].perceptionCoroutine, agent)
  assert(not errorMessage, errorMessage)
  local isJobFinished, shouldMoveJobToBack = coroutine.status(agent.perceptionData[self].perceptionCoroutine) == "dead", false
  return isJobFinished, shouldMoveJobToBack
end
