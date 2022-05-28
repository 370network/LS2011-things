JobQueue = {}
local JobQueue_mt = Class(JobQueue)
function JobQueue:new(capacity, jobsFinishedCallbackFunction, jobsFinishedCallbackObject)
  if self == JobQueue then
    self = setmetatable({}, JobQueue_mt)
  end
  self.jobsList = {}
  self.indexQueueBegin = 1
  self.indexQueueEnd = 1
  self.capacity = capacity
  self.jobsPerTick = 0
  self.jobsFinishedCallbackFunction = jobsFinishedCallbackFunction
  self.jobsFinishedCallbackObject = jobsFinishedCallbackObject
  return self
end
function JobQueue:prepareDispatch(scheduledTicks, jobsPerTick, jobsPerFrame)
  self.jobsPerFrame = nil
  self.jobsPerTick = nil
  if jobsPerFrame then
    self.jobsPerFrame = jobsPerFrame
  else
    self.jobsPerTick = jobsPerTick or (self.indexQueueEnd - self.indexQueueBegin) / scheduledTicks
  end
end
function JobQueue:addJob(jobToAdd)
  if self.capacity and self.indexQueueEnd == self.capacity then
    if self.indexQueueBegin > 1 then
      self:resettleQueue()
    else
      error("the queue has reached its capacity")
    end
  end
  self.jobsList[self.indexQueueEnd] = jobToAdd
  self.indexQueueEnd = self.indexQueueEnd + 1
end
function JobQueue:addJobToBegin(jobToAdd)
  if self.indexQueueBegin > 1 then
    self.indexQueueBegin = self.indexQueueBegin - 1
    self.jobsList[self.indexQueueBegin] = jobToAdd
  elseif self.capacity and self.indexQueueEnd == self.capacity then
    error("the queue has reached its capacity")
  else
    self.indexQueueBegin = self.indexQueueBegin - 1
    self.jobsList[self.indexQueueBegin] = jobToAdd
    self:resettleQueue()
  end
end
function JobQueue:retrieveJob(...)
  for i = self.indexQueueBegin, self.indexQueueEnd do
    local currentJob = self.jobsList[i]
    if currentJob:equals(...) then
      return currentJob, i
    end
  end
  return nil
end
function JobQueue:removeJob(jobToRemove, indexToRemove)
  if not indexToRemove then
    for i = self.indexQueueBegin, self.indexQueueEnd do
      if self.jobsList[i] == jobToRemove then
        indexToRemove = i
        break
      end
    end
  end
  for i = indexToRemove, self.indexQueueEnd do
    self.jobsList[i] = self.jobsList[i + 1]
  end
  self.indexQueueEnd = self.indexQueueEnd - 1
end
function JobQueue:resettleQueue()
  local jobsListCopy = self.jobsList
  local indexQueueBeginCopy = self.indexQueueBegin
  local indexQueueEndCopy = self.indexQueueEnd
  self.jobsList = {}
  self.indexQueueBegin = 1
  self.indexQueueEnd = 1
  for i = indexQueueBeginCopy, indexQueueEndCopy - 1 do
    self.jobsList[self.indexQueueEnd] = jobsListCopy[i]
    self.indexQueueEnd = self.indexQueueEnd + 1
  end
end
function JobQueue:update(dt, ...)
  local jobsToDo = self.jobsPerFrame or math.min(dt * self.jobsPerTick, self.indexQueueEnd - self.indexQueueBegin)
  if 0 < jobsToDo then
    jobsToDo = math.ceil(jobsToDo)
    for i = 1, jobsToDo do
      local currentJob = self.jobsList[self.indexQueueBegin]
      local isJobFinished, shouldMoveToBack = currentJob:doJob(...)
      if isJobFinished or shouldMoveToBack then
        self.jobsList[self.indexQueueBegin] = nil
        self.indexQueueBegin = self.indexQueueBegin + 1
        if not isJobFinished and shouldMoveToBack then
          self:addJob(currentJob)
        elseif self.indexQueueBegin == self.indexQueueEnd then
          self:resettleQueue()
          return self:handleJobsFinished(...)
        end
      end
    end
  end
end
function JobQueue:handleJobsFinished(...)
  self.jobsFinishedCallbackFunction(self.jobsFinishedCallbackObject, ...)
end
