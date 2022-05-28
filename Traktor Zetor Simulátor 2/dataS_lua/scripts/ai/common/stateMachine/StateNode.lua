StateNode = {}
local StateNode_mt = Class(StateNode)
function StateNode:initialize(name, stateTransitionsList)
  self.name = name or ""
  self.stateTransitionsList = stateTransitionsList
end
function StateNode:checkForStateTransition(entity)
  for _, stateTransition in ipairs(self.stateTransitionsList) do
    if stateTransition:checkForStateTransition(entity, self) then
      return
    end
  end
end
function StateNode:onEnter(entity)
  for _, stateTransition in ipairs(self.stateTransitionsList) do
    stateTransition:prepare(entity)
  end
end
function StateNode:onLeave(entity)
end
