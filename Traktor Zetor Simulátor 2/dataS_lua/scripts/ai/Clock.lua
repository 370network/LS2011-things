Clock = {
  currentTicks = 0,
  ticksPerDay = 1,
  currentTimeOfDay = 0,
  DAY_BEGIN = 0,
  DAY_END = 1
}
Class(Clock)
function Clock:initialize(ticksPerDay, currentTimeOfDay)
  self.ticksPerDay = ticksPerDay or 86400000
  self.currentTicks = self:convertTimeOfDayToTicks(currentTimeOfDay or 0)
  self.currentTimeOfDay = 0
  assert(self.ticksPerDay > 0)
  self:update(0)
end
function Clock:update(dt)
  self.currentTicks = self.currentTicks + dt
  self.currentTimeOfDay = self:convertTicksToTimeOfDay(self.currentTicks)
end
function Clock:draw()
  setTextColor(1, 1, 1, 1)
  local hour = math.floor(self.currentTimeOfDay * 24)
  local temp = (self.currentTimeOfDay * 24 - hour) * 60
  local minute = math.floor(temp)
  local second = math.floor((temp - minute) * 60)
  local timeText = string.format("%02d:%02d:%02d", hour, minute, second)
  setTextAlignment(RenderText.ALIGN_LEFT)
  renderText(0.85, 0, 0.05, timeText)
end
function Clock:convertTicksToTimeOfDay(ticks)
  return ticks % self.ticksPerDay / self.ticksPerDay
end
function Clock:convertTimeOfDayToTicks(timeOfDay)
  return math.floor(timeOfDay % 1 * self.ticksPerDay)
end
