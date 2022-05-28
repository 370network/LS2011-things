ConnectionRequestAnswerEvent = {}
ConnectionRequestAnswerEvent_mt = Class(ConnectionRequestAnswerEvent, Event)
InitStaticEventClass(ConnectionRequestAnswerEvent, "ConnectionRequestAnswerEvent", EventIds.EVENT_CONNECTION_REQUEST_ANSWER)
ConnectionRequestAnswerEvent.ANSWER_OK = 0
ConnectionRequestAnswerEvent.ANSWER_DENIED = 1
ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD = 2
ConnectionRequestAnswerEvent.ANSWER_FULL = 3
function ConnectionRequestAnswerEvent:emptyNew()
  local self = Event:new(ConnectionRequestAnswerEvent_mt)
  self.className = "ConnectionRequestAnswerEvent"
  return self
end
function ConnectionRequestAnswerEvent:new(answer, difficulty, timeScale)
  local self = ConnectionRequestAnswerEvent:emptyNew()
  self.answer = answer
  self.difficulty = difficulty
  self.timeScale = timeScale
  return self
end
function ConnectionRequestAnswerEvent:readStream(streamId, connection)
  self.answer = streamReadUIntN(streamId, 2)
  if self.answer == ConnectionRequestAnswerEvent.ANSWER_OK then
    self.difficulty = streamReadUIntN(streamId, 3)
    self.timeScale = streamReadFloat32(streamId)
  end
  self:run(connection)
end
function ConnectionRequestAnswerEvent:writeStream(streamId, connection)
  streamWriteUIntN(streamId, self.answer, 2)
  if self.answer == ConnectionRequestAnswerEvent.ANSWER_OK then
    streamWriteUIntN(streamId, self.difficulty, 3)
    streamWriteFloat32(streamId, self.timeScale)
  end
end
function ConnectionRequestAnswerEvent:run(connection)
  g_currentMission:onConnectionRequestAnswer(connection, self.answer, self.difficulty, self.timeScale)
end
