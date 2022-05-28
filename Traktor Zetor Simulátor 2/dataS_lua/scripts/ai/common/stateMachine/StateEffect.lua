StateEffect = {}
local StateEffect_mt = Class(StateEffect)
function StateEffect:new()
  if self == StateEffect then
    self = setmetatable({}, StateEffect_mt)
  end
  return self
end
function StateEffect:apply(entity)
  return
end
