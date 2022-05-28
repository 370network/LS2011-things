GamePauseEvent = {}
GamePauseEvent_mt = Class(GamePauseEvent, Event)
InitStaticEventClass(GamePauseEvent, "GamePauseEvent", EventIds.EVENT_GAME_PAUSE)
function GamePauseEvent:emptyNew()
  local self = Event:new(GamePauseEvent_mt)
  self.className = "GamePauseEvent"
  return self
end
function GamePauseEvent:new(pause)
  local self = GamePauseEvent:emptyNew()
  self.pause = pause
  return self
end
function GamePauseEvent:readStream(streamId, connection)
  self.pause = streamReadBool(streamId)
  self:run(connection)
end
function GamePauseEvent:writeStream(streamId, connection)
  streamWriteBool(streamId, self.pause)
end
function GamePauseEvent:run(connection)
  if self.pause then
    g_currentMission:pauseGame()
  else
    g_currentMission:unpauseGame()
  end
end
