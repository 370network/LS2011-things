BlendSequence = {}
local BlendSequence_mt = Class(BlendSequence, BlendNode)
function BlendSequence:new(agent, agentAnimationData, blendNode)
  if self == BlendSequence then
    self = setmetatable({}, BlendSequence_mt)
  end
  BlendNode.new(self, blendNode.firstElementToBlend, blendNode.secondElementToBlend, blendNode.blendTime)
  self.animationSequence = {}
  self.animationSequenceStartTimes = {}
  self.animationSequenceBlendTimes = {}
  self.animationSequenceFirstUsedIndex = 0
  self.animationSequenceFirstFreeIndex = 0
  return self
end
function BlendSequence:stop(agent, agentAnimationData)
  BlendNode.stop(self, agent, agentAnimationData)
end
function BlendSequence:completeStop(agent, agentAnimationData)
  BlendNode.completeStop(self, agent, agentAnimationData)
end
function BlendSequence:addSubAnimation(agent, agentAnimationData, animation, animationStartTime, blendTime)
  print("BlendSequence:addSubAnimation : warning : adding a sub animation to a sequence might not have the intenden effect!")
  BlendNode.addSubAnimation(self, agent, agentAnimationData, animation, animationStartTime, blendTime)
end
function BlendSequence:addSubAnimationToSequence(agent, agentAnimationData, animation, animationStartTime, blendTime)
  local firstFreeIndex = self.animationSequenceFirstFreeIndex
  self.animationSequence[firstFreeIndex] = animation
  self.animationSequenceStartTimes[firstFreeIndex] = animationStartTime
  self.animationSequenceBlendTimes[firstFreeIndex] = blendTime
  self.animationSequenceFirstFreeIndex = firstFreeIndex + 1
end
function BlendSequence:update(agent, agentAnimationData, availableBlendWeight, dt)
  local animationFinished, subBlendFinished = self.currentBlendNode:update(agent, agentAnimationData, availableBlendWeight, dt)
  local isLastBlend = self.animationSequenceFirstUsedIndex == self.animationSequenceFirstFreeIndex
  if subBlendFinished then
    if isLastBlend then
      return animationFinished, true
    end
    local indexToUse = self.animationSequenceFirstUsedIndex
    local nextAnimation = self.animationSequence[indexToUse]
    local nextAnimationStartTime = self.animationSequenceStartTimes[indexToUse]
    local nextAnimationBlendTime = self.animationSequenceBlendTimes[indexToUse]
    self.animationSequence[indexToUse] = nil
    self.animationSequenceStartTimes[indexToUse] = nil
    self.animationSequenceBlendTimes[indexToUse] = nil
    self.animationSequenceFirstUsedElement = indexToUse + 1
    nextAnimationInstance = nextAnimation:start(agent, agentAnimationData, nextAnimationStartTime)
    if not nextAnimationInstance then
      error("BlendSequence.addAnimation error: cannot instantiate animation")
    end
    self.currentBlendNode.firstElementToBlend = subBlendActiveNode
    self.currentBlendNode.secondElementToBlend = nextAnimationInstance
    self.currentBlendNode.blendTime = nextAnimationBlendTime
    self.currentBlendNode.remainingBlendTime = nextAnimationBlendTime
    return false, false
  end
end
function BlendSequence:getCurrentAnimationInstance()
  return self.currentBlendNode:getCurrentAnimationInstance()
end
