Vehicle = {}
source("dataS/scripts/vehicles/specializations/VehicleSetBeaconLightEvent.lua")
InitStaticObjectClass(Vehicle, "Vehicle", ObjectIds.OBJECT_VEHICLE)
Vehicle.springScale = 10
Vehicle.NUM_JOINTTYPES = 0
Vehicle.jointTypeNameToInt = {}
Vehicle.defaultWidth = 8
Vehicle.defaultLength = 8
Vehicle.debugRendering = false
function Vehicle.registerJointType(name)
  local key = "JOINTTYPE_" .. string.upper(name)
  if Vehicle[key] == nil then
    Vehicle.NUM_JOINTTYPES = Vehicle.NUM_JOINTTYPES + 1
    Vehicle[key] = Vehicle.NUM_JOINTTYPES
    Vehicle.jointTypeNameToInt[name] = Vehicle.NUM_JOINTTYPES
  end
end
Vehicle.registerJointType("implement")
Vehicle.registerJointType("trailer")
Vehicle.registerJointType("trailerLow")
Vehicle.registerJointType("telehandler")
Vehicle.registerJointType("frontloader")
function Vehicle:new(isServer, isClient, customMt)
  if Vehicle_mt == nil then
    Vehicle_mt = Class(Vehicle, Object)
  end
  local mt = customMt
  if mt == nil then
    mt = Vehicle_mt
  end
  local instance = Object:new(isServer, isClient, mt)
  instance.className = "Vehicle"
  instance.isAddedToMission = false
  return instance
end
function Vehicle:load(configFile, positionX, offsetY, positionZ, yRot, typeName)
  local instance = self
  local modName, baseDirectory = getModNameAndBaseDirectory(configFile)
  instance.configFileName = configFile
  instance.baseDirectory = baseDirectory
  instance.customEnvironment = modName
  local xmlFile = loadXMLFile("TempConfig", configFile)
  local i3dNode = Utils.loadSharedI3DFile(getXMLString(xmlFile, "vehicle.filename"), baseDirectory)
  instance.rootNode = getChildAt(i3dNode, 0)
  local tempRootNode = createTransformGroup("tempRootNode")
  instance.components = {}
  local numComponents = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.components#count"), 1)
  local rootX, rootY, rootZ
  instance.vehicleNodes = {}
  for i = 1, numComponents do
    table.insert(instance.components, {
      node = getChildAt(i3dNode, 0)
    })
    if not self.isServer then
      setRigidBodyType(instance.components[i].node, "Kinematic")
    end
    link(tempRootNode, instance.components[i].node)
    if i == 1 then
      rootX, rootY, rootZ = getTranslation(instance.components[i].node)
    end
    translate(instance.components[i].node, -rootX, -rootY, -rootZ)
    instance.components[i].originalTranslation = {
      getTranslation(instance.components[i].node)
    }
    instance.components[i].originalRotation = {
      getRotation(instance.components[i].node)
    }
    instance.vehicleNodes[instance.components[i].node] = instance.components[i].node
  end
  instance.interpolationAlpha = 0
  instance.positionIsDirty = false
  delete(i3dNode)
  local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ)
  setTranslation(tempRootNode, positionX, terrainHeight + offsetY, positionZ)
  setRotation(tempRootNode, 0, yRot, 0)
  for i = 1, numComponents do
    local x, y, z = getWorldTranslation(instance.components[i].node)
    local rx, ry, rz = getWorldRotation(instance.components[i].node)
    local qx, qy, qz, qw = getWorldQuaternion(instance.components[i].node)
    setTranslation(instance.components[i].node, x, y, z)
    setRotation(instance.components[i].node, rx, ry, rz)
    link(getRootNode(), instance.components[i].node)
    instance.components[i].sentTranslation = {
      x,
      y,
      z
    }
    instance.components[i].sentRotation = {
      qx,
      qy,
      qz,
      qw
    }
    instance.components[i].lastTranslation = {
      x,
      y,
      z
    }
    instance.components[i].lastRotation = {
      qx,
      qy,
      qz,
      qw
    }
    instance.components[i].targetTranslation = {
      x,
      y,
      z
    }
    instance.components[i].targetRotation = {
      qx,
      qy,
      qz,
      qw
    }
    instance.components[i].curTranslation = {
      x,
      y,
      z
    }
    instance.components[i].curRotation = {
      qx,
      qy,
      qz,
      qw
    }
  end
  delete(tempRootNode)
  instance.maxRotTime = 0
  instance.minRotTime = 0
  instance.autoRotateBackSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.wheels#autoRotateBackSpeed"), 1)
  instance.wheels = {}
  local i = 0
  while true do
    local wheelnamei = string.format("vehicle.wheels.wheel(%d)", i)
    local wheel = {}
    local reprStr = getXMLString(xmlFile, wheelnamei .. "#repr")
    if reprStr == nil then
      break
    end
    wheel.repr = Utils.indexToObject(instance.components, reprStr)
    if wheel.repr == nil then
      print("Error: invalid wheel repr " .. reprStr)
    else
      wheel.rotSpeed = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotSpeed"))
      wheel.rotMax = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMax"))
      wheel.rotMin = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMin"))
      wheel.driveMode = Utils.getNoNil(getXMLInt(xmlFile, wheelnamei .. "#driveMode"), 0)
      wheel.driveNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, wheelnamei .. "#driveNode"))
      if wheel.driveNode == nil then
        wheel.driveNode = wheel.repr
      end
      wheel.showSteeringAngle = Utils.getNoNil(getXMLBool(xmlFile, wheelnamei .. "#showSteeringAngle"), true)
      local radius = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#radius"), 1)
      local positionX, positionY, positionZ = getTranslation(wheel.repr)
      wheel.deltaY = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#deltaY"), 0)
      positionY = positionY + wheel.deltaY
      local suspTravel = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#suspTravel"), 0)
      local spring = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#spring"), 0) * Vehicle.springScale
      local damper = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#damper"), 0)
      local mass = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#mass"), 0.01)
      wheel.radius = radius
      wheel.steeringAxleScale = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#steeringAxleScale"), 0)
      wheel.steeringAxleRotMax = Utils.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#steeringAxleRotMax"), 20))
      wheel.steeringAxleRotMin = Utils.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#steeringAxleRotMin"), -20))
      wheel.lateralStiffness = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#lateralStiffness"), 19)
      wheel.longitudalStiffness = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#longitudalStiffness"), 1)
      wheel.steeringAngle = 0
      wheel.hasGroundContact = false
      wheel.axleSpeed = 0
      wheel.hasHandbrake = true
      wheel.node = getParent(wheel.repr)
      if self.isServer then
        wheel.wheelShape = createWheelShape(wheel.node, positionX, positionY, positionZ, radius, suspTravel, spring, damper, mass)
        setWheelShapeTireFunction(wheel.node, wheel.wheelShape, false, 1000000 * wheel.lateralStiffness)
        setWheelShapeTireFunction(wheel.node, wheel.wheelShape, true, 1000000 * wheel.longitudalStiffness)
      end
      wheel.netInfo = {}
      wheel.netInfo.xDrive = 0
      wheel.netInfo.x = positionX
      wheel.netInfo.y = positionY
      wheel.netInfo.z = positionZ
      wheel.netInfo.yMin = positionY - suspTravel
      wheel.netInfo.yRange = math.ceil(2 * suspTravel)
      if 1 > wheel.netInfo.yRange then
        wheel.netInfo.yRange = 1
      end
      local maxRotTime = wheel.rotMax / wheel.rotSpeed
      local minRotTime = wheel.rotMin / wheel.rotSpeed
      if maxRotTime < minRotTime then
        local temp = minRotTime
        minRotTime = maxRotTime
        maxRotTime = temp
      end
      if maxRotTime > instance.maxRotTime then
        instance.maxRotTime = maxRotTime
      end
      if minRotTime < instance.minRotTime then
        instance.minRotTime = minRotTime
      end
      table.insert(instance.wheels, wheel)
    end
    i = i + 1
  end
  instance.wheelFrictionScale = 1
  instance.dynamicWheelFrictionCosAngleMax = math.cos(math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.dynamicWheelFriction#minAngle"), 40)))
  instance.dynamicWheelFrictionCosAngleMin = math.cos(math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.dynamicWheelFriction#maxAngle"), 50)))
  instance.dynamicWheelFrictionMinScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.dynamicWheelFriction#minScale"), 0.001)
  instance.lastWheelRpm = 0
  instance.movingDirection = 0
  instance.steeringAxleNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, "vehicle.steeringAxleNode#index"))
  if instance.steeringAxleNode == nil then
    instance.steeringAxleNode = instance.components[1].node
  end
  instance.downForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.downForce"), 0)
  instance.sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), Vehicle.defaultWidth)
  instance.sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), Vehicle.defaultLength)
  instance.widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#widthOffset"), 0)
  instance.lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#lengthOffset"), 0)
  instance.typeDesc = Utils.getXMLI18N(xmlFile, "vehicle.typeDesc", "", "TypeDescription", instance.customEnvironment)
  local numLights = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.lights#count"), 0)
  instance.lights = {}
  for i = 1, numLights do
    local lightnamei = string.format("vehicle.lights.light%d", i)
    local node = Utils.indexToObject(instance.components, getXMLString(xmlFile, lightnamei .. "#index"))
    if node ~= nil then
      setVisibility(node, false)
      table.insert(instance.lights, node)
    end
  end
  self.lightCoronas = {}
  local i = 0
  while true do
    local key = string.format("vehicle.lightCoronas.lightCorona(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    if node ~= nil then
      setVisibility(node, false)
      table.insert(self.lightCoronas, node)
    end
    i = i + 1
  end
  self.lightCones = {}
  local i = 0
  while true do
    local key = string.format("vehicle.lightCones.lightCone(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    if node ~= nil then
      setVisibility(node, false)
      table.insert(self.lightCones, node)
    end
    i = i + 1
  end
  self.beaconLights = {}
  local i = 0
  while true do
    local key = string.format("vehicle.beaconLights.beaconLight(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"))
    local speed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speed"), 0.02)
    if node ~= nil then
      setVisibility(node, false)
      table.insert(self.beaconLights, {node = node, speed = speed})
    end
    i = i + 1
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  instance.cuttingAreas = {}
  for i = 1, numCuttingAreas do
    instance.cuttingAreas[i] = {}
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    instance.cuttingAreas[i].start = Utils.indexToObject(instance.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    instance.cuttingAreas[i].width = Utils.indexToObject(instance.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    instance.cuttingAreas[i].height = Utils.indexToObject(instance.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
  end
  local attachSound = getXMLString(xmlFile, "vehicle.attachSound#file")
  if attachSound ~= nil and attachSound ~= "" then
    attachSound = Utils.getFilename(attachSound, self.baseDirectory)
    instance.attachSound = createSample("attachSound")
    loadSample(instance.attachSound, attachSound, false)
    instance.attachSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.attachSound#pitchOffset"), 0)
  end
  for i = 1, numComponents do
    local namei = string.format("vehicle.components.component%d", i)
    local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, namei .. "#centerOfMass"))
    if x ~= nil and y ~= nil and z ~= nil then
      setCenterOfMass(instance.components[i].node, x, y, z)
      instance.components[i].centerOfMass = {
        x,
        y,
        z
      }
    end
    local count = getXMLInt(xmlFile, namei .. "#solverIterationCount")
    if count ~= nil then
      setSolverIterationCount(instance.components[i].node, count)
      instance.components[i].solverIterationCount = count
    end
  end
  instance.componentJoints = {}
  local componentJointI = 0
  while true do
    local key = string.format("vehicle.components.joint(%d)", componentJointI)
    local index1 = getXMLInt(xmlFile, key .. "#component1")
    local index2 = getXMLInt(xmlFile, key .. "#component2")
    local jointIndexStr = getXMLString(xmlFile, key .. "#index")
    if index1 == nil or index2 == nil or jointIndexStr == nil then
      break
    end
    local jointNode = Utils.indexToObject(instance.components, jointIndexStr)
    if jointNode ~= nil and jointNode ~= 0 then
      local jointDesc = {}
      jointDesc.componentIndices = {
        index1 + 1,
        index2 + 1
      }
      jointDesc.jointNode = jointNode
      if self.isServer then
        local constr = JointConstructor:new()
        if instance.components[index1 + 1] == nil or instance.components[index2 + 1] == nil then
          print("Error: invalid joint indices (" .. index1 .. ", " .. index2 .. ") for component joint " .. componentJointI .. " in '" .. self.configFileName .. "'")
          break
        end
        constr:setActors(instance.components[index1 + 1].node, instance.components[index2 + 1].node)
        constr:setJointTransforms(jointNode, jointNode)
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimit"))
        local rotLimits = {}
        rotLimits[1] = math.rad(Utils.getNoNil(x, 0))
        rotLimits[2] = math.rad(Utils.getNoNil(y, 0))
        rotLimits[3] = math.rad(Utils.getNoNil(z, 0))
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#transLimit"))
        local transLimits = {}
        transLimits[1] = Utils.getNoNil(x, 0)
        transLimits[2] = Utils.getNoNil(y, 0)
        transLimits[3] = Utils.getNoNil(z, 0)
        for i = 1, 3 do
          local rotLimit = rotLimits[i]
          if 0 <= rotLimit then
            constr:setRotationLimit(i - 1, -rotLimit, rotLimit)
          end
          local transLimit = transLimits[i]
          if 0 <= transLimit then
            constr:setTranslationLimit(i - 1, true, -transLimit, transLimit)
          else
            constr:setTranslationLimit(i - 1, false, 0, 0)
          end
        end
        if Utils.getNoNil(getXMLBool(xmlFile, key .. "#breakable"), false) then
          local force = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#breakForce"), 10)
          local torque = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#breakTorque"), 10)
          constr:setBreakable(force, torque)
        end
        jointDesc.jointIndex = constr:finalize()
      end
      table.insert(instance.componentJoints, jointDesc)
    end
    componentJointI = componentJointI + 1
  end
  local collisionPairI = 0
  while true do
    local key = string.format("vehicle.components.collisionPair(%d)", collisionPairI)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local enabled = getXMLBool(xmlFile, key .. "#enabled")
    local index1 = getXMLInt(xmlFile, key .. "#component1")
    local index2 = getXMLInt(xmlFile, key .. "#component2")
    if index1 ~= nil and index2 ~= nil and enabled ~= nil then
      local component1 = instance.components[index1 + 1]
      local component2 = instance.components[index2 + 1]
      if component1 ~= nil and component2 ~= nil and not enabled then
        setPairCollision(component1.node, component2.node, false)
      end
    end
    collisionPairI = collisionPairI + 1
  end
  instance.attacherJoints = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local object = Utils.indexToObject(instance.components, index)
    if object ~= nil then
      local entry = {}
      entry.jointTransform = object
      local jointTypeStr = getXMLString(xmlFile, baseName .. "#jointType")
      local jointType
      if jointTypeStr ~= nil then
        jointType = Vehicle.jointTypeNameToInt[jointTypeStr]
        if jointType == nil then
          print("Warning: invalid jointType " .. jointTypeStr)
        end
      end
      if jointType == nil then
        jointType = Vehicle.JOINTTYPE_IMPLEMENT
      end
      entry.jointType = jointType
      entry.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsJointLimitMovement"), true)
      entry.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsLowering"), true)
      local x, y, z
      local rotationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rotationNode"))
      if rotationNode ~= nil then
        entry.rotationNode = rotationNode
        x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRot"))
        entry.maxRot = {}
        entry.maxRot[1] = math.rad(Utils.getNoNil(x, 0))
        entry.maxRot[2] = math.rad(Utils.getNoNil(y, 0))
        entry.maxRot[3] = math.rad(Utils.getNoNil(z, 0))
        x, y, z = getRotation(rotationNode)
        entry.minRot = {
          x,
          y,
          z
        }
      end
      local rotationNode2 = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rotationNode2"))
      if rotationNode2 ~= nil then
        entry.rotationNode2 = rotationNode2
        x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRot2"))
        entry.maxRot2 = {}
        entry.maxRot2[1] = math.rad(Utils.getNoNil(x, 0))
        entry.maxRot2[2] = math.rad(Utils.getNoNil(y, 0))
        entry.maxRot2[3] = math.rad(Utils.getNoNil(z, 0))
        x, y, z = getRotation(rotationNode2)
        entry.minRot2 = {
          x,
          y,
          z
        }
      end
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRotLimit"))
      entry.maxRotLimit = {}
      entry.maxRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)))
      entry.maxRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)))
      entry.maxRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)))
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#minRotLimit"))
      entry.minRotLimit = {}
      entry.minRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)))
      entry.minRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)))
      entry.minRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)))
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxTransLimit"))
      entry.maxTransLimit = {}
      entry.maxTransLimit[1] = math.abs(Utils.getNoNil(x, 0))
      entry.maxTransLimit[2] = math.abs(Utils.getNoNil(y, 0))
      entry.maxTransLimit[3] = math.abs(Utils.getNoNil(z, 0))
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#minTransLimit"))
      entry.minTransLimit = {}
      entry.minTransLimit[1] = math.abs(Utils.getNoNil(x, 0))
      entry.minTransLimit[2] = math.abs(Utils.getNoNil(y, 0))
      entry.minTransLimit[3] = math.abs(Utils.getNoNil(z, 0))
      entry.moveTime = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#moveTime"), 0.5) * 1000
      local rotationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".topArm#rotationNode"))
      local translationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".topArm#translationNode"))
      local referenceNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".topArm#referenceNode"))
      if rotationNode ~= nil then
        local topArm = {}
        topArm.rotationNode = rotationNode
        topArm.rotX, topArm.rotY, topArm.rotZ = getRotation(rotationNode)
        if translationNode ~= nil and referenceNode ~= nil then
          topArm.translationNode = translationNode
          local x, y, z = getTranslation(translationNode)
          if math.abs(x) >= 1.0E-4 or math.abs(y) >= 1.0E-4 or math.abs(z) >= 1.0E-4 then
            print("Warning: translation of topArm of attacherJoint " .. i .. " is not 0/0/0 in '" .. self.configFileName .. "'")
          end
          local ax, ay, az = getWorldTranslation(referenceNode)
          local bx, by, bz = getWorldTranslation(translationNode)
          topArm.referenceDistance = Utils.vector3Length(ax - bx, ay - by, az - bz)
        end
        topArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".topArm#zScale"), 1))
        entry.topArm = topArm
      end
      local rotationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".bottomArm#rotationNode"))
      local translationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".bottomArm#translationNode"))
      local referenceNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".bottomArm#referenceNode"))
      if rotationNode ~= nil then
        local bottomArm = {}
        bottomArm.rotationNode = rotationNode
        bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = getRotation(rotationNode)
        if translationNode ~= nil and referenceNode ~= nil then
          bottomArm.translationNode = translationNode
          local x, y, z = getTranslation(translationNode)
          if math.abs(x) >= 1.0E-4 or math.abs(y) >= 1.0E-4 or math.abs(z) >= 1.0E-4 then
            print("Warning: translation of bottomArm of attacherJoint " .. i .. " is not 0/0/0 in '" .. self.configFileName .. "'")
          end
          local ax, ay, az = getWorldTranslation(referenceNode)
          local bx, by, bz = getWorldTranslation(translationNode)
          bottomArm.referenceDistance = Utils.vector3Length(ax - bx, ay - by, az - bz)
        end
        bottomArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".bottomArm#zScale"), 1))
        entry.bottomArm = bottomArm
      end
      entry.rootNode = Utils.getNoNil(Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rootNode")), instance.components[1].node)
      entry.jointIndex = 0
      table.insert(instance.attacherJoints, entry)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("vehicle.trailerAttacherJoints.trailerAttacherJoint(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local object = Utils.indexToObject(instance.components, index)
    if object ~= nil then
      local entry = {}
      entry.jointTransform = object
      entry.jointIndex = 0
      local isLow = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#low"), false)
      if isLow then
        entry.jointType = Vehicle.JOINTTYPE_TRAILERLOW
      else
        entry.jointType = Vehicle.JOINTTYPE_TRAILER
      end
      entry.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsJointLimitMovement"), false)
      entry.allowsLowering = false
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRotLimit"))
      entry.maxRotLimit = {}
      entry.maxRotLimit[1] = Utils.degToRad(math.abs(Utils.getNoNil(x, 10)))
      entry.maxRotLimit[2] = Utils.degToRad(math.abs(Utils.getNoNil(y, 50)))
      entry.maxRotLimit[3] = Utils.degToRad(math.abs(Utils.getNoNil(z, 50)))
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#minRotLimit"))
      entry.minRotLimit = {}
      entry.minRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)))
      entry.minRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)))
      entry.minRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)))
      x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxTransLimit"))
      entry.maxTransLimit = {}
      entry.maxTransLimit[1] = math.abs(Utils.getNoNil(x, 0))
      entry.maxTransLimit[2] = math.abs(Utils.getNoNil(y, 0))
      entry.maxTransLimit[3] = math.abs(Utils.getNoNil(z, 0))
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#minTransLimit"))
      entry.minTransLimit = {}
      entry.minTransLimit[1] = math.abs(Utils.getNoNil(x, 0))
      entry.minTransLimit[2] = math.abs(Utils.getNoNil(y, 0))
      entry.minTransLimit[3] = math.abs(Utils.getNoNil(z, 0))
      entry.rootNode = Utils.getNoNil(Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rootNode")), instance.components[1].node)
      table.insert(instance.attacherJoints, entry)
    end
    i = i + 1
  end
  instance.attachedImplements = {}
  instance.selectedImplement = 0
  instance.requiredDriveMode = 1
  instance.steeringAxleAngle = 0
  instance.rotatedTime = 0
  instance.firstTimeRun = false
  instance.lightsActive = false
  instance.realLightsActive = false
  instance.lightConesActive = false
  instance.lastPosition = nil
  instance.lastSpeed = 0
  instance.lastSpeedReal = 0
  instance.lastMovedDistance = 0
  instance.speedDisplayDt = 0
  instance.speedDisplayScale = 1
  instance.isBroken = false
  instance.isVehicleSaved = true
  instance.checkSpeedLimit = true
  instance.lastSoundSpeed = 0
  instance.time = 0
  instance.forceIsActive = false
  instance.vehicleDirtyFlag = instance.nextDirtyFlag
  instance.nextDirtyFlag = instance.vehicleDirtyFlag * 2
  instance.typeName = typeName
  local typeDef = VehicleTypeUtil.vehicleTypes[typeName]
  instance.specializations = typeDef.specializations
  for i = 1, table.getn(instance.specializations) do
    instance.specializations[i].load(instance, xmlFile)
  end
  for i = 1, table.getn(instance.specializations) do
    if instance.specializations[i].postLoad ~= nil then
      instance.specializations[i].postLoad(instance, xmlFile)
    end
  end
  instance.componentsVisibility = true
  delete(xmlFile)
end
function Vehicle:delete()
  for i = table.getn(self.attachedImplements), 1, -1 do
    self:detachImplement(1, true)
  end
  for i = table.getn(self.specializations), 1, -1 do
    self.specializations[i].delete(self)
  end
  if self.attachSound ~= nil then
    delete(self.attachSound)
  end
  if self.isServer then
    for k, v in pairs(self.componentJoints) do
      removeJoint(v.jointIndex)
    end
  end
  for k, v in pairs(self.components) do
    delete(v.node)
  end
  Vehicle:superClass().delete(self)
end
function Vehicle:readStream(streamId, connection)
  Vehicle:superClass().readStream(self, streamId)
  local configFile = Utils.convertFromNetworkFilename(streamReadString(streamId))
  local typeName = streamReadString(streamId)
  if self.configFileName == nil then
    self:load(configFile, 0, 0, 0, 0, typeName)
  end
  for i = 1, table.getn(self.components) do
    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    local x_rot = streamReadFloat32(streamId)
    local y_rot = streamReadFloat32(streamId)
    local z_rot = streamReadFloat32(streamId)
    local w_rot = streamReadFloat32(streamId)
    self:setWorldPositionQuaternion(x, y, z, x_rot, y_rot, z_rot, w_rot, i)
    self.components[i].lastTranslation = {
      x,
      y,
      z
    }
    self.components[i].lastRotation = {
      x_rot,
      y_rot,
      z_rot,
      w_rot
    }
    self.components[i].targetTranslation = {
      x,
      y,
      z
    }
    self.components[i].targetRotation = {
      x_rot,
      y_rot,
      z_rot,
      w_rot
    }
    self.components[i].curTranslation = {
      x,
      y,
      z
    }
    self.components[i].curRotation = {
      x_rot,
      y_rot,
      z_rot,
      w_rot
    }
  end
  self.interpolationAlpha = 0
  self.positionIsDirty = false
  for i = 1, table.getn(self.wheels) do
    local wheel = self.wheels[i]
    wheel.netInfo.x = streamReadFloat32(streamId)
    wheel.netInfo.y = streamReadFloat32(streamId)
    wheel.netInfo.z = streamReadFloat32(streamId)
    wheel.netInfo.xDrive = streamReadFloat32(streamId)
  end
  local numImplements = streamReadInt8(streamId)
  for i = 1, numImplements do
    local implementId = streamReadInt32(streamId)
    local jointDescIndex = streamReadInt8(streamId)
    local moveDown = streamReadBool(streamId)
    local object = networkGetObject(implementId)
    if object ~= nil then
      self:attachImplement(object, jointDescIndex, true)
      self:setJointMoveDown(jointDescIndex, moveDown, true)
    end
  end
  for k, v in pairs(self.specializations) do
    if v.readStream ~= nil then
      v.readStream(self, streamId, connection)
    end
  end
end
function Vehicle:writeStream(streamId, connection)
  Vehicle:superClass().writeStream(self, streamId)
  streamWriteString(streamId, Utils.convertToNetworkFilename(self.configFileName))
  streamWriteString(streamId, self.typeName)
  for i = 1, table.getn(self.components) do
    local x, y, z = getTranslation(self.components[i].node)
    local x_rot, y_rot, z_rot, w_rot = getQuaternion(self.components[i].node)
    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)
    streamWriteFloat32(streamId, x_rot)
    streamWriteFloat32(streamId, y_rot)
    streamWriteFloat32(streamId, z_rot)
    streamWriteFloat32(streamId, w_rot)
  end
  for i = 1, table.getn(self.wheels) do
    local wheel = self.wheels[i]
    streamWriteFloat32(streamId, wheel.netInfo.x)
    streamWriteFloat32(streamId, wheel.netInfo.y)
    streamWriteFloat32(streamId, wheel.netInfo.z)
    streamWriteFloat32(streamId, wheel.netInfo.xDrive)
  end
  streamWriteInt8(streamId, table.getn(self.attachedImplements))
  for i = 1, table.getn(self.attachedImplements) do
    local implement = self.attachedImplements[i]
    local jointDescIndex = implement.jointDescIndex
    local jointDesc = self.attacherJoints[jointDescIndex]
    local moveDown = jointDesc.moveDown
    streamWriteInt32(streamId, networkGetObjectId(implement.object))
    streamWriteInt8(streamId, jointDescIndex)
    streamWriteBool(streamId, moveDown)
  end
  for k, v in pairs(self.specializations) do
    if v.writeStream ~= nil then
      v.writeStream(self, streamId, connection)
    end
  end
end
function Vehicle:readUpdateStream(streamId, timestamp, connection)
  if connection.isServer then
    local hasUpdate = streamReadBool(streamId)
    if hasUpdate then
      for i = 1, table.getn(self.components) do
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        local x_rot = Utils.readCompressedAngle(streamId)
        local y_rot = Utils.readCompressedAngle(streamId)
        local z_rot = Utils.readCompressedAngle(streamId)
        local x_rot, y_rot, z_rot, w_rot = mathEulerToQuaternion(x_rot, y_rot, z_rot)
        self.components[i].targetTranslation = {
          x,
          y,
          z
        }
        self.components[i].targetRotation = {
          x_rot,
          y_rot,
          z_rot,
          w_rot
        }
        local trans = self.components[i].curTranslation
        local rot = self.components[i].curRotation
        self.components[i].lastTranslation = {
          trans[1],
          trans[2],
          trans[3]
        }
        self.components[i].lastRotation = {
          rot[1],
          rot[2],
          rot[3],
          rot[4]
        }
      end
      self.interpolationAlpha = 0
      self.positionIsDirty = true
      for i = 1, table.getn(self.wheels) do
        local wheel = self.wheels[i]
        local y = streamReadUInt8(streamId)
        wheel.netInfo.y = y / 255 * wheel.netInfo.yRange + wheel.netInfo.yMin
        wheel.netInfo.xDrive = streamReadFloat32(streamId)
      end
      self.rotatedTime = streamReadFloat32(streamId)
    end
  end
  for k, v in pairs(self.specializations) do
    if v.readUpdateStream ~= nil then
      v.readUpdateStream(self, streamId, timestamp, connection)
    end
  end
end
function Vehicle:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection.isServer then
    if bitAND(dirtyMask, self.vehicleDirtyFlag) ~= 0 then
      streamWriteBool(streamId, true)
      for i = 1, table.getn(self.components) do
        local x, y, z = getTranslation(self.components[i].node)
        local x_rot, y_rot, z_rot = getRotation(self.components[i].node)
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        Utils.writeCompressedAngle(streamId, x_rot)
        Utils.writeCompressedAngle(streamId, y_rot)
        Utils.writeCompressedAngle(streamId, z_rot)
      end
      for i = 1, table.getn(self.wheels) do
        local wheel = self.wheels[i]
        streamWriteUInt8(streamId, Utils.clamp((wheel.netInfo.y - wheel.netInfo.yMin) / wheel.netInfo.yRange * 255, 0, 255))
        streamWriteFloat32(streamId, wheel.netInfo.xDrive)
      end
      streamWriteFloat32(streamId, self.rotatedTime)
    else
      streamWriteBool(streamId, false)
    end
  end
  for k, v in pairs(self.specializations) do
    if v.writeUpdateStream ~= nil then
      v.writeUpdateStream(self, streamId, connection, dirtyMask)
    end
  end
end
function Vehicle:testScope(x, y, z, coeff)
  local vx, vy, vz = getTranslation(self.components[1].node)
  local distanceSq = Utils.vector3LengthSq(vx - x, vy - y, vz - z)
  for k, v in pairs(self.specializations) do
    if v.testScope ~= nil and not v.testScope(self, x, y, z, coeff, distanceSq) then
      return false
    end
  end
  return true
end
function Vehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection)
  if self:getOwner() == connection then
    return 50
  end
  local x1, y1, z1 = getTranslation(self.components[1].node)
  local dist = Utils.vector3Length(x1 - x, y1 - y, z1 - z)
  local clipDist = getClipDistance(self.components[1].node) * coeff
  return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end
function Vehicle:onGhostRemove()
  for k, v in pairs(self.specializations) do
    if v.onGhostRemove ~= nil then
      v.onGhostRemove(self)
    end
  end
end
function Vehicle:onGhostAdd()
  for k, v in pairs(self.specializations) do
    if v.onGhostAdd ~= nil then
      v.onGhostAdd(self)
    end
  end
end
function Vehicle:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local findPlace = resetVehicles
  if not findPlace then
    local isAbsolute = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isAbsolute"), false)
    if isAbsolute then
      local pos = {}
      for i = 1, table.getn(self.components) do
        local componentKey = key .. ".component" .. i
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, componentKey .. "#position"))
        local xRot, yRot, zRot = Utils.getVectorFromString(getXMLString(xmlFile, componentKey .. "#rotation"))
        if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
          findPlace = true
          break
        end
        pos[i] = {
          x = x,
          y = y,
          z = z,
          xRot = xRot,
          yRot = yRot,
          zRot = zRot
        }
      end
      if not findPlace then
        for i = 1, table.getn(self.components) do
          local p = pos[i]
          self:setWorldPosition(p.x, p.y, p.z, p.xRot, p.yRot, p.zRot, i)
        end
      end
    else
      local yOffset = getXMLFloat(xmlFile, key .. "#yOffset")
      local xPosition = getXMLFloat(xmlFile, key .. "#xPosition")
      local zPosition = getXMLFloat(xmlFile, key .. "#zPosition")
      local yRotation = getXMLFloat(xmlFile, key .. "#yRotation")
      if yOffset == nil or xPosition == nil or zPosition == nil or yRotation == nil then
        findPlace = true
      else
        self:setRelativePosition(xPosition, yOffset, zPosition, math.rad(yRotation))
      end
    end
  end
  if findPlace then
    if resetVehicles then
      local x, y, z, place, width, offset = PlacementUtil.getPlace(g_currentMission.loadSpawnPlaces, self.sizeWidth, self.sizeLength, self.widthOffset, self.lengthOffset, g_currentMission.usedLoadPlaces)
      if x ~= nil then
        local yRot = Utils.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
        PlacementUtil.markPlaceUsed(g_currentMission.usedLoadPlaces, place, width)
        self:setRelativePosition(x, offset, z, yRot)
      else
        return BaseMission.VEHICLE_LOAD_ERROR
      end
    else
      return BaseMission.VEHICLE_LOAD_DELAYED
    end
  end
  for k, v in pairs(self.specializations) do
    if v.loadFromAttributesAndNodes ~= nil then
      local r = v.loadFromAttributesAndNodes(self, xmlFile, key, resetVehicles)
      if r ~= BaseMission.VEHICLE_LOAD_OK then
        return r
      end
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Vehicle:getSaveAttributesAndNodes(nodeIdent)
  local attributes = "isAbsolute=\"true\""
  local nodes = ""
  if not self.isBroken then
    for i = 1, table.getn(self.components) do
      if 1 < i then
        nodes = nodes .. "\n"
      end
      local node = self.components[i].node
      local x, y, z = getTranslation(node)
      local xRot, yRot, zRot = getRotation(node)
      nodes = nodes .. nodeIdent .. "<component" .. i .. " position=\"" .. x .. " " .. y .. " " .. z .. "\" rotation=\"" .. xRot .. " " .. yRot .. " " .. zRot .. "\" />"
    end
  end
  for k, v in pairs(self.specializations) do
    if v.getSaveAttributesAndNodes ~= nil then
      local specAttributes, specNodes = v.getSaveAttributesAndNodes(self, nodeIdent)
      if specAttributes ~= nil and specAttributes ~= "" then
        attributes = attributes .. " " .. specAttributes
      end
      if specNodes ~= nil and specNodes ~= "" then
        nodes = nodes .. "\n" .. specNodes
      end
    end
  end
  return attributes, nodes
end
function Vehicle:setRelativePosition(positionX, offsetY, positionZ, yRot)
  local tempRootNode = createTransformGroup("tempRootNode")
  local numComponents = table.getn(self.components)
  for i = 1, numComponents do
    link(tempRootNode, self.components[i].node)
    setTranslation(self.components[i].node, unpack(self.components[i].originalTranslation))
    setRotation(self.components[i].node, unpack(self.components[i].originalRotation))
  end
  local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ)
  setTranslation(tempRootNode, positionX, terrainHeight + offsetY, positionZ)
  setRotation(tempRootNode, 0, yRot, 0)
  for i = 1, numComponents do
    local x, y, z = getWorldTranslation(self.components[i].node)
    local rx, ry, rz = getWorldRotation(self.components[i].node)
    local qx, qy, qz, qw = getWorldQuaternion(self.components[i].node)
    setTranslation(self.components[i].node, x, y, z)
    setRotation(self.components[i].node, rx, ry, rz)
    link(getRootNode(), self.components[i].node)
    self.components[i].lastTranslation = {
      x,
      y,
      z
    }
    self.components[i].lastRotation = {
      qx,
      qy,
      qz,
      qw
    }
    self.components[i].targetTranslation = {
      x,
      y,
      z
    }
    self.components[i].targetRotation = {
      qx,
      qy,
      qz,
      qw
    }
    self.components[i].curTranslation = {
      x,
      y,
      z
    }
    self.components[i].curRotation = {
      qx,
      qy,
      qz,
      qw
    }
  end
  self.interpolationAlpha = 0
  self.positionIsDirty = false
  delete(tempRootNode)
  for k, v in pairs(self.specializations) do
    if v.setRelativePosition ~= nil then
      v.setRelativePosition(self, positionX, offsetY, positionZ, yRot)
    end
  end
end
function Vehicle:setWorldPosition(x, y, z, xRot, yRot, zRot, i)
  setTranslation(self.components[i].node, x, y, z)
  setRotation(self.components[i].node, xRot, yRot, zRot)
end
function Vehicle:setWorldPositionQuaternion(x, y, z, xRot, yRot, zRot, wRot, i)
  setTranslation(self.components[i].node, x, y, z)
  setQuaternion(self.components[i].node, xRot, yRot, zRot, wRot)
end
function Vehicle:addNodeVehicleMapping(list)
  for k, v in pairs(self.components) do
    list[v.node] = self
  end
  for k, v in pairs(self.specializations) do
    if v.addNodeVehicleMapping ~= nil then
      v.addNodeVehicleMapping(self, list)
    end
  end
end
function Vehicle:removeNodeVehicleMapping(list)
  for k, v in pairs(self.components) do
    list[v.node] = nil
  end
  for k, v in pairs(self.specializations) do
    if v.removeNodeVehicleMapping ~= nil then
      v.removeNodeVehicleMapping(self, list)
    end
  end
end
function Vehicle:mouseEvent(posX, posY, isDown, isUp, button)
  for k, v in pairs(self.specializations) do
    v.mouseEvent(self, posX, posY, isDown, isUp, button)
  end
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function Vehicle:keyEvent(unicode, sym, modifier, isDown)
  for k, v in pairs(self.specializations) do
    v.keyEvent(self, unicode, sym, modifier, isDown)
  end
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:keyEvent(unicode, sym, modifier, isDown)
  end
end
function Vehicle:update(dt)
  if not self.isServer and self.positionIsDirty then
    self.interpolationAlpha = math.min(self.interpolationAlpha + dt / 45, 1.2)
    if self.interpolationAlpha == 1.5 then
      self.positionIsDirty = false
    end
    for i = 1, table.getn(self.components) do
      for c = 1, 3 do
        self.components[i].curTranslation[c] = self.components[i].lastTranslation[c] * (1 - self.interpolationAlpha) + self.components[i].targetTranslation[c] * self.interpolationAlpha
      end
      local rot1 = self.components[i].lastRotation
      local rot2 = self.components[i].targetRotation
      local x, y, z, w = Utils.nlerpQuaternionShortestPath(rot1[1], rot1[2], rot1[3], rot1[4], rot2[1], rot2[2], rot2[3], rot2[4], self.interpolationAlpha)
      self.components[i].curRotation = {
        x,
        y,
        z,
        w
      }
      local trans = self.components[i].curTranslation
      self:setWorldPositionQuaternion(trans[1], trans[2], trans[3], x, y, z, w, i)
    end
  end
  self.time = self.time + dt
  self.isActive = self:getIsActive()
  self.speedDisplayDt = self.speedDisplayDt + dt
  self.lastMovedDistance = 0
  if self.speedDisplayDt > 100 then
    local newX, newY, newZ = getWorldTranslation(self.components[1].node)
    if self.lastPosition == nil then
      self.lastPosition = {
        newX,
        newY,
        newZ
      }
    end
    local dx, dy, dz = worldDirectionToLocal(self.components[1].node, newX - self.lastPosition[1], newY - self.lastPosition[2], newZ - self.lastPosition[3])
    if 0.01 < dz then
      self.movingDirection = 1
    elseif dz < -0.01 then
      self.movingDirection = -1
    else
      self.movingDirection = 0
    end
    self.lastMovedDistance = Utils.vector3Length(dx, dy, dz)
    self.lastSpeedReal = self.lastMovedDistance / 100
    self.lastSpeed = self.lastSpeed * 0.85 + self.lastSpeedReal * 0.15
    self.lastPosition = {
      newX,
      newY,
      newZ
    }
    self.speedDisplayDt = self.speedDisplayDt - 100
  end
  if self.downForce ~= 0 and self.isServer then
    local worldX, worldY, worldZ = localDirectionToWorld(self.components[1].node, 0, -self.downForce * dt / 1000, 0)
    addForce(self.components[1].node, worldX, worldY, worldZ, 0, 0, 0, true)
  end
  if self.isActive then
    for k, implement in pairs(self.attachedImplements) do
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      local attacherJoint = implement.object.attacherJoint
      if jointDesc.topArm ~= nil and attacherJoint.topReferenceNode ~= nil then
        local ax, ay, az = getWorldTranslation(jointDesc.topArm.rotationNode)
        local bx, by, bz = getWorldTranslation(attacherJoint.topReferenceNode)
        local x, y, z = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), bx - ax, by - ay, bz - az)
        local upX, upY, upZ = 0, 1, 0
        if math.abs(y) > 0.99 * Utils.vector3Length(x, y, z) then
          upY = 0
          if 0 < y then
            upZ = 1
          else
            upZ = -1
          end
        end
        setDirection(jointDesc.topArm.rotationNode, x * jointDesc.topArm.zScale, y * jointDesc.topArm.zScale, z * jointDesc.topArm.zScale, upX, upY, upZ)
        if jointDesc.topArm.translationNode ~= nil then
          local distance = Utils.vector3Length(ax - bx, ay - by, az - bz)
          setTranslation(jointDesc.topArm.translationNode, 0, 0, (distance - jointDesc.topArm.referenceDistance) * jointDesc.topArm.zScale)
        end
      end
      if jointDesc.bottomArm ~= nil then
        local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode)
        local bx, by, bz = getWorldTranslation(attacherJoint.node)
        local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx - ax, by - ay, bz - az)
        local upX, upY, upZ = 0, 1, 0
        if math.abs(y) > 0.99 * Utils.vector3Length(x, y, z) then
          upY = 0
          if 0 < y then
            upZ = 1
          else
            upZ = -1
          end
        end
        setDirection(jointDesc.bottomArm.rotationNode, x * jointDesc.bottomArm.zScale, y * jointDesc.bottomArm.zScale, z * jointDesc.bottomArm.zScale, upX, upY, upZ)
        if jointDesc.bottomArm.translationNode ~= nil then
          local distance = Utils.vector3Length(ax - bx, ay - by, az - bz)
          setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance - jointDesc.bottomArm.referenceDistance) * jointDesc.bottomArm.zScale)
        end
      end
    end
    local realLightsActive = false
    local lightConesActive = false
    if self:getIsActiveForSound() then
      realLightsActive = self.lightsActive
    else
      lightConesActive = self.lightsActive
    end
    if realLightsActive ~= self.realLightsActive then
      self.realLightsActive = realLightsActive
      for _, light in pairs(self.lights) do
        setVisibility(light, realLightsActive)
      end
    end
    if lightConesActive ~= self.lightConesActive then
      self.lightConesActive = lightConesActive
      for _, lightCone in pairs(self.lightCones) do
        setVisibility(lightCone, lightConesActive)
      end
    end
    if self.beaconLightsActive then
      for _, beaconLight in pairs(self.beaconLights) do
        rotate(beaconLight.node, 0, beaconLight.speed * dt, 0)
      end
    end
  end
  if self.firstTimeRun then
    WheelsUtil.updateWheelsGraphics(self, dt)
  end
  for k, v in pairs(self.specializations) do
    v.update(self, dt)
  end
  for _, v in ipairs(self.specializations) do
    if v.postUpdate ~= nil then
      v.postUpdate(self, dt)
    end
  end
  self.firstTimeRun = true
end
function Vehicle:getAttachedTrailersFillLevelAndCapacity()
  local fillLevel = 0
  local capacity = 0
  local hasTrailer = false
  if self.fillLevel ~= nil and self.capacity ~= nil then
    fillLevel = fillLevel + self.fillLevel
    capacity = capacity + self.capacity
    hasTrailer = true
  end
  if self.manureCapacity ~= nil and self.manureIsFilled ~= nil then
    if self.manureIsFilled then
      fillLevel = fillLevel + self.manureCapacity
    end
    capacity = capacity + self.manureCapacity
    hasTrailer = true
  end
  for k, implement in pairs(self.attachedImplements) do
    local f, c = implement.object:getAttachedTrailersFillLevelAndCapacity()
    if f ~= nil and c ~= nil then
      fillLevel = fillLevel + f
      capacity = capacity + c
      hasTrailer = true
    end
  end
  if hasTrailer then
    return fillLevel, capacity
  end
  return nil
end
function Vehicle:draw()
  for k, v in pairs(self.specializations) do
    v.draw(self)
  end
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:draw()
  end
end
function Vehicle:updateTick(dt)
  self.tickDt = dt
  if self.isServer then
    local hasOwner = self:getOwner() ~= nil
    for i = 1, table.getn(self.components) do
      local x, y, z = getTranslation(self.components[i].node)
      local x_rot, y_rot, z_rot, w_rot = getQuaternion(self.components[i].node)
      if hasOwner or math.abs(x - self.components[i].sentTranslation[1]) > 0.005 or 0.005 < math.abs(y - self.components[i].sentTranslation[2]) or 0.005 < math.abs(z - self.components[i].sentTranslation[3]) or math.abs(x_rot - self.components[i].sentRotation[1]) > 0.1 or math.abs(y_rot - self.components[i].sentRotation[2]) > 0.1 or math.abs(z_rot - self.components[i].sentRotation[3]) > 0.1 then
        self:raiseDirtyFlags(self.vehicleDirtyFlag)
        self.components[i].sentTranslation = {
          x,
          y,
          z
        }
        self.components[i].sentRotation = {
          x_rot,
          y_rot,
          z_rot,
          w_rot
        }
      end
    end
    if table.getn(self.wheels) > 0 then
      local frictionScale = 1
      if self:getIsActive() then
        local upX, cosAngle, upZ = localDirectionToWorld(self.components[1].node, 0, 1, 0)
        if cosAngle < self.dynamicWheelFrictionCosAngleMax then
          frictionScale = math.max((1 - self.dynamicWheelFrictionMinScale) * (cosAngle - self.dynamicWheelFrictionCosAngleMin) / (self.dynamicWheelFrictionCosAngleMax - self.dynamicWheelFrictionCosAngleMin), self.dynamicWheelFrictionMinScale)
        end
      end
      if math.abs(frictionScale - self.wheelFrictionScale) > 0.01 or frictionScale == 1 and self.wheelFrictionScale ~= 1 then
        for i = 1, table.getn(self.wheels) do
          local wheel = self.wheels[i]
          setWheelShapeTireFunction(wheel.node, wheel.wheelShape, false, 1000000 * wheel.lateralStiffness * frictionScale)
          setWheelShapeTireFunction(wheel.node, wheel.wheelShape, true, 1000000 * wheel.longitudalStiffness * frictionScale)
        end
        self.wheelFrictionScale = frictionScale
      end
    end
  end
  if self.isActive then
    for k, implement in pairs(self.attachedImplements) do
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      local jointFrameInvalid = false
      if jointDesc.rotationNode ~= nil then
        local x, y, z = getRotation(jointDesc.rotationNode)
        local rot = {
          x,
          y,
          z
        }
        local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot, jointDesc.minRot, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
        setRotation(jointDesc.rotationNode, unpack(newRot))
        for i = 1, 3 do
          if math.abs(newRot[i] - rot[i]) > 5.0E-4 then
            jointFrameInvalid = true
          end
        end
      end
      if jointDesc.rotationNode2 ~= nil then
        local x, y, z = getRotation(jointDesc.rotationNode2)
        local rot = {
          x,
          y,
          z
        }
        local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot2, jointDesc.minRot2, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
        setRotation(jointDesc.rotationNode2, unpack(newRot))
        for i = 1, 3 do
          if math.abs(newRot[i] - rot[i]) > 5.0E-4 then
            jointFrameInvalid = true
          end
        end
      end
      for k, v in pairs(self.specializations) do
        if v.validateAttacherJoint ~= nil and not jointFrameInvalid then
          jointFrameInvalid = v.validateAttacherJoint(self, implement, jointDesc, dt)
        end
      end
      jointFrameInvalid = jointFrameInvalid or jointDesc.jointFrameInvalid
      if jointFrameInvalid then
        jointDesc.jointFrameInvalid = false
        if self.isServer then
          setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
        end
      end
      if self.isServer and jointDesc.allowsJointLimitMovement then
        local attacherJoint = implement.object.attacherJoint
        if attacherJoint.allowsJointRotLimitMovement then
          local newRotLimit = Utils.getMovedLimitedValues(implement.jointRotLimit, implement.maxRotLimit, implement.minRotLimit, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
          for i = 1, 3 do
            if 5.0E-4 < math.abs(newRotLimit[i] - implement.jointRotLimit[i]) then
              setJointRotationLimit(jointDesc.jointIndex, i - 1, true, -newRotLimit[i], newRotLimit[i])
            end
          end
          implement.jointRotLimit = newRotLimit
        end
        if attacherJoint.allowsJointTransLimitMovement then
          local newTransLimit = Utils.getMovedLimitedValues(implement.jointTransLimit, implement.maxTransLimit, implement.minTransLimit, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
          for i = 1, 3 do
            if 5.0E-4 < math.abs(newTransLimit[i] - implement.jointTransLimit[i]) then
              setJointTranslationLimit(jointDesc.jointIndex, i - 1, true, -newTransLimit[i], newTransLimit[i])
            end
          end
          implement.jointTransLimit = newTransLimit
        end
      end
    end
  end
  for k, v in pairs(self.specializations) do
    if v.updateTick ~= nil then
      v.updateTick(self, dt)
    end
  end
  for _, v in ipairs(self.specializations) do
    if v.postUpdateTick ~= nil then
      v.postUpdateTick(self, dt)
    end
  end
end
function Vehicle:attachImplement(object, jointIndex, noEventSend, index)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(VehicleAttachEvent:new(self, object, jointIndex), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(VehicleAttachEvent:new(self, object, jointIndex))
    end
  end
  local jointDesc = self.attacherJoints[jointIndex]
  local implement = {}
  implement.object = object
  implement.object:onAttach(self)
  implement.jointDescIndex = jointIndex
  if jointDesc.rotationNode ~= nil then
    setRotation(jointDesc.rotationNode, unpack(jointDesc.maxRot))
  end
  if jointDesc.rotationNode2 ~= nil then
    setRotation(jointDesc.rotationNode2, unpack(jointDesc.maxRot2))
  end
  if self.isServer then
    local constr = JointConstructor:new()
    constr:setActors(jointDesc.rootNode, implement.object.attacherJoint.rootNode)
    constr:setJointTransforms(jointDesc.jointTransform, implement.object.attacherJoint.node)
    implement.jointRotLimit = {}
    implement.jointTransLimit = {}
    implement.maxRotLimit = {}
    implement.maxTransLimit = {}
    implement.minRotLimit = {}
    implement.minTransLimit = {}
    if jointDesc.minRotLimit == nil then
      print("Warning: jointDesc.minRotLimit of joint " .. jointIndex .. " was not set in '" .. self.configFileName .. "'")
      jointDesc.minRotLimit = {
        0,
        0,
        0
      }
    end
    if jointDesc.minTransLimit == nil then
      print("Warning: jointDesc.minTransLimit of joint " .. jointIndex .. " was not set in '" .. self.configFileName .. "'")
      jointDesc.minTransLimit = {
        0,
        0,
        0
      }
    end
    for i = 1, 3 do
      local maxRotLimit = jointDesc.maxRotLimit[i] * implement.object.attacherJoint.rotLimitScale[i]
      local minRotLimit = jointDesc.minRotLimit[i] * implement.object.attacherJoint.rotLimitScale[i]
      if implement.object.attacherJoint.fixedRotation then
        maxRotLimit = 0
        minRotLimit = 0
      end
      local maxTransLimit = jointDesc.maxTransLimit[i] * implement.object.attacherJoint.transLimitScale[i]
      local minTransLimit = jointDesc.minTransLimit[i] * implement.object.attacherJoint.transLimitScale[i]
      implement.maxRotLimit[i] = maxRotLimit
      implement.minRotLimit[i] = minRotLimit
      implement.maxTransLimit[i] = maxTransLimit
      implement.minTransLimit[i] = minTransLimit
      constr:setRotationLimit(i - 1, -maxRotLimit, maxRotLimit)
      implement.jointRotLimit[i] = maxRotLimit
      constr:setTranslationLimit(i - 1, true, -maxTransLimit, maxTransLimit)
      implement.jointTransLimit[i] = maxTransLimit
    end
    jointDesc.jointIndex = constr:finalize()
  else
    jointDesc.jointIndex = -1
  end
  jointDesc.moveDown = implement.object.isDefaultLowered
  if index == nil then
    table.insert(self.attachedImplements, implement)
  else
    local numAdd = index - table.getn(self.attachedImplements)
    for i = 1, numAdd do
      table.insert(self.attachedImplements, {})
    end
    self.attachedImplements[index] = implement
  end
  if self.isClient and self.selectedImplement == 0 then
    self.selectedImplement = 1
    implement.object:onSelect()
  end
  for k, v in pairs(self.specializations) do
    if v.attachImplement ~= nil then
      v.attachImplement(self, implement)
    end
  end
end
function Vehicle:detachImplement(implementIndex, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(VehicleDetachEvent:new(self, self.attachedImplements[implementIndex].object), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(VehicleDetachEvent:new(self, self.attachedImplements[implementIndex].object))
    end
  end
  for k, v in pairs(self.specializations) do
    if v.detachImplement ~= nil then
      v.detachImplement(self, implementIndex)
    end
  end
  local implement = self.attachedImplements[implementIndex]
  local jointDesc = self.attacherJoints[implement.jointDescIndex]
  if self.isServer then
    removeJoint(jointDesc.jointIndex)
  end
  jointDesc.jointIndex = 0
  if self.isClient and implementIndex == self.selectedImplement then
    implement.object:onDeselect()
  end
  implement.object:onDetach()
  implement.object = nil
  if self.isClient then
    if jointDesc.topArm ~= nil then
      setRotation(jointDesc.topArm.rotationNode, jointDesc.topArm.rotX, jointDesc.topArm.rotY, jointDesc.topArm.rotZ)
      if jointDesc.topArm.translationNode ~= nil then
        setTranslation(jointDesc.topArm.translationNode, 0, 0, 0)
      end
    end
    if jointDesc.bottomArm ~= nil then
      setRotation(jointDesc.bottomArm.rotationNode, jointDesc.bottomArm.rotX, jointDesc.bottomArm.rotY, jointDesc.bottomArm.rotZ)
      if jointDesc.bottomArm.translationNode ~= nil then
        setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0)
      end
    end
  end
  if self.isServer and jointDesc.rotationNode ~= nil then
    setRotation(jointDesc.rotationNode, unpack(jointDesc.minRot))
  end
  table.remove(self.attachedImplements, implementIndex)
  if self.isClient then
    self.selectedImplement = math.min(self.selectedImplement, table.getn(self.attachedImplements))
    if self.selectedImplement ~= 0 then
      self.attachedImplements[self.selectedImplement].object:onSelect()
    end
  end
end
function Vehicle:detachImplementByObject(object, noEventSend)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].object == object then
      self:detachImplement(i, noEventSend)
      break
    end
  end
end
function Vehicle:getImplementByObject(object)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].object == object then
      return self.attachedImplements[i]
    end
  end
  return nil
end
function Vehicle:setSelectedImplement(selected)
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:onDeselect()
  end
  self.selectedImplement = selected
  self.attachedImplements[selected].object:onSelect()
end
function Vehicle:playAttachSound()
  if self.attachSound ~= nil then
    setSamplePitch(self.attachSound, self.attachSoundPitchOffset)
    playSample(self.attachSound, 1, 1, 0)
  end
end
function Vehicle:playDetachSound()
  if self.attachSound ~= nil then
    setSamplePitch(self.attachSound, self.attachSoundPitchOffset)
    playSample(self.attachSound, 1, 1, 0)
  end
end
function Vehicle:handleAttachEvent()
  if self == g_currentMission.controlledVehicle and g_currentMission.trailerInTipRange ~= nil then
    if g_currentMission.currentTipTrigger ~= nil then
      local fruitType = g_currentMission.trailerInTipRange:getCurrentFruitType()
      if fruitType == FruitUtil.FRUITTYPE_UNKNOWN or g_currentMission.currentTipTrigger.acceptedFruitTypes[fruitType] then
        g_currentMission.trailerInTipRange:toggleTipState(g_currentMission.currentTipTrigger)
      end
    end
  elseif self:handleAttachAttachableEvent() then
    self:playAttachSound()
  elseif self:handleDetachAttachableEvent() then
    self:playDetachSound()
  end
end
function Vehicle:handleAttachAttachableEvent()
  if g_currentMission.attachableInMountRange ~= nil then
    if g_currentMission.attachableInMountRangeVehicle == self then
      if self.attacherJoints[g_currentMission.attachableInMountRangeIndex].jointIndex == 0 then
        self:attachImplement(g_currentMission.attachableInMountRange, g_currentMission.attachableInMountRangeIndex)
        return true
      end
    else
      for i = 1, table.getn(self.attachedImplements) do
        if self.attachedImplements[i].object:handleAttachAttachableEvent() then
          return true
        end
      end
    end
  end
  return false
end
function Vehicle:handleDetachAttachableEvent()
  if self.selectedImplement ~= 0 then
    local attachable = self.attachedImplements[self.selectedImplement].object
    if not Input.isKeyPressed(Input.KEY_shift) and attachable:handleDetachAttachableEvent() then
      return true
    end
    local implement = self.attachedImplements[self.selectedImplement]
    if implement.object.allowsDetaching then
      self:detachImplement(self.selectedImplement)
      return true
    end
  end
  return false
end
function Vehicle:handleLowerImplementEvent()
  if self.selectedImplement ~= 0 then
    local implement = self.attachedImplements[self.selectedImplement]
    if implement.object.allowsLowering then
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      if jointDesc.allowsLowering then
        self:setJointMoveDown(implement.jointDescIndex, not jointDesc.moveDown, false)
      end
    end
  end
end
function Vehicle:getAttachedIndexFromJointDescIndex(jointDescIndex)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].jointDescIndex == jointDescIndex then
      return i
    end
  end
  return nil
end
function Vehicle:getImplementIndexByObject(implement)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].object == implement then
      return i
    end
  end
  return nil
end
function Vehicle:setLightsVisibility(visibility, noEventSend)
  if visibility ~= self.lightsActive then
    if noEventSend == nil or noEventSend == false then
      if g_server ~= nil then
        g_server:broadcastEvent(SteerableToggleLightEvent:new(self, visibility), nil, nil, self)
      else
        g_client:getServerConnection():sendEvent(SteerableToggleLightEvent:new(self, visibility))
      end
    end
    self.lightsActive = visibility
    self.realLightsActive = false
    if not visibility or self:getIsActiveForSound() then
      self.realLightsActive = visibility
      for _, light in pairs(self.lights) do
        setVisibility(light, visibility)
      end
    end
    for _, corona in pairs(self.lightCoronas) do
      setVisibility(corona, visibility)
    end
    self.lightConesActive = false
    for _, lightCone in pairs(self.lightCones) do
      setVisibility(lightCone, false)
    end
    for _, v in pairs(self.attachedImplements) do
      v.object:setLightsVisibility(visibility, true)
    end
    for _, v in pairs(self.specializations) do
      if v.setLightsVisibility ~= nil then
        v.setLightsVisibility(self, visibility)
      end
    end
  end
end
function Vehicle:setBeaconLightsVisibility(visibility, noEventSend)
  if visibility ~= self.beaconLightsActive then
    if noEventSend == nil or noEventSend == false then
      if g_server ~= nil then
        g_server:broadcastEvent(VehicleSetBeaconLightEvent:new(self, visibility), nil, nil, self)
      else
        g_client:getServerConnection():sendEvent(VehicleSetBeaconLightEvent:new(self, visibility))
      end
    end
    self.beaconLightsActive = visibility
    for _, beaconLight in pairs(self.beaconLights) do
      setVisibility(beaconLight.node, visibility)
    end
    for _, v in pairs(self.attachedImplements) do
      v.object:setBeaconLightsVisibility(visibility, true)
    end
    for _, v in pairs(self.specializations) do
      if v.setBeaconLightsVisibility ~= nil then
        v.setBeaconLightsVisibility(self, visibility)
      end
    end
  end
end
function Vehicle:getIsActiveForInput()
  if g_gui.currentGui ~= nil then
    return false
  end
  if self.isEntered then
    return true
  end
  if self.attacherVehicle ~= nil then
    return self.isSelected and self.attacherVehicle:getIsActiveForInput()
  end
  return false
end
function Vehicle:getIsActiveForSound()
  if self.isEntered then
    return true
  end
  if self.attacherVehicle ~= nil then
    return self.attacherVehicle:getIsActiveForSound()
  end
  return false
end
function Vehicle:getIsActive()
  if self.isBroken then
    return false
  end
  if self.isEntered or self.isControlled then
    return true
  end
  if self.attacherVehicle ~= nil then
    return self.attacherVehicle:getIsActive()
  end
  if self.forceIsActive then
    return true
  end
  return false
end
function Vehicle:getIsHired()
  if self.isHired then
    return true
  elseif self.attacherVehicle ~= nil then
    return self.attacherVehicle:getIsHired()
  end
  return false
end
function Vehicle:getOwner()
  if self.owner ~= nil then
    return self.owner
  end
  if self.attacherVehicle ~= nil then
    return self.attacherVehicle:getOwner()
  end
  return nil
end
function Vehicle:onDeactivateAttachements()
  for k, v in pairs(self.attachedImplements) do
    v.object:onDeactivate()
  end
end
function Vehicle:onActivateAttachements()
  for k, v in pairs(self.attachedImplements) do
    v.object:onActivate()
  end
end
function Vehicle:onDeactivateAttachementsSounds()
  for k, v in pairs(self.attachedImplements) do
    v.object:onDeactivateSounds()
  end
end
function Vehicle:onDeactivateAttachementsLights()
  for k, v in pairs(self.attachedImplements) do
    v.object:onDeactivateLights()
  end
end
function Vehicle:onActivate()
  self:onActivateAttachements()
  for k, v in pairs(self.specializations) do
    if v.onActivate ~= nil then
      v.onActivate(self)
    end
  end
end
function Vehicle:onDeactivate()
  self:onDeactivateAttachements()
  for k, v in pairs(self.specializations) do
    if v.onDeactivate ~= nil then
      v.onDeactivate(self)
    end
  end
end
function Vehicle:onDeactivateSounds()
  self:onDeactivateAttachementsSounds()
  for k, v in pairs(self.specializations) do
    if v.onDeactivateSounds ~= nil then
      v.onDeactivateSounds(self)
    end
  end
end
function Vehicle:onDeactivateLights()
  self:onDeactivateAttachementsLights()
  for k, v in pairs(self.specializations) do
    if v.onDeactivateLights ~= nil then
      v.onDeactivateLights(self)
    end
  end
end
function Vehicle:doCheckSpeedLimit()
  if self.attacherVehicle ~= nil then
    return self.checkSpeedLimit and self.attacherVehicle:doCheckSpeedLimit()
  end
  return self.checkSpeedLimit
end
function Vehicle:isLowered(default)
  if self.attacherVehicle ~= nil then
    local implement = self.attacherVehicle:getImplementByObject(self)
    if implement ~= nil then
      local jointDesc = self.attacherVehicle.attacherJoints[implement.jointDescIndex]
      if jointDesc.allowsLowering then
        return jointDesc.moveDown or self.attacherVehicle:isLowered(default)
      end
    end
  end
  return default
end
function Vehicle:setJointMoveDown(jointDescIndex, moveDown, noEventSend)
  VehicleLowerImplementEvent.sendEvent(self, jointDescIndex, moveDown, noEventSend)
  local jointDesc = self.attacherJoints[jointDescIndex]
  jointDesc.moveDown = moveDown
  local implementIndex = self:getAttachedIndexFromJointDescIndex(jointDescIndex)
  if implementIndex ~= nil then
    local implement = self.attachedImplements[implementIndex]
    if implement.object.onSetLowered ~= nil then
      implement.object:onSetLowered(moveDown)
    end
  end
end
function Vehicle:getIsVehicleNode(nodeId)
  return self.vehicleNodes[nodeId] ~= nil
end
function Vehicle:getIsAttachedVehicleNode(nodeId)
  if self.vehicleNodes[nodeId] ~= nil then
    return true
  end
  for _, v in pairs(self.attachedImplements) do
    if v.object:getIsAttachedVehicleNode(nodeId) then
      return true
    end
  end
  return false
end
function Vehicle:setComponentsVisibility(visiblity)
  if self.componentsVisibility ~= visiblity then
    self.componentsVisibility = visiblity
    for k, v in pairs(self.components) do
      setVisibility(v.node, visiblity)
      if visiblity then
        addToPhysics(v.node)
      else
        removeFromPhysics(v.node)
      end
    end
  end
end
function Vehicle:getIsAreaActive(area)
  return true
end
function Vehicle.consoleCommandToggleDebugRendering(unusedSelf)
  Vehicle.debugRendering = not Vehicle.debugRendering
  return "VehicleDebugRendering = " .. tostring(Vehicle.debugRendering)
end
addConsoleCommand("gsVehicleToggleDebugRendering", "Toggles the debug rendering of the vehicles", "Vehicle.consoleCommandToggleDebugRendering", nil)
