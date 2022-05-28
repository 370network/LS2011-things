EnvironmentTimeEvent = {}
EnvironmentTimeEvent_mt = Class(EnvironmentTimeEvent, Event)
InitStaticEventClass(EnvironmentTimeEvent, "EnvironmentTimeEvent", EventIds.EVENT_ENVIRONMENT_TIME)
function EnvironmentTimeEvent:emptyNew()
  local self = Event:new(EnvironmentTimeEvent_mt)
  self.className = " EnvironmentTimeEvent"
  return self
end
function EnvironmentTimeEvent:new(dayTime, currentDay)
  local self = EnvironmentTimeEvent:emptyNew()
  self.dayTime = dayTime
  self.currentDay = currentDay
  return self
end
function EnvironmentTimeEvent:readStream(streamId, connection)
  self.dayTime = streamReadFloat32(streamId)
  self.currentDay = streamReadInt32(streamId)
  if g_currentMission ~= nil and g_currentMission.environment ~= nil then
    g_currentMission.environment:setEnvironmentTime(self.dayTime, self.currentDay)
  end
end
function EnvironmentTimeEvent:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.dayTime)
  streamWriteInt32(streamId, self.currentDay)
end
function EnvironmentTimeEvent:run(connection)
  print("The server should not receive a dayTime update")
end
