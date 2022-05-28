Server = {}
Server_mt = Class(Server, NetworkNode)
function Server:new()
  local self = NetworkNode:new(Server_mt)
  self.clients = {}
  self.clientConnections = {}
  self.clientPositions = {}
  self.clientClipDistCoeffs = {}
  self.objects = {}
  self.tickRate = 30
  self.tickDuration = 1000 / self.tickRate
  self.tickSum = 0
  self.netIsRunning = false
  addConsoleCommand("gsToggleShowNetworkTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", self)
  addConsoleCommand("gsToggleNetworkDebug", "Toggle network debugging", "consoleCommandToggleNetworkDebug", self)
  return self
end
function Server:delete()
  removeConsoleCommand("gsToggleShowNetworkTraffic")
  removeConsoleCommand("gsToggleNetworkDebug")
  Server:superClass().delete(self)
  self:stop()
end
function Server:update(dt, isRunning)
  Server:superClass().update(self, dt)
  if not isRunning then
    return
  end
  for k, object in pairs(self.objects) do
    object:update(dt)
  end
  maxUploadSize = g_maxUploadRate * 8 * self.tickDuration
  self.tickSum = self.tickSum + dt
  if self.tickSum >= self.tickDuration then
    local numClients = table.getn(self.clients)
    local maxPacketSize = maxUploadSize / numClients
    for k, object in pairs(self.objects) do
      object:updateTick(self.tickSum)
    end
    for i = 1, table.getn(self.clients) do
      local streamId = self.clients[i]
      local connection = self.clientConnections[streamId]
      if connection.isReadyForObjects then
        if connection:getIsWindowFull() then
          if not connection.ackPingPacketSent then
            connection.ackPingPacketSent = true
            streamWriteInt8(self.clients[i], MessageIds.OBJECT_PING)
            connection:writeUpdateAck(self.clients[i], false)
            netSendStream(self.clients[i], "medium", "reliable_ordered", 2, true)
          end
        else
          connection.ackPingPacketSent = false
          local objectsInfo = connection.objectsInfo
          local sendUpdates = {}
          local sendCreates = {}
          local sendDeletes = {}
          local x, y, z = self:getClientPosition(self.clients[i])
          local coeff = self:getClientClipDistCoeff(self.clients[i])
          for k, object in pairs(self.objects) do
            local objectInfo = objectsInfo[object.id]
            local processObject = true
            if objectInfo ~= nil then
              objectInfo.dirtyMask = bitOR(objectInfo.dirtyMask, object.dirtyMask)
              objectInfo.skipCount = objectInfo.skipCount + 1
              if objectInfo.creating or objectInfo.deleting then
                processObject = false
              end
            end
            if processObject then
              if object:testScope(x, y, z, coeff) then
                if objectInfo == nil then
                  local updatePriority = object:getUpdatePriority(1, x, y, z, coeff, connection)
                  table.insert(sendCreates, {object = object, prio = updatePriority})
                elseif objectInfo.dirtyMask ~= 0 then
                  objectInfo.skipCount = objectInfo.skipCount + 1
                  local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection)
                  table.insert(sendUpdates, {object = object, prio = updatePriority})
                else
                  objectInfo.skipCount = 0
                end
              elseif objectInfo ~= nil then
                local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection)
                table.insert(sendDeletes, {object = object, prio = updatePriority})
              end
            end
          end
          table.sort(sendCreates, Server.prioCmp)
          table.sort(sendUpdates, Server.prioCmp)
          table.sort(sendDeletes, Server.prioCmp)
          streamWriteTimestamp(self.clients[i])
          streamWriteInt8(self.clients[i], MessageIds.OBJECT_UPDATE)
          connection:writeUpdateAck(self.clients[i], true)
          streamWriteBool(self.clients[i], g_networkDebug)
          streamAlignWriteToByteBoundary(self.clients[i])
          local numCreatesOffset = streamGetWriteOffset(self.clients[i])
          streamWriteInt16(self.clients[i], 0)
          local numUpdatesOffset = streamGetWriteOffset(self.clients[i])
          streamWriteInt16(self.clients[i], 0)
          local numDeletesOffset = streamGetWriteOffset(self.clients[i])
          streamWriteInt16(self.clients[i], 0)
          local oldPacketSize = 0
          local numCreatesSent = table.getn(sendCreates)
          for j = 1, table.getn(sendCreates) do
            local object = sendCreates[j].object
            local startOffset = 0
            if g_networkDebug then
              streamAlignWriteToByteBoundary(self.clients[i])
              startOffset = streamGetWriteOffset(self.clients[i])
              streamWriteInt32(self.clients[i], 0)
            end
            streamWriteInt32(self.clients[i], object.classId)
            streamWriteInt32(self.clients[i], object.id)
            object:writeStream(self.clients[i], connection)
            objectsInfo[object.id] = {
              skipCount = 0,
              dirtyMask = 0,
              creating = true,
              deleting = false,
              history = {}
            }
            objectsInfo[object.id].history[connection.lastSeqSent] = {
              mask = 0,
              creating = true,
              deleting = false
            }
            if g_networkDebug then
              local endOffset = streamGetWriteOffset(self.clients[i])
              streamSetWriteOffset(self.clients[i], startOffset)
              streamWriteInt32(self.clients[i], endOffset - (startOffset + 32))
              streamSetWriteOffset(self.clients[i], endOffset)
            end
            local packetSize = streamGetWriteOffset(self.clients[i])
            if object:isa(Vehicle) then
              self.packetBytes[NetworkNode.PACKET_VEHICLE] = self.packetBytes[NetworkNode.PACKET_VEHICLE] + (packetSize - oldPacketSize) / 8
            else
              self.packetBytes[NetworkNode.PACKET_OTHERS] = self.packetBytes[NetworkNode.PACKET_OTHERS] + (packetSize - oldPacketSize) / 8
            end
            oldPacketSize = packetSize
            if maxPacketSize < packetSize then
              numCreatesSent = j
              break
            end
          end
          local numUpdatesSent = table.getn(sendUpdates)
          for j = 1, table.getn(sendUpdates) do
            local object = sendUpdates[j].object
            local startOffset = 0
            if g_networkDebug then
              streamAlignWriteToByteBoundary(self.clients[i])
              startOffset = streamGetWriteOffset(self.clients[i])
              streamWriteInt32(self.clients[i], 0)
            end
            local dirtyMask = objectsInfo[object.id].dirtyMask
            streamWriteInt32(self.clients[i], object.id)
            object:writeUpdateStream(self.clients[i], connection, dirtyMask)
            objectsInfo[object.id].history[connection.lastSeqSent] = {
              mask = dirtyMask,
              creating = false,
              deleting = false
            }
            objectsInfo[object.id].skipCount = 0
            objectsInfo[object.id].dirtyMask = 0
            if g_networkDebug then
              local endOffset = streamGetWriteOffset(self.clients[i])
              streamSetWriteOffset(self.clients[i], startOffset)
              streamWriteInt32(self.clients[i], endOffset - (startOffset + 32))
              streamSetWriteOffset(self.clients[i], endOffset)
            end
            local packetSize = streamGetWriteOffset(self.clients[i])
            if object:isa(Vehicle) then
              self.packetBytes[NetworkNode.PACKET_VEHICLE] = self.packetBytes[NetworkNode.PACKET_VEHICLE] + (packetSize - oldPacketSize) / 8
            else
              self.packetBytes[NetworkNode.PACKET_OTHERS] = self.packetBytes[NetworkNode.PACKET_OTHERS] + (packetSize - oldPacketSize) / 8
            end
            if g_networkDebugPrints then
              local extraInfo = ""
              if object.configFileName ~= nil then
                extraInfo = "(" .. object.configFileName .. ")"
              end
              print("  send object " .. extraInfo .. ", mask " .. dirtyMask .. ", size " .. (packetSize - oldPacketSize) / 8 .. " bytes")
            end
            oldPacketSize = packetSize
            if maxPacketSize < packetSize then
              numUpdatesSent = j
              break
            end
          end
          local numDeletesSent = table.getn(sendDeletes)
          for j = 1, table.getn(sendDeletes) do
            local object = sendDeletes[j].object
            streamWriteInt32(self.clients[i], object.id)
            objectsInfo[object.id].deleting = true
            objectsInfo[object.id].history[connection.lastSeqSent] = {
              mask = 0,
              creating = false,
              deleting = true
            }
            local packetSize = streamGetWriteOffset(self.clients[i])
            if object:isa(Vehicle) then
              self.packetBytes[NetworkNode.PACKET_VEHICLE] = self.packetBytes[NetworkNode.PACKET_VEHICLE] + (packetSize - oldPacketSize) / 8
            else
              self.packetBytes[NetworkNode.PACKET_OTHERS] = self.packetBytes[NetworkNode.PACKET_OTHERS] + (packetSize - oldPacketSize) / 8
            end
            oldPacketSize = packetSize
            if maxPacketSize < packetSize then
              numDeletesSent = j
              break
            end
          end
          local endOffset = streamGetWriteOffset(self.clients[i])
          streamSetWriteOffset(self.clients[i], numCreatesOffset)
          streamWriteInt16(self.clients[i], numCreatesSent)
          streamSetWriteOffset(self.clients[i], numUpdatesOffset)
          streamWriteInt16(self.clients[i], numUpdatesSent)
          streamSetWriteOffset(self.clients[i], numDeletesOffset)
          streamWriteInt16(self.clients[i], numDeletesSent)
          streamSetWriteOffset(self.clients[i], endOffset)
          netSendStream(self.clients[i], "medium", "unreliable_sequenced", 2, true)
        end
      end
    end
    for k, object in pairs(self.objects) do
      object.dirtyMask = 0
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
function Server:keyEvent(unicode, sym, modifier, isDown)
  Server:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function Server:mouseEvent(posX, posY, isDown, isUp, button)
end
function Server:draw()
  Server:superClass().draw(self)
end
function Server:startLocal()
  if g_client ~= nil then
    self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection:new(NetworkNode.LOCAL_STREAM_ID, false)
    self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForObjects(true)
    self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForEvents(true)
  end
end
function Server:start(serverPort)
  if not self.netIsRunning then
    self.netIsRunning = true
    print("Started network game (" .. serverPort .. ")")
    if not g_connectionManager:startup(serverPort) then
      print("Error: Failed to startup network. Probably the select port is already in use")
    end
    g_connectionManager:setDefaultListener(Server.packetReceived, self)
    if g_client ~= nil then
      self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection:new(NetworkNode.LOCAL_STREAM_ID, false)
    end
  end
end
function Server:init()
  EventIds.assignEventIds()
  ObjectIds.assignObjectClassIds()
end
function Server:stop()
  if self.netIsRunning then
    for i = 1, table.getn(self.clients) do
      netCloseConnection(self.clients[i], true, 0)
    end
    self.clients = {}
    for _, connection in pairs(self.clientConnections) do
      connection.isConnected = false
      connection:setIsReadyForObjects(false)
      connection:setIsReadyForEvents(false)
    end
    self.clientConnections = {}
    g_connectionManager:shutdown()
    g_connectionManager:setDefaultListener(nil, nil)
    self.netIsRunning = false
  end
end
function Server:closeConnection(connection)
  if connection.isConnected then
    self:removeStreamFromClients(connection.streamId)
    if connection ~= nil and self.networkListener ~= nil then
      self.networkListener:onConnectionClosed(connection)
    end
    netCloseConnection(connection.streamId, true, 0)
    connection.streamId = 0
  end
end
function Server:packetReceived(packetType, timestamp, streamId)
  Server:superClass().packetReceived(self, packetType, timestamp, streamId)
  if packetType == Network.TYPE_APPLICATION then
    local id = streamReadInt8(streamId)
    if id == MessageIds.OBJECT_CREATED then
      local connection = self.clientConnections[streamId]
      local objectsInfo = connection.objectsInfo
      local objectClassId = streamReadInt32(streamId)
      local clientObjectId = streamReadInt32(streamId)
      local objectClass = ObjectIds.getObjectClassById(objectClassId)
      if objectClass ~= nil then
        local tempObject = objectClass:new(true, g_client ~= nil)
        tempObject:readStream(streamId, connection)
        tempObject.isManuallyReplicated = false
        tempObject.isRegistered = true
        self:addObject(tempObject, tempObject.id)
        objectsInfo[tempObject.id] = {
          skipCount = 0,
          dirtyMask = 0,
          creating = true,
          deleting = false,
          history = {}
        }
        streamWriteInt8(streamId, MessageIds.OBJECT_SERVER_ID)
        streamWriteInt32(streamId, tempObject.id)
        streamWriteInt32(streamId, clientObjectId)
        netSendStream(streamId, "high", "reliable_ordered", 1, true)
      end
    elseif id == MessageIds.OBJECT_SERVER_ID_ACK then
      local connection = self.clientConnections[streamId]
      local objectsInfo = connection.objectsInfo
      local serverObjectId = streamReadInt32(streamId)
      objectsInfo[serverObjectId].creating = false
    elseif id == MessageIds.OBJECT_DELETED then
      local serverObjectId = streamReadInt32(streamId)
      local object = self:getObject(serverObjectId)
      self.clientConnections[streamId].objectsInfo[object.id] = nil
      for i = 1, table.getn(self.clients) do
        if self.clients[i] ~= streamId then
          local clientStreamId = self.clients[i]
          self.clientConnections[clientStreamId]:sendDeleteObject(object)
        end
      end
      self:unregisterObject(object, true)
      object:delete()
    elseif id == MessageIds.OBJECT_UPDATE then
      local connection = self.clientConnections[streamId]
      connection:readUpdateAck(streamId)
      streamAlignReadToByteBoundary(streamId)
      local numObjects = streamReadInt16(streamId)
      local x = streamReadFloat32(streamId)
      local y = streamReadFloat32(streamId)
      local z = streamReadFloat32(streamId)
      self:setClientPosition(streamId, x, y, z)
      for i = 1, numObjects do
        local id = streamReadInt32(streamId)
        local object = self:getObject(id)
        object:readUpdateStream(streamId, timestamp, connection)
      end
    elseif id == MessageIds.OBJECT_PING then
      local connection = self.clientConnections[streamId]
      if connection ~= nil then
        connection:readUpdateAck(streamId)
        streamWriteInt8(streamId, MessageIds.OBJECT_ACK)
        connection:writeUpdateAck(streamId, false)
        netSendStream(streamId, "medium", "reliable_ordered", 2, true)
      end
    elseif id == MessageIds.OBJECT_ACK then
      local connection = self.clientConnections[streamId]
      if connection ~= nil then
        connection:readUpdateAck(streamId)
      end
    elseif id == MessageIds.EVENT then
      local eventId = streamReadInt32(streamId)
      local eventClass = EventIds.getEventClassById(eventId)
      if eventClass ~= nil then
        local tempEvent = eventClass:emptyNew()
        tempEvent:readStream(streamId, self.clientConnections[streamId])
        tempEvent:delete()
      end
    elseif id == MessageIds.CLIP_COEFF then
      local coeff = streamReadFloat32(streamId)
      self:setClientClipDistCoeff(self.clientConnections[streamId], coeff)
    else
      print("Error: Invalid message id")
    end
  elseif packetType == Network.TYPE_NEW_INCOMING_CONNECTION then
    self:removeStreamFromClients(streamId)
    table.insert(self.clients, streamId)
    self.clientConnections[streamId] = Connection:new(streamId, false)
    for k, object in pairs(self.objects) do
      if object.isManuallyReplicated then
        self.clientConnections[streamId].objectsInfo[object.id] = {
          skipCount = 0,
          dirtyMask = 0,
          creating = true,
          deleting = false,
          history = {}
        }
      end
    end
    if self.networkListener ~= nil then
      self.networkListener:onConnectionOpened(self.clientConnections[streamId])
    end
  elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
    local connection = self.clientConnections[streamId]
    self:removeStreamFromClients(streamId)
    if connection ~= nil and self.networkListener ~= nil then
      self.networkListener:onConnectionClosed(connection)
    end
  elseif packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or packetType == Network.TYPE_CONNECTION_LOST or packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD then
    local connection = self.clientConnections[streamId]
    self:removeStreamFromClients(streamId)
    if connection ~= nil and self.networkListener ~= nil then
      self.networkListener:onConnectionClosed(connection)
    end
  end
end
function Server:removeStreamFromClients(streamId)
  for i = 1, table.getn(self.clients) do
    if self.clients[i] == streamId then
      table.remove(self.clients, i)
      break
    end
  end
  if self.clientConnections[streamId] ~= nil then
    self.clientConnections[streamId].isConnected = false
    self.clientConnections[streamId]:setIsReadyForEvents(false)
    self.clientConnections[streamId]:setIsReadyForObjects(false)
    self.clientConnections[streamId] = nil
  end
end
function Server:registerObject(object, alreadySent)
  if not object.isRegistered then
    self:addObject(object, object.id)
    object.isManuallyReplicated = alreadySent
    if alreadySent then
      for i = 1, table.getn(self.clients) do
        local streamId = self.clients[i]
        self.clientConnections[streamId].objectsInfo[object.id] = {
          skipCount = 0,
          dirtyMask = 0,
          creating = true,
          deleting = false,
          history = {}
        }
      end
    end
    object.isRegistered = true
  end
end
function Server:unregisterObject(object, alreadySent)
  if object.isRegistered then
    if self.objects[object.id] ~= nil then
      self:removeObject(object, object.id)
      if alreadySent == nil or not alreadySent then
        for i = 1, table.getn(self.clients) do
          local streamId = self.clients[i]
          self.clientConnections[streamId]:sendDeleteObject(object)
        end
      end
    end
    object.isRegistered = false
  end
end
function Server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force)
  local connections = {}
  for k, v in pairs(self.clientConnections) do
    if (k ~= NetworkNode.LOCAL_STREAM_ID or sendLocal) and (ignoreConnection == nil or v ~= ignoreConnection) and (ghostObject == nil or self:hasGhostObject(v, ghostObject)) then
      v:sendEvent(event, false, force)
    end
  end
  event:delete()
end
function Server:sendEventIds(connection)
  local streamId = connection.streamId
  streamWriteInt8(streamId, MessageIds.EVENT_IDS)
  local numIds = 0
  for className, classObject in pairs(EventIds.eventClasses) do
    numIds = numIds + 1
  end
  streamWriteInt32(streamId, numIds)
  for className, classObject in pairs(EventIds.eventClasses) do
    streamWriteInt32(streamId, classObject.eventId)
    streamWriteString(streamId, className)
  end
  netSendStream(streamId, "high", "reliable_ordered", 1, true)
end
function Server:sendObjectClassIds(connection)
  local streamId = connection.streamId
  streamWriteInt8(streamId, MessageIds.OBJECT_CLASS_IDS)
  local numIds = 0
  for className, classObject in pairs(ObjectIds.objectClasses) do
    numIds = numIds + 1
  end
  streamWriteInt32(streamId, numIds)
  for className, classObject in pairs(ObjectIds.objectClasses) do
    streamWriteInt32(streamId, classObject.classId)
    streamWriteString(streamId, className)
  end
  netSendStream(streamId, "high", "reliable_ordered", 1, true)
end
function Server:sendObjects(connection, x, y, z, viewDistanceCoeff)
  connection:setIsReadyForObjects(false)
  local streamId = connection.streamId
  local objectsInfo = connection.objectsInfo
  streamWriteInt8(streamId, MessageIds.OBJECT_INITIAL_ARRAY)
  streamWriteBool(streamId, g_networkDebug)
  streamAlignWriteToByteBoundary(streamId)
  local numToSendOffset = streamGetWriteOffset(streamId)
  streamWriteInt32(streamId, 0)
  local numToSend = 0
  for k, object in pairs(self.objects) do
    if (objectsInfo[object.id] == nil or not object.isManuallyReplicated) and object:testScope(x, y, z, viewDistanceCoeff) then
      numToSend = numToSend + 1
      local startOffset = 0
      if g_networkDebug then
        streamAlignWriteToByteBoundary(streamId)
        startOffset = streamGetWriteOffset(streamId)
        streamWriteInt32(streamId, 0)
      end
      streamWriteInt32(streamId, object.classId)
      streamWriteInt32(streamId, object.id)
      object:writeStream(streamId, connection)
      objectsInfo[object.id] = {
        skipCount = 0,
        dirtyMask = 0,
        creating = false,
        deleting = false,
        history = {}
      }
      if g_networkDebug then
        local endOffset = streamGetWriteOffset(streamId)
        streamSetWriteOffset(streamId, startOffset)
        streamWriteInt32(streamId, endOffset - (startOffset + 32))
        streamSetWriteOffset(streamId, endOffset)
      end
    end
  end
  local endOffset = streamGetWriteOffset(streamId)
  streamSetWriteOffset(streamId, numToSendOffset)
  streamWriteInt32(streamId, numToSend)
  streamSetWriteOffset(streamId, endOffset)
  netSendStream(streamId, "high", "reliable_ordered", 1, true)
end
function Server:setClientPosition(client, x, y, z)
  self.clientPositions[client] = {
    x,
    y,
    z
  }
end
function Server:getClientPosition(client)
  local pos = self.clientPositions[client]
  if pos ~= nil then
    return unpack(pos)
  end
  return 0, 0, 0
end
function Server:setClientClipDistCoeff(client, coeff)
  self.clientClipDistCoeffs[client] = coeff
end
function Server:getClientClipDistCoeff(client)
  local ret = self.clientClipDistCoeffs[client]
  if ret == nil then
    ret = 1
  end
  return ret
end
function Server:hasGhostObject(connection, ghostObject)
  if connection:getIsLocal() then
    return true
  end
  return connection.objectsInfo[ghostObject.id] ~= nil and not connection.objectsInfo[ghostObject.id].creating and not connection.objectsInfo[ghostObject.id].deleting
end
function Server:finishRegisterObject(connection, object)
  connection.objectsInfo[object.id].creating = false
end
function Server.prioCmp(w1, w2)
  if w1.prio > w2.prio then
    return true
  else
    return false
  end
end
function Server:consoleCommandToggleShowNetworkTraffic()
  self.showNetworkTraffic = not self.showNetworkTraffic
  return "ShowNetworkTraffic = " .. tostring(self.showNetworkTraffic)
end
function Server:consoleCommandToggleNetworkDebug()
  g_networkDebug = not g_networkDebug
  return "NetworkDebug = " .. tostring(g_networkDebug)
end
