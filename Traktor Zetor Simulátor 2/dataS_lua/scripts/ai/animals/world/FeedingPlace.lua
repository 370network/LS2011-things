FeedingPlace = {
  name = "FeedingPlace",
  type = EntityType.OBJECT
}
local FeedingPlace_mt = Class(FeedingPlace, InteractionPlace)
function FeedingPlace:onCreate(feedingPlaceObjectId)
  assert(feedingPlaceObjectId)
  local directionObjectId = getChild(feedingPlaceObjectId, "direction")
  assert(directionObjectId, "You didn't specify the direction object for the feeding place, please check the model and add a child with the name \"direction\" in the direction the animal should face when eating")
  local positionX, positionY, positionZ = getWorldTranslation(feedingPlaceObjectId)
  local directionPositionX, directionPositionY, directionPositionZ = getWorldTranslation(directionObjectId)
  local connectionX, connectionY, connectionZ = directionPositionX - positionX, directionPositionY - positionY, directionPositionZ - positionZ
  local connectionLength = Utils.vector3Length(connectionX, connectionY, connectionZ)
  assert(0 < connectionLength, "distance between position and direction object is not allowed to be 0")
  local directionX, directionY, directionZ = connectionX / connectionLength, connectionY / connectionLength, connectionZ / connectionLength
  FeedingPlace:new(positionX, positionY, positionZ, directionX, directionY, directionZ, getUserAttribute(feedingPlaceObjectId, "availableSlots"))
end
function FeedingPlace:new(positionX, positionY, positionZ, viewingDirectionX, viewingDirectionY, viewingDirectionZ, availableSlots)
  if self == FeedingPlace then
    self = {}
    setmetatable(self, FeedingPlace_mt)
  end
  FeedingPlace:superClass().new(self)
  self.eatingPositionX, self.eatingPositionY, self.eatingPositionZ = positionX, positionY, positionZ
  local approachingDistance = StateGoTo.TARGET_ARRIVE_DISPLACEMENT
  local approachingPositionX, approachingPositionY, approachingPositionZ = self.eatingPositionX - viewingDirectionX * approachingDistance, self.eatingPositionY - viewingDirectionY * approachingDistance, self.eatingPositionZ - viewingDirectionZ * approachingDistance
  local presets_hash = {}
  presets_hash.name = FeedingPlace.name
  presets_hash.type = FeedingPlace.type
  presets_hash.positionX, presets_hash.positionY, presets_hash.positionZ = positionX, positionY, positionZ
  presets_hash.approachingPositionX, presets_hash.approachingPositionY, presets_hash.approachingPositionZ = approachingPositionX, approachingPositionY, approachingPositionZ
  FeedingPlace:superClass().initialize(self, presets_hash, availableSlots)
  self.isEatable = true
  self.isAlwaysPerceivable = true
  self.directionX, self.directionY, self.directionZ = viewingDirectionX or 0, viewingDirectionY or 0, viewingDirectionZ or 1
  return self
end
function FeedingPlace:refill()
  self.refillTime = AnimalHusbandry.time
end
function FeedingPlace:isFilled()
  return g_currentMission:getSiloAmount(Fillable.FILLTYPE_GRASS) > 2000
end
