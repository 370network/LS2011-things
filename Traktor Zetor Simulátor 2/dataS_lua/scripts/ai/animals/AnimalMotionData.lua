AnimalMotionData = {
  SPEED_STAND = "speedStand",
  SPEED_WANDER = "speedWander",
  SPEED_WALK = "speedWalk",
  SPEED_RACE = "speedRace",
  ACCELERATION_STAND = "accelerationStand",
  ACCELERATION_WANDER = "accelerationWander",
  ACCELERATION_WALK = "accelerationWalk",
  ACCELERATION_RACE = "accelerationRace"
}
local AnimalMotionData_mt = Class(AnimalMotionData)
function AnimalMotionData:new(animal, initialState)
  self = setmetatable({}, AnimalMotionData_mt)
  self.timeBetweenCalculationUpdates = 1000
  self.lastCalculationUpdateTime = 0
  self.timeToNextCalculationUpdate = self.timeBetweenCalculationUpdates
  self.lastCalculationUpdateAccelerationX = 0
  self.lastCalculationUpdateAccelerationY = 0
  self.lastCalculationUpdateAccelerationZ = 0
  self.lastCalculationUpdateValidPositionX = 0
  self.lastCalculationUpdateValidPositionY = 0
  self.lastCalculationUpdateValidPositionZ = 0
  self.positionAdjustmentXPerMS = 0
  self.positionAdjustmentYPerMS = 0
  self.positionAdjustmentZPerMS = 0
  self.directionAdjustmentAnglePerMS = 0
  self.isPositionCorrectionActive = false
  self.isManualPositionOverrideActive = false
  self.manualPositionOverrideObject = false
  self.manualPositionOverrideStorage = nil
  return self
end
