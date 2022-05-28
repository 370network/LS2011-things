EnvironmentTmpEvent = {}
EnvironmentTmpEvent_mt = Class(EnvironmentTmpEvent, Event)
InitStaticEventClass(EnvironmentTmpEvent, "EnvironmentTmpEvent", EventIds.EVENT_ENVIRONMENT_TMP)
function EnvironmentTmpEvent:emptyNew()
  local self = Event:new(EnvironmentTmpEvent_mt)
  self.className = " EnvironmentTmpEvent"
  return self
end
function EnvironmentTmpEvent:new(pdaWeatherTemperaturesDay, pdaWeatherTemperaturesNight)
  local self = EnvironmentTmpEvent:emptyNew()
  self.pdaWeatherTemperaturesDay = pdaWeatherTemperaturesDay
  self.pdaWeatherTemperaturesNight = pdaWeatherTemperaturesNight
  return self
end
function EnvironmentTmpEvent:readStream(streamId, connection)
  self.pdaWeatherTemperaturesDay = {}
  self.pdaWeatherTemperaturesNight = {}
  self.pdaWeatherTemperaturesDay[1] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesDay[2] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesDay[3] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesDay[4] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesNight[1] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesNight[2] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesNight[3] = streamReadInt32(streamId)
  self.pdaWeatherTemperaturesNight[4] = streamReadInt32(streamId)
  g_currentMission.missionPDA:setEnvironmentTemperature(self.pdaWeatherTemperaturesDay, self.pdaWeatherTemperaturesNight)
end
function EnvironmentTmpEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesDay[1])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesDay[2])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesDay[3])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesDay[4])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesNight[1])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesNight[2])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesNight[3])
  streamWriteInt32(streamId, self.pdaWeatherTemperaturesNight[4])
end
function EnvironmentTmpEvent:run(connection)
  print("The server should not receive a TmpEvent update")
end
