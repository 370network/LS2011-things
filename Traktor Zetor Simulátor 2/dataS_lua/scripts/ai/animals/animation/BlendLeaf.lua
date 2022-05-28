BlendLeaf = {}
local BlendLeaf_mt = Class(BlendLeaf)
function BlendLeaf:new(agent, agentAnimationData, animationInstance)
  if self == BlendLeaf then
    self = setmetatable({}, BlendLeaf_mt)
  end
  self.animationInstance = animationInstance
  self.name = animationInstance.animation.name
  return self
end
function BlendLeaf:stop(agent, agentAnimationData)
  return self.animationInstance:stop(agent, agentAnimationData)
end
function BlendLeaf:completeStop(agent, agentAnimationData)
  self.animationInstance:stop(agent, agentAnimationData)
end
function BlendLeaf:stopFirstAnimation(agent, agentAnimationData)
  self.animationInstance:stop(agent, agentAnimationData)
end
function BlendLeaf:stopLastAnimation(agent, agentAnimationData)
  self.animationInstance:stop(agent, agentAnimationData)
end
function BlendLeaf:update(agent, agentAnimationData, availableBlendWeight, dt)
  return self.animationInstance:update(agent, agentAnimationData, availableBlendWeight, dt)
end
function BlendLeaf:getCurrentAnimationInstance()
  return self.animationInstance
end
function BlendLeaf:getNeededTrackCount(agent, agentAnimationData)
  return self.animationInstance:getNeededTrackCount()
end
function BlendLeaf:getFirstAnimation(agent, agentAnimationData)
  return self.animationInstance
end
function BlendLeaf:getLastAnimation(agent, agentAnimationData)
  return self.animationInstance
end
