CombineSetPipeStateEvent = {}
CombineSetPipeStateEvent_mt = Class(CombineSetPipeStateEvent, Event)
InitStaticEventClass(CombineSetPipeStateEvent, "CombineSetPipeStateEvent", EventIds.EVENT_COMBINE_SET_PIPE_STATE)
function CombineSetPipeStateEvent:emptyNew()
  local self = Event:new(CombineSetPipeStateEvent_mt)
  self.className = "CombineSetPipeStateEvent"
  return self
end
function CombineSetPipeStateEvent:new(object, pipeState)
  local self = CombineSetPipeStateEvent:emptyNew()
  self.object = object
  self.pipeState = pipeState
  assert(self.pipeState >= 0 and self.pipeState < 8)
  return self
end
function CombineSetPipeStateEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.pipeState = streamReadUIntN(streamId, 3)
  self.object = networkGetObject(id)
  self:run(connection)
end
function CombineSetPipeStateEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteUIntN(streamId, self.pipeState, 3)
end
function CombineSetPipeStateEvent:run(connection)
  self.object:setPipeState(self.pipeState, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(CombineSetPipeStateEvent:new(self.object, self.pipeState), nil, connection, self.object)
  end
end
