AnimalPerceptionData = {}
local AnimalPerceptionData_mt = Class(AnimalPerceptionData)
function AnimalPerceptionData:new()
  self = setmetatable({}, AnimalPerceptionData_mt)
  self.perceptionExtractorsHash = {}
  self.perceptionFlagsHash = {}
  self.perceivedPredicates = {}
  self.perceptionEntitiesHash = {}
  self.entityPerceptionLists = {}
  self.perceptionPassiveEntitiesHash = {}
  self.perceptionTime = 1000
  self.isPerceptionActive = false
  return self
end
