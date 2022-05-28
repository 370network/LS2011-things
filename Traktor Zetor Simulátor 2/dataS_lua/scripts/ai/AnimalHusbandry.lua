AnimalHusbandry = {
  VISUALCLASS_LOW = "low",
  VISUALCLASS_MEDIUM = "medium",
  VISUALCLASS_HIGH = "high",
  VISUALCLASS_VERY_HIGH = "very high",
  startleAnimalSounds = {
    {
      filename = "dataS2/character/cow/cowBoyWhistle01.wav",
      minVolume = 0.75,
      maxVolume = 1,
      minPitch = 0.75,
      maxPitch = 1.25
    },
    {
      filename = "dataS2/character/cow/cowBoyWhistle02.wav",
      minVolume = 0.75,
      maxVolume = 1,
      minPitch = 0.75,
      maxPitch = 1.25
    },
    {
      filename = "dataS2/character/cow/cowBoyWhistle03.wav",
      minVolume = 0.75,
      maxVolume = 1,
      minPitch = 0.75,
      maxPitch = 1.25
    }
  }
}
function getNavMeshRandomPosition(navMesh)
  local positionX, positionY, positionZ = getWorldTranslation(AnimalHusbandry.herd.defaultNavMeshId)
  if not isInsideNavMesh(navMesh, positionX, positionY, positionZ) then
    print("Error: Getting random navmesh position")
    return
  end
  local maxDistance = 150
  local randomNumber = math.random()
  randomNumber = 1 - randomNumber * randomNumber
  local currentMaxDistance = randomNumber * maxDistance
  local angle = math.random() * math.pi
  local directionX, directionY, directionZ = math.sin(angle), 0, math.cos(angle)
  local stepDistance = maxDistance / 10
  local currentDistance = 0
  while currentMaxDistance > currentDistance do
    local newPositionX, newPositionY, newPositionZ = positionX + directionX * stepDistance, positionY + directionY * stepDistance, positionZ + directionZ * stepDistance
    if not isInsideNavMesh(navMesh, newPositionX, newPositionY, newPositionZ) then
      break
    end
    positionX, positionY, positionZ = newPositionX, newPositionY, newPositionZ
    currentDistance = currentDistance + stepDistance
  end
  return positionX, positionY, positionZ
end
function AnimalHusbandry.getSpawnPlaceRandomPosition()
  local positionIsAvailable = false
  local maxTries = math.min(3, table.getn(AnimalHusbandry.spawnPositions))
  local currentTries = 0
  local positionX, positionY, positionZ
  while not positionIsAvailable and maxTries > currentTries do
    positionX, positionY, positionZ = AnimalHusbandry.getNextSpawnPosition()
    positionIsAvailable = true
    for i, animalData in ipairs(AnimalHusbandry.herd.visibleAnimals) do
      local distance = Utils.vector3Length(animalData.positionX - positionX, animalData.positionY - positionY, animalData.positionZ - positionZ)
      if distance < 2 then
        positionIsAvailable = false
        break
      end
    end
    currentTries = currentTries + 1
  end
  return positionX, positionY, positionZ
end
function AnimalHusbandry.getNextSpawnPosition()
  local spawnPosition = AnimalHusbandry.spawnPositions[AnimalHusbandry.spawnPositionNextId]
  AnimalHusbandry.spawnPositionNextId = AnimalHusbandry.spawnPositionNextId % table.getn(AnimalHusbandry.spawnPositions) + 1
  local positionX, positionY, positionZ = spawnPosition[1], spawnPosition[2], spawnPosition[3]
  return positionX, positionY, positionZ
end
function isInsideNavMesh(navMesh, positionX, positionY, positionZ, ttt)
  local distanceToWall = getNavMeshDistanceToWall(navMesh, positionX, positionY, positionZ, 100, "")
  if ttt then
    local distanceToWall1 = getNavMeshDistanceToWall(navMesh, positionX, positionY, positionZ, 100, "")
    local distanceToWall2 = getNavMeshDistanceToWall(navMesh, positionX, positionY, positionZ, 100, "navMeshObstacleCallback", NavMeshLimiterController)
    local distanceToWall3 = getNavMeshDistanceToWall(navMesh, positionX, positionY, positionZ, 10, "")
    local distanceToWall4 = getNavMeshDistanceToWall(navMesh, positionX, positionY, positionZ, 10, "navMeshObstacleCallback", NavMeshLimiterController)
    print(string.format("distanceToWall1 %.2f", distanceToWall1))
    print(string.format("distanceToWall2 %.2f", distanceToWall2))
    print(string.format("distanceToWall3 %.2f", distanceToWall3))
    print(string.format("distanceToWall4 %.2f", distanceToWall4))
  end
  return 0 < distanceToWall
end
function AnimalHusbandry.initialize(presetsHash)
  presetsHash = presetsHash or {}
  local isMultiplayerGame = g_currentMission.missionDynamicInfo.isMultiplayer
  local gpuClass = isMultiplayerGame and "low" or presetsHash.gpuClass or getGPUPerformanceClass()
  if gpuClass == "auto" then
    gpuClass = getAutoGPUPerformanceClass()
  end
  gpuClass = string.lower(gpuClass)
  if gpuClass == "low" then
    AnimalHusbandry.visualClass = AnimalHusbandry.VISUALCLASS_LOW
  elseif gpuClass == "medium" then
    AnimalHusbandry.visualClass = AnimalHusbandry.VISUALCLASS_MEDIUM
  elseif gpuClass == "high" then
    AnimalHusbandry.visualClass = AnimalHusbandry.VISUALCLASS_HIGH
  elseif gpuClass == "very high" then
    AnimalHusbandry.visualClass = AnimalHusbandry.VISUALCLASS_VERY_HIGH
  else
    print(string.format("error: unknown gpuClass %s", tostring(gpuClass)))
  end
  g_agentManager = AgentManager:new()
  ClockWrapper:initialize()
  AnimalHusbandry.time = 0
  AnimalHusbandry.playerWrappers = {}
  AnimalHusbandry.isInUse = true
end
function AnimalHusbandry:delete()
  AnimalHusbandry.dispose()
end
function AnimalHusbandry.addHerd(animalDefinitionFilename, defaultNavMesh, navMeshHash, groundObjectIdToUse, useAnimalAI, useAnimalVisualization, useUpdateToNetwork, useUpdateFromNetwork, maxNumberOfAnimals, initialNumberOfAnimals, spawnPositionNodeList)
  if AnimalHusbandry.herd ~= nil then
    print("Error: AnimalHusbandry currently only one herd is allowed")
  end
  if not animalDefinitionFilename or type(animalDefinitionFilename) ~= "string" then
    print(string.format("   error: animal definition filename is invalid (%s)", tostring(animalDefinitionFilename)))
  end
  if not maxNumberOfAnimals or type(maxNumberOfAnimals) ~= "number" then
    print(string.format("   error: maximum number of animals is invalid (%s)", tostring(maxNumberOfAnimals)))
  end
  if not defaultNavMesh or defaultNavMesh == 0 then
    print(string.format("   error: invalid default nav mesh object id specified (%s)", tostring(defaultNavMesh)))
  end
  if navMeshHash and type(navMeshHash) ~= "table" then
    print(string.format("   error: invalid nav mesh hash specified (%s)", tostring(navMeshHash)))
  end
  if not groundObjectIdToUse or groundObjectIdToUse == 0 then
    print(string.format("   error: invalid ground object id specified (%s)", tostring(groundObjectIdToUse)))
  end
  if not spawnPositionNodeList or type(spawnPositionNodeList) ~= "table" or table.getn(spawnPositionNodeList) == 0 then
    print(string.format("   error: invalid ground object id specified (%s)", tostring(groundObjectIdToUse)))
  end
  AnimalHusbandry.groundObjectId = groundObjectIdToUse
  AnimalHusbandry.spawnPositions = {}
  AnimalHusbandry.spawnPositionNextId = 1
  local spawnPositionAdded = false
  for i, positionNode in ipairs(spawnPositionNodeList) do
    local positionX, positionY, positionZ = getWorldTranslation(positionNode)
    if isInsideNavMesh(defaultNavMesh, positionX, positionY, positionZ) then
      positionY = getTerrainHeightAtWorldPos(AnimalHusbandry.groundObjectId, positionX, positionY, positionZ)
      table.insert(AnimalHusbandry.spawnPositions, {
        positionX,
        positionY,
        positionZ
      })
      spawnPositionAdded = true
    end
  end
  if not spawnPositionAdded then
    print(string.format("   error: no valid spawn places specified"))
  end
  AnimalHusbandry.useAnimalAI = useAnimalAI
  AnimalHusbandry.useAnimalVisualization = useAnimalVisualization
  AnimalHusbandry.useUpdateToNetwork = useUpdateToNetwork
  AnimalHusbandry.useUpdateFromNetwork = useUpdateFromNetwork
  if AnimalHusbandry.useAnimalVisualization then
    AnimalSoundManager.init()
  end
  AnimalHusbandry.herd = Herd:new(animalDefinitionFilename, {
    defaultNavMeshId = defaultNavMesh,
    navMeshHash = navMeshHash or {},
    groundObjectId = groundObjectIdToUse,
    availableNamesList = AnimalHusbandry.animalNameList,
    maxNumberOfAnimals = maxNumberOfAnimals,
    useAI = AnimalHusbandry.useAnimalAI
  })
  initialNumberOfAnimals = initialNumberOfAnimals or 0
  for i = 1, initialNumberOfAnimals do
    AnimalHusbandry.addAnimal()
  end
end
function AnimalHusbandry.finalize()
  if AnimalHusbandry.herd ~= nil then
    g_currentMission:addUpdateable(AnimalHusbandry)
    if g_currentMission:getIsServer() then
      for i = 1, g_currentMission.missionInfo.numCows do
        AnimalHusbandry.addAnimal()
      end
    end
    if AnimalHusbandry.useAnimalVisualization then
      AnimalSoundManager.start()
      if table.getn(AnimalHusbandry.herd.visibleAnimals) < AnimalSoundManager.AMBIENTSOUNDS_START_ANIMAL_COUNT then
        AnimalSoundManager.pauseAmbientSounds()
      end
    end
    AnimalHusbandry.prepareFeedingPlaces()
  else
    g_currentMission:addNonUpdateable(AnimalHusbandry)
    print("Warning: No animal husbandry herd was added")
  end
end
function AnimalHusbandry.addPlayer(connection)
  if not AnimalHusbandry.isInUse then
    return
  end
  AnimalHusbandry.playerWrappers[connection] = PlayerWrapper:new(connection)
end
function AnimalHusbandry.removePlayer(connection)
  if not AnimalHusbandry.isInUse then
    return
  end
  if AnimalHusbandry.playerWrappers[connection] ~= nil then
    AnimalHusbandry.playerWrappers[connection]:delete()
    AnimalHusbandry.playerWrappers[connection] = nil
  end
end
function AnimalHusbandry.dispose()
  g_currentMission:removeUpdateable(AnimalHusbandry)
  g_currentMission:removeNonUpdateable(AnimalHusbandry)
  AnimalHusbandry.clearFeedingPlaces()
  AnimalHusbandry.spawnPositions = nil
  if AnimalHusbandry.herd ~= nil then
    AnimalHusbandry.herd:dispose()
    AnimalHusbandry.herd = nil
  end
  if AnimalHusbandry.useAnimalVisualization then
    AnimalSoundManager.delete()
  end
  AnimationControl.dispose()
  for _, player in pairs(AnimalHusbandry.playerWrappers) do
    player:delete()
  end
  AnimalHusbandry.playerWrappers = {}
  delete(AnimalHusbandry.groundObjectId)
  AnimalHusbandry.groundObjectId = nil
  AnimalHusbandry.useAnimalAI = nil
  AnimalHusbandry.useAnimalVisualization = nil
  AnimalHusbandry.useUpdateToNetwork = nil
  AnimalHusbandry.useUpdateFromNetwork = nil
  AnimalHusbandry.maxNumberOfAnimals = nil
  AnimalHusbandry.isInUse = false
end
function AnimalHusbandry:update(dt)
  AnimalHusbandry.time = AnimalHusbandry.time + dt
  AnimalHusbandry.herd:calculateVisibility()
  local visibilityFactor = AnimalHusbandry.herd.visibilityFactor
  local lastVisibilityFactor = AnimalHusbandry.herd.lastVisibilityFactor
  local distanceFactor = AnimalHusbandry.herd.distanceFactor
  local lastDistanceFactor = AnimalHusbandry.herd.lastDistanceFactor
  local currentVisibility = visibilityFactor * distanceFactor
  local lastVisibility = lastVisibilityFactor * lastDistanceFactor
  for _, player in pairs(AnimalHusbandry.playerWrappers) do
    player:update(dt)
  end
  ClockWrapper:update(dt)
  if AnimalHusbandry.useAnimalAI then
    if AnimalHusbandry.useUpdateToNetwork then
      g_agentManager:update(dt)
    else
      local aiVisibilityLimit = 0.6
      if currentVisibility >= aiVisibilityLimit then
        if lastVisibility < aiVisibilityLimit then
        end
        g_agentManager:update(dt)
      elseif lastVisibility >= aiVisibilityLimit then
      end
    end
  end
  if AnimalHusbandry.useAnimalVisualization then
    local animationVisibilityLimit = 0.6
    local activeUpdateAnimations = currentVisibility >= animationVisibilityLimit
    local passiveUpdateAnimations = not activeUpdateAnimations
    local resumeAnimations = activeUpdateAnimations and lastVisibility < animationVisibilityLimit
    local stopAnimations = passiveUpdateAnimations and lastVisibility >= animationVisibilityLimit
    AnimalHusbandry.herd.isVisible = activeUpdateAnimations
    for _, animal in ipairs(AnimalHusbandry.herd.visibleAnimals) do
      if activeUpdateAnimations then
        if resumeAnimations then
          AnimationControl.resume(animal)
        end
        AnimationControl.updateAnimation(animal, dt)
      else
        if stopAnimations then
          AnimationControl.stop(animal)
        end
        setTranslation(animal.bonesId, animal.positionX, animal.positionY, animal.positionZ)
        setDirection(animal.bonesId, animal.directionX, animal.directionY, animal.directionZ, 0, 1, 0)
      end
    end
    local soundDistanceLimit = 0.7
    if soundDistanceLimit <= AnimalHusbandry.herd.distanceFactor then
      AnimalSoundManager.update(dt)
    end
  end
end
function AnimalHusbandry.canAddAnimal()
  return AnimalHusbandry.isInUse and AnimalHusbandry.herd ~= nil and table.getn(AnimalHusbandry.herd.animals) < AnimalHusbandry.herd.maxNumberOfAnimals
end
function AnimalHusbandry.canRemoveAnimal()
  return AnimalHusbandry.isInUse and AnimalHusbandry.herd ~= nil and table.getn(AnimalHusbandry.herd.animals) > 0
end
function AnimalHusbandry.getNumberOfAnimals()
  if AnimalHusbandry.herd ~= nil then
    return table.getn(AnimalHusbandry.herd.animals)
  end
  return 0
end
function AnimalHusbandry.getAnimalNameByIndex(animalIndex)
  return AnimalHusbandry.herd.animals[animalIndex].name
end
function AnimalHusbandry.addAnimal(newAnimalName, newAnimalPositionX, newAnimalPositionY, newAnimalPositionZ, newAnimalDirectionX, newAnimalDirectionY, newAnimalDirectionZ, newAnimalAppearanceId)
  if not AnimalHusbandry.useAnimalAI and not newAnimalName then
    print("Error AnimalHusbandry.addAnimal(): You have to provide an animal name if no AI is in use")
  end
  local results = {
    AnimalHusbandry.herd:addAnimal(newAnimalName, newAnimalPositionX, newAnimalPositionY, newAnimalPositionZ, newAnimalDirectionX, newAnimalDirectionY, newAnimalDirectionZ, newAnimalAppearanceId)
  }
  if AnimalHusbandry.useAnimalVisualization and table.getn(AnimalHusbandry.herd.visibleAnimals) >= AnimalSoundManager.AMBIENTSOUNDS_START_ANIMAL_COUNT then
    AnimalSoundManager.resumeAmbientSounds()
  end
  return unpack(results)
end
function AnimalHusbandry.removeAnimal(animalIdentifier)
  AnimalHusbandry.herd:removeAnimal(animalIdentifier)
  if table.getn(AnimalHusbandry.herd.visibleAnimals) < AnimalSoundManager.AMBIENTSOUNDS_START_ANIMAL_COUNT then
    AnimalSoundManager.pauseAmbientSounds()
  end
end
function AnimalHusbandry.refillFeedingPlaces()
  local entityType = EntityType.OBJECT
  local worldState = g_agentManager.worldState
  local currentEntity = worldState:getNextEntityOfSpecifiedType(entityType)
  while currentEntity do
    if currentEntity.isEatable then
      currentEntity:refill()
    end
    currentEntity = worldState:getNextEntityOfSpecifiedType(entityType, currentEntity)
  end
end
function AnimalHusbandry.prepareFeedingPlaces()
  g_currentMission:addSiloAmountListener(AnimalHusbandry, Fillable.FILLTYPE_GRASS)
end
function AnimalHusbandry.onSiloAmountChanged(_, fillType, amount)
  AnimalHusbandry.refillFeedingPlaces()
end
function AnimalHusbandry.clearFeedingPlaces()
  g_currentMission:removeSiloAmountListener(AnimalHusbandry, Fillable.FILLTYPE_GRASS)
end
function AnimalHusbandry.setMilkRobotState(milkRobotStateId)
  local entityType = EntityType.OBJECT
  local worldState = g_agentManager.worldState
  local currentEntity = worldState:getNextEntityOfSpecifiedType(entityType)
  local milkingPlace
  while currentEntity do
    if currentEntity.isMilkingPlace then
      milkingPlace = currentEntity
      break
    end
    currentEntity = worldState:getNextEntityOfSpecifiedType(entityType, currentEntity)
  end
  if milkingPlace then
    milkingPlace:changeState(milkRobotStateId)
  end
end
