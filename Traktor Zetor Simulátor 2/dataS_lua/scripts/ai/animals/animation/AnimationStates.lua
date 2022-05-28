AnimationState = {}
function AnimationState:new(presetsHash)
  if not presetsHash.name then
    print("animation state name not specified")
    return nil
  end
  if not presetsHash.type then
    print("animation type not specified")
    return nil
  end
  if presetsHash.type ~= "Default" and presetsHash.type ~= "Walk" and presetsHash.type ~= "ConstrainedWalk" then
    print(string.format("specified animation type \"%s\" not specified", presetsHash.type))
    return nil
  end
  if presetsHash.type == "Default" then
    self = DefaultAnimationState:new(presetsHash)
  elseif presetsHash.type == "Walk" then
    self = WalkAnimationState:new(presetsHash)
  end
  return self
end
DefaultAnimationState = {}
local DefaultAnimationState_mt = Class(DefaultAnimationState)
function DefaultAnimationState:new(presetsHash)
  if self == DefaultAnimationState then
    self = setmetatable({}, DefaultAnimationState_mt)
  end
  self.name = presetsHash.name
  self.animationPoses = {}
  self.agentSpecificData = {}
  return self
end
function DefaultAnimationState:onEnter(agent, agentAnimationData)
  self.agentSpecificData[agent] = {}
  self.agentSpecificData[agent].flagsHash = {}
end
function DefaultAnimationState:update(agent, agentAnimationData, dt)
end
function DefaultAnimationState:onLeave(agent, agentAnimationData)
  self.agentSpecificData[agent] = nil
end
function DefaultAnimationState:onEnterByDrivingAnimation(agent, agentAnimationData)
  if next(agentAnimationData.flagsHash) then
    for i, v in pairs(agentAnimationData.flagsHash) do
      agentAnimationData.flagsHash[i] = nil
    end
  end
  if not self.agentSpecificData[agent] then
    self.agentSpecificData[agent] = {
      flagsHash = {}
    }
  end
  if next(self.agentSpecificData[agent].flagsHash) then
    for i, v in pairs(self.agentSpecificData[agent].flagsHash) do
      agentAnimationData.flagsHash[i] = v
    end
  end
end
function DefaultAnimationState:onLeaveByDrivingAnimation(agent, agentAnimationData)
end
function DefaultAnimationState:setFlags(agent, agentAnimationData, flagsToUse)
  if not self.agentSpecificData[agent] then
    self.agentSpecificData[agent] = {}
  end
  if not self.agentSpecificData[agent].flagsHash then
    self.agentSpecificData[agent].flagsHash = {}
  else
    for flag, _ in pairs(self.agentSpecificData[agent].flagsHash) do
      self.agentSpecificData[agent].flagsHash[flag] = nil
    end
  end
  local flagsHash = self.agentSpecificData[agent].flagsHash
  for _, flag in ipairs(flagsToUse) do
    flagsHash[flag] = true
  end
end
function DefaultAnimationState:isFlagSet(agent, agentAnimationData, flagToCheck)
  return self.agentSpecificData[agent] and self.agentSpecificData[agent].flagsHash[flagToCheck]
end
WalkAnimationState = {}
local WalkAnimationState_mt = Class(WalkAnimationState, DefaultAnimationState)
function WalkAnimationState:new(presetsHash)
  if self == WalkAnimationState then
    self = setmetatable({}, WalkAnimationState_mt)
  end
  DefaultAnimationState.new(self, presetsHash)
  return self
end
function WalkAnimationState:onEnter(agent, agentAnimationData)
end
function WalkAnimationState:update(agent, agentAnimationData, dt)
end
function WalkAnimationState:updateWalkingAnimationData(agent, agentAnimationData, dt)
  local movementLatency = AnimationControl.latency
  local movementLatency_s = 1
  local futureAgentPositionX, futureAgentPositionY, futureAgentPositionZ = agent.positionX, agent.positionY, agent.positionZ
  local positionDifferenceX, positionDifferenceY, positionDifferenceZ = futureAgentPositionX - agentAnimationData.animationPositionX, futureAgentPositionY - agentAnimationData.animationPositionY, futureAgentPositionZ - agentAnimationData.animationPositionZ
  local distance = Utils.vector3Length(positionDifferenceX, positionDifferenceY, positionDifferenceZ)
  local planeNormalX, planeNormalY, planeNormalZ = agent.directionX, agent.directionY, agent.directionZ
  local lambda = Utils.dotProduct(planeNormalX, planeNormalY, planeNormalZ, futureAgentPositionX, futureAgentPositionY, futureAgentPositionZ)
  local length = Utils.dotProduct(planeNormalX, planeNormalY, planeNormalZ, agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ) - lambda
  local getAngleBetweenDirections = function(x1, y1, z1, x2, y2, z2)
    local dot = Utils.dotProduct(x1, y1, z1, x2, y2, z2)
    if 0.999999999 < dot then
      return 0
    end
    if dot < -0.999999999 then
      return math.pi
    end
    local sideX, sideY, sideZ = Utils.crossProduct(x1, y1, z1, 0, 1, 0)
    local isLeft = Utils.dotProduct(x2, y2, z2, sideX, sideY, sideZ) < 0
    return math.acos(dot) * (isLeft and -1 or 1)
  end
  local directionToAgentX, directionToAgentY, directionToAgentZ
  if 0 < distance then
    directionToAgentX, directionToAgentY, directionToAgentZ = positionDifferenceX / distance, positionDifferenceY / distance, positionDifferenceZ / distance
  else
    directionToAgentX, directionToAgentY, directionToAgentZ = agent.directionX, agent.directionY, agent.directionZ
  end
  local angleToAnimalDirection = getAngleBetweenDirections(agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ, agent.directionX, agent.directionY, agent.directionZ)
  local angleToAnimal = getAngleBetweenDirections(agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ, directionToAgentX, directionToAgentY, directionToAgentZ)
  local positionFactor = Utils.dotProduct(directionToAgentX, directionToAgentY, directionToAgentZ, agent.directionX, agent.directionY, agent.directionZ)
  positionFactor = 1 - math.abs(positionFactor)
  local directionFactor = Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, directionToAgentX, directionToAgentY, directionToAgentZ)
  directionFactor = (directionFactor + 1) * 0.5
  local blendStartDistanceFront = 0.125
  local blendEndDistanceFront = 1
  local blendStartDistanceBack = 1
  local blendEndDistanceBack = 2.5
  local blendStartDistance = directionFactor * blendStartDistanceFront + (1 - directionFactor) * blendStartDistanceBack
  local blendEndDistance = directionFactor * blendEndDistanceFront + (1 - directionFactor) * blendEndDistanceBack
  local blendDistanceWidth = blendEndDistance - blendStartDistance
  local blendFactor
  if 0 < blendDistanceWidth then
    blendFactor = math.min(1, math.max(0, distance - blendStartDistance) / blendDistanceWidth)
  else
    blendFactor = 0
  end
  blendFactor = blendFactor * blendFactor
  blendFactor = blendFactor * math.min(1, blendFactor + positionFactor)
  local angleToRotate = blendFactor * angleToAnimal + (1 - blendFactor) * angleToAnimalDirection
  angleToRotate = (agentAnimationData.angle * 2 + angleToRotate) / 3
  if length < 0 then
    agentAnimationData.forwardSpeed = math.abs(length)
    agentAnimationData.rotationalSpeed = angleToRotate
    agentAnimationData.distance = distance
    agentAnimationData.angle = angleToRotate
  else
    agentAnimationData.forwardSpeed = 0
    agentAnimationData.rotationalSpeed = angleToRotate
    agentAnimationData.distance = 0
    agentAnimationData.angle = angleToRotate
  end
end
function WalkAnimationState:onLeave(agent, agentAnimationData)
end
