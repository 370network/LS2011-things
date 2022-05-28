ChangeStateAction = {}
local ChangeStateAction_mt = Class(ChangeStateAction, StateTransition)
function ChangeStateAction:new()
  if self == ChangeStateAction then
    self = setmetatable({}, ChangeStateAction_mt)
  end
  ChangeStateAction:superClass().new(self)
  return self
end
function ChangeStateAction:initialize(targetState, precondition, effect)
  ChangeStateAction:superClass().initialize(self, targetState, precondition, effect)
  return self
end
function ChangeStateAction:useStateTransition(agent, sourceState)
  local resultingEntity = self.precondition:checkPrecondition(agent)
  agent.stateData.nextStateTarget = resultingEntity
  ChangeStateAction:superClass().useStateTransition(self, agent, sourceState)
end
