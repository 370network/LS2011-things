TrailerToggleTipEvent = {}
TrailerToggleTipEvent_mt = Class(TrailerToggleTipEvent, Event)
InitStaticEventClass(TrailerToggleTipEvent, "TrailerToggleTipEvent", EventIds.EVENT_TRAILER_TOGGLE_TIP)
function TrailerToggleTipEvent:emptyNew()
  local self = Event:new(TrailerToggleTipEvent_mt)
  self.className = "TrailerToggleTipEvent"
  return self
end
function TrailerToggleTipEvent:new(object, isStart, currentTipTrigger)
  local self = TrailerToggleTipEvent:emptyNew()
  self.isStart = isStart
  self.currentTipTrigger = currentTipTrigger
  self.object = object
  return self
end
function TrailerToggleTipEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.isStart = streamReadBool(streamId)
  if self.isStart then
    local triggerId = streamReadInt32(streamId)
    self.currentTipTrigger = networkGetObject(triggerId)
  end
  self.object = networkGetObject(id)
  self:run(connection)
end
function TrailerToggleTipEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isStart)
  if self.isStart then
    streamWriteInt32(streamId, networkGetObjectId(self.currentTipTrigger))
  end
end
function TrailerToggleTipEvent:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.object)
  end
  if self.isStart then
    self.object:onStartTip(self.currentTipTrigger, true)
  else
    self.object:onEndTip(true)
  end
end
