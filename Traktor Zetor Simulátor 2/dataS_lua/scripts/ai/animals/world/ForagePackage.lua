ForagePackage = {}
local ForagePackage_mt = Class(ForagePackage, Entity)
function ForagePackage:new(presets_hash)
  presets_hash = presets_hash or {}
  presets_hash.name = "ForagePackage"
  presets_hash.type = EntityType.OBJECT
  if self == ForagePackage then
    self = {}
    setmetatable(self, ForagePackage_mt)
  end
  ForagePackage:superClass().new(self)
  ForagePackage:superClass().initialize(self, presets_hash)
  self.isEatable = true
  self.directionX, self.directionY, self.directionZ = presets_hash.directionX or 0, presets_hash.directionY or 0, presets_hash.directionZ or 1
  self.remainingPercentage = presets_hash.remainingPercentage or 1
  self.nutritionOfPackage = presets_hash.nutritionOfPackage or 1
  self.eatPercentageDrop = presets_hash.eatPercentageDrop or 0.1
  self.objectId = clone(controller.foragePackageFactoryId, false)
  assert(self.objectId, "error creating the foliage package object")
  link(getRootNode(), self.objectId)
  setTranslation(self.objectId, self.positionX, self.positionY, self.positionZ)
  return self
end
function ForagePackage:eat(percentageToEat)
  percentageToEat = percentageToEat or self.eatPercentageDrop
  local percentageEaten = math.min(self.remainingPercentage, percentageToEat)
  self.remainingPercentage = self.remainingPercentage - percentageEaten
  if self.remainingPercentage == 0 then
    self:dispose()
  else
    setScale(self.objectId, self.remainingPercentage, self.remainingPercentage, self.remainingPercentage)
  end
  return percentageEaten * self.nutritionOfPackage
end
