BasicPrecondition = {}
local BasicPrecondition_mt = Class(BasicPrecondition, StatePrecondition)
function BasicPrecondition:new(flagToUse, arity)
  assert(flagToUse, "You have to specify a flag to set for this precondition")
  if self == BasicPrecondition then
    self = setmetatable({}, BasicPrecondition_mt)
  end
  BasicPrecondition:superClass().new(self)
  self.perceptionPredicate = PerceptionPredicate:new(flagToUse, arity)
  self.flagToUse = tostring(flagToUse)
  self.name = tostring(flagToUse)
  return self
end
function BasicPrecondition:prepare(agent)
  assert(agent)
  self:register(agent)
  self:preparePreconditionFlag(agent)
  self:preparePerceptionPredicate(agent)
end
function BasicPrecondition:register(agent)
  agent.perceptionData.perceptionExtractorsHash[self] = self
end
function BasicPrecondition:preparePreconditionFlag(agent)
  agent.perceptionData.perceptionFlagsHash[self.flagToUse] = false
end
function BasicPrecondition:preparePerceptionPredicate(agent)
  self.perceptionPredicate:register(agent)
end
function BasicPrecondition:perceive(agent, entity, ...)
  entity = entity or agent
  coroutine.yield()
  if self:isCheckPerceptionNeeded(agent, entity, ...) then
    local result, resultingEntity = self:checkPerception(agent, entity, ...)
    self.perceptionPredicate:store(agent, result, entity, ...)
    resultingEntity = resultingEntity or entity
    if result and not agent.perceptionData.perceptionFlagsHash[self.flagToUse] then
      agent.perceptionData.perceptionFlagsHash[self.flagToUse] = resultingEntity
    end
    return result, resultingEntity
  else
    local result = self.perceptionPredicate:getResult(agent, entity, ...)
    local resultingEntity = agent.perceptionData.perceptionFlagsHash[self.flagToUse]
    return result, resultingEntity
  end
end
function BasicPrecondition:checkPerception(agent, entity)
  return agent
end
function BasicPrecondition:isCheckPerceptionNeeded(agent, ...)
  return not self.perceptionPredicate:isKnown(agent, ...)
end
function BasicPrecondition:putToLog(agent, message, isPeriodicInfo)
  isPeriodicInfo = isPeriodicInfo or true
  if isPeriodicInfo then
    agent.log:addMessage(message, {
      AnimalLogDefaultLabels.ACTION,
      AnimalLogDefaultLabels.PRECONDITION
    }, AnimalLogMessageImportanceLevels.PERIODIC_INFO)
  else
    agent.log:addMessage(message, {
      AnimalLogDefaultLabels.ACTION,
      AnimalLogDefaultLabels.PRECONDITION
    }, AnimalLogMessageImportanceLevels.INFO)
  end
end
function BasicPrecondition:checkPrecondition(agent)
  return agent.perceptionData.perceptionFlagsHash[self.flagToUse]
end
NegatePrecondition = {}
local NegatePrecondition_mt = Class(NegatePrecondition, BasicPrecondition)
function NegatePrecondition:new(flagToUse, preconditionToNegate, arity)
  if self == NegatePrecondition then
    self = setmetatable({}, NegatePrecondition_mt)
  end
  NegatePrecondition:superClass().new(self, flagToUse, arity or preconditionToNegate.perceptionPredicate.arity)
  self.preconditionToNegate = preconditionToNegate
  return self
end
function NegatePrecondition:preparePreconditionFlag(agent)
  NegatePrecondition:superClass().preparePreconditionFlag(self, agent)
  self.preconditionToNegate:preparePreconditionFlag(agent)
end
function NegatePrecondition:preparePerceptionPredicate(agent)
  PreconditionCollection:superClass().preparePerceptionPredicate(self, agent)
  self.preconditionToNegate:preparePerceptionPredicate(agent)
end
function NegatePrecondition:checkPerception(agent, entity, ...)
  local result = self.preconditionToNegate:perceive(agent, entity, ...)
  return not result
end
PreconditionCollection = {}
local PreconditionCollection_mt = Class(PreconditionCollection, BasicPrecondition)
function PreconditionCollection:new(flagToUse, arity, ...)
  local subPreconditionsList = {
    ...
  }
  if self == PreconditionCollection then
    self = setmetatable({}, PreconditionCollection_mt)
  end
  PreconditionCollection:superClass().new(self, flagToUse, arity)
  self.subPreconditionsList = subPreconditionsList
  return self
end
function PreconditionCollection:preparePreconditionFlag(agent)
  PreconditionCollection:superClass().preparePreconditionFlag(self, agent)
  for _, subPrecondition in ipairs(self.subPreconditionsList) do
    if not subPrecondition.preparePreconditionFlag then
      print()
    end
    subPrecondition:preparePreconditionFlag(agent)
  end
end
function PreconditionCollection:preparePerceptionPredicate(agent)
  PreconditionCollection:superClass().preparePerceptionPredicate(self, agent)
  for _, subPrecondition in ipairs(self.subPreconditionsList) do
    subPrecondition:preparePerceptionPredicate(agent)
  end
end
function PreconditionCollection:checkPerception(agent, entity, ...)
  local result = true
  local resultingEntity
  for _, subPrecondition in ipairs(self.subPreconditionsList) do
    result, resultingEntity = subPrecondition:perceive(agent, entity, ...)
    if not result then
      result = false
      break
    end
  end
  return result, resultingEntity
end
EntityPreconditionCollection = {}
local EntityPreconditionCollection_mt = Class(EntityPreconditionCollection, PreconditionCollection)
function EntityPreconditionCollection:new(flagToUse, arity, entityTypeToAnalyze, ...)
  if not entityTypeToAnalyze then
    print("stop")
  end
  assert(entityTypeToAnalyze, "You have to specify an entity type")
  if self == EntityPreconditionCollection then
    self = setmetatable({}, EntityPreconditionCollection_mt)
  end
  EntityPreconditionCollection:superClass().new(self, flagToUse, arity, ...)
  self.entityTypeToAnalyze = entityTypeToAnalyze
  return self
end
function EntityPreconditionCollection:isCheckPerceptionNeeded(agent)
  return not EntityPreconditionCollection:superClass().checkPrecondition(self, agent)
end
function EntityPreconditionCollection:perceive(agent, entity, ...)
  entity = entity or agent
  local result = false
  local resultingEntity
  if agent.perceptionData.entityPerceptionLists[self.entityTypeToAnalyze] then
    for _, entityPerception in ipairs(agent.perceptionData.entityPerceptionLists[self.entityTypeToAnalyze]) do
      if EntityPreconditionCollection:superClass().perceive(self, agent, entityPerception.entity, entity, ...) then
        result = true
        resultingEntity = entityPerception.entity
        break
      end
    end
  end
  return result, resultingEntity
end
InjectionPrecondition = {}
local InjectionPrecondition_mt = Class(InjectionPrecondition, BasicPrecondition)
function InjectionPrecondition:new(flagToUse, basicPrecondition)
  if self == InjectionPrecondition then
    self = setmetatable({}, InjectionPrecondition_mt)
  end
  InjectionPrecondition:superClass().new(self, flagToUse, 1)
  return self
end
function InjectionPrecondition:register(agent)
end
function InjectionPrecondition:preparePreconditionFlag(agent)
  InjectionPrecondition:superClass().preparePreconditionFlag(self, agent)
end
function InjectionPrecondition:preparePerceptionPredicate(agent)
  PreconditionCollection:superClass().preparePerceptionPredicate(self, agent)
end
function InjectionPrecondition:isApplicable(agent)
  return agent.perceptionData.perceptionFlagsHash[self.flagToUse] ~= nil
end
function InjectionPrecondition:perceive(agent, entity, ...)
end
function InjectionPrecondition:inject(agent, resultingEntity)
  if not self:isApplicable(agent) then
    return
  end
  agent.perceptionData.perceptionFlagsHash[self.flagToUse] = resultingEntity
end
function InjectionPrecondition:checkPerception(agent, entity, ...)
  return self.basicPrecondition:perceive(agent, entity, ...)
end
