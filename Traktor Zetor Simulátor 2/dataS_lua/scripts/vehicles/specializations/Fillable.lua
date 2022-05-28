Fillable = {}
Fillable.NUM_FILLTYPES = 0
Fillable.FILLTYPE_UNKNOWN = 0
Fillable.fillTypeNameToInt = {}
Fillable.fillTypeIntToName = {}
Fillable.fruitTypeToFillType = {}
Fillable.fillTypeToFruitType = {}
Fillable.fillTypeNameToInt.unknown = Fillable.FILLTYPE_UNKNOWN
Fillable.fillTypeIntToName[Fillable.FILLTYPE_UNKNOWN] = "unknown"
Fillable.sendNumBits = 6
function Fillable.registerFillType(name)
  local key = "FILLTYPE_" .. string.upper(name)
  if Fillable[key] == nil then
    if Fillable.NUM_FILLTYPES >= 64 then
      print("Error: Fillable.registerFillType too many fill types. Only 64 fill types are supported")
      return
    end
    Fillable.NUM_FILLTYPES = Fillable.NUM_FILLTYPES + 1
    Fillable[key] = Fillable.NUM_FILLTYPES
    Fillable.fillTypeNameToInt[name] = Fillable.NUM_FILLTYPES
    Fillable.fillTypeIntToName[Fillable.NUM_FILLTYPES] = name
  end
  return Fillable[key]
end
function Fillable.prerequisitesPresent(specializations)
  return true
end
function Fillable:load(xmlFile)
  self.allowFillType = Fillable.allowFillType
  self.resetFillLevelIfNeeded = Fillable.resetFillLevelIfNeeded
  self.setFillLevel = Fillable.setFillLevel
  self.fillLevel = 0
  self.capacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.capacity"), 0)
  self.fillTypeChangeThreshold = 0.05
  self.fillRootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.fillRootNode#index"))
  if self.fillRootNode == nil then
    self.fillRootNode = self.components[1].node
  end
  self.fillMassNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.fillMassNode#index"))
  if self.fillMassNode == nil then
    self.fillMassNode = self.fillRootNode
  end
  self.exactFillRootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.exactFillRootNode#index"))
  if self.exactFillRootNode == nil then
    self.exactFillRootNode = self.fillRootNode
  end
  self.fillAutoAimTargetNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.fillAutoAimTargetNode#index"))
  if self.fillAutoAimTargetNode == nil then
    self.fillAutoAimTargetNode = self.exactFillRootNode
  end
  self.fillTypes = {}
  self.fillTypes[Fillable.FILLTYPE_UNKNOWN] = true
  local fillTypes = getXMLString(xmlFile, "vehicle.fillTypes#fillTypes")
  if fillTypes ~= nil then
    local types = Utils.splitString(" ", fillTypes)
    for k, v in pairs(types) do
      local fillType = Fillable.fillTypeNameToInt[v]
      if fillType ~= nil then
        self.fillTypes[fillType] = true
      else
        print("Warning: '" .. self.configFileName .. "' has invalid fillType '" .. v .. "'.")
      end
    end
  end
  local fruitTypes = getXMLString(xmlFile, "vehicle.fillTypes#fruitTypes")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    for k, v in pairs(types) do
      local fillType = Fillable.fillTypeNameToInt[v]
      if fillType ~= nil then
        self.fillTypes[fillType] = true
      else
        print("Warning: '" .. self.configFileName .. "' has invalid fillType '" .. v .. "'.")
      end
    end
  end
  self.currentFillType = Fillable.FILLTYPE_UNKNOWN
  if self.isServer then
    self.sentFillType = self.currentFillType
    self.sentFillLevel = self.fillLevel
  end
  if self.isClient then
    self.fillPlanes = {}
    local i = 0
    while true do
      local key = string.format("vehicle.fillPlanes.fillPlane(%d)", i)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local fillPlane = {}
      fillPlane.nodes = {}
      local fillType = getXMLString(xmlFile, key .. "#type")
      if fillType ~= nil then
        local nodeI = 0
        while true do
          local nodeKey = key .. string.format(".node(%d)", nodeI)
          if not hasXMLProperty(xmlFile, nodeKey) then
            break
          end
          local node = Utils.indexToObject(self.components, getXMLString(xmlFile, nodeKey .. "#index"))
          if node ~= nil then
            local defaultX, defaultY, defaultZ = getTranslation(node)
            local defaultRX, defaultRY, defaultRZ = getRotation(node)
            setVisibility(node, false)
            local animCurve = AnimCurve:new(linearInterpolatorTransRotScale)
            local keyI = 0
            while true do
              local animKey = nodeKey .. string.format(".key(%d)", keyI)
              local keyTime = getXMLFloat(xmlFile, animKey .. "#time")
              local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#translation"))
              if y == nil then
                y = getXMLFloat(xmlFile, animKey .. "#y")
              end
              local rx, ry, rz = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#rotation"))
              local sx, sy, sz = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#scale"))
              if keyTime == nil then
                break
              end
              local x = Utils.getNoNil(x, defaultX)
              local y = Utils.getNoNil(y, defaultY)
              local z = Utils.getNoNil(z, defaultZ)
              local rx = Utils.getNoNil(rx, defaultRX)
              local ry = Utils.getNoNil(ry, defaultRY)
              local rz = Utils.getNoNil(rz, defaultRZ)
              local sx = Utils.getNoNil(sx, 1)
              local sy = Utils.getNoNil(sy, 1)
              local sz = Utils.getNoNil(sz, 1)
              animCurve:addKeyframe({
                x = x,
                y = y,
                z = z,
                rx = rx,
                ry = ry,
                rz = rz,
                sx = sx,
                sy = sy,
                sz = sz,
                time = keyTime
              })
              keyI = keyI + 1
            end
            if keyI == 0 then
              local minY, maxY = Utils.getVectorFromString(getXMLString(xmlFile, nodeKey .. "#minMaxY"))
              local minY = Utils.getNoNil(minY, defaultY)
              local maxY = Utils.getNoNil(maxY, defaultY)
              animCurve:addKeyframe({
                x = defaultX,
                y = minY,
                z = defaultZ,
                rx = defaultRX,
                ry = defaultRY,
                rz = defaultRZ,
                sx = 1,
                sy = 1,
                sz = 1,
                time = 0
              })
              animCurve:addKeyframe({
                x = defaultX,
                y = maxY,
                z = defaultZ,
                rx = defaultRX,
                ry = defaultRY,
                rz = defaultRZ,
                sx = 1,
                sy = 1,
                sz = 1,
                time = 1
              })
            end
            table.insert(fillPlane.nodes, {node = node, animCurve = animCurve})
          end
          nodeI = nodeI + 1
        end
        if 0 < table.getn(fillPlane.nodes) then
          if self.defaultFillPlane == nil then
            self.defaultFillPlane = fillPlane
          end
          self.fillPlanes[fillType] = fillPlane
        end
      end
      i = i + 1
    end
    if self.defaultFillPlane == nil then
      self.fillPlanes = nil
    end
    if self.fillPlanes == nil then
      Fillable.loadDeprecatedTrailerGrainPlane(self, xmlFile)
    end
  end
  self.allowFillFromAir = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.allowFillFromAir#value"), true)
  self.massScale = 9.1E-5 * Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.massScale#value"), 1)
  self:setFillLevel(0, Fillable.FILLTYPE_UNKNOWN)
  setUserAttribute(self.fillRootNode, "vehicleType", "Integer", 2)
  self.fillableDirtyFlag = self:getNextDirtyFlag()
end
function Fillable:postLoad(xmlFile)
  local startFillLevel = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.startFillLevel"), 0)
  if 0 < startFillLevel then
    local firstFillType = Fillable.FILLTYPE_UNKNOWN
    for k, v in pairs(self.fillTypes) do
      if k ~= Fillable.FILLTYPE_UNKNOWN and v then
        firstFillType = k
        break
      end
    end
    if firstFillType ~= Fillable.FILLTYPE_UNKNOWN then
      self:setFillLevel(startFillLevel, firstFillType, true)
    end
  end
end
function Fillable:loadDeprecatedTrailerGrainPlane(xmlFile)
  if self.isClient and self.fillPlanes == nil then
    local defaultX, defaultY, defaultZ, defaultRX, defaultRY, defaultRZ, defaultSX, defaultSY, defaultSZ
    self.fillPlanes = {}
    local i = 0
    while true do
      local key = string.format("vehicle.grainPlane.node(%d)", i)
      local fruitType = getXMLString(xmlFile, key .. "#type")
      local index = getXMLString(xmlFile, key .. "#index")
      if fruitType == nil or index == nil then
        break
      end
      local node = Utils.indexToObject(self.components, index)
      if node ~= nil then
        defaultX, defaultY, defaultZ = getTranslation(node)
        defaultRX, defaultRY, defaultRZ = getRotation(node)
        defaultSX, defaultSY, defaultSZ = getScale(node)
        setVisibility(node, false)
        local fillPlane = {}
        fillPlane.nodes = {}
        table.insert(fillPlane.nodes, {node = node})
        self.fillPlanes[fruitType] = fillPlane
        if self.defaultFillPlane == nil then
          self.defaultFillPlane = fillPlane
        end
      end
      i = i + 1
    end
    if self.defaultFillPlane == nil then
      self.fillPlanes = nil
    else
      local animCurve = AnimCurve:new(linearInterpolatorTransRotScale)
      local keyI = 0
      while true do
        local animKey = string.format("vehicle.grainPlane.key(%d)", keyI)
        local keyTime = getXMLFloat(xmlFile, animKey .. "#time")
        local y = getXMLFloat(xmlFile, animKey .. "#y")
        local sx, sy, sz = Utils.getVectorFromString(getXMLString(xmlFile, animKey .. "#scale"))
        if keyTime == nil then
          break
        end
        local x = Utils.getNoNil(x, defaultX)
        local y = Utils.getNoNil(y, defaultY)
        local z = Utils.getNoNil(z, defaultZ)
        local rx = Utils.getNoNil(rx, defaultRX)
        local ry = Utils.getNoNil(ry, defaultRY)
        local rz = Utils.getNoNil(rz, defaultRZ)
        local sx = Utils.getNoNil(sx, defaultSX)
        local sy = Utils.getNoNil(sy, defaultSY)
        local sz = Utils.getNoNil(sz, defaultSZ)
        animCurve:addKeyframe({
          x = x,
          y = y,
          z = z,
          rx = rx,
          ry = ry,
          rz = rz,
          sx = sx,
          sy = sy,
          sz = sz,
          time = keyTime
        })
        keyI = keyI + 1
      end
      if keyI == 0 then
        local minY, maxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainPlane#minMaxY"))
        local minY = Utils.getNoNil(minY, defaultY)
        local maxY = Utils.getNoNil(maxY, defaultY)
        animCurve:addKeyframe({
          x = defaultX,
          y = minY,
          z = defaultZ,
          rx = defaultRX,
          ry = defaultRY,
          rz = defaultRZ,
          sx = defaultSX,
          sy = defaultSY,
          sz = defaultSZ,
          time = 0
        })
        animCurve:addKeyframe({
          x = defaultX,
          y = maxY,
          z = defaultZ,
          rx = defaultRX,
          ry = defaultRY,
          rz = defaultRZ,
          sx = defaultSX,
          sy = defaultSY,
          sz = defaultSZ,
          time = 1
        })
      end
      for _, fillPlane in pairs(self.fillPlanes) do
        fillPlane.nodes[1].animCurve = animCurve
      end
    end
  end
end
function Fillable:delete()
end
function Fillable:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local fillLevel = getXMLFloat(xmlFile, key .. "#fillLevel")
  local fillType = getXMLString(xmlFile, key .. "#fillType")
  if fillLevel ~= nil and fillType ~= nil then
    local fillTypeInt = Fillable.fillTypeNameToInt[fillType]
    if fillTypeInt ~= nil then
      self:setFillLevel(fillLevel, fillTypeInt)
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Fillable:getSaveAttributesAndNodes(nodeIdent)
  local fillType = Fillable.fillTypeIntToName[self.currentFillType]
  if fillType == nil then
    fillType = "unknown"
  end
  local attributes = "fillLevel=\"" .. self.fillLevel .. "\" fillType=\"" .. fillType .. "\""
  return attributes, nil
end
function Fillable:addNodeVehicleMapping(list)
  list[self.fillRootNode] = self
  list[self.exactFillRootNode] = self
end
function Fillable:removeNodeVehicleMapping(list)
  list[self.fillRootNode] = nil
  list[self.exactFillRootNode] = nil
end
function Fillable:mouseEvent(posX, posY, isDown, isUp, button)
end
function Fillable:keyEvent(unicode, sym, modifier, isDown)
end
function Fillable:readStream(streamId, connection)
  if connection:getIsServer() then
    local fillLevel = streamReadFloat32(streamId)
    local fillType = streamReadUIntN(streamId, Fillable.sendNumBits)
    self:setFillLevel(fillLevel, fillType)
  end
end
function Fillable:writeStream(streamId, connection)
  if not connection:getIsServer() then
    streamWriteFloat32(streamId, self.fillLevel)
    streamWriteUIntN(streamId, self.currentFillType, Fillable.sendNumBits)
  end
end
function Fillable:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() and streamReadBool(streamId) then
    local fillLevel = streamReadUInt16(streamId) / 65535 * self.capacity
    local fillType = streamReadUIntN(streamId, Fillable.sendNumBits)
    self:setFillLevel(fillLevel, fillType, true)
  end
end
function Fillable:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.fillableDirtyFlag) ~= 0) then
    local percent = 0
    if self.capacity ~= 0 then
      percent = Utils.clamp(self.fillLevel / self.capacity, 0, 1)
    end
    streamWriteUInt16(streamId, math.floor(percent * 65535))
    streamWriteUIntN(streamId, self.currentFillType, Fillable.sendNumBits)
  end
end
function Fillable:update(dt)
  if self.firstTimeRun and self.isServer then
    if self.emptyMass == nil then
      self.emptyMass = getMass(self.fillMassNode)
      self.currentMass = self.emptyMass
    end
    local newMass = self.emptyMass + self.fillLevel * self.massScale
    if newMass ~= self.currentMass then
      setMass(self.fillMassNode, newMass)
      self.currentMass = newMass
      for k, v in pairs(self.components) do
        if v.node == self.fillMassNode then
          if v.centerOfMass ~= nil then
            setCenterOfMass(v.node, v.centerOfMass[1], v.centerOfMass[2], v.centerOfMass[3])
          end
          break
        end
      end
    end
  end
end
function Fillable:updateTick(dt)
  if self.isServer and (self.fillLevel ~= self.sentFillLevel or self.currentFillType ~= self.sentFillType) then
    self:raiseDirtyFlags(self.fillableDirtyFlag)
    self.sentFillLevel = self.fillLevel
    self.sentFillType = self.currentFillType
  end
end
function Fillable:draw()
end
function Fillable:resetFillLevelIfNeeded(fillType)
  if self.currentFillType ~= fillType then
    self.fillLevel = 0
  end
end
function Fillable:allowFillType(fillType, allowEmptying)
  local allowed = false
  if self.fillTypes[fillType] then
    if self.currentFillType ~= Fillable.FILLTYPE_UNKNOWN then
      if self.currentFillType ~= fillType then
        if self.fillLevel / self.capacity <= self.fillTypeChangeThreshold then
          allowed = true
          if allowEmptying then
            self.fillLevel = 0
          end
        end
      else
        allowed = true
      end
    else
      allowed = true
    end
  end
  return allowed
end
function Fillable:setFillLevel(fillLevel, fillType, force)
  if (force == nil or force == false) and not self:allowFillType(fillType, false) then
    return
  end
  self.currentFillType = fillType
  self.fillLevel = fillLevel
  if self.fillLevel > self.capacity then
    self.fillLevel = self.capacity
  end
  if self.fillLevel < 0 then
    self.fillLevel = 0
    self.currentFillType = Fillable.FILLTYPE_UNKNOWN
  end
  if self.isClient then
    if self.currentFillPlane ~= nil then
      for _, node in ipairs(self.currentFillPlane.nodes) do
        setVisibility(node.node, false)
      end
      self.currentFillPlane = nil
    end
    if self.fillPlanes ~= nil and self.defaultFillPlane ~= nil and fillType ~= Fillable.FILLTYPE_UNKNOWN then
      local fillTypeName = Fillable.fillTypeIntToName[fillType]
      local fillPlane = self.fillPlanes[fillTypeName]
      if fillPlane == nil then
        fillPlane = self.defaultFillPlane
      end
      local t = self.fillLevel / self.capacity
      for _, node in ipairs(fillPlane.nodes) do
        local x, y, z, rx, ry, rz, sx, sy, sz = node.animCurve:get(t)
        setTranslation(node.node, x, y, z)
        setRotation(node.node, rx, ry, rz)
        setScale(node.node, sx, sy, sz)
        setVisibility(node.node, self.fillLevel > 0)
      end
      self.currentFillPlane = fillPlane
    end
  end
end
