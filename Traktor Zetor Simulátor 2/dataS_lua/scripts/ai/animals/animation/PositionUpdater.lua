PositionUpdater = {type = "none"}
local PositionUpdater_mt = Class(PositionUpdater)
function PositionUpdater:load(updaterType)
  if updaterType == "none" then
    return PositionUpdater
  elseif updaterType == "byAgent" then
    return PositionByAgentUpdater
  elseif updaterType == "continuous" then
    return PositionContinuousUpdater
  elseif updaterType == "final" then
    return PositionFinalUpdater
  else
    error(string.format("unknown position updater type (%s)", tostring(updaterType)))
  end
end
function PositionUpdater:new()
  if self == PositionUpdater then
    self = setmetatable({}, PositionUpdater_mt)
  end
  return self
end
function PositionUpdater:start(agent, agentAnimationData)
end
function PositionUpdater:update(agent, agentAnimationData, dt)
end
function PositionUpdater:stop(agent, agentAnimationData)
end
function PositionUpdater:move(agent, agentAnimationData, deltaX, deltaY, deltaZ)
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = agentAnimationData.animationPositionX + deltaX, agentAnimationData.animationPositionY + deltaY, agentAnimationData.animationPositionZ + deltaZ
end
function PositionUpdater:setPosition(agent, agentAnimationData, positionX, positionY, positionZ)
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = positionX, positionY, positionZ
end
function PositionUpdater:getCurrentDisplacement(agent, agentAnimationData)
  return 0, 0, 0, 0, 0, 0
end
PositionByAgentUpdater = {type = "byAgent"}
local PositionByAgentUpdater_mt = Class(PositionByAgentUpdater, PositionUpdater)
function PositionByAgentUpdater:new()
  if self == PositionByAgentUpdater then
    self = setmetatable({}, PositionByAgentUpdater_mt)
  end
  return self
end
function PositionByAgentUpdater:start(agent, agentAnimationData)
end
function PositionByAgentUpdater:update(agent, agentAnimationData, dt)
  setTranslation(agentAnimationData.bonesId, agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ)
  setDirection(agentAnimationData.bonesId, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ, 0, 1, 0)
end
function PositionByAgentUpdater:stop(agent, agentAnimationData)
end
PositionContinuousUpdater = {type = "continuous"}
local PositionContinuousUpdater_mt = Class(PositionContinuousUpdater, PositionUpdater)
function PositionContinuousUpdater:new()
  if self == PositionContinuousUpdater then
    self = setmetatable({}, PositionContinuousUpdater_mt)
  end
  return self
end
function PositionContinuousUpdater:start(agent, agentAnimationData)
  agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ = agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ
  agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ = agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ
end
function PositionContinuousUpdater:update(agent, agentAnimationData, dt)
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ = PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ, agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ)
  setTranslation(agentAnimationData.bonesId, agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ)
  setDirection(agentAnimationData.bonesId, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ, 0, 1, 0)
end
function PositionContinuousUpdater:stop(agent, agentAnimationData)
  PositionContinuousUpdater:update(agent, agentAnimationData)
  WalkAnimationState:updateWalkingAnimationData(agent, agentAnimationData, dt)
end
PositionFinalUpdater = {type = "final"}
local PositionFinalUpdater_mt = Class(PositionFinalUpdater, PositionUpdater)
function PositionFinalUpdater:new()
  if self == PositionFinalUpdater then
    self = setmetatable({}, PositionFinalUpdater_mt)
  end
  return self
end
function PositionFinalUpdater:start(agent, agentAnimationData)
  agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ = agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ
  agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ = agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ
end
function PositionFinalUpdater:update(agent, agentAnimationData, dt)
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ = PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ, agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ)
end
function PositionFinalUpdater:stop(agent, agentAnimationData)
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ = PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ, agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ)
  setTranslation(agentAnimationData.bonesId, agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ)
  setDirection(agentAnimationData.bonesId, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ, 0, 1, 0)
end
function PositionFinalUpdater:getCurrentDisplacement(agent, agentAnimationData)
  return PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ, agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ)
end
function PositionFinalUpdater:setPosition(agent, agentAnimationData, positionX, positionY, positionZ)
  local currentAnimationPositionX, currentAnimationPositionY, currentAnimationPositionZ, currentAnimationDirectionX, currentAnimationDirectionY, currentAnimationDirectionZ = PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ, agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ)
  local displacementX, displacementY, displacementZ = positionX - currentAnimationPositionX, 0, positionZ - currentAnimationPositionZ
  agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ = agentAnimationData.animationStartPositionX + displacementX, agentAnimationData.animationStartPositionY + displacementY, agentAnimationData.animationStartPositionZ + displacementZ
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ = PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ, agentAnimationData.animationStartDirectionX, agentAnimationData.animationStartDirectionY, agentAnimationData.animationStartDirectionZ)
  setTranslation(agentAnimationData.bonesId, agentAnimationData.animationStartPositionX, agentAnimationData.animationStartPositionY, agentAnimationData.animationStartPositionZ)
end
function PositionUpdater.getPositionDataFromAnimation(agent, agentAnimationData, initialPositionX, initialPositionY, initialPositionZ, initialDirectionX, initialDirectionY, initialDirectionZ)
  local translationX, translationY, translationZ = getTranslation(agentAnimationData.translationMarkerId)
  local rotationX, rotationY, rotationZ = getRotation(agentAnimationData.translationMarkerId)
  local finalPositionX, finalPositionY, finalPositionZ, finalDirectionX, finalDirectionY, finalDirectionZ
  local length = Utils.vector3Length(translationX, translationY, translationZ)
  if 0 < length then
    local directionX, directionY, directionZ = translationX / length, translationY / length, translationZ / length
    local worldDirectionX, worldDirectionY, worldDirectionZ = localDirectionToWorld(agentAnimationData.bonesId, directionX, directionY, directionZ)
    local worldTranslationX, worldTranslationY, worldTranslationZ = worldDirectionX * length, worldDirectionY * length, worldDirectionZ * length
    finalPositionX, finalPositionY, finalPositionZ = initialPositionX + worldTranslationX, initialPositionY + worldTranslationY, initialPositionZ + worldTranslationZ
  else
    finalPositionX, finalPositionY, finalPositionZ = initialPositionX, initialPositionY, initialPositionZ
  end
  finalDirectionX, finalDirectionY, finalDirectionZ = MotionControl:getRotatedDirection(initialDirectionX, initialDirectionY, initialDirectionZ, -rotationX, -rotationY, -rotationZ)
  return finalPositionX, finalPositionY, finalPositionZ, finalDirectionX, finalDirectionY, finalDirectionZ
end
