Entity = {counter = 0}
local Entity_mt = Class(Entity)
function Entity:new()
  if self == Entity then
    self = setmetatable({}, Entity_mt)
  end
  return self
end
function Entity:initialize(presets_hash)
  presets_hash = presets_hash or {}
  assert(presets_hash.positionX, "you didn't provide the position (x) for the entity")
  assert(presets_hash.positionY, "you didn't provide the position (y) for the entity")
  assert(presets_hash.positionZ, "you didn't provide the position (z) for the entity")
  assert(presets_hash.name, "you didn't provide the name for the entity")
  assert(presets_hash.type, "you didn't provide the type of the entity")
  self.positionX, self.positionY, self.positionZ = presets_hash.positionX, presets_hash.positionY, presets_hash.positionZ
  self.name = presets_hash.name .. tostring(Entity.counter)
  Entity.counter = Entity.counter + 1
  self.type = presets_hash.type
  g_agentManager.worldState:addEntity(self)
  return self
end
function Entity:delete()
  g_agentManager.worldState:removeEntity(self)
end
EntityType = {
  AGENT = "AGENT",
  ANIMAL = "ANIMAL",
  HERD = "HERD",
  PLAYER = "PLAYER",
  OBJECT = "OBJECT",
  WORLD_PATCH = "WORLD_PATCH",
  BASIC_PATCH = "BASIC_PATCH",
  PATCH_SLOT = "PATCH_SLOT"
}
