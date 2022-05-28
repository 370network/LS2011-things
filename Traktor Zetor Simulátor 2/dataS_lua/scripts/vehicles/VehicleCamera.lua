VehicleCamera = {}
VehicleCamera.doCameraSmoothing = false
local VehicleCamera_mt = Class(VehicleCamera)
function VehicleCamera:new(vehicle, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, VehicleCamera_mt)
  end
  instance.vehicle = vehicle
  instance.isActivated = false
  instance.smoothUpdateDt = 0
  instance.raycastDistance = 0
  instance.normalX = 0
  instance.normalY = 0
  instance.normalZ = 0
  instance.raycastNodes = {}
  instance.disableCollisionTime = -1
  return instance
end
function VehicleCamera:loadFromXML(xmlFile, key)
  local camIndexStr = getXMLString(xmlFile, key .. "#index")
  self.cameraNode = Utils.indexToObject(self.vehicle.components, camIndexStr)
  if self.cameraNode == nil or not getHasClassId(self.cameraNode, ClassIds.CAMERA) then
    print("Error loading camera " .. key .. ": invalid camera node")
    return false
  end
  if VehicleCamera.doCameraSmoothing then
    self.cameraPositionNode = createTransformGroup("cameraNode")
    link(getParent(self.cameraNode), self.cameraPositionNode)
    local x, y, z = getTranslation(self.cameraNode)
    setTranslation(self.cameraPositionNode, x, y, z)
  else
    self.cameraPositionNode = self.cameraNode
  end
  self.isRotatable = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rotatable"), false)
  self.limit = Utils.getNoNil(getXMLBool(xmlFile, key .. "#limit"), false)
  if self.limit then
    self.rotMinX = getXMLFloat(xmlFile, key .. "#rotMinX")
    self.rotMaxX = getXMLFloat(xmlFile, key .. "#rotMaxX")
    self.transMin = getXMLFloat(xmlFile, key .. "#transMin")
    self.transMax = getXMLFloat(xmlFile, key .. "#transMax")
    if self.rotMinX == nil or self.rotMaxX == nil or self.transMin == nil or self.transMax == nil then
      print("Error loading camera " .. key .. ": missing limit values")
      return false
    end
  end
  self.isInside = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isInside"), false)
  if self.isRotatable then
    self.rotateNode = Utils.indexToObject(self.vehicle.components, getXMLString(xmlFile, key .. "#rotateNode"))
  end
  if self.rotateNode == nil or self.rotateNode == self.cameraNode then
    self.rotateNode = self.cameraPositionNode
  end
  if VehicleCamera.doCameraSmoothing then
    link(getParent(self.rotateNode), self.cameraNode)
  end
  self.origRotX, self.origRotY, self.origRotZ = getRotation(self.rotateNode)
  self.rotX = self.origRotX
  self.rotY = self.origRotY
  self.rotZ = self.origRotZ
  self.origTransX, self.origTransY, self.origTransZ = getTranslation(self.cameraPositionNode)
  self.transX = self.origTransX
  self.transY = self.origTransY
  self.transZ = self.origTransZ
  local transLength = Utils.vector3Length(self.origTransX, self.origTransY, self.origTransZ)
  self.zoom = transLength
  self.zoomTarget = transLength
  self.zoomLimitedTarget = -1
  local trans1OverLength = 1 / transLength
  self.transDirX = trans1OverLength * self.origTransX
  self.transDirY = trans1OverLength * self.origTransY
  self.transDirZ = trans1OverLength * self.origTransZ
  self.allowTranslation = self.rotateNode ~= self.cameraPositionNode
  table.insert(self.raycastNodes, self.rotateNode)
  local i = 0
  while true do
    local raycastKey = key .. string.format(".raycastNode(%d)", i)
    if not hasXMLProperty(xmlFile, raycastKey) then
      break
    end
    local node = Utils.indexToObject(self.vehicle.components, getXMLString(xmlFile, raycastKey .. "#index"))
    if node ~= nil then
      table.insert(self.raycastNodes, node)
    end
    i = i + 1
  end
  return true
end
function VehicleCamera:delete()
end
function VehicleCamera:zoom(offset)
  self.zoomTarget = self.zoomTarget + offset
  if self.limit then
    self.zoomTarget = math.min(self.transMax, math.max(self.transMin, self.zoomTarget))
  end
  self.zoom = self.zoomTarget
end
function VehicleCamera:zoomSmoothly(offset)
  self.zoomTarget = self.zoomTarget + offset
  if self.limit then
    self.zoomTarget = math.min(self.transMax, math.max(self.transMin, self.zoomTarget))
  end
end
function VehicleCamera:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActivated then
    local translateMode = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) or Input.isMouseButtonPressed(Input.MOUSE_BUTTON_RIGHT)
    if self.isRotatable and not translateMode then
      self.rotX = self.rotX + InputBinding.mouseMovementY
      self.rotY = self.rotY - InputBinding.mouseMovementX
    end
  end
end
function VehicleCamera:keyEvent(unicode, sym, modifier, isDown)
end
function VehicleCamera:raycastCallback(transformId, x, y, z, distance, nx, ny, nz)
  self.raycastDistance = distance
  self.normalX = nx
  self.normalY = ny
  self.normalZ = nz
  self.raycastTransformId = transformId
end
function VehicleCamera:update(dt)
  self.smoothUpdateDt = self.smoothUpdateDt + dt
  local smoothDt = 25
  while smoothDt < self.smoothUpdateDt do
    local target = self.zoomTarget
    if self.zoomLimitedTarget >= 0 then
      target = math.min(self.zoomLimitedTarget, self.zoomTarget)
    end
    self.zoom = 0.9 * self.zoom + 0.1 * target
    self.smoothUpdateDt = self.smoothUpdateDt - smoothDt
  end
  if self.isActivated and self.isRotatable and not translateMode then
    local rotSpeed = 0.001 * dt
    local inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_UPDOWN_VEHICLE)
    local inputZ = InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_LEFTRIGHT_VEHICLE)
    if InputBinding.isAxisZero(inputW) then
      inputW = InputBinding.getAnalogInputAxis(InputBinding.AXIS_LOOK_UPDOWN_VEHICLE)
    end
    if InputBinding.isAxisZero(inputZ) then
      inputZ = InputBinding.getAnalogInputAxis(InputBinding.AXIS_LOOK_LEFTRIGHT_VEHICLE)
    end
    self.rotX = self.rotX - rotSpeed * inputW
    self.rotY = self.rotY - rotSpeed * inputZ
  end
  local useScaledTrans = false
  local scaledTransDist = 0
  if self.limit then
    self.rotX = math.min(self.rotMaxX, math.max(self.rotMinX, self.rotX))
    local hasCollision, collisionDistance = self:getCollisionDistance()
    collisionDistance = math.max(collisionDistance - 0.1, 0)
    if hasCollision then
      self.disableCollisionTime = self.vehicle.time + 400
      self.zoomLimitedTarget = collisionDistance
      if collisionDistance < self.zoom then
        self.zoom = collisionDistance
      end
    elseif self.disableCollisionTime <= self.vehicle.time then
      self.zoomLimitedTarget = -1
    end
  end
  self.transX, self.transY, self.transZ = self.transDirX * self.zoom, self.transDirY * self.zoom, self.transDirZ * self.zoom
  setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)
  setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)
  if VehicleCamera.doCameraSmoothing then
    local alpha = 0.6
    local alpha2 = 0.6
    local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
    self.targetLookAtPosition[1] = alpha2 * self.targetLookAtPosition[1] + (1 - alpha2) * xlook
    self.targetLookAtPosition[2] = alpha2 * self.targetLookAtPosition[2] + (1 - alpha2) * ylook
    self.targetLookAtPosition[3] = alpha2 * self.targetLookAtPosition[3] + (1 - alpha2) * zlook
    local x, y, z = getWorldTranslation(self.cameraPositionNode)
    self.targetPosition[1] = alpha * self.targetPosition[1] + (1 - alpha) * x
    self.targetPosition[2] = alpha * self.targetPosition[2] + (1 - alpha) * y
    self.targetPosition[3] = alpha * self.targetPosition[3] + (1 - alpha) * z
    local dx, dy, dz = worldDirectionToLocal(getParent(self.cameraNode), self.targetPosition[1] - self.targetLookAtPosition[1], self.targetPosition[2] - self.targetLookAtPosition[2], self.targetPosition[3] - self.targetLookAtPosition[3])
    local upx, upy, upz = worldDirectionToLocal(getParent(self.cameraNode), 0, 1, 0)
    local x, y, z = worldToLocal(getParent(self.cameraNode), self.targetPosition[1], self.targetPosition[2], self.targetPosition[3])
    setDirection(self.cameraNode, dx, dy, dz, upx, upy, upz)
    setTranslation(self.cameraNode, x, y, z)
  end
end
function VehicleCamera:onActivate()
  self.isActivated = true
  self:resetCamera()
  setCamera(self.cameraNode)
  if VehicleCamera.doCameraSmoothing then
    local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
    self.targetLookAtPosition = {
      xlook,
      ylook,
      zlook
    }
    local x, y, z = getWorldTranslation(self.cameraPositionNode)
    self.targetPosition = {
      x,
      y,
      z
    }
    setDirection(self.cameraNode, x - xlook, y - ylook, z - zlook, 0, 1, 0)
    setTranslation(self.cameraNode, x, y, z)
  end
end
function VehicleCamera:onDeactivate()
  self:resetCamera()
  self.isActivated = false
end
function VehicleCamera:resetCamera()
  self.rotX = self.origRotX
  self.rotY = self.origRotY
  self.rotZ = self.origRotZ
  self.transX = self.origTransX
  self.transY = self.origTransY
  self.transZ = self.origTransZ
  local transLength = Utils.vector3Length(self.origTransX, self.origTransY, self.origTransZ)
  self.zoom = transLength
  self.zoomTarget = transLength
  self.zoomLimitedTarget = -1
  setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)
  setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)
  if VehicleCamera.doCameraSmoothing then
    local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
    self.targetLookAtPosition = {
      xlook,
      ylook,
      zlook
    }
    local x, y, z = getWorldTranslation(self.cameraPositionNode)
    self.targetPosition = {
      x,
      y,
      z
    }
    setDirection(self.cameraNode, x - xlook, y - ylook, z - zlook, 0, 1, 0)
    setTranslation(self.cameraNode, x, y, z)
  end
end
function VehicleCamera:getCollisionDistance()
