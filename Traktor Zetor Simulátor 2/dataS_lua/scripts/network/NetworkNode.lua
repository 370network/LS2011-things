NetworkNode = {}
NetworkNode_mt = Class(NetworkNode)
NetworkNode.LOCAL_STREAM_ID = 0
NetworkNode.PACKET_EVENT = 1
NetworkNode.PACKET_VEHICLE = 2
NetworkNode.PACKET_OTHERS = 3
NetworkNode.NUM_PACKETS = 3
function NetworkNode:new(customMt)
  local self = {}
  local mt = customMt
  if mt == nil then
    mt = NetworkNode_mt
  end
  setmetatable(self, mt)
  self.objects = {}
  self.objectIds = {}
  self.lastUploadedKBs = 0
  self.lastUploadedKBsSmooth = 0
  self.maxUploadedKBs = 0
  self.graphColors = {}
  self.graphColors[NetworkNode.PACKET_EVENT] = {
    1,
    0,
    0,
    1
  }
  self.graphColors[NetworkNode.PACKET_VEHICLE] = {
    0,
    1,
    0,
    1
  }
  self.graphColors[NetworkNode.PACKET_OTHERS] = {
    0,
    0,
    1,
    1
  }
  self.packetGraphs = {}
  self.packetBytes = {}
  local showGraphLabels = true
  for i = 1, NetworkNode.NUM_PACKETS do
    if 1 < i then
      showGraphLabels = false
    end
    self.packetGraphs[i] = Graph:new(80, 0.2, 0.2, 0.6, 0.6, 0, 500, showGraphLabels, "bytes")
    self.packetGraphs[i]:setColor(self.graphColors[i][1], self.graphColors[i][2], self.graphColors[i][3], self.graphColors[i][4])
    self.packetBytes[i] = 0
  end
  self.showNetworkTraffic = false
  return self
end
function NetworkNode:delete()
  for k, object in pairs(self.objects) do
    self:unregisterObject(object, true)
    object:delete()
  end
  for i = 1, NetworkNode.NUM_PACKETS do
    self.packetGraphs[i]:delete()
  end
end
function NetworkNode:setNetworkListener(listener)
  self.networkListener = listener
end
function NetworkNode:keyEvent(unicode, sym, modifier, isDown)
end
function NetworkNode:mouseEvent(posX, posY, isDown, isUp, button)
end
function NetworkNode:update(dt)
end
function NetworkNode:draw()
  if self.showNetworkTraffic then
    local smoothAlpha = 0.8
    self.lastUploadedKBsSmooth = self.lastUploadedKBsSmooth * smoothAlpha + self.lastUploadedKBs * (1 - smoothAlpha)
    renderText(0.7, 0.73, 0.025, "Upload KBs " .. self.lastUploadedKBsSmooth)
    for i = 1, NetworkNode.NUM_PACKETS do
      self.packetGraphs[i]:draw()
    end
    if self.clientConnections ~= nil then
      local i = 0
      for k, connection in pairs(self.clientConnections) do
        renderText(0.7, 0.7 - i * 0.03, 0.025, "Window size: " .. connection.lastSeqSent - connection.highestAckedSeq)
        i = i + 1
      end
    end
  end
end
function NetworkNode:packetReceived(packetType, timestamp, streamId)
  local packetTypeName = "TYPE_UNKNOWN"
  for key, value in pairs(Network) do
    if value == packetType then
      packetTypeName = key
    end
  end
end
function NetworkNode:getObject(id)
  return self.objects[id]
end
function NetworkNode:getObjectId(object)
  return self.objectIds[object]
end
function NetworkNode:addObject(object, id)
  self.objects[id] = object
  self.objectIds[object] = id
  if self.networkListener ~= nil then
    self.networkListener:onObjectCreated(object)
  end
end
function NetworkNode:removeObject(object, id)
  if self.networkListener ~= nil then
    self.networkListener:onObjectDeleted(object)
  end
  self.objects[id] = nil
  self.objectIds[object] = nil
end
function NetworkNode:registerObject(object, alreadySent)
end
function NetworkNode:unregisterObject(object, alreadySent)
end
function networkGetObject(id)
  if g_server ~= nil then
    return g_server:getObject(id)
  else
    return g_client:getObject(id)
  end
end
function networkGetObjectId(object)
  if g_server ~= nil then
    return g_server:getObjectId(object)
  else
    return g_client:getObjectId(object)
  end
end
