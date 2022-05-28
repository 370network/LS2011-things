Object = {}
Object_mt = Class(Object)
InitStaticObjectClass(Object, "Object", ObjectIds.OBJECT_OBJECT)
Object.nextObjectId = 1
function Object:new(isServer, isClient, customMt)
  local self = {}
  local mt = customMt
  if mt == nil then
    mt = Object_mt
  end
  setmetatable(self, mt)
  self.id = Object.nextObjectId
  Object.nextObjectId = Object.nextObjectId + 1
  self.className = "Object"
  self.isRegistered = false
  self.isServer = isServer
  self.isClient = isClient
  self.owner = nil
  self.nextDirtyFlag = 1
  self.dirtyMask = 0
  return self
end
function Object:delete()
  if self.isRegistered then
    self:unregister()
  end
end
function Object:register(alreadySent)
  if self.isServer then
    g_server:registerObject(self, alreadySent)
  else
    g_client:registerObject(self, alreadySent)
  end
end
function Object:unregister()
  if self.isServer then
    g_server:unregisterObject(self)
  else
    g_client:unregisterObject(self)
  end
end
function Object:readStream(streamId)
end
function Object:writeStream(streamId)
end
function Object:readUpdateStream(streamId, timestamp, connection)
end
function Object:writeUpdateStream(streamId, connection, dirtyMask)
end
function Object:mouseEvent(posX, posY, isDown, isUp, button)
end
function Object:update(dt)
end
function Object:updateTick(dt)
end
function Object:draw()
end
function Object:setOwner(owner)
  if self.isServer then
    self.owner = owner
  else
    print("Error: setOwner only allowed on Server")
  end
end
function Object:testScope(x, y, z, coeff)
  return true
end
function Object:onGhostRemove()
end
function Object:onGhostAdd()
end
function Object:getUpdatePriority(skipCount, x, y, z, coeff, connection)
  return skipCount * 0.5
end
function Object:getNextDirtyFlag()
  local nextFlag = self.nextDirtyFlag
  self.nextDirtyFlag = self.nextDirtyFlag * 2
  return nextFlag
end
function Object:raiseDirtyFlags(flag)
  self.dirtyMask = bitOR(self.dirtyMask, flag)
end
function Object:clearDirtyFlags(flag)
  self.dirtyMask = bitAND(self.dirtyMask, bitNOT(flag))
end
