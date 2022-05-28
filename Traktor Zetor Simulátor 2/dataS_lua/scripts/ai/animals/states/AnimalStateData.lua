AnimalStateData = {}
local AnimalStateData_mt = Class(AnimalStateData)
function AnimalStateData:new(animal, initialState)
  self = setmetatable({}, AnimalStateData_mt)
  self.currentState = initialState or StateIdle
  self.speedLimit = animal.speedWalk
  self.accelerationLimit = animal.accelerationWalk
  self.target = nil
  self.nextStateTarget = nil
  self.timeEntered = 0
  self.innerClockDifference = ClockWrapper:calculateRandomInnerClockDifferenceAsTimeOfDay()
  self.isStateChangePracticable = true
  return self
end
