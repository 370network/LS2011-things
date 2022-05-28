BlendNode = {}
local BlendNode_mt = Class(BlendNode)
function BlendNode:new(firstElementToBlend, secondElementToBlend, blendTime)
  if self == BlendNode then
    self = setmetatable({}, BlendNode_mt)
  end
  if blendTime == 0 then
    print("Error: blend time is 0")
  end
  self.name = "BlendNode"
  self.firstElementToBlend = firstElementToBlend
  self.secondElementToBlend = secondElementToBlend
  self.blendTime = blendTime
  self.remainingBlendTime = blendTime
  return self
end
function BlendNode:stop(agent, agentAnimationData)
  self.firstElementToBlend:stop(agent, agentAnimationData)
end
function BlendNode:completeStop(agent, agentAnimationData)
  self.firstElementToBlend:completeStop(agent, agentAnimationData)
  self.secondElementToBlend:completeStop(agent, agentAnimationData)
end
function BlendNode:stopFirstAnimation(agent, agentAnimationData)
  local newFirstBlendNode = self.firstElementToBlend:stopFirstAnimation(agent, agentAnimationData)
  if not newFirstBlendNode then
    return self.secondElementToBlend
  else
    self.firstElementToBlend = newFirstBlendNode
  end
  return self
end
function BlendNode:stopLastAnimation(agent, agentAnimationData)
  local newSecondBlendNode = self.secondElementToBlend:stopLastAnimation(agent, agentAnimationData)
  if not newSecondBlendNode then
    return self.firstElementToBlend
  else
    self.secondElementToBlend = newSecondBlendNode
  end
  return self
end
function BlendNode:update(agent, agentAnimationData, availableBlendWeight, dt)
  self.remainingBlendTime = self.remainingBlendTime - dt
  local blendFinished = false
  local blendFactor
  if self.remainingBlendTime < 0 then
    blendFinished = true
    blendFactor = 0
  else
    blendFactor = (math.cos((1 - self.remainingBlendTime / self.blendTime) * math.pi) + 1) * 0.5
  end
  if blendFinished then
    self.firstElementToBlend:completeStop(agent, agentAnimationData)
    local secondAnimationFinished, newSecondBlendNode = self.secondElementToBlend:update(agent, agentAnimationData, availableBlendWeight, dt)
    if newSecondBlendNode then
      self.secondElementToBlend = newSecondBlendNode
    end
    return secondAnimationFinished, self.secondElementToBlend
  else
    local firstAnimationFinished, newFirstBlendNode = self.firstElementToBlend:update(agent, agentAnimationData, blendFactor * availableBlendWeight, dt)
    if newFirstBlendNode then
      self.firstElementToBlend = newFirstBlendNode
    end
    local secondAnimationFinished, newSecondBlendNode = self.secondElementToBlend:update(agent, agentAnimationData, (1 - blendFactor) * availableBlendWeight, dt)
    if newSecondBlendNode then
      self.secondElementToBlend = newSecondBlendNode
    end
    return secondAnimationFinished, false
  end
end
function BlendNode:getCurrentAnimationInstance()
  return self.secondElementToBlend:getCurrentAnimationInstance()
end
function BlendNode:getNeededTrackCount(agent, agentAnimationData)
  return self.firstElementToBlend:getNeededTrackCount() + self.secondElementToBlend:getNeededTrackCount()
end
function BlendNode:getFirstAnimation(agent, agentAnimationData)
  return self.firstElementToBlend:getFirstAnimation(agent, agentAnimationData)
end
function BlendNode:getLastAnimation(agent, agentAnimationData)
  return self.secondElementToBlend:getLastAnimation(agent, agentAnimationData)
end
