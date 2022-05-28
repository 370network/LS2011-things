BaleLoaderStateEvent = {}
BaleLoaderStateEvent_mt = Class(BaleLoaderStateEvent, Event)
InitStaticEventClass(BaleLoaderStateEvent, "BaleLoaderStateEvent", EventIds.EVENT_BALE_LOADER_STATE)
function BaleLoaderStateEvent:emptyNew()
  local self = Event:new(BaleLoaderStateEvent_mt)
  self.className = "BaleLoaderStateEvent"
  return self
end
function BaleLoaderStateEvent:new(object, stateId, nearestBaleServerId)
  local self = BaleLoaderStateEvent:emptyNew()
  self.object = object
  self.stateId = stateId
  assert(nearestBaleServerId ~= nil or self.stateId ~= BaleLoader.CHANGE_GRAB_BALE)
  self.nearestBaleServerId = nearestBaleServerId
  return self
end
function BaleLoaderStateEvent:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.stateId = streamReadInt8(streamId)
  if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
    self.nearestBaleServerId = streamReadInt32(streamId)
  end
  self:run(connection)
end
function BaleLoaderStateEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt8(streamId, self.stateId)
  if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
    streamWriteInt32(streamId, self.nearestBaleServerId)
  end
end
function BaleLoaderStateEvent:run(connection)
  self.object:doStateChange(self.stateId, self.nearestBaleServerId)
end
