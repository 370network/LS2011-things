EnvironmentWeatherEvent = {}
EnvironmentWeatherEvent_mt = Class(EnvironmentWeatherEvent, Event)
InitStaticEventClass(EnvironmentWeatherEvent, "EnvironmentWeatherEvent", EventIds.EVENT_ENVIRONMENT_WEATHER)
function EnvironmentWeatherEvent:emptyNew()
  local self = Event:new(EnvironmentWeatherEvent_mt)
  self.className = " EnvironmentWeatherEvent"
  self.eventId = EventIds.EVENT_ENVIRONMENT_WEATHER
  return self
end
function EnvironmentWeatherEvent:new(timeUntilNextRain, timeUntilRainAfterNext, rainTime, nextRainDuration, nextRainType, rainTypeAfterNext)
  local self = EnvironmentWeatherEvent:emptyNew()
  self.timeUntilNextRain = timeUntilNextRain
  self.timeUntilRainAfterNext = timeUntilRainAfterNext
  self.rainTime = rainTime
  self.nextRainDuration = nextRainDuration
  self.nextRainType = nextRainType
  self.rainTypeAfterNext = rainTypeAfterNext
  return self
end
function EnvironmentWeatherEvent:readStream(streamId, connection)
  self.timeUntilNextRain = streamReadFloat32(streamId)
  self.timeUntilRainAfterNext = streamReadFloat32(streamId)
  self.rainTime = streamReadFloat32(streamId)
  self.nextRainDuration = streamReadFloat32(streamId)
  self.nextRainType = streamReadInt8(streamId)
  self.rainTypeAfterNext = streamReadFloat32(streamId)
  if g_currentMission ~= nil and g_currentMission.environment ~= nil then
    g_currentMission.environment:setEnvironmentWeather(self.timeUntilNextRain, self.timeUntilRainAfterNext, self.rainTime, self.nextRainDuration, self.nextRainType, self.rainTypeAfterNext)
  end
end
function EnvironmentWeatherEvent:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.timeUntilNextRain)
  streamWriteFloat32(streamId, self.timeUntilRainAfterNext)
  streamWriteFloat32(streamId, self.rainTime)
  streamWriteFloat32(streamId, self.nextRainDuration)
  streamWriteInt8(streamId, self.nextRainType)
  streamWriteFloat32(streamId, self.rainTypeAfterNext)
end
function EnvironmentWeatherEvent:run(connection)
  print("The server should not receive a weatherEvent update")
end
