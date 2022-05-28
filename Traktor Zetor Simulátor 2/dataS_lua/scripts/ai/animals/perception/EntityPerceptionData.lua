EntityPerceptionData = {}
local EntityPerceptionData_mt = Class(EntityPerceptionData)
function EntityPerceptionData:new(agent, entity, currentTicks)
  if self == EntityPerceptionData then
    self = setmetatable({}, EntityPerceptionData_mt)
  end
  self.entity = entity
  self:updatePerceptionData(agent, currentTicks)
  Perception:addEntityPerception(agent, self)
  return self
end
function EntityPerceptionData:updatePerceptionData(agent, currentTicks)
  local entity = self.entity
  local connectionX, connectionY, connectionZ = entity.positionX - agent.positionX, entity.positionY - agent.positionY, entity.positionZ - agent.positionZ
  self.distanceToEntity = Utils.vector3Length(connectionX, connectionY, connectionZ)
  if self.distanceToEntity > 0 then
    self.directionToEntityX, self.directionToEntityY, self.directionToEntityZ = connectionX / self.distanceToEntity, connectionY / self.distanceToEntity, connectionZ / self.distanceToEntity
  else
    self.directionToEntityX, self.directionToEntityY, self.directionToEntityZ = agent.directionX, agent.directionY, agent.directionZ
  end
  self.angleToEntity = Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, self.directionToEntityX, self.directionToEntityY, self.directionToEntityZ)
  self.angleFromEntity = Utils.dotProduct(entity.directionX, entity.directionY, entity.directionZ, self.directionToEntityX * -1, self.directionToEntityY * -1, self.directionToEntityZ * -1)
  self.angleToEntityDirection = Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, entity.directionX, entity.directionY, entity.directionZ)
  self.isPerceivable = self:checkIsPerceivable(agent)
  local timeTillUpdate = 0
  if not self.isPerceivable then
    timeTillUpdate = 5000
  elseif self.distanceToEntity > agent.closeDistance then
    timeTillUpdate = 3000
  else
    timeTillUpdate = 2000
  end
  self.timeForUpdate = currentTicks + timeTillUpdate
end
function EntityPerceptionData:checkIsPerceivable(agent)
  if self.entity.isAlwaysPerceivable then
    return true
  end
  return self.distanceToEntity <= agent.farDistance
end
function rayCastIsEntityVisibleCallback(hitObjectId, x, y, z, distance)
  if hitObjectId ~= AnimalHusbandry.groundObjectId then
    return true
  else
    assert(not rayCastResult, "error on calling the raycast callback")
    rayCastResult = true
    return false
  end
end
function EntityPerceptionData:update(agent, currentTicks)
  if currentTicks >= self.timeForUpdate then
    Perception:removeEntityPerception(agent, self)
    self:updatePerceptionData(agent, currentTicks)
    Perception:addEntityPerception(agent, self)
  end
end
