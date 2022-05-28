Connection = {}
Connection_mt = Class(Connection)
function Connection:new(id, isServer, reverseConnection)
  local self = {}
  setmetatable(self, Connection_mt)
  self.streamId = id
  self.isServer = isServer
  self.isConnected = true
  self.isReadyForObjects = false
  self.isReadyForEvents = false
  self.dataSent = 0
  self.objectsInfo = {}
  self.objectsToDeleteAfterCreation = {}
  self.lastSeqSent = 0
  self.lastSeqReceived = 0
  self.highestAckedSeq = 0
  self.ackMask = 0
  self.hasPacketsToAck = false
  self.ackPingPacketSent = false
  if self.streamId == NetworkNode.LOCAL_STREAM_ID then
    self:setIsReadyForObjects(true)
    self:setIsReadyForEvents(true)
    if reverseConnection ~= nil then
      self.localConnection = reverseConnection
    else
      self.localConnection = Connection:new(id, not isServer, self)
      self.localConnection:setIsReadyForObjects(true)
      self.localConnection:setIsReadyForEvents(true)
    end
  end
  return self
end
function Connection:setIsReadyForObjects(isReadyForObjects)
  self.isReadyForObjects = isReadyForObjects
end
function Connection:setIsReadyForEvents(isReadyForEvents)
  self.isReadyForEvents = isReadyForEvents
end
function Connection:sendEvent(event, deleteEvent, force)
  self.dataSent = 0
  if not self.isConnected then
    return
  end
  if self.streamId == NetworkNode.LOCAL_STREAM_ID then
    event:run(self.localConnection)
  elseif self.isReadyForEvents or force then
    if event.eventId == nil then
      print("Error: Invalid event id")
    else
      streamWriteInt8(self.streamId, MessageIds.EVENT)
      streamWriteInt32(self.streamId, event.eventId)
      event:writeStream(self.streamId, self)
      self.dataSent = streamGetWriteOffset(self.streamId)
      netSendStream(self.streamId, "high", "reliable_ordered", 1, true)
      if g_server ~= nil then
        g_server.packetBytes[NetworkNode.PACKET_EVENT] = g_server.packetBytes[NetworkNode.PACKET_EVENT] + self.dataSent / 8
      else
        g_client.packetBytes[NetworkNode.PACKET_EVENT] = g_client.packetBytes[NetworkNode.PACKET_EVENT] + self.dataSent / 8
      end
    end
  end
  if deleteEvent == nil or deleteEvent then
    event:delete()
  end
end
function Connection:getIsClient()
  return not self.isServer
end
function Connection:getIsServer()
  return self.isServer
end
function Connection:getIsLocal()
  return self.streamId == NetworkNode.LOCAL_STREAM_ID
end
function Connection:writeUpdateAck(streamId, increaseSeq)
  if increaseSeq then
    self.lastSeqSent = self.lastSeqSent + 1
  end
  streamWriteInt8(streamId, self.lastSeqSent)
  streamWriteInt8(streamId, self.lastSeqReceived)
  streamWriteInt32(streamId, self.ackMask)
  self.hasPacketsToAck = false
end
function Connection:readUpdateAck(streamId)
  local seq = streamReadInt8(streamId)
  local highestAck = streamReadInt8(streamId)
  local ackMask = streamReadInt32(streamId)
  seq = seq + bitAND(self.lastSeqReceived, 4294967040)
  if seq < self.lastSeqReceived then
    seq = seq + 256
  end
  if seq > self.lastSeqReceived + 31 then
    return false
  end
  highestAck = highestAck + bitAND(self.highestAckedSeq, 4294967040)
  if highestAck < self.highestAckedSeq then
    highestAck = highestAck + 256
  end
  if highestAck > self.lastSeqSent then
    return false
  end
  self.ackMask = bitShiftLeft(self.ackMask, seq - self.lastSeqReceived)
  self.ackMask = self.ackMask + 1
  self.hasPacketsToAck = true
  for i = self.highestAckedSeq + 1, highestAck do
    local isTransmitted = bitAND(ackMask, bitShiftLeft(1, highestAck - i)) ~= 0
    if isTransmitted then
      self:onPacketSent(i)
    else
      self:onPacketLost(i)
    end
  end
  self.highestAckedSeq = highestAck
  self.lastSeqReceived = seq
  return true
end
function Connection:getIsWindowFull()
  return self.lastSeqSent - self.highestAckedSeq >= 30
end
function Connection:onPacketSent(i)
  for objectKey, objectInfo in pairs(self.objectsInfo) do
    local historyEntry = objectInfo.history[i]
    if historyEntry ~= nil then
      if g_networkDebug then
        for k, _ in pairs(objectInfo.history) do
          assert(i <= k)
        end
      end
      objectInfo.history[i] = nil
      if historyEntry.creating then
        objectInfo.creating = false
        if self.objectsToDeleteAfterCreation[objectKey] ~= nil then
          self:sendDeleteObject(self.objectsToDeleteAfterCreation[objectKey])
        end
      elseif historyEntry.deleting then
        self.objectsInfo[objectKey] = nil
      end
    end
  end
end
function Connection:onPacketLost(i)
  for objectKey, objectInfo in pairs(self.objectsInfo) do
    local historyEntry = objectInfo.history[i]
    if historyEntry ~= nil then
      if g_networkDebug then
        for k, _ in pairs(objectInfo.history) do
          assert(i <= k)
        end
      end
      objectInfo.history[i] = nil
      local laterUpdatedMask = 0
      for _, h in pairs(objectInfo.history) do
        laterUpdatedMask = bitOR(laterUpdatedMask, h.mask)
      end
      local notLaterUpdatedMask = bitAND(historyEntry.mask, bitNOT(laterUpdatedMask))
      if notLaterUpdatedMask ~= 0 then
        objectInfo.dirtyMask = bitOR(objectInfo.dirtyMask, notLaterUpdatedMask)
      end
      if historyEntry.creating then
        self.objectsInfo[objectKey] = nil
        if self.objectsToDeleteAfterCreation[objectKey] ~= nil then
          self:sendDeleteObject(self.objectsToDeleteAfterCreation[objectKey])
        end
      elseif historyEntry.deleting then
        objectInfo.deleting = false
      end
    end
  end
end
function Connection:sendDeleteObject(object)
  assert(not self.isServer)
  local objectInfo = self.objectsInfo[object.id]
  if objectInfo == nil or not objectInfo.creating then
    self.objectsInfo[object.id] = nil
    streamWriteInt8(self.streamId, MessageIds.OBJECT_DELETED)
    streamWriteInt32(self.streamId, object.id)
    netSendStream(self.streamId, "high", "reliable_ordered", 1, true)
  else
    self.objectsToDeleteAfterCreation[object.id] = object
  end
end
function Connection:getLatency()
  return 20
end
