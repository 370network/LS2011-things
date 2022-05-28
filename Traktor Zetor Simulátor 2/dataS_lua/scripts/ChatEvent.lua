ChatEvent = {}
ChatEvent_mt = Class(ChatEvent, Event)
InitStaticEventClass(ChatEvent, "ChatEvent", EventIds.EVENT_CHAT)
function ChatEvent:emptyNew()
  local self = Event:new(ChatEvent_mt)
  self.className = "ChatEvent"
  return self
end
function ChatEvent:new(msg, sender)
  local self = ChatEvent:emptyNew()
  self.msg = msg
  self.sender = sender
  return self
end
function ChatEvent:readStream(streamId, connection)
  self.msg = streamReadString(streamId)
  self.sender = streamReadString(streamId)
  self:run(connection)
end
function ChatEvent:writeStream(streamId, connection)
  assert(self.msg ~= nil and self.sender ~= nil, "ChatEvent msg and sender valid")
  local filteredMsg = filterText(self.msg)
  streamWriteString(streamId, filteredMsg)
  streamWriteString(streamId, self.sender)
end
function ChatEvent:run(connection)
  g_currentMission:addChatMessage(self.sender, self.msg)
  if not connection:getIsServer() then
    g_server:broadcastEvent(ChatEvent:new(self.msg, self.sender), nil, connection, nil)
  end
end
