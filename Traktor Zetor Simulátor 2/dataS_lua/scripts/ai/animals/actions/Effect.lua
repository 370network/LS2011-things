BasicEffect = {}
local BasicEffect_mt = Class(BasicEffect, StateEffect)
function BasicEffect:new(name)
  if self == BasicEffect then
    self = setmetatable({}, BasicEffect_mt)
  end
  self.name = name or "anonymous Effect"
  return self
end
function BasicEffect:apply(agent)
  error("method has to get overwritten")
end
EffectCollection = {}
local EffectCollection_mt = Class(EffectCollection, BasicEffect)
function EffectCollection:new(name, ...)
  local subEffectsList = {
    ...
  }
  if self == EffectCollection then
    self = setmetatable({}, EffectCollection_mt)
  end
  EffectCollection:superClass().new(self, name)
  self.subEffectsList = subEffectsList
  return self
end
function EffectCollection:apply(agent)
  for _, subEffect in ipairs(self.subEffectsList) do
    subEffect:apply(agent)
  end
end
AttributeEffect = {}
local AttributeEffect_mt = Class(AttributeEffect, BasicEffect)
function AttributeEffect:new(attributeType, changeValue, name)
  assert(attributeType, "You didn't specify an attribute to change")
  assert(changeValue, "You didn't specify a value for changing the attribute")
  if self == AttributeEffect then
    self = setmetatable({}, AttributeEffect_mt)
  end
  AttributeEffect:superClass().new(self, name)
  self.attributeType = attributeType
  self.changeValue = changeValue
  return self
end
function AttributeEffect:apply(agent)
  agent.attributes[self.attributeType]:changeValue(self.changeValue)
end
