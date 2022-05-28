StatePrecondition = {}
local StatePrecondition_mt = Class(StatePrecondition)
function StatePrecondition:new()
  if self == StatePrecondition then
    self = setmetatable({}, StatePrecondition_mt)
  end
  return self
end
function StatePrecondition:prepare(entity)
end
function StatePrecondition:checkPrecondition(entity)
  return true
end
