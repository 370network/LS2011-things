Herd = {
  visibleAnimalsByVisualClass = {}
}
Herd.visibleAnimalsByVisualClass[AnimalHusbandry.VISUALCLASS_LOW] = {
  {real = 0, visible = 0},
  {real = 5, visible = 5},
  {real = 100, visible = 8},
  {real = 200, visible = 10}
}
Herd.visibleAnimalsByVisualClass[AnimalHusbandry.VISUALCLASS_MEDIUM] = {
  {real = 0, visible = 0},
  {real = 7, visible = 7},
  {real = 100, visible = 12},
  {real = 200, visible = 14}
}
Herd.visibleAnimalsByVisualClass[AnimalHusbandry.VISUALCLASS_HIGH] = {
  {real = 0, visible = 0},
  {real = 9, visible = 9},
  {real = 100, visible = 15},
  {real = 200, visible = 18}
}
Herd.visibleAnimalsByVisualClass[AnimalHusbandry.VISUALCLASS_VERY_HIGH] = {
  {real = 0, visible = 0},
  {real = 10, visible = 10},
  {real = 100, visible = 16},
  {real = 200, visible = 20}
}
local Herd_mt = Class(Herd, Agent)
function Herd:new(animalDefinitionFilename, presets_hash)
  presets_hash = presets_hash or {}
  if self == Herd then
    self = setmetatable({}, Herd_mt)
  end
  presets_hash.type = presets_hash.type or EntityType.HERD
  presets_hash.name = "herd"
  self.objectId = createTransformGroup("Herd")
  self:_loadAnimalDefinitionFile(animalDefinitionFilename)
  AnimalHusbandry.herd = {}
  AnimalHusbandry.herd.defaultNavMeshId = presets_hash.defaultNavMeshId
  presets_hash.positionX, presets_hash.positionY, presets_hash.positionZ = getNavMeshRandomPosition(presets_hash.defaultNavMeshId)
  Herd:superClass().new(self, presets_hash)
  setTranslation(self.objectId, self.positionX, self.positionY, self.positionZ)
  link(getRootNode(), self.objectId)
  self.animals = {}
  self.visibleAnimals = {}
  self.maxNumberOfAnimals = presets_hash.maxNumberOfAnimals
  self.uniqueHerdAnimalId = 0
  self.groundObjectId = presets_hash.groundObjectId
  self.defaultNavMeshId = presets_hash.defaultNavMeshId
  local navMeshHash = presets_hash.navMeshHash
  self.navMeshByStateHash = {}
  for state, _ in pairs(StateRepository.states) do
    if navMeshHash[state.name] then
      self.navMeshByStateHash[state] = navMeshHash[state.name]
    else
      self.navMeshByStateHash[state] = self.defaultNavMeshId
    end
  end
  self.useAI = presets_hash.useAI or true
  self.useUpdateToNetwork = presets_hash.useUpdateToNetwork or false
  self.useUpdateFromNetwork = presets_hash.useUpdateFromNetwork or false
  self:setUpdateAgentFunction()
  self.visibilityFactor = 1
  self.lastVisibilityFactor = 1
  self.distanceFactor = 1
  self.lastDistanceFactor = 1
  self.isVisible = true
  self.availableNames = {}
  self.remainingNames = {}
  if AnimalHusbandry.useAnimalAI then
    for _, name in ipairs(self.animalNameList) do
      if type(name) ~= "string" then
        print(string.format("error loading herd animal name (%s)", tostring(name)))
      else
        self.availableNames[name] = {1}
      end
    end
    if not next(self.availableNames) then
      print("error loading herd animal names")
    end
  end
  if AnimalHusbandry.useAnimalVisualization then
    self.animationNavMesh = navMeshHash.Animation or self.defaultNavMeshId
    if not self.animationNavMesh then
      print("Error: Herd needs NavMesh with the name \"Animation\"")
    end
  end
  return self
end
function Herd:dispose()
  for i = 1, table.getn(self.animals) do
    self:removeAnimalByIndex(1)
  end
  if AnimalHusbandry.useAnimalVisualization then
    delete(self.animalFactoryId)
    self.animalFactoryId = nil
  end
end
function Herd:setUpdateAgentFunction()
  local functionString = "local self, dt = ...; "
  if self.useAI then
    functionString = functionString .. "self:recalculateMovement(); "
  end
  if self.useUpdateFromNetwork then
    functionString = functionString .. "self:updateFromNetwork(); "
  end
  if self.useUpdateToNetwork then
    functionString = functionString .. "self:updateToNetwork(); "
  end
  local updateAgentFunction = loadstring(functionString)
  self.updateAgent = updateAgentFunction
end
function Herd:updateToNetwork()
end
function Herd:updateFromNetwork()
end
function Herd:recalculateMovement()
  local animalCount = table.getn(self.visibleAnimals)
  if 0 < animalCount then
    self.velocityX, self.velocityY, self.velocityZ = 0, 0, 0
    self.positionX, self.positionY, self.positionZ = 0, 0, 0
    for _, animal in ipairs(self.visibleAnimals) do
      self.velocityX, self.velocityY, self.velocityZ = self.velocityX + animal.velocityX, self.velocityY + animal.velocityY, self.velocityZ + animal.velocityZ
      self.positionX, self.positionY, self.positionZ = self.positionX + animal.positionX, self.positionY + animal.positionY, self.positionZ + animal.positionZ
    end
    self.velocityX, self.velocityY, self.velocityZ = self.velocityX / animalCount, self.velocityY / animalCount, self.velocityZ / animalCount
    self.positionX, self.positionY, self.positionZ = self.positionX / animalCount, self.positionY / animalCount, self.positionZ / animalCount
    setTranslation(self.objectId, self.positionX, self.positionY, self.positionZ)
  end
end
function Herd:calculateVisibility()
  self.lastDistanceFactor = self.distanceFactor
  self.lastVisibilityFactor = self.visibilityFactor
  local maxDistance = 500
  local minDistance = maxDistance
  for _, player in pairs(AnimalHusbandry.playerWrappers) do
    local dx, dy, dz = self.positionX - player.positionX, self.positionY - player.positionY, self.positionZ - player.positionZ
    local distance = Utils.vector3Length(dx, dy, dz)
    minDistance = math.min(minDistance, distance)
  end
  self.distanceFactor = 1 - math.min(1, minDistance / maxDistance)
end
function Herd:getNewName()
  local newName = table.remove(self.remainingNames, 1)
  if not newName then
    for name, idList in pairs(self.availableNames) do
      local addedNameCount = table.getn(self.remainingNames)
      local randomIndex = addedNameCount == 0 and 1 or math.random(1, addedNameCount)
      table.insert(self.remainingNames, randomIndex, name)
    end
    newName = table.remove(self.remainingNames, 1)
  end
  local nameIdList = self.availableNames[newName]
  local newNameId
  if table.getn(nameIdList) == 1 then
    newNameId = nameIdList[1]
    nameIdList[1] = newNameId + 1
  else
    newNameId = table.remove(nameIdList, 1)
  end
  local newBaseName = newName
  newName = newNameId <= 1 and newBaseName or newBaseName .. newNameId
  return newName, newBaseName, newNameId
end
function Herd:freeOldName(baseName, nameId)
  if not self.availableNames[baseName] then
    print(string.format("error: base name that should be freed is not known (%s)", baseName))
  end
  local idList = self.availableNames[baseName]
  table.insert(idList, nameId)
  table.sort(idList)
  for i = table.getn(idList), 2, -1 do
    local lastIndex = idList[i]
    local secondLastIndex = idList[i - 1]
    if lastIndex == secondLastIndex + 1 then
      table.remove(idList)
    end
  end
  table.insert(self.remainingNames, baseName)
end
function Herd:printNames()
  print(string.format("availableNames:"))
  for name, idList in pairs(self.availableNames) do
    local idString = ""
    for index, value in ipairs(idList) do
      idString = idString .. value .. " "
    end
    print(string.format("%s - %s", name, idString))
  end
  print(string.format("remainingNames:"))
  for i, name in ipairs(self.remainingNames) do
    print(string.format("%d. - %s", i, name))
  end
  print("----------------")
end
function Herd:_loadAnimalDefinitionFile(animalDefinitionFilename)
  local xmlFile = loadXMLFile("AnimalDefinitions", animalDefinitionFilename)
  if not xmlFile or xmlFile <= 0 then
    print(string.format("   error loading animal definition file (%s)", animalDefinitionFilename))
  end
  local baseName = "AnimalDefinition"
  local animalName = getXMLString(xmlFile, baseName .. "#name")
  local meshBaseName = baseName .. ".Mesh"
  if AnimalHusbandry.useAnimalAI then
    self.animalSpeedWander = getXMLFloat(xmlFile, baseName .. "#speedWander")
    self.animalSpeedWalk = getXMLFloat(xmlFile, baseName .. "#speedWalk")
    self.animalSpeedRace = getXMLFloat(xmlFile, baseName .. "#speedRace")
    self.animalAccelerationWander = getXMLFloat(xmlFile, baseName .. "#accelerationWander")
    self.animalAccelerationWalk = getXMLFloat(xmlFile, baseName .. "#accelerationWalk")
    self.animalAccelerationRace = getXMLFloat(xmlFile, baseName .. "#accelerationRace")
    local animalNameList = {}
    local namesBasicNode = baseName .. ".NameList"
    local useI18N = getXMLBool(xmlFile, meshBaseName .. "#useI18N")
    if useI18N then
      local languagePrefix = getXMLString(xmlFile, meshBaseName .. "#languagePrefix")
      local minIndex = Utils.getNoNil(getXMLInt(xmlFile, meshBaseName .. "#minIndex"), 1)
      local maxIndex = getXMLInt(xmlFile, meshBaseName .. "#maxIndex")
      if not languagePrefix then
        print(string.format("   error: loading I18N animal names, no language prefix was specified"))
      end
      if not maxIndex then
        print(string.format("   error: loading I18N animal names, no maximum index was specified"))
      end
      for i = minIndex, maxIndex do
        local languageIdentifier = languagePrefix .. i
        local animalName = g_i18n:getText(languageIdentifier)
        if self:_isValidAnimalName(animalName) then
          table.insert(animalNameList, animalName)
        else
          print(string.format("   error: animal name %s is not valid", animalName))
        end
      end
    else
      local nameId = 0
      while true do
        local nameNode = namesBasicNode .. string.format(".Name(%d)", nameId)
        if not hasXMLProperty(xmlFile, nameNode) then
          break
        end
        local name = getXMLString(xmlFile, nameNode .. "#name")
        if not name then
          print(string.format("   error: loading animal names, name node has no name attribute"))
        end
        if self:_isValidAnimalName(name) then
          table.insert(animalNameList, name)
        else
          print(string.format("   error: animal name %s is not valid", name))
        end
        nameId = nameId + 1
      end
    end
    if table.getn(animalNameList) == 0 then
      print(string.format("   error: no names specified/loaded, using default"))
      table.insert(animalNameList, "Animal")
    end
    self.animalNameList = animalNameList
  end
  if AnimalHusbandry.useAnimalVisualization then
    local meshI3dFilename = getXMLString(xmlFile, meshBaseName .. "#i3d")
    local meshIndex = getXMLString(xmlFile, meshBaseName .. "#meshIndex")
    local rootBoneIndex = getXMLString(xmlFile, meshBaseName .. "#rootBoneIndex")
    local translationMarkerIndex = getXMLString(xmlFile, meshBaseName .. "#translationMarkerIndex")
    local boundingBoxIndex = getXMLString(xmlFile, meshBaseName .. "#boundingBoxIndex")
    local animationDefinitionFilename = getXMLString(xmlFile, baseName .. ".AnimationData#xml")
    if not meshBaseName then
      print(string.format("   error: mesh base name was not specified"))
    end
    if not meshIndex then
      print(string.format("   error: mesh index was not specified"))
    end
    if not rootBoneIndex then
      print(string.format("   error: root bone index was not specified"))
    end
    if not translationMarkerIndex then
      print(string.format("   error: translation marker index was not specified"))
    end
    if not boundingBoxIndex then
      print(string.format("   error: bounding box index was not specified"))
    end
    if not animationDefinitionFilename then
      print(string.format("   error: animation definitions filename was not specified"))
    end
    local animalI3d = loadI3DFile(meshI3dFilename)
    if not animalI3d or animalI3d <= 0 then
      print(string.format("   error: loading animal mesh file (%s)", tostring(meshI3dFilename)))
    end
    local meshId = Utils.indexToObject(animalI3d, meshIndex)
    if not meshId or meshId <= 0 then
      print(string.format("   error: loading animal mesh failed, mesh index seems incorrect (%s)", tostring(meshIndex)))
    end
    local rootBoneId = Utils.indexToObject(animalI3d, rootBoneIndex)
    if not rootBoneId or rootBoneId <= 0 then
      print(string.format("   error: loading animal mesh failed, root bone index seems incorrect (%s)", tostring(rootBoneIndex)))
    end
    local translationMarkerId = Utils.indexToObject(animalI3d, translationMarkerIndex)
    if not translationMarkerId or translationMarkerId <= 0 then
      print(string.format("   error: loading animal mesh failed, translation marker index seems incorrect (%s)", tostring(translationMarkerIndex)))
    end
    local boundingBoxId = Utils.indexToObject(animalI3d, boundingBoxIndex)
    if not boundingBoxId or boundingBoxId <= 0 then
      print(string.format("   error: loading animal mesh failed, bounding box index seems incorrect (%s)", tostring(boundingBoxIndex)))
    end
    unlink(meshId)
    unlink(rootBoneId)
    unlink(translationMarkerId)
    unlink(boundingBoxId)
    delete(animalI3d)
    self.animalFactoryId = createTransformGroup(animalName .. "Factory")
    link(self.animalFactoryId, meshId)
    link(self.animalFactoryId, rootBoneId)
    setVisibility(animationId, false)
    link(self.animalFactoryId, translationMarkerId)
    link(self.animalFactoryId, boundingBoxId)
    setRigidBodyType(meshId, "NoRigidBody")
    setRigidBodyType(rootBoneId, "NoRigidBody")
    setRigidBodyType(translationMarkerId, "NoRigidBody")
    setRigidBodyType(boundingBoxId, "Kinematic")
    local xmlFile = loadXMLFile("AnimalAnimations", animationDefinitionFilename)
    local ambientSoundNode = AnimalSoundManager.loadFromXML(xmlFile)
    link(self.objectId, ambientSoundNode)
    local rootBoneId = getChildAt(self.animalFactoryId, 1)
    AnimationControl.initialize(rootBoneId, animationDefinitionFilename)
  end
  delete(xmlFile)
end
function Herd:_isValidAnimalName(animalName)
  return string.len(animalName) > 0 and string.find(animalName, "(%d+)") == nil
end
function Herd:_getAnimalBaseNameAndCount(animalName)
  local animalBaseName, animalBaseNameCount
  if string.find(animalName, "(%d+)") == nil then
    animalBaseName = animalName
    animalBaseNameCount = 1
  else
    animalBaseName = string.gmatch(animalName, "(%a+)%d+")()
    animalBaseNameCount = string.gmatch(animalName, "%a+(%d+)")()
  end
  return animalBaseName, animalBaseNameCount
end
function Herd:addAnimal(newAnimalName, newAnimalPositionX, newAnimalPositionY, newAnimalPositionZ, newAnimalDirectionX, newAnimalDirectionY, newAnimalDirectionZ, newAnimalAppearanceId, newAnimalIsVisible)
  if table.getn(self.animals) >= self.maxNumberOfAnimals then
    return nil
  end
  local animalName, animalBaseName, animalNameCount
  if newAnimalName == nil then
    animalName, animalBaseName, animalNameCount = self:getNewName()
  else
    animalName, animalBaseName, animalNameCount = newAnimalName, self:_getAnimalBaseNameAndCount(newAnimalName)
  end
  local isNewAnimalVirtual = true
  if newAnimalIsVisible ~= nil then
    isNewAnimalVirtual = not newAnimalIsVisible
  elseif AnimalHusbandry.useAnimalVisualization or AnimalHusbandry.useAnimalAI then
    local oldAnimalCount = table.getn(self.animals)
    local newAnimalCount = oldAnimalCount + 1
    local oldVisibleAnimalCount = Herd.getVisualAnimalCountForTotalAnimalCount(AnimalHusbandry.visualClass, oldAnimalCount)
    local newVisibleAnimalCount = Herd.getVisualAnimalCountForTotalAnimalCount(AnimalHusbandry.visualClass, newAnimalCount)
    isNewAnimalVirtual = oldVisibleAnimalCount >= newVisibleAnimalCount
  end
  local animal = {
    name = animalName,
    baseName = animalBaseName,
    baseNameCount = animalNameCount
  }
  table.insert(self.animals, animal)
  if not isNewAnimalVirtual then
    local newAnimalId, animalMeshId, animalAnimationId, animalTranslationMarkerId, animalBonesId, animalBoundingBoxId
    if AnimalHusbandry.useAnimalVisualization then
      newAnimalId = clone(self.animalFactoryId, false)
      animalMeshId = getChildAt(newAnimalId, 0)
      animalAnimationId = getChildAt(newAnimalId, 1)
      animalTranslationMarkerId = getChildAt(newAnimalId, 2)
      animalBoundingBoxId = getChildAt(newAnimalId, 3)
      animalBonesId = createTransformGroup("BonesDisplacement")
      link(animalBonesId, animalAnimationId)
      link(animalBonesId, animalBoundingBoxId)
      link(getRootNode(), animalMeshId)
      link(getRootNode(), animalBonesId)
      link(getRootNode(), animalTranslationMarkerId)
      delete(newAnimalId)
    end
    local positionX, positionY, positionZ
    if newAnimalPositionX and newAnimalPositionY and newAnimalPositionZ then
      positionX, positionY, positionZ = newAnimalPositionX, newAnimalPositionY, newAnimalPositionZ
    else
      positionX, positionY, positionZ = AnimalHusbandry.getSpawnPlaceRandomPosition()
    end
    local directionX, directionY, directionZ
    if newAnimalDirectionX and newAnimalDirectionY and newAnimalDirectionZ then
      directionX, directionY, directionZ = newAnimalDirectionX, newAnimalDirectionY, newAnimalDirectionZ
    else
      local angle = math.random() * math.pi * 2
      directionX, directionY, directionZ = math.sin(angle), 0, math.cos(angle)
    end
    local visibleAnimal = Animal:new({
      name = animalName,
      baseName = animalBaseName,
      baseNameCount = animalNameCount,
      bonesId = animalBonesId,
      meshId = animalMeshId,
      animationId = animalAnimationId,
      translationMarkerId = animalTranslationMarkerId,
      boundingBoxId = animalBoundingBoxId,
      herd = AnimalHusbandry.herd,
      positionX = positionX,
      positionY = positionY,
      positionZ = positionZ,
      directionX = directionX,
      directionY = directionY,
      directionZ = directionZ,
      [AnimalMotionData.SPEED_WANDER] = self.animalSpeedWander,
      [AnimalMotionData.SPEED_WALK] = self.animalSpeedWalk,
      [AnimalMotionData.SPEED_RACE] = self.animalSpeedRace,
      [AnimalMotionData.ACCELERATION_WANDER] = self.animalAccelerationWander,
      [AnimalMotionData.ACCELERATION_WALK] = self.animalAccelerationWalk,
      [AnimalMotionData.ACCELERATION_RACE] = self.animalAccelerationRace,
      appearanceId = newAnimalAppearanceId,
      useAI = AnimalHusbandry.useAnimalAI,
      useVisualization = AnimalHusbandry.useAnimalVisualization,
      useUpdateToNetwork = AnimalHusbandry.useUpdateToNetwork,
      useUpdateFromNetwork = AnimalHusbandry.useUpdateFromNetwork
    })
    self.uniqueHerdAnimalId = self.uniqueHerdAnimalId + 1
    table.insert(self.visibleAnimals, visibleAnimal)
    animal.isVisible = true
    animal.visibleListId = table.getn(self.visibleAnimals)
  else
    animal.isVirtual = true
  end
  return animalName
end
function Herd:removeAnimal(arg)
  if arg == nil then
    return self:removeAnimalByIndex(1)
  elseif type(arg) == "string" then
    return self:removeAnimalByName(arg)
  elseif type(arg) == "number" then
    return self:removeAnimalByIndex(arg)
  else
    print("error: invalid argument provided to remove an animal")
  end
end
function Herd:removeAnimalByName(animalName)
  local animalToRemoveIndex
  local animalFound = false
  for i, animal in ipairs(self.animals) do
    if animal.name == animalName then
      animalToRemoveIndex = i
      animalFound = true
      break
    end
  end
  if not animalFound then
    print(string.format("error: specified animal to remove (%s) was not found", animalName))
    return
  end
  return self:removeAnimalByIndex(animalToRemoveIndex)
end
function Herd:removeAnimalByIndex(animalToRemoveIndex)
  local animalToRemove = self.animals[animalToRemoveIndex]
  local isRemovedAnimalVisible = animalToRemove.isVisible
  if isRemovedAnimalVisible then
    local visibleAnimalCountDidNotChange = false
    if AnimalHusbandry.useAnimalVisualization or AnimalHusbandry.useAnimalAI then
      local oldAnimalCount = table.getn(self.animals)
      local newAnimalCount = oldAnimalCount - 1
      local oldVisibleAnimalCount = Herd.getVisualAnimalCountForTotalAnimalCount(AnimalHusbandry.visualClass, oldAnimalCount)
      local newVisibleAnimalCount = Herd.getVisualAnimalCountForTotalAnimalCount(AnimalHusbandry.visualClass, newAnimalCount)
      visibleAnimalCountDidNotChange = newVisibleAnimalCount == oldVisibleAnimalCount
    end
    local visibleAnimal = animalToRemove
    local visibleAnimalData = self.visibleAnimals[animalToRemove.visibleListId]
    if visibleAnimalCountDidNotChange then
      local virtualAnimal, virtualAnimalIndex
      local virtualAnimalFound = false
      for i, animal in ipairs(self.animals) do
        if animal.isVirtual then
          virtualAnimal = animal
          virtualAnimalIndex = i
          virtualAnimalFound = true
          break
        end
      end
      if not virtualAnimalFound then
        print("error on virtual animal setup")
      end
      visibleAnimal.name, virtualAnimal.name = virtualAnimal.name, visibleAnimal.name
      visibleAnimal.baseName, virtualAnimal.baseName = virtualAnimal.baseName, visibleAnimal.baseName
      visibleAnimal.baseNameCount, virtualAnimal.baseNameCount = virtualAnimal.baseNameCount, visibleAnimal.baseNameCount
      visibleAnimalData.name = visibleAnimal.name
      visibleAnimalData.baseName = visibleAnimal.baseName
      visibleAnimalData.baseNameCount = visibleAnimal.baseNameCount
      animalToRemove = virtualAnimal
      animalToRemoveIndex = virtualAnimalIndex
    else
      visibleAnimalData:delete()
      table.remove(self.visibleAnimals, visibleAnimal.visibleListId)
      for i = animalToRemoveIndex, table.getn(self.animals) do
        local animal = self.animals[i]
        if animal.isVisible then
          animal.visibleListId = animal.visibleListId - 1
        end
      end
    end
  end
  table.remove(self.animals, animalToRemoveIndex)
  if AnimalHusbandry.useAnimalAI then
    self:freeOldName(animalToRemove.baseName, animalToRemove.baseNameCount)
  end
end
function Herd:getAnimalByName(animalName)
  local foundAnimal
  for i, animal in ipairs(self.animals) do
    if animal.name == animalName then
      foundAnimal = animal
      break
    end
  end
  local isVisible = foundAnimal.isVisible or false
  if isVisible then
    foundAnimal = self.visibleAnimals[foundAnimal.visibleListId]
  end
  return foundAnimal, isVisible
end
function Herd.getVisualAnimalCountForTotalAnimalCount(visualClass, totalAnimalCount)
  local visibleAnimalsData = Herd.visibleAnimalsByVisualClass[visualClass]
  local found = false
  local lowerIndex = 1
  local upperIndex = 1
  for i, data in ipairs(visibleAnimalsData) do
    if totalAnimalCount >= data.real then
      lowerIndex = i
    end
    if totalAnimalCount <= data.real then
      found = true
      upperIndex = i
      break
    end
  end
  if not found then
    local maxIndex = table.getn(visibleAnimalsData)
    lowerIndex = maxIndex
    upperIndex = maxIndex
  end
  local width = visibleAnimalsData[upperIndex].real - visibleAnimalsData[lowerIndex].real
  local factor = width == 0 and 1 or (totalAnimalCount - visibleAnimalsData[lowerIndex].real) / width
  local visibleAnimalCount = visibleAnimalsData[lowerIndex].visible * (1 - factor) + visibleAnimalsData[upperIndex].visible * factor
  return math.floor(visibleAnimalCount + 0.5)
end
