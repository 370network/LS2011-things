SprayerSetIsFillingEvent = {}
SprayerSetIsFillingEvent_mt = Class(SprayerSetIsFillingEvent, Event)
InitStaticEventClass(SprayerSetIsFillingEvent, "SprayerSetIsFillingEvent", EventIds.EVENT_SPRAYER_SET_IS_FILLING)
function SprayerSetIsFillingEvent:emptyNew()
  local self = Event:new(SprayerSetIsFillingEvent_mt)
  self.className = "SprayerSetIsFillingEvent"
  return self
end
function SprayerSetIsFillingEvent:new(object, isFilling, fillType, isSiloTrigger)
  local self = SprayerSetIsFillingEvent:emptyNew()
  self.object = object
  self.isFilling = isFilling
  self.fillType = fillType
  self.isSiloTrigger = isSiloTrigger
  return self
end
function SprayerSetIsFillingEvent:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.isFilling = streamReadBool(streamId)
  if self.isFilling and not connection:getIsServer() then
    self.isSiloTrigger = streamReadBool(streamId)
    self.fillType = streamReadUIntN(streamId, Fillable.sendNumBits)
  end
  self:run(connection)
end
function SprayerSetIsFillingEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isFilling)
  if self.isFilling and connection:getIsServer() then
    streamWriteBool(streamId, self.isSiloTrigger)
    streamWriteUIntN(streamId, self.fillType, Fillable.sendNumBits)
  end
end
function SprayerSetIsFillingEvent:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.object)
  end
  self.object:setIsSprayerFilling(self.isFilling, self.fillType, self.isSiloTrigger, true)
end
function SprayerSetIsFillingEvent.sendEvent(object, isFilling, fillType, isSiloTrigger, noEventSend)
  if isFilling ~= object.isSprayerFilling and (noEventSend == nil or noEventSend == false) then
    if g_server ~= nil then
      g_server:broadcastEvent(SprayerSetIsFillingEvent:new(object, isFilling, fillType, isSiloTrigger), nil, nil, self)
    else
      assert(not isFilling or fillType ~= nil and isSiloTrigger ~= nil)
      g_client:getServerConnection():sendEvent(SprayerSetIsFillingEvent:new(object, isFilling, fillType, isSiloTrigger))
    end
  end
end
