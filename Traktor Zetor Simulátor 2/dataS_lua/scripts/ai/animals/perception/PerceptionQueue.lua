PerceptionQueue = {}
local PerceptionQueue_mt = Class(PerceptionQueue, JobQueue)
function PerceptionQueue:new(jobsFinishedCallbackFunction, jobsFinishedCallbackObject)
  if self == PerceptionQueue then
    self = setmetatable({}, PerceptionQueue_mt)
  end
  PerceptionQueue:superClass().new(self, capacity, jobsFinishedCallbackFunction, jobsFinishedCallbackObject)
  self.ticksBegin = 0
  self.ticksEnd = 0
  self.ticksDuration = 0
  return self
end
function PerceptionQueue:prepareDispatch(scheduledTicks)
  self.ticksBegin = ClockWrapper.currentTicks
  local newJobsPerTick = (self.ticksDuration / scheduledTicks - 1) ^ 3 * self.jobsPerTick + self.jobsPerTick
  newJobsPerTick = math.min(math.max(newJobsPerTick, 0.001), 100)
  PerceptionQueue:superClass().prepareDispatch(self, scheduledTicks, newJobsPerTick)
end
function PerceptionQueue:update(agent, dt, ...)
  PerceptionQueue:superClass().update(self, dt, agent, ClockWrapper.currentTicks, ...)
end
function PerceptionQueue:handleJobsFinished(agent, ...)
  self.ticksEnd = ClockWrapper.currentTicks
  self.ticksDuration = self.ticksEnd - self.ticksBegin
  PerceptionQueue:superClass().handleJobsFinished(self, agent, ...)
end
