BalerSetIsUnloadingBaleEvent = {}
BalerSetIsUnloadingBaleEvent_mt = Class(BalerSetIsUnloadingBaleEvent, Event)
InitStaticEventClass(BalerSetIsUnloadingBaleEvent, "BalerSetIsUnloadingBaleEvent", EventIds.EVENT_BALER_SET_IS_UNLOADING_BALE)
function BalerSetIsUnloadingBaleEvent:emptyNew()
  local self = Event:new(BalerSetIsUnloadingBaleEvent_mt)
  self.className = "BalerSetIsUnloadingBaleEvent"
  return self
end
function BalerSetIsUnloadingBaleEvent:new(object, isUnloadingBale)
  local self = BalerSetIsUnloadingBaleEvent:emptyNew()
  self.object = object
  self.isUnloadingBale = isUnloadingBale
  return self
end
function BalerSetIsUnloadingBaleEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.isUnloadingBale = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function BalerSetIsUnloadingBaleEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isUnloadingBale)
end
function BalerSetIsUnloadingBaleEvent:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.object)
  end
  self.object:setIsUnloadingBale(self.isUnloadingBale, true)
end
function BalerSetIsUnloadingBaleEvent.sendEvent(object, isUnloadingBale, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(BalerSetIsUnloadingBaleEvent:new(object, isUnloadingBale), nil, nil, object)
    else
      g_client:getServerConnection():sendEvent(BalerSetIsUnloadingBaleEvent:new(object, isUnloadingBale))
    end
  end
end
