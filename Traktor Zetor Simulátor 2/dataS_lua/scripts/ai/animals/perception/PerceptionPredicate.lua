PerceptionPredicate = {}
local PerceptionPredicate_mt = Class(PerceptionPredicate)
function PerceptionPredicate:new(name, arity)
  if self == PerceptionPredicate then
    self = setmetatable({}, PerceptionPredicate_mt)
  end
  self.name = name
  self.arity = arity
  return self
end
function PerceptionPredicate:register(agent)
  if not agent.perceptionData.perceivedPredicates[self.name] then
    agent.perceptionData.perceivedPredicates[self.name] = {}
  end
end
function PerceptionPredicate:isKnown(agent, ...)
  local perceptionInformation = agent.perceptionData.perceivedPredicates[self.name]
  for i = 1, self.arity do
    local entity = select(i, ...)
    if perceptionInformation[entity] == nil then
      return false
    end
    perceptionInformation = perceptionInformation[entity]
  end
  return true
end
function PerceptionPredicate:store(agent, result, ...)
  local perceptionInformation = agent.perceptionData.perceivedPredicates[self.name]
  for i = 1, self.arity do
    local entity = select(i, ...)
    if not perceptionInformation[entity] then
      perceptionInformation[entity] = {}
    end
    perceptionInformation = perceptionInformation[entity]
  end
  if result == nil then
    print(self.name)
    print(debug.traceback())
  end
  perceptionInformation[result] = {}
end
function PerceptionPredicate:getResult(agent, ...)
  local perceptionInformation = agent.perceptionData.perceivedPredicates[self.name]
  local lastPerceptionInformation
  for i = 1, self.arity do
    local entity = select(i, ...)
    if not perceptionInformation[entity] then
      return nil
    end
    lastPerceptionInformation = perceptionInformation
    perceptionInformation = perceptionInformation[entity]
  end
  local result = not not next(perceptionInformation)
  if result then
    return result, lastPerceptionInformation
  else
    return result
  end
end
