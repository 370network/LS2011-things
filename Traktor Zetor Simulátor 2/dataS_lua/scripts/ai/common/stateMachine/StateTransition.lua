StateTransition = {}
local StateTransition_mt = Class(StateTransition)
function StateTransition:new()
  if self == StateTransition then
    self = setmetatable({}, StateTransition_mt)
  end
  return self
end
function StateTransition:initialize(targetState, precondition, effect)
  self.targetState = targetState
  self.precondition = precondition
  self.effect = effect or StateEffect:new()
end
function StateTransition:prepare(entity)
  self.precondition:prepare(entity)
end
function StateTransition:checkForStateTransition(entity, state)
  if self.precondition:checkPrecondition(entity) then
    self:useStateTransition(entity, state)
    return true
  end
  return false
end
function StateTransition:useStateTransition(entity, sourceState)
  sourceState:onLeave(entity)
  self.effect:apply(entity)
  self.targetState:onEnter(entity)
end
