WorldState = {}
local WorldState_mt = Class(WorldState)
function WorldState:new(presets_hash)
  presets_hash = presets_hash or {}
  local self = {}
  setmetatable(self, WorldState_mt)
  self.entitiesHash = {}
  return self
end
function WorldState:addEntity(entityToAdd, entityType)
  assert(entityToAdd, "You didn't specify the entity to add")
  assert(entityToAdd.name, "The specified entity doesn't have a name attribute")
  assert(entityToAdd.positionX, "The specified entity doesn't have a positionX attribute")
  assert(entityToAdd.positionY, "The specified entity doesn't have a positionY attribute")
  assert(entityToAdd.positionZ, "The specified entity doesn't have a positionZ attribute")
  assert(entityToAdd.type or entityType, "The specified entity doesn't have a type attribute and you have not manually specified a type for it as second argument")
  entityToAdd.type = entityToAdd.type or entityType
  self.entitiesHash[entityToAdd] = true
end
function WorldState:removeEntity(entityToRemove)
  self.entitiesHash[entityToRemove] = nil
end
function WorldState:getNextEntityOfSpecifiedType(entityType, entityToStart)
  local currentEntity = next(self.entitiesHash, entityToStart)
  while currentEntity do
    if currentEntity.type == entityType then
      return currentEntity
    end
    currentEntity = next(self.entitiesHash, currentEntity)
  end
  return nil
end
