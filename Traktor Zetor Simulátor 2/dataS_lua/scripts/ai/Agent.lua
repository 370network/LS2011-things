Agent = {}
local Agent_mt = Class(Agent, Entity)
function Agent:new(presets_hash)
  presets_hash = presets_hash or {}
  if self == Agent then
    self = setmetatable({}, Agent_mt)
  end
  presets_hash.type = presets_hash.type or EntityType.AGENT
  Agent:superClass().new(self):initialize(presets_hash)
  self.name = presets_hash.name or "unnamed agent"
  self.velocityX, self.velocityY, self.velocityZ = presets_hash.velocityX or 0, presets_hash.velocityY or 0, presets_hash.velocityZ or 0
  self.speed = Utils.vector3Length(self.velocityX, self.velocityY, self.velocityZ)
  self.rotationalSpeed = 0
  self.directionX, self.directionY, self.directionZ = presets_hash.directionX or 1, presets_hash.directionY or 0, presets_hash.directionZ or 0
  self.deferredUpdate_TimeToWait = presets_hash.deferredUpdate_TimeToWait or 33
  self.deferredUpdate_TimeWaited = 0
  g_agentManager:addAgent(self)
  return self
end
function Agent:delete()
  g_agentManager:removeAgent(self)
  Agent:superClass().delete(self)
end
function Agent:update(dt)
  self.deferredUpdate_TimeWaited = self.deferredUpdate_TimeWaited + dt
  local loopCount = 1
  while self.deferredUpdate_TimeWaited > self.deferredUpdate_TimeToWait do
    self:updateAgent(self.deferredUpdate_TimeToWait)
    self.deferredUpdate_TimeWaited = self.deferredUpdate_TimeWaited - self.deferredUpdate_TimeToWait
    if 5 <= loopCount then
      self.deferredUpdate_TimeWaited = 0
      break
    end
    loopCount = loopCount + 1
  end
end
function Agent:updateAgent(dt)
  error("has to get overwritten")
end
function Agent:draw()
end
