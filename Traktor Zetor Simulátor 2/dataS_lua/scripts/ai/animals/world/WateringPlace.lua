WateringPlace = {}
local WateringPlace_mt = Class(WateringPlace, InteractionPlace)
function WateringPlace:onCreate(wateringPlaceObjectId)
  assert(wateringPlaceObjectId)
  local positionObjectId = getChild(wateringPlaceObjectId, "position")
  assert(positionObjectId, "You didn't specify the position object for the watering place, please check the model and add a child with the name \"position\" at the position the animal should stand while drinking")
  local directionObjectId = getChild(wateringPlaceObjectId, "direction")
  assert(directionObjectId, "You didn't specify the direction object for the watering place, please check the model and add a child with the name \"direction\" in the direction the animal should face while drinking")
  local positionX, positionY, positionZ = getWorldTranslation(positionObjectId)
  local directionPositionX, directionPositionY, directionPositionZ = getWorldTranslation(directionObjectId)
  local connectionX, connectionY, connectionZ = directionPositionX - positionX, directionPositionY - positionY, directionPositionZ - positionZ
  local connectionLength = Utils.vector3Length(connectionX, connectionY, connectionZ)
  assert(0 < connectionLength, "distance between position and direction object is not allowed to be 0")
  local directionX, directionY, directionZ = connectionX / connectionLength, connectionY / connectionLength, connectionZ / connectionLength
  WateringPlace:new(positionX, positionY, positionZ, directionX, directionY, directionZ, getUserAttribute(wateringPlaceObjectId, "availableSlots"))
end
function WateringPlace:new(positionX, positionY, positionZ, viewingDirectionX, viewingDirectionY, viewingDirectionZ, availableSlots)
  if self == WateringPlace then
    self = setmetatable({}, WateringPlace_mt)
  end
  WateringPlace:superClass().new(self)
  self.drinkingPositionX, self.drinkingPositionY, self.drinkingPositionZ = positionX, positionY, positionZ
  local approachingDistance = StateGoTo.TARGET_ARRIVE_DISPLACEMENT
  local approachingPositionX, approachingPositionY, approachingPositionZ = self.drinkingPositionX - viewingDirectionX * approachingDistance, self.drinkingPositionY - viewingDirectionY * approachingDistance, self.drinkingPositionZ - viewingDirectionZ * approachingDistance
  local presets_hash = {}
  presets_hash.name = "WateringPlace"
  presets_hash.type = EntityType.OBJECT
  presets_hash.positionX, presets_hash.positionY, presets_hash.positionZ = positionX, positionY, positionZ
  presets_hash.approachingPositionX, presets_hash.approachingPositionY, presets_hash.approachingPositionZ = approachingPositionX, approachingPositionY, approachingPositionZ
  WateringPlace:superClass().initialize(self, presets_hash, availableSlots)
  self.isDrinkable = true
  self.isAlwaysPerceivable = true
  self.directionX, self.directionY, self.directionZ = viewingDirectionX or 0, viewingDirectionY or 0, viewingDirectionZ or 1
  return self
end
