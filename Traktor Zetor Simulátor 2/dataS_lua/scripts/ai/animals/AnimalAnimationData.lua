AnimalAnimationData = {}
local AnimalAnimationData_mt = Class(AnimalAnimationData)
function AnimalAnimationData:new(animal, initialState)
  self = setmetatable({}, AnimalAnimationData_mt)
  return self
end
