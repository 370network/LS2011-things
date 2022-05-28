AnimationPose = {}
local AnimationPose_mt = Class(AnimationPose)
function AnimationPose:new(presetsHash)
  if self == AnimationPose then
    self = setmetatable({}, AnimationPose_mt)
  end
  self.name = presetsHash.name
  self.stateName = presetsHash.stateName
  return self
end
function AnimationPose:getNextAnimationTransition(agent, agentAnimationData)
  local nextAnimationTransition
  if self.stateName ~= agentAnimationData.targetAnimationState.name then
    local path = AnimationControl.animationPoseChangeToStateData[self.name][agentAnimationData.targetAnimationState.name].path
    nextAnimationTransition = path[1]
  end
  if not nextAnimationTransition then
    local transitionData = AnimationControl.animationTransitions[self.name]
    local transitionToStateData = transitionData.transitionsToState[agentAnimationData.targetAnimationState.name]
    if transitionToStateData and next(transitionToStateData.transitions) then
      local randomTransitionIndex = math.random(table.getn(transitionToStateData.transitions))
      nextAnimationTransition = transitionToStateData.transitions[randomTransitionIndex]
    else
      local randomTransitionIndex = math.random(table.getn(transitionData.transitions))
      nextAnimationTransition = transitionData.transitions[randomTransitionIndex]
    end
  end
  return nextAnimationTransition
end
WalkAnimationPose = {}
local WalkAnimationPose_mt = Class(WalkAnimationPose, AnimationPose)
function WalkAnimationPose:new(presetsHash)
  if self == WalkAnimationPose then
    self = setmetatable({}, WalkAnimationPose_mt)
  end
  self.name = presetsHash.name
  self.stateName = presetsHash.stateName
  return self
end
function WalkAnimationPose:getNextAnimationTransition(agent, agentAnimationData)
  local nextAnimationTransition
  local transitionData = AnimationControl.animationTransitions[self.name]
  for _, animationTransitionData in ipairs(transitionData.transitions) do
    local animationName = animationTransitionData.animationName
    local allConditionsFulFilled = true
    for i, conditionFunction in ipairs(animationTransitionData.conditions) do
      if not conditionFunction(agentAnimationData) then
        allConditionsFulFilled = false
        break
      end
    end
    if allConditionsFulFilled then
      nextAnimationTransition = animationTransitionData
      break
    end
  end
  if not nextAnimationTransition then
    print("error : conditions for transitions from animation pose \"" .. self.name .. "\" did not allow to choose a new animation")
  end
  return nextAnimationTransition
end
