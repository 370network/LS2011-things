Client = {}
Client_mt = Class(Client, NetworkNode)
local clientLocalNetConnect = ""
function InitClientOnce()
  if clientLocalNetConnect == "" then
    clientLocalNetConnect = netConnect
  end
end
function Client:new()
  local self = NetworkNode:new(Client_mt)
  self.clientNetworkCardAddress = ""
  self.clientPort = 0
  self.serverConnection = nil
  self.tempCreateObjects = {}
  self.tickRate = 30
  self.tickDuration = 1000 / self.tickRate
  self.tickSum = 0
  self.netIsRunning = false
  self.lastNumUpdatesSent = 0
  return self
end
function Client:delete()
  Client:superClass().delete(self)
  self:stop()
end
function Client:update(dt, isRunning)
  if g_server == nil then
    Client:superClass().update(self, dt)
    if self.serverStreamId == 0 then
      return
    end
    if not isRunning then
      return
    end
    for k, object in pairs(self.objects) do
      object:update(dt)
    end
    local maxUploadSize = g_maxUploadRate * 8 * self.tickDuration
    self.tickSum = self.tickSum + dt
    if self.tickSum >= self.tickDuration then
      local updates = {}
      for serverId, object in pairs(self.objects) do
        object:updateTick(self.tickSum)
        if object.dirtyMask ~= 0 then
          table.insert(updates, {serverId, object})
        end
      end
      if self.serverConnection:getIsWindowFull() then
        if not self.serverConnection.ackPingPacketSent then
          self.serverConnection.ackPingPacketSent = true
          streamWriteInt8(self.serverStreamId, MessageIds.OBJECT_PING)
          self.serverConnection:writeUpdateAck(self.serverStreamId, false)
          netSendStream(self.serverStreamId, "medium", "reliable_ordered", 2, true)
        end
      else
        self.serverConnection.ackPingPacketSent = false
        local numUpdates = table.getn(updates)
        local numUpdatesSent = numUpdates
        if 0 < numUpdates then
          streamWriteTimestamp(self.serverStreamId)
        end
        streamWriteInt8(self.serverStreamId, MessageIds.OBJECT_UPDATE)
        self.serverConnection:writeUpdateAck(self.serverStreamId, true)
        streamAlignWriteToByteBoundary(self.serverStreamId)
        local numUpdatesOffset = streamGetWriteOffset(self.serverStreamId)
        streamWriteInt16(self.serverStreamId, 0)
        local x, y, z = 0, 0, 0
        if self.networkListener ~= nil then
          x, y, z = self.networkListener:getClientPosition()
        end
        streamWriteFloat32(self.serverStreamId, x)
        streamWriteFloat32(self.serverStreamId, y)
        streamWriteFloat32(self.serverStreamId, z)
        local oldPacketSize = 0
        for j = 1, numUpdates do
          local object = updates[j][2]
          local id = updates[j][1]
          streamWriteInt32(self.serverStreamId, id)
          object:writeUpdateStream(self.serverStreamId, self.serverConnection, object.dirtyMask)
          object.dirtyMask = 0
          local packetSize = streamGetWriteOffset(self.serverStreamId)
          if object:isa(Vehicle) then
            self.packetBytes[NetworkNode.PACKET_VEHICLE] = self.packetBytes[NetworkNode.PACKET_VEHICLE] + (packetSize - oldPacketSize) / 8
          else
            self.packetBytes[NetworkNode.PACKET_OTHERS] = self.packetBytes[NetworkNode.PACKET_OTHERS] + (packetSize - oldPacketSize) / 8
          end
          oldPacketSize = packetSize
          if maxUploadSize < packetSize then
            numUpdatesSent = j
            break
          end
        end
        local endOffset = streamGetWriteOffset(self.serverStreamId)
        streamSetWriteOffset(self.serverStreamId, numUpdatesOffset)
        streamWriteInt16(self.serverStreamId, numUpdatesSent)
        streamSetWriteOffset(self.serverStreamId, endOffset)
        netSendStream(self.serverStreamId, "medium", "unreliable_sequenced", 2, true)
      end
      local packetBytesSum = 0
      for i = 1, NetworkNode.NUM_PACKETS do
        self.packetGraphs[i]:addValue(packetBytesSum + self.packetBytes[i], packetBytesSum)
        packetBytesSum = packetBytesSum + self.packetBytes[i]
        self.packetBytes[i] = 0
      end
      self.lastUploadedKBs = packetBytesSum / 1024 * 1000 / self.tickSum
      self.tickSum = 0
    end
  end
end
function Client:keyEvent(unicode, sym, modifier, isDown)
  if g_server == nil then
    Client:superClass().keyEvent(self, unicode, sym, modifier, isDown)
  end
end
function Client:mouseEvent(posX, posY, isDown, isUp, button)
end
function Client:draw()
  if g_server == nil then
    Client:superClass().draw(self)
    if self.showNetworkTraffic then
      renderText(0.7, 0.7, 0.025, "Num Updates " .. self.lastNumUpdatesSent)
    end
  end
end
function Client:startLocal()
  self.serverConnection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID].localConnection
  self:connectionRequestAccepted()
end
function Client:start(serverAddress, serverPort)
  if not self.netIsRunning then
    self.netIsRunning = true
    g_connectionManager:startupWithWorkingPort(g_defaultServerPort)
    g_connectionManager:setDefaultListener(Client.packetReceived, self)
    self.serverStreamId = clientLocalNetConnect(serverAddress, serverPort, "")
    self.serverConnection = Connection:new(self.serverStreamId, true)
    if self.serverStreamId == 0 then
      print("Error: Failed to call connect")
      self.serverConnection.isConnected = false
      self.serverConnection:setIsReadyForObjects(false)
      self.serverConnection:setIsReadyForEvents(false)
      if self.networkListener ~= nil then
        self.networkListener:onConnectionClosed(self.serverConnection)
      end
    else
      self.serverConnection:setIsReadyForObjects(true)
      self.serverConnection:setIsReadyForEvents(true)
    end
  end
end
function Client:stop()
  if self.netIsRunning then
    if self.serverStreamId ~= 0 then
      netCloseConnection(self.serverStreamId, true, 0)
      self.serverStreamId = 0
    end
    self.serverConnection.isConnected = false
    self.serverConnection:setIsReadyForObjects(false)
    self.serverConnection:setIsReadyForEvents(false)
    g_connectionManager:shutdown()
    g_connectionManager:setDefaultListener(nil, nil)
    self.netIsRunning = false
  end
end
function Client:packetReceived(packetType, timestamp, streamId)
  if streamId ~= self.serverStreamId then
    return
  end
  local packetTypeName = "TYPE_UNKNOWN"
  for key, value in pairs(Network) do
    if value == packetType then
      packetTypeName = key
    end
  end
  Client:superClass().packetReceived(self, packetType, timestamp, streamId)
  if packetType == Network.TYPE_APPLICATION then
    local id = streamReadInt8(streamId)
    if id == MessageIds.OBJECT_DELETED then
      local id = streamReadInt32(streamId)
      local object = self:getObject(id)
      if object ~= nil then
        self:unregisterObject(object, true)
        object:delete()
      end
    elseif id == MessageIds.OBJECT_UPDATE then
      self.serverConnection:readUpdateAck(streamId)
      local networkDebug = streamReadBool(streamId)
      streamAlignReadToByteBoundary(streamId)
      local numCreateObjects = streamReadInt16(streamId)
      local numUpdateObjects = streamReadInt16(streamId)
      local numDeleteObjects = streamReadInt16(streamId)
      for i = 1, numCreateObjects do
        if g_server ~= nil then
          print("Error: Unexpected packet object created")
          return
        end
        local numBits = 0
        local startOffset = 0
        if networkDebug then
          streamAlignReadToByteBoundary(streamId)
          startOffset = streamGetReadOffset(streamId)
          numBits = streamReadInt32(streamId)
        end
        local objectClassId = streamReadInt32(streamId)
        local id = streamReadInt32(streamId)
        local object = self:getObject(id)
        local needsCreation = object == nil
        if needsCreation then
          local objectClass = ObjectIds.getObjectClassById(objectClassId)
          if objectClass ~= nil then
            object = objectClass:new(false, true)
            object.isManuallyReplicated = false
            object.isRegistered = true
          end
        end
        if object == nil then
          return
        end
        object:readStream(streamId, self.serverConnection)
        if needsCreation then
          self:addObject(object, id)
        else
          object:onGhostAdd()
        end
        self.serverConnection.objectsInfo[id] = {
          dirtyMask = 0,
          creating = false,
          deleting = false,
          history = {}
        }
        if networkDebug then
          local endOffset = streamGetReadOffset(streamId)
          local readNumBits = endOffset - (startOffset + 32)
          if readNumBits ~= numBits then
            local extraInfo = ""
            if object.configFileName ~= nil then
              extraInfo = " (" .. object.configFileName .. ")"
            end
            print("Error: Not all bits read in object update creation" .. object.className .. extraInfo)
          end
        end
      end
      for i = 1, numUpdateObjects do
        local numBits = 0
        local startOffset = 0
        if networkDebug then
          streamAlignReadToByteBoundary(streamId)
          startOffset = streamGetReadOffset(streamId)
          numBits = streamReadInt32(streamId)
        end
        local id = streamReadInt32(streamId)
        local object = self:getObject(id)
        if object == nil then
          break
        else
          object:readUpdateStream(streamId, timestamp, self.serverConnection)
        end
        if networkDebug then
          local endOffset = streamGetReadOffset(streamId)
          local readNumBits = endOffset - (startOffset + 32)
          if readNumBits ~= numBits then
            local extraInfo = ""
            if object.configFileName ~= nil then
              extraInfo = " (" .. object.configFileName .. ")"
            end
            print("Error: Not all bits read in object update " .. object.className .. extraInfo)
          end
        end
      end
      for i = 1, numDeleteObjects do
        local id = streamReadInt32(streamId)
        local object = self:getObject(id)
        if object ~= nil then
          object:onGhostRemove()
        end
      end
    elseif id == MessageIds.OBJECT_PING then
      self.serverConnection:readUpdateAck(streamId)
      streamWriteInt8(streamId, MessageIds.OBJECT_ACK)
      self.serverConnection:writeUpdateAck(streamId, false)
      netSendStream(streamId, "medium", "reliable_ordered", 2, true)
    elseif id == MessageIds.OBJECT_ACK then
      self.serverConnection:readUpdateAck(streamId)
    elseif id == MessageIds.OBJECT_INITIAL_ARRAY then
      self.waitingForObjects = false
      if g_server ~= nil then
        print("Error: Unexpected packet object created array")
        return
      end
      local networkDebug = streamReadBool(streamId)
      streamAlignReadToByteBoundary(streamId)
      local numObjects = streamReadInt32(streamId)
      print("Joined network game (" .. numObjects .. ")")
      for i = 1, numObjects do
        local numBits = 0
        local startOffset = 0
        if networkDebug then
          streamAlignReadToByteBoundary(streamId)
          startOffset = streamGetReadOffset(streamId)
          numBits = streamReadInt32(streamId)
        end
        local objectClassId = streamReadInt32(streamId)
        local id = streamReadInt32(streamId)
        local objectClass = ObjectIds.getObjectClassById(objectClassId)
        local object
        if objectClass ~= nil then
          object = objectClass:new(false, true)
          object.isManuallyReplicated = false
          object.isRegistered = true
        end
        if object == nil then
          print("Error: Failed to create new object with class id " .. objectClassId .. " in initial object array")
          return
        end
        object:readStream(streamId, self.serverConnection)
        self:addObject(object, id)
        if networkDebug then
          local endOffset = streamGetReadOffset(streamId)
          local readNumBits = endOffset - (startOffset + 32)
          if readNumBits ~= numBits then
            local extraInfo = ""
            if object.configFileName ~= nil then
              extraInfo = " (" .. object.configFileName .. ")"
            end
            print("Error: Not all bits read in object create array (" .. readNumBits .. " vs " .. numBits .. ")" .. objectClass.className .. extraInfo)
          end
        end
      end
    elseif id == MessageIds.OBJECT_SERVER_ID then
      local serverObjectId = streamReadInt32(streamId)
      local clientObjectId = streamReadInt32(streamId)
      local object = self.tempCreateObjects[clientObjectId]
      streamWriteInt8(streamId, MessageIds.OBJECT_SERVER_ID_ACK)
      streamWriteInt32(streamId, serverObjectId)
      netSendStream(streamId, "high", "reliable_ordered", 1, true)
      if object ~= nil then
        self:finishRegisterObject(object, serverObjectId)
        self.tempCreateObjects[clientObjectId] = nil
      else
        streamWriteInt8(self.serverStreamId, MessageIds.OBJECT_DELETED)
        streamWriteInt32(self.serverStreamId, serverObjectId)
        netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
      end
    elseif id == MessageIds.EVENT then
      local eventId = streamReadInt32(streamId)
      local eventClass = EventIds.getEventClassById(eventId)
      if eventClass ~= nil then
        local tempEvent = eventClass:emptyNew()
        tempEvent:readStream(streamId, self.serverConnection)
        tempEvent:delete()
      end
    elseif id == MessageIds.EVENT_IDS then
      local numIds = streamReadInt32(streamId)
      for i = 1, numIds do
        local id = streamReadInt32(streamId)
        local className = streamReadString(streamId)
        EventIds.assignEventId(className, id)
      end
    elseif id == MessageIds.OBJECT_CLASS_IDS then
      local numIds = streamReadInt32(streamId)
      for i = 1, numIds do
        local id = streamReadInt32(streamId)
        local className = streamReadString(streamId)
        ObjectIds.assignObjectClassId(className, id)
      end
    else
      print("Error: Invalid message id " .. id)
    end
  elseif packetType == Network.TYPE_CONNECTION_REQUEST_ACCEPTED then
    streamWriteInt8(self.serverStreamId, MessageIds.CLIP_COEFF)
    streamWriteFloat32(self.serverStreamId, getViewDistanceCoeff())
    netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
    self:connectionRequestAccepted()
  elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
    if streamId == self.serverStreamId then
      self.serverStreamId = 0
      self.serverConnection.isConnected = false
      self.serverConnection:setIsReadyForObjects(false)
      self.serverConnection:setIsReadyForEvents(false)
      if self.networkListener ~= nil then
        self.networkListener:onConnectionClosed(self.serverConnection)
      end
    end
  elseif (packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or packetType == Network.TYPE_CONNECTION_LOST or packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD) and streamId == self.serverStreamId then
    self.serverStreamId = 0
    self.serverConnection.isConnected = false
    self.serverConnection:setIsReadyForObjects(false)
    self.serverConnection:setIsReadyForEvents(false)
    if self.networkListener ~= nil then
      self.networkListener:onConnectionClosed(self.serverConnection)
    end
  end
end
function Client:connectionRequestAccepted()
  if self.networkListener ~= nil then
    self.networkListener:onConnectionAccepted(self.serverConnection)
  end
end
function Client:registerObject(object, alreadySent)
  if not object.isRegistered then
    object.isManuallyReplicated = alreadySent
    if not alreadySent then
      if g_server ~= nil then
        print("Error: Client:registerObject not expected")
        printCallstack()
      end
      self.tempCreateObjects[object.id] = object
      streamWriteInt8(self.serverStreamId, MessageIds.OBJECT_CREATED)
      streamWriteInt32(self.serverStreamId, object.classId)
      streamWriteInt32(self.serverStreamId, object.id)
      object:writeStream(self.serverStreamId, self.serverConnection)
      netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
    end
    object.isRegistered = true
  end
end
function Client:unregisterObject(object, alreadySent)
  if object.isRegistered then
    local serverId = self:getObjectId(object)
    if serverId ~= nil then
      if alreadySent == nil or not alreadySent then
        streamWriteInt8(self.serverStreamId, MessageIds.OBJECT_DELETED)
        streamWriteInt32(self.serverStreamId, serverId)
        netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
      end
      self:removeObject(object, serverId)
    else
      self.tempCreateObjects[object.id] = nil
    end
    object.isRegistered = false
  end
end
function Client:finishRegisterObject(object, serverId)
  self:addObject(object, serverId)
  self.serverConnection.objectsInfo[serverId] = {
    dirtyMask = 0,
    creating = false,
    deleting = false,
    history = {}
  }
end
function Client:getServerConnection()
  return self.serverConnection
end
