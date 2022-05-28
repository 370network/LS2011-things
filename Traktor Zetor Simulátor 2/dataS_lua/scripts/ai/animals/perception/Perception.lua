Perception = {}
local Perception_mt = Class(Perception)
function Perception:startPerception(agent)
  if agent.perceptionData.isPerceptionActive then
    return
  end
  agent.perceptionData.isPerceptionActive = true
  agent.perceptionData.perceptionQueue = PerceptionQueue:new(Perception.perceiveEnd, Perception)
  Perception:perceiveBegin(agent)
end
function Perception:reset(agent)
  agent.perceptionData.perceptionExtractorsHash = {}
  agent.perceptionData.perceptionFlagsHash = {}
end
function Perception:perceiveBegin(agent)
  if not agent.perceptionData.isPerceptionActive then
    return false
  end
  EntityPerceptionJob:initialize(agent)
  agent.perceptionData.perceptionQueue:addJob(EntityPerceptionJob)
  EntityPerceptionSortingJob:initialize(agent)
  agent.perceptionData.perceptionQueue:addJob(EntityPerceptionSortingJob)
  PredicatePerceptionJob:initialize(agent)
  agent.perceptionData.perceptionQueue:addJob(PredicatePerceptionJob)
  agent.perceptionData.perceptionQueue:prepareDispatch(agent.perceptionData.perceptionTime)
  for flag, hash in pairs(agent.perceptionData.perceptionFlagsHash) do
    agent.perceptionData.perceptionFlagsHash[flag] = false
  end
  for predicateName, hash in pairs(agent.perceptionData.perceivedPredicates) do
    agent.perceptionData.perceivedPredicates[predicateName] = {}
  end
end
function Perception:update(agent, dt)
  agent.perceptionData.perceptionQueue:update(agent, dt)
end
function Perception:perceiveEnd(agent)
  agent.stateData.currentState:checkForStateTransition(agent)
  Perception:perceiveBegin(agent)
end
function Perception:addEntityPerception(agent, entityPerceptionData)
  local entity = entityPerceptionData.entity
  if entityPerceptionData.isPerceivable then
    agent.perceptionData.perceptionEntitiesHash[entity.type][entity] = entityPerceptionData
  else
    agent.perceptionData.perceptionPassiveEntitiesHash[entity.type][entity] = entityPerceptionData
  end
end
function Perception:removeEntityPerception(agent, entityPerceptionData)
  local entity = entityPerceptionData.entity
  if entityPerceptionData.isPerceivable then
    agent.perceptionData.perceptionEntitiesHash[entity.type][entity] = nil
  else
    agent.perceptionData.perceptionPassiveEntitiesHash[entity.type][entity] = nil
  end
end
function Perception:injectPerception(agent, preconditionToPerceive, shouldCheckForStateChange, resultingEntity)
  preconditionToPerceive:inject(agent, resultingEntity)
  if shouldCheckForStateChange then
    agent.stateData.currentState:checkForStateTransition(agent)
    agent.perceptionData.perceptionQueue = PerceptionQueue:new(Perception.perceiveEnd, Perception)
    Perception:perceiveBegin(agent)
  end
end
function Perception:printPerceptions(agent)
  print("\"printing all perceptions\" triggered, waiting for current perception to finish...")
  assert(not Perception.temp)
  Perception.temp = Perception.perceiveBegin
  Perception.perceiveBegin = Perception.printPerceptionsHelper
end
function Perception:printPerceptionsHelper(agent)
  Perception.perceiveBegin = Perception.temp
  Perception.temp = nil
  print("-------------------------------------------------------------------------------")
  print("printing all perceptions...")
  Perception:printEntityPerceptions(agent)
  Perception:printPreconditionPerceptions(agent)
  print("... finished printing all perceptions")
  print("-------------------------------------------------------------------------------")
  Perception:perceiveBegin(agent)
end
function Perception:printEntityPerceptions(agent)
  print("-------------------------------------------------------------------------------")
  print("listing entity perceptions...")
  print("listing active entities : ")
  for entityType, perceptionTable in pairs(agent.perceptionData.perceptionEntitiesHash) do
    if perceptionTable then
      for _, perceptionData in pairs(perceptionTable) do
        print("type : " .. entityType .. " - name : " .. perceptionData.entity.name)
      end
    else
      print("type : " .. entityType .. " - empty")
    end
  end
  print("-------------------------------------------------------------------------------")
  print("listing passive entities : ")
  for entityType, perceptionTable in pairs(agent.perceptionData.perceptionPassiveEntitiesHash) do
    if perceptionTable then
      for _, perceptionData in pairs(perceptionTable) do
        print("type : " .. entityType .. " - name : " .. perceptionData.entity.name)
      end
    else
      print("type : " .. entityType .. " - empty")
    end
  end
  print("...finished listing entity perceptions")
  print("-------------------------------------------------------------------------------")
end
function Perception:printPreconditionPerceptions(agent)
  print("-------------------------------------------------------------------------------")
  print("listing precondition perceptions...")
  print("listing perception flags : ")
  for flag, entity in pairs(agent.perceptionData.perceptionFlagsHash) do
    print(flag .. " : " .. tostring(entity and entity.name))
  end
  print("-------------------------------------------------------------------------------")
  print("listing perception predicates : ")
  for predicateName, predicate in pairs(agent.perceptionData.perceivedPredicates) do
    local resultString = predicateName .. " - "
    if not next(predicate) then
      resultString = resultString .. " not perceived "
      print(resultString)
    else
      Perception:printPerceptionPredicateHelper(agent, predicate, predicate, 1, resultString)
    end
  end
  print("...finished listing precondition perceptions")
  print("-------------------------------------------------------------------------------")
end
function Perception:printPerceptionPredicateHelper(agent, predicate, currentSubPredicate, currentDepth, currentString)
  for entity, subPredicate in pairs(currentSubPredicate) do
    if type(entity) == "boolean" then
      currentString = currentString .. " : " .. tostring(entity)
      print(currentString)
    else
      Perception:printPerceptionPredicateHelper(agent, predicate, subPredicate, currentDepth + 1, currentDepth == 1 and currentString .. entity.name or currentString .. ", " .. entity.name)
    end
  end
end
