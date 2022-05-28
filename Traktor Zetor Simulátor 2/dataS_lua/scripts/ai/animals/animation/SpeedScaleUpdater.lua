SpeedScaleUpdater = {type = "none"}
local SpeedScaleUpdater_mt = Class(SpeedScaleUpdater)
function SpeedScaleUpdater:load(updaterType)
  if updaterType == "none" then
    return SpeedScaleUpdater
  elseif updaterType == "byAgent" then
    return SpeedScaleByAgentUpdater
  elseif updaterType == "byAgentBegin" then
    return SpeedScaleByAgentBeginUpdater
  elseif updaterType == "byAnimation" then
    return SpeedScaleByAnimationUpdater
  elseif updaterType == "byAnimationTransition" then
    return SpeedScaleUpdater
  else
    error(string.format("unknown speed scale updater type (%s)", tostring(updaterType)))
  end
end
function SpeedScaleUpdater:new()
  if self == SpeedScaleUpdater then
    self = setmetatable({}, SpeedScaleUpdater_mt)
  end
  return self
end
function SpeedScaleUpdater:start(agent, agentAnimationData, animationInstance)
end
function SpeedScaleUpdater:update(agent, agentAnimationData, animationInstance, dt)
end
function SpeedScaleUpdater:stop(agent, agentAnimationData, animationInstance)
end
SpeedScaleByAgentUpdater = {type = "byAgent"}
local SpeedScaleByAgentUpdater_mt = Class(SpeedScaleByAgentUpdater, SpeedScaleUpdater)
function SpeedScaleByAgentUpdater:start(agent, agentAnimationData, animationInstance)
end
function SpeedScaleByAgentUpdater:update(agent, agentAnimationData, animationInstance, dt)
  local minSpeedWithoutIdleBlending = 0.05
  local currentForwardSpeed = agentAnimationData.forwardSpeed
  local speedFactor = math.max(minSpeedWithoutIdleBlending, currentForwardSpeed)
  speedFactor = speedFactor / animationInstance.averageClipSpeed
  setAnimTrackSpeedScale(agentAnimationData.characterSet, animationInstance.assignedTrackId, speedFactor)
end
function SpeedScaleByAgentUpdater:stop(agent, agentAnimationData, animationInstance)
end
SpeedScaleByAgentBeginUpdater = {
  type = "byAgentBegin"
}
local SpeedScaleByAgentBeginUpdater_mt = Class(SpeedScaleByAgentBeginUpdater, SpeedScaleUpdater)
function SpeedScaleByAgentBeginUpdater:start(agent, agentAnimationData, animationInstance)
  local minSpeedWithoutIdleBlending = 0.05
  local currentForwardSpeed = agentAnimationData.forwardSpeed
  local speedFactor = math.max(minSpeedWithoutIdleBlending, currentForwardSpeed)
  setAnimTrackSpeedScale(agentAnimationData.characterSet, animationInstance.assignedTrackId, speedFactor)
end
function SpeedScaleByAgentBeginUpdater:update(agent, agentAnimationData, animationInstance, dt)
end
function SpeedScaleByAgentBeginUpdater:stop(agent, agentAnimationData, animationInstance)
end
SpeedScaleByAnimationUpdater = {
  type = "byAnimation"
}
local SpeedScaleByAnimationUpdater_mt = Class(SpeedScaleByAnimationUpdater, SpeedScaleUpdater)
function SpeedScaleByAnimationUpdater:start(agent, agentAnimationData, animationInstance)
end
function SpeedScaleByAnimationUpdater:update(agent, agentAnimationData, animationInstance, dt)
end
function SpeedScaleByAnimationUpdater:stop(agent, agentAnimationData, animationInstance)
end
