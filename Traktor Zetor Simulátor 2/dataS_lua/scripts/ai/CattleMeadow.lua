CattleMeadow = {}
function CattleMeadow:onCreate(transformId)
  local groundObjectId = g_currentMission.terrainRootNode
  local navigationMeshId = getChild(transformId, "NavMesh")
  local navMeshHashNode = getChild(transformId, "NavMeshes")
  local navMeshHash = {}
  if navMeshHashNode and 0 < navMeshHashNode then
    if not navigationMeshId or navigationMeshId <= 0 then
      navigationMeshId = getChild(navMeshHashNode, "NavMesh")
    end
    if not navigationMeshId or navigationMeshId <= 0 then
      navigationMeshId = getChild(navMeshHashNode, "Default")
    end
    for i = 0, getNumOfChildren(navMeshHashNode) - 1 do
      local currentNavMeshId = getChildAt(navMeshHashNode, i)
      navMeshHash[getName(currentNavMeshId)] = currentNavMeshId
    end
  end
  local spawnPositionNode = getChild(transformId, "SpawnPositions")
  local spawnPositionNodeList = {}
  if spawnPositionNode and 0 < spawnPositionNode then
    for i = 0, getNumOfChildren(spawnPositionNode) - 1 do
      local currentSpawnPositionId = getChildAt(spawnPositionNode, i)
      table.insert(spawnPositionNodeList, currentSpawnPositionId)
    end
  end
  AnimalHusbandry.addHerd(getUserAttribute(transformId, "animalDefinitionFilename"), navigationMeshId, navMeshHash, groundObjectId, not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission:getIsServer(), true, g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer(), false, getUserAttribute(transformId, "maxNumberOfAnimals") or 20, getUserAttribute(transformId, "initialNumberOfAnimals") or 0, spawnPositionNodeList)
end
