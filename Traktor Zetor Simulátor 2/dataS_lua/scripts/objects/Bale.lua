Bale = {}
Bale_mt = Class(Bale, PhysicsObject)
InitStaticObjectClass(Bale, "Bale", ObjectIds.OBJECT_BALE)
function Bale:new(isServer, isClient, customMt)
  local mt = customMt
  if mt == nil then
    mt = Bale_mt
  end
  local self = PhysicsObject:new(isServer, isClient, mt)
  self.className = "Bale"
  self.forcedClipDistance = 80
  registerObjectClassName(self, "Bale")
  self.baleValue = 0
  return self
end
function Bale:delete()
  unregisterObjectClassName(self)
  g_currentMission:removeItemToSave(self)
  Bale:superClass().delete(self)
end
function Bale:readStream(streamId, connection)
  local i3dFilename = Utils.convertFromNetworkFilename(streamReadString(streamId))
  if self.nodeId == 0 then
    self:createNode(i3dFilename)
  end
  Bale:superClass().readStream(self, streamId, connection)
  g_currentMission:addItemToSave(self)
end
function Bale:writeStream(streamId, connection)
  streamWriteString(streamId, Utils.convertToNetworkFilename(self.i3dFilename))
  Bale:superClass().writeStream(self, streamId, connection)
end
function Bale:testScope(x, y, z, coeff)
  if self.mountObject ~= nil then
    return self.mountObject:testScope(x, y, z, coeff)
  else
    return Bale:superClass().testScope(self, x, y, z, coeff)
  end
end
function Bale:mount(object, node, x, y, z, rx, ry, rz)
  if self.mountObject == nil then
    setRigidBodyType(self.nodeId, "None")
  end
  setTranslation(self.nodeId, x, y, z)
  setRotation(self.nodeId, rx, ry, rz)
  link(node, self.nodeId)
  g_currentMission:removeItemToSave(self)
  self.mountObject = object
end
function Bale:unmount()
  self.mountObject = nil
  local x, y, z = getWorldTranslation(self.nodeId)
  local rx, ry, rz = getWorldRotation(self.nodeId)
  link(getRootNode(), self.nodeId)
  setTranslation(self.nodeId, x, y, z)
  setRotation(self.nodeId, rx, ry, rz)
  setRigidBodyType(self.nodeId, "Dynamic")
  g_currentMission:addItemToSave(self)
end
function Bale:setNodeId(nodeId)
  Bale:superClass().setNodeId(self, nodeId)
  local isRoundbale = Utils.getNoNil(getUserAttribute(nodeId, "isRoundbale"), false)
  local baleValue = tonumber(getUserAttribute(nodeId, "baleValue"))
  if baleValue ~= nil then
    self.baleValue = baleValue
  elseif isRoundbale then
    self.baleValue = 500
  else
    self.baleValue = 200
  end
end
function Bale:createNode(i3dFilename)
  self.i3dFilename = i3dFilename
  local baleRoot = Utils.loadSharedI3DFile(i3dFilename)
  local baleId = getChildAt(baleRoot, 0)
  link(getRootNode(), baleId)
  delete(baleRoot)
  self:setNodeId(baleId)
end
function Bale:load(i3dFilename, x, y, z, rx, ry, rz)
  self.i3dFilename = i3dFilename
  self:createNode(i3dFilename)
  setTranslation(self.nodeId, x, y, z)
  setRotation(self.nodeId, rx, ry, rz)
  g_currentMission:addItemToSave(self)
end
function Bale:loadFromMemory(nodeId, i3dFilename)
  self.i3dFilename = i3dFilename
  self:setNodeId(nodeId)
end
function Bale:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#position"))
  local xRot, yRot, zRot = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))
  if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
    return false
  end
  local filename = getXMLString(xmlFile, key .. "#filename")
  if filename == nil then
    return false
  end
  filename = Utils.convertFromNetworkFilename(filename)
  local rootNode = Utils.loadSharedI3DFile(filename)
  if rootNode == 0 then
    return false
  end
  local ret = false
  local node = getChildAt(rootNode, 0)
  if node ~= nil and node ~= 0 then
    setTranslation(node, x, y, z)
    setRotation(node, xRot, yRot, zRot)
    link(getRootNode(), node)
    ret = true
  end
  delete(rootNode)
  if not ret then
    return false
  end
  self:loadFromMemory(node, filename)
  return true
end
function Bale:getSaveAttributesAndNodes(nodeIdent)
  local x, y, z = getTranslation(self.nodeId)
  local xRot, yRot, zRot = getRotation(self.nodeId)
  local attributes = "filename=\"" .. Utils.encodeToHTML(Utils.convertToNetworkFilename(self.i3dFilename)) .. "\" position=\"" .. x .. " " .. y .. " " .. z .. "\" rotation=\"" .. xRot .. " " .. yRot .. " " .. zRot .. "\""
  local nodes = ""
  return attributes, nodes
end
function Bale:getValue()
  return self.baleValue
end
