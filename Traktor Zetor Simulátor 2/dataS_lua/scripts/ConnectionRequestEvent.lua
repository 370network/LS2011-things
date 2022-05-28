ConnectionRequestEvent = {}
ConnectionRequestEvent_mt = Class(ConnectionRequestEvent, Event)
InitStaticEventClass(ConnectionRequestEvent, "ConnectionRequestEvent", EventIds.EVENT_CONNECTION_REQUEST)
function ConnectionRequestEvent:emptyNew()
  local self = Event:new(ConnectionRequestEvent_mt)
  self.className = "ConnectionRequestEvent"
  return self
end
function ConnectionRequestEvent:new(nickname, language, password)
  local self = ConnectionRequestEvent:emptyNew()
  self.nickname = nickname
  self.language = language
  self.password = password
  return self
end
function ConnectionRequestEvent:readStream(streamId, connection)
  self.nickname = streamReadString(streamId)
  self.language = streamReadUInt8(streamId)
  self.password = streamReadString(streamId)
  self:run(connection)
end
function ConnectionRequestEvent:writeStream(streamId, connection)
  streamWriteString(streamId, self.nickname)
  streamWriteUInt8(streamId, self.language)
  streamWriteString(streamId, self.password)
end
function ConnectionRequestEvent:run(connection)
  g_currentMission:onConnectionRequest(connection, self.nickname, self.language, self.password)
end
