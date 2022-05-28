ClockWrapper = {
  currentTicks = 0,
  ticksPerDay = 1,
  currentTimeOfDay = 0,
  DAY_BEGIN = 0,
  DAY_END = 1
}
Class(ClockWrapper)
function ClockWrapper:initialize(ticksPerDay, currentTimeOfDay)
  self.ticksPerDay = ticksPerDay or 86400000
  self.currentTicks = self:convertTimeOfDayToTicks(currentTimeOfDay or 0)
  self.currentTimeOfDay = 0
  assert(self.ticksPerDay > 0)
  self:update(0)
end
function ClockWrapper:update(dt)
  local oldTime = self.currentTicks
  self.currentTicks = g_currentMission.environment.dayTime
  self.currentTimeOfDay = self:convertTicksToTimeOfDay(self.currentTicks)
  if oldTime > self.currentTicks then
    self:handleNewDay()
  end
end
function ClockWrapper:draw()
  setTextColor(1, 1, 1, 1)
  local hour = math.floor(self.currentTimeOfDay * 24)
  local temp = (self.currentTimeOfDay * 24 - hour) * 60
  local minute = math.floor(temp)
  local second = math.floor((temp - minute) * 60)
  local timeText = string.format("%02d:%02d:%02d", hour, minute, second)
  setTextAlignment(RenderText.ALIGN_LEFT)
  renderText(0.85, 0, 0.05, timeText)
end
function ClockWrapper:convertTicksToTimeOfDay(ticks)
  return ticks % self.ticksPerDay / self.ticksPerDay
end
function ClockWrapper:convertTimeOfDayToTicks(timeOfDay)
  return math.floor(timeOfDay % 1 * self.ticksPerDay)
end
function ClockWrapper:handleNewDay()
  if AnimalHusbandry.useAnimalAI then
    local passedTime = AnimalHusbandry.time
    AnimalHusbandry.time = 0
    for _, animal in ipairs(AnimalHusbandry.herd.visibleAnimals) do
      animal.stateData.timeEntered = animal.stateData.timeEntered - passedTime
    end
  end
end
function ClockWrapper:calculateRandomInnerClockDifferenceAsTimeOfDay()
  local maxDisplacement = 0.15
  return (math.random() * 2 - 1) * maxDisplacement
end
