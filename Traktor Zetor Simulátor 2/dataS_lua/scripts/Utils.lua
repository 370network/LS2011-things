Utils = {}
function Utils.checkChildIndex(node, index)
  if index >= getNumOfChildren(node) then
    print("Error: index out of range")
    printCallstack()
    return false
  end
  return true
end
function Utils.indexToObject(components, index)
  if index == nil or components == nil then
    return nil
  end
  local curPos = 1
  local rootNode
  local componentIndex = 1
  local iStart, iEnd = string.find(index, ">", 1)
  if iStart ~= nil then
    curPos = iEnd + 1
  end
  if type(components) == "table" then
    local componentIndex = 1
    if iStart ~= nil then
      componentIndex = tonumber(string.sub(index, 1, iStart - 1)) + 1
    end
    rootNode = components[componentIndex].node
  else
    rootNode = components
  end
  if iStart ~= nil and iEnd == string.len(index) then
    return rootNode
  end
  local retVal = rootNode
  local iStart, iEnd = string.find(index, "|", curPos)
  while iStart ~= nil do
    local indexNumber = tonumber(string.sub(index, curPos, iStart - 1))
    if not Utils.checkChildIndex(retVal, indexNumber) then
      print("Index: " .. index)
      return nil
    end
    retVal = getChildAt(retVal, indexNumber)
    curPos = iEnd + 1
    iStart, iEnd = string.find(index, "|", curPos)
  end
  local indexNumber = tonumber(string.sub(index, curPos))
  if not Utils.checkChildIndex(retVal, indexNumber) then
    print("Index: " .. index)
    return nil
  end
  retVal = getChildAt(retVal, indexNumber)
  return retVal, rootNode
end
local UPDATE_INDEX = 0
local KEEP_INDEX = 1
local SET_INDEX_TO_ZERO = 2
local TYPE_COMPARE_EQUAL = 0
local TYPE_COMPARE_NOTEQUAL = 1
local TYPE_COMPARE_NONE = 2
local NUM_FRUIT_DENSITYMAP_CHANNELS = 8
function Utils.cutFruitArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return 0
  end
  local id = ids.id
  local value = 0
  local desc = FruitUtil.fruitIndexToDesc[fruitId]
  if not desc.needsSeeding then
    value = 1
  end
  setDensityReturnValueShift(id, -1)
  setDensityMaskParams(id, "greater", desc.minHarvestingGrowthState)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = setDensityMaskedParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, id, 0, 3, value)
  setDensityReturnValueShift(id, 0)
  setDensityMaskParams(id, "greater", 0)
  return area
end
function Utils.updateFruitCutShortArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.cutShortId == 0 then
    return 0
  end
  local desc = FruitUtil.fruitIndexToDesc[fruitId]
  local cutShortId = ids.cutShortId
  local maskId = ids.id
  local numMaskChannels = 3
  if value < 0.1 then
    maskId = cutShortId
    numMaskChannels = 1
  else
    if maskId == 0 then
      return 0
    end
    setDensityMaskParams(cutShortId, "greater", desc.minHarvestingGrowthState)
  end
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cutShortId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(cutShortId, x, z, widthX, widthZ, heightX, heightZ, 0, 1, maskId, 0, numMaskChannels, value)
  setDensityMaskParams(cutShortId, "greater", 0)
end
function Utils.updateFruitCutLongArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value, force, deleteFruit)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.cutLongId == 0 then
    return 0
  end
  local cutLongId = ids.cutLongId
  local maskId = ids.id
  local numMaskChannels = 3
  if value < 0.1 then
    maskId = cutLongId
    numMaskChannels = 2
  else
    if maskId == 0 and not force then
      return 0
    end
    setDensityMaskParams(cutLongId, "greater", 1)
  end
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cutLongId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret = 0
  if force then
    if (deleteFruit == nil or deleteFruit) and ids.id ~= 0 then
      setDensityParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, 0)
    end
    if ids.windrowId ~= 0 then
      setDensityParallelogram(ids.windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, 0)
    end
    ret = setDensityParallelogram(cutLongId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, value)
  else
    ret = setDensityMaskedParallelogram(cutLongId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, maskId, 0, numMaskChannels, value)
  end
  setDensityMaskParams(cutLongId, "greater", 0)
  return ret
end
function Utils.updateFruitWindrowArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value, force, deleteFruit)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.windrowId == 0 then
    return 0
  end
  local windrowId = ids.windrowId
  local maskId = ids.id
  local numMaskChannels = 3
  if value < 0.1 then
    maskId = windrowId
    numMaskChannels = 2
  else
    if maskId == 0 and not force then
      return 0
    end
    setDensityMaskParams(windrowId, "greater", 1)
  end
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(windrowId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret = 0
  if force then
    if (deleteFruit == nil or deleteFruit) and ids.id ~= 0 then
      setDensityParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, 0)
    end
    if ids.cutLongId ~= 0 then
      setDensityParallelogram(ids.cutLongId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, 0)
    end
    ret = setDensityParallelogram(windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, value)
  else
    ret = setDensityMaskedParallelogram(windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, maskId, 0, numMaskChannels, value)
  end
  setDensityMaskParams(windrowId, "greater", 0)
  return ret
end
function Utils.setGrowthStateAtCutLongArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, newFruitId, value)
  local newIds = g_currentMission.fruits[newFruitId]
  local ids = g_currentMission.fruits[fruitId]
  if newIds == nil or ids == nil or ids.cutLongId == 0 or newIds.id == 0 then
    return
  end
  local id = newIds.id
  local maskId = ids.cutLongId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, maskId, 0, 2, value)
end
function Utils.setGrowthStateAtWindrowArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, newFruitId, value)
  local newIds = g_currentMission.fruits[newFruitId]
  local ids = g_currentMission.fruits[fruitId]
  if newIds == nil or ids == nil or ids.windrowId == 0 or newIds.id == 0 then
    return
  end
  local id = newIds.id
  local maskId = ids.windrowId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, maskId, 0, 2, value)
end
function Utils.switchFruitTypeArea(newFruitId, maskFruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, newValue)
  local newIds = g_currentMission.fruits[newFruitId]
  local ids = g_currentMission.fruits[maskFruitId]
  if newIds == nil or ids == nil or ids.id == 0 or newIds.id == 0 then
    return
  end
  local id = newIds.id
  local maskId = ids.id
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  if newValue ~= nil then
    setDensityMaskedParallelogram(maskId, x, z, widthX, widthZ, heightX, heightZ, 0, 3, maskId, 0, 3, newValue)
  end
  setTypeIndexMaskedParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, maskId, 0, 3)
end
function Utils.destroyOtherFruit(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return
  end
  local id = ids.id
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityTypeIndexCompareMode(id, TYPE_COMPARE_NOTEQUAL)
  setDensityMaskedParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, id, 0, 3, 0)
  setDensityTypeIndexCompareMode(id, TYPE_COMPARE_EQUAL)
end
function Utils.getFruitArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return 0, 0
  end
  local id = ids.id
  setDensityReturnValueShift(id, -1)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3)
  setDensityReturnValueShift(id, 0)
  return ret, total
end
function Utils.getFruitCutLongArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.cutLongId == 0 then
    return 0, 0
  end
  local id = ids.cutLongId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 2)
  return ret, total
end
function Utils.getFruitWindrowArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.windrowId == 0 then
    return 0, 0
  end
  local id = ids.windrowId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 2)
  return ret, total
end
function Utils.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force)
  local detailId = g_currentMission.terrainDetailId
  Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = 0
  if force == nil or force == true then
    area = area + setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.cultivatorChannel, 1, 1, 1)
  else
    area = area + setDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.cultivatorChannel, 1, detailId, g_currentMission.ploughChannel, 1, 1)
    area = area + setDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.cultivatorChannel, 1, detailId, g_currentMission.sowingChannel, 1, 1)
  end
  setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughChannel, 1, 0)
  setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sowingChannel, 1, 0)
  setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sprayChannel, 1, 0)
  return area
end
function Utils.updatePloughArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force)
  local detailId = g_currentMission.terrainDetailId
  Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = 0
  if force == nil or force == true then
    area = area + setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughChannel, 1, 1, 1)
  else
    area = area + setDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughChannel, 1, detailId, g_currentMission.cultivatorChannel, 1, 1)
    area = area + setDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughChannel, 1, detailId, g_currentMission.sowingChannel, 1, 1)
  end
  setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.cultivatorChannel, 1, 0)
  setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sowingChannel, 1, 0)
  setDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sprayChannel, 1, 0)
  return area
end
function Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  for index, entry in pairs(g_currentMission.fruits) do
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(entry.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    setDensityNewTypeIndexMode(entry.id, SET_INDEX_TO_ZERO)
    setDensityTypeIndexCompareMode(entry.id, TYPE_COMPARE_NONE)
    setDensityParallelogram(entry.id, x, z, widthX, widthZ, heightX, heightZ, 0, NUM_FRUIT_DENSITYMAP_CHANNELS, 0)
    setDensityNewTypeIndexMode(entry.id, UPDATE_INDEX)
    setDensityTypeIndexCompareMode(entry.id, TYPE_COMPARE_EQUAL)
    break
  end
  for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
    local id = g_currentMission.dynamicFoliageLayers[i]
    Utils.updateDensity(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0)
  end
end
function Utils.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local cultivatorId = g_currentMission.terrainDetailId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cultivatorId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local _, numPixels1 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, 3, 1, cultivatorId, 0, 1, 1)
  local _, numPixels2 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, 3, 1, cultivatorId, 1, 1, 1)
  local _, numPixels3 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, 3, 1, cultivatorId, 2, 1, 1)
  return numPixels1 + numPixels2 + numPixels3
end
function Utils.updateSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return 0
  end
  local cultivatorId = g_currentMission.terrainDetailId
  local sowingChannel = g_currentMission.sowingChannel
  local cultivatorChannel = g_currentMission.cultivatorChannel
  local ploughChannel = g_currentMission.ploughChannel
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(ids.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, cultivatorId, cultivatorChannel, 1, 1)
  setDensityMaskedParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, cultivatorId, ploughChannel, 1, 1)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cultivatorId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area1, numPixels1 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, sowingChannel, 1, cultivatorId, cultivatorChannel, 1, 1)
  local area2, numPixels2 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, sowingChannel, 1, cultivatorId, ploughChannel, 1, 1)
  setDensityParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, cultivatorChannel, 1, 0)
  setDensityParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, ploughChannel, 1, 0)
  return numPixels1 + numPixels2
end
function Utils.updateMeadowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1)
  return Utils.cutFruitArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
end
function Utils.updateCuttedMeadowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  area = area + g_currentMission.windrowCutLongRatio * Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  area = area + Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  area = area + g_currentMission.windrowCutLongRatio * Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_DRYGRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1)
  return area
end
function Utils.updateDensity(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, channel, value, channel2, value2, channel3, value3, channel4, value4)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local returnValues = {}
  if channel2 ~= nil and value2 ~= nil then
    returnValues[2] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel2, 1, value2)
    if channel3 ~= nil and value3 ~= nil then
      returnValues[3] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel3, 1, value3)
      if channel4 ~= nil and value4 ~= nil then
        returnValues[4] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel4, 1, value4)
      end
    end
  end
  returnValues[1] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel, 1, value)
  return unpack(returnValues)
end
function Utils.getDensity(id, channel, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  return getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel, 1)
end
function Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  return startWorldX, startWorldZ, widthWorldX - startWorldX, widthWorldZ - startWorldZ, heightWorldX - startWorldX, heightWorldZ - startWorldZ
end
function Utils.vector2Length(x, y)
  return math.sqrt(x * x + y * y)
end
function Utils.vector2LengthSq(x, y)
  return x * x + y * y
end
function Utils.vector3Length(x, y, z)
  return math.sqrt(x * x + y * y + z * z)
end
function Utils.vector3LengthSq(x, y, z)
  return x * x + y * y + z * z
end
function Utils.dotProduct(ax, ay, az, bx, by, bz)
  return ax * bx + ay * by + az * bz
end
function Utils.crossProduct(ax, ay, az, bx, by, bz)
  return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end
function Utils.vector3Transformation(x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33)
  return x * m11 + y * m21 + z * m31, x * m12 + y * m22 + z * m32, x * m13 + y * m23 + z * m33
end
function Utils.projectOnLine(px, pz, lineX, lineZ, lineDirX, lineDirZ)
  local dx, dz = px - lineX, pz - lineZ
  local dot = dx * lineDirX + dz * lineDirZ
  return lineX + lineDirX * dot, lineZ + lineDirZ * dot
end
function Utils.getYRotationFromDirection(dx, dz)
  return math.atan2(dx, dz)
end
function Utils.getDirectionFromYRotation(rotY)
  return math.sin(rotY), math.cos(rotY)
end
function Utils.normalizeRotationForShortestPath(targetRotation, curRotation)
  while curRotation < targetRotation do
    targetRotation = targetRotation - 2 * math.pi
  end
  while curRotation > targetRotation do
    targetRotation = targetRotation + 2 * math.pi
  end
  if targetRotation - curRotation > curRotation + 2 * math.pi - targetRotation then
    targetRotation = targetRotation - 2 * math.pi
  end
  return targetRotation
end
function Utils.nlerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
  local c = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
  local x, y, z, w
  if c < 0 then
    x, y, z, w = x1 + (-x2 - x1) * t, y1 + (-y2 - y1) * t, z1 + (-z2 - z1) * t, w1 + (-w2 - w1) * t
  else
    x, y, z, w = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, z1 + (z2 - z1) * t, w1 + (w2 - w1) * t
  end
  local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)
  return x * len, y * len, z * len, w * len
end
function Utils.slerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
  local fCos = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
  local fAngle = math.acos(fCos)
  if math.abs(fAngle) < 0.01 then
    return x1, y1, z1, w1
  end
  local fSin = math.sin(fAngle)
  local fInvSin = 1 / fSin
  local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
  local fCoeff1 = math.sin(t * fAngle) * fInvSin
  if fCos < 0 then
    fCoeff0 = -fCoeff0
    local x, y, z, w = x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
    local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)
    return x * len, y * len, z * len, w * len
  else
    return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
  end
end
function Utils.lerp(v1, v2, alpha)
  return v1 * (1 - alpha) + v2 * alpha
end
function Utils.clamp(value, minVal, maxVal)
  return math.min(math.max(value, minVal), maxVal)
end
function Utils.degToRad(deg)
  if deg ~= nil then
    return math.rad(deg)
  else
    return 0
  end
end
function Utils.getNoNil(value, setTo)
  if value == nil then
    return setTo
  end
  return value
end
function Utils.getVectorFromString(input)
  if input == nil then
    return nil
  end
  local strings = Utils.splitString(" ", input)
  local results = {}
  for i = 1, table.getn(strings) do
    table.insert(results, tonumber(strings[i]))
  end
  return unpack(results)
end
function Utils.getVectorNFromString(input, num)
  if input == nil then
    return nil
  end
  local strings = Utils.splitString(" ", input)
  if num == nil then
    num = table.getn(strings)
    if num == 0 then
      return nil
    end
  end
  if num > table.getn(strings) then
    return nil
  end
  local results = {}
  for i = 1, num do
    table.insert(results, tonumber(strings[i]))
  end
  return results
end
function Utils.getRadiansFromString(input, num)
  if input == nil then
    return nil
  end
  local strings = Utils.splitString(" ", input)
  if num > table.getn(strings) then
    return nil
  end
  local results = {}
  for i = 1, num do
    table.insert(results, math.rad(tonumber(strings[i])))
  end
  return results
end
function Utils.splitString(splitPattern, text)
  local results = {}
  local start = 1
  local splitStart, splitEnd = string.find(text, splitPattern, start)
  while splitStart ~= nil do
    table.insert(results, string.sub(text, start, splitStart - 1))
    start = splitEnd + 1
    splitStart, splitEnd = string.find(text, splitPattern, start)
  end
  table.insert(results, string.sub(text, start))
  return results
end
function Utils.startsWith(str, find)
  return str:sub(1, find:len()) == find
end
function Utils.endsWith(str, find)
  return str:sub(str:len() - find:len() + 1) == find
end
function Utils.trim(str)
  local n = str:find("%S")
  return n and str:match(".*%S", n) or ""
end
function Utils.limitTextToWidth(text, textSize, width, trimFront, trimReplaceText)
  local indexOfFirstCharacter = 1
  local indexOfLastCharacter = utf8Strlen(text)
  if 0 <= width and width < getTextWidth(textSize, text) then
    if trimFront then
      while text ~= "" and width < getTextWidth(textSize, trimReplaceText .. text) do
        text = utf8Substr(text, 1)
        indexOfFirstCharacter = indexOfFirstCharacter + 1
      end
      text = trimReplaceText .. text
    else
      while text ~= "" and width < getTextWidth(textSize, text .. trimReplaceText) do
        text = utf8Substr(text, 0, indexOfLastCharacter)
        indexOfLastCharacter = indexOfLastCharacter - 1
      end
      text = text .. trimReplaceText
    end
  end
  return text, indexOfFirstCharacter, indexOfLastCharacter
end
function Utils.sign(x)
  if 0 < x then
    return 1
  elseif x < 0 then
    return -1
  end
  return 0
end
function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
  local ret = {}
  for i = 1, numValues do
    local limitF = math.min
    local limitF2 = math.max
    local maxVal = maxValues[i]
    local minVal = minValues[i]
    if inverted then
      maxVal = minVal
      minVal = maxValues[i]
    end
    if maxVal < minVal then
      limitF = math.max
      limitF2 = math.min
    end
    ret[i] = limitF2(limitF(currentValues[i] + (maxVal - minVal) / speed * dt, maxVal), minVal)
  end
  return ret
end
Utils.bitTypeToNumBits = {
  11,
  16,
  20,
  32
}
function Utils.simWriteCompressed2DVectors(refX, refY, values, scale, addRefPoint)
  if scale == nil then
    scale = 0.01
  end
  local invScale = 1 / scale
  local numValues = table.getn(values)
  local bitType = 0
  for i = 1, numValues do
    local dx, dy = values[i].x - refX, values[i].y - refY
    local len = math.sqrt(dx * dx + dy * dy) * invScale
    if len < 1024 then
      bitType = math.max(bitType, 0)
    elseif len < 32768 then
      bitType = math.max(bitType, 1)
    elseif len < 524288 then
      bitType = math.max(bitType, 2)
    else
      bitType = math.max(bitType, 3)
    end
  end
  local ret = {}
  if addRefPoint then
    table.insert(ret, {x = refX, y = refY})
  end
  if bitType ~= 3 then
    for i = 1, numValues do
      local dx, dy = values[i].x - refX, values[i].y - refY
      local x = math.floor(dx * invScale)
      local y = math.floor(dy * invScale)
      x = refX + x * scale
      y = refY + y * scale
      table.insert(ret, {x = x, y = y})
    end
  else
    for i = 1, numValues do
      table.insert(ret, {
        x = values[i].x,
        y = values[i].y
      })
    end
  end
  return ret, bitType
end
function Utils.writeCompressed2DVectors(streamId, refX, refY, values, scale, bitType)
  if scale == nil then
    scale = 0.01
  end
  local invScale = 1 / scale
  local numValues = table.getn(values)
  if 0 < numValues then
    if bitType == nil then
      bitType = 0
      for i = 1, numValues do
        local dx, dy = values[i].x - refX, values[i].y - refY
        local len = math.sqrt(dx * dx + dy * dy) * invScale
        if len < 1024 then
          bitType = math.max(bitType, 0)
        elseif len < 32768 then
          bitType = math.max(bitType, 1)
        elseif len < 524288 then
          bitType = math.max(bitType, 2)
        else
          bitType = math.max(bitType, 3)
        end
      end
    end
    streamWriteUIntN(streamId, bitType, 2)
    if bitType ~= 3 then
      local numBits = Utils.bitTypeToNumBits[bitType + 1]
      for i = 1, numValues do
        local dx, dy = values[i].x - refX, values[i].y - refY
        streamWriteIntN(streamId, math.floor(dx * invScale), numBits)
        streamWriteIntN(streamId, math.floor(dy * invScale), numBits)
      end
    else
      for i = 1, numValues do
        streamWriteFloat32(streamId, values[i].x)
        streamWriteFloat32(streamId, values[i].y)
      end
    end
  end
end
function Utils.readCompressed2DVectors(streamId, refX, refY, numValues, scale, addRefPoint)
  if scale == nil then
    scale = 0.01
  end
  local ret = {}
  if addRefPoint then
    table.insert(ret, {x = refX, y = refY})
  end
  if 0 < numValues then
    local bitType = streamReadUIntN(streamId, 2)
    if bitType ~= 3 then
      local numBits = Utils.bitTypeToNumBits[bitType + 1]
      for i = 1, numValues do
        local x = streamReadIntN(streamId, numBits)
        local y = streamReadIntN(streamId, numBits)
        x = refX + x * scale
        y = refY + y * scale
        table.insert(ret, {x = x, y = y})
      end
    else
      for i = 1, numValues do
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        table.insert(ret, {x = x, y = y})
      end
    end
  end
  return ret
end
function Utils.writeCompressedAngle(streamId, angle)
  local angle = angle % (2 * math.pi)
  assert(0 <= angle and angle <= 2 * math.pi)
  streamWriteUIntN(streamId, math.floor(angle * 2047.5 / math.pi), 12)
end
function Utils.readCompressedAngle(streamId)
  local angle = streamReadUIntN(streamId, 12) / 2047.5 * math.pi
  return angle
end
function Utils.convertToNetworkFilename(filename)
  local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(Utils.trim(filename))
  if isMod then
    filename = "$moddir$" .. modFilename
  elseif isDlc then
    filename = "$pdlcdir" .. string.format("%d", dlcsDirectoryIndex) .. "$" .. modFilename
  end
  return filename
end
function Utils.convertFromNetworkFilename(filename)
  local filenameLower = filename:lower()
  local modPrefix = "$moddir$"
  if Utils.startsWith(filenameLower, modPrefix) then
    filename = g_modsDirectory .. "/" .. filename:sub(modPrefix:len() + 1)
  elseif Utils.startsWith(filenameLower, "$pdlcdir") then
    for i = 1, table.getn(g_dlcsDirectories) do
      local pdlcPrefix = "$pdlcdir" .. string.format("%d", i) .. "$"
      if Utils.startsWith(filenameLower, pdlcPrefix) then
        local tmpFilename = filename:sub(pdlcPrefix:len() + 1)
        local f, l = tmpFilename:find("/")
        if f ~= nil and l ~= nil and 1 < f then
          local modName = g_uniqueDlcNamePrefix .. tmpFilename:sub(1, f - 1)
          local modDir = g_modNameToDirectory[modName]
          if modDir ~= nil then
            filename = modDir .. tmpFilename:sub(f + 1)
          end
        end
        break
      end
    end
  end
  return filename
end
function Utils.removeModDirectory(filename)
  local modsDirLen = g_modsDirectory:len()
  local isMod = false
  local isDlc = false
  local dlcsDirectoryIndex = 0
  if filename == nil then
    printCallstack()
  end
  local filenameLower = filename:lower()
  local modsDirLower = g_modsDirectory:lower()
  if filenameLower:sub(1, modsDirLen + 1) == modsDirLower .. "/" then
    filename = filename:sub(modsDirLen + 2)
    isMod = true
  else
    for i = 1, table.getn(g_dlcsDirectories) do
      local dlcDir = g_dlcsDirectories[i].path:lower()
      local dlcDirLen = dlcDir:len()
      if filenameLower:sub(1, dlcDirLen + 1) == dlcDir .. "/" then
        filename = filename:sub(dlcDirLen + 2)
        dlcsDirectoryIndex = i
        isDlc = true
        break
      end
    end
  end
  return filename, isMod, isDlc, dlcsDirectoryIndex
end
function Utils.getModNameAndBaseDirectory(filename)
  local modName
  local baseDirectory = ""
  local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(filename)
  if isMod or isDlc then
    local f, l = modFilename:find("/")
    if f ~= nil and l ~= nil and 1 < f then
      modName = modFilename:sub(1, f - 1)
      if isDlc then
        baseDirectory = g_dlcsDirectories[dlcsDirectoryIndex].path .. "/" .. modName .. "/"
        modName = g_uniqueDlcNamePrefix .. modName
      else
        baseDirectory = g_modsDirectory .. "/" .. modName .. "/"
      end
    end
  end
  return modName, baseDirectory
end
function Utils.loadParticleSystemData(xmlFile, data, baseString)
  data.nodeStr = getXMLString(xmlFile, baseString .. "#node")
  data.psFile = getXMLString(xmlFile, baseString .. "#file")
  data.posX, data.posY, data.posZ = Utils.getVectorFromString(getXMLString(xmlFile, baseString .. "#position"))
  data.rotX, data.rotY, data.rotZ = Utils.getVectorFromString(getXMLString(xmlFile, baseString .. "#rotation"))
  data.rotX = Utils.degToRad(data.rotX)
  data.rotY = Utils.degToRad(data.rotY)
  data.rotZ = Utils.degToRad(data.rotZ)
end
function Utils.loadParticleSystem(xmlFile, particleSystems, baseString, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
  local data = {}
  Utils.loadParticleSystemData(xmlFile, data, baseString)
  return Utils.loadParticleSystemFromData(data, particleSystems, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
end
function Utils.loadParticleSystemFromData(data, particleSystems, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
  if defaultLinkNode == nil then
    defaultLinkNode = linkNodes
    if type(linkNodes) == "table" then
      defaultLinkNode = linkNodes[1].node
    end
  end
  local linkNode = Utils.getNoNil(Utils.indexToObject(linkNodes, data.nodeStr), defaultLinkNode)
  local psFile = data.psFile
  if psFile == nil then
    psFile = defaultPsFile
  end
  if psFile == nil then
    return
  end
  psFile = Utils.getFilename(psFile, baseDir)
  local rootNode = loadI3DFile(psFile, true, true, nil, nil, false)
  if rootNode == 0 then
    print("Error: failed to load particle system " .. psFile)
    return
  end
  if linkNode ~= nil then
    link(linkNode, rootNode)
  end
  local posX, posY, posZ = data.posX, data.posY, data.posZ
  if posX ~= nil and posY ~= nil and posZ ~= nil then
    setTranslation(rootNode, posX, posY, posZ)
  end
  local rotX, rotY, rotZ = data.rotX, data.rotY, data.rotZ
  if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
    setRotation(rootNode, rotX, rotY, rotZ)
  end
  for i = getNumOfChildren(rootNode) - 1, 0, -1 do
    local child = getChildAt(rootNode, i)
    if getHasClassId(child, ClassIds.SHAPE) then
      local geometry = getGeometry(child)
      if geometry ~= 0 and getHasClassId(geometry, ClassIds.PARTICLE_SYSTEM) then
        local emitterShape = getEmitterShape(geometry)
        local emitterParent = getParent(shape)
        if emitterShape ~= 0 and getParent(emitterShape) == child then
          setTranslation(emitterShape, worldToLocal(rootNode, getWorldTranslation(emitterShape)))
          local dx, dy, dz = worldDirectionToLocal(rootNode, localDirectionToWorld(emitterShape, 0, 0, 1))
          local upx, upy, upz = worldDirectionToLocal(rootNode, localDirectionToWorld(emitterShape, 0, 1, 0))
          setDirection(emitterShape, dx, dy, dz, upx, upy, upz)
          link(rootNode, emitterShape)
        end
        link(getRootNode(), child)
        setTranslation(child, 0, 0, 0)
        setRotation(child, 0, 0, 0)
        table.insert(particleSystems, {geometry = geometry, shape = child})
        if defaultEmittingState ~= nil then
          setEmittingState(geometry, defaultEmittingState)
        end
      end
    end
  end
  return rootNode
end
function Utils.deleteParticleSystem(particleSystems)
  for k, v in ipairs(particleSystems) do
    delete(v.shape)
  end
  if particleSystems.rootNode ~= nil then
    delete(particleSystems.rootNode)
  end
end
function Utils.setEmittingState(particleSystems, state)
  if particleSystems ~= nil and particleSystems.isEmitting ~= state then
    particleSystems.isEmitting = state
    for k, v in ipairs(particleSystems) do
      setEmittingState(v.geometry, state)
    end
  end
end
function Utils.resetNumOfEmittedParticles(particleSystems)
  if particleSystems ~= nil then
    for k, v in ipairs(particleSystems) do
      resetNumOfEmittedParticles(v.geometry)
    end
  end
end
function Utils.loadSample(xmlFile, sample, baseString, defaultSampleFile, baseDir)
  local sampleFilename = getXMLString(xmlFile, baseString .. "#file")
  if sampleFilename == nil then
    sampleFilename = defaultSampleFile
  end
  if sampleFilename ~= nil then
    sampleFilename = Utils.getFilename(sampleFilename, baseDir)
    sample.sample = createSample(sampleFilename)
    loadSample(sample.sample, sampleFilename, false)
    sample.pitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, baseString .. "#pitchOffset"), 0)
    sample.volume = Utils.getNoNil(getXMLFloat(xmlFile, baseString .. "#volume"), 1)
    sample.isPlaying = false
  end
end
function Utils.deleteSample(sample)
  if sample.sample ~= nil then
    delete(sample.sample)
    sample.sample = nil
  end
end
function Utils.playSample(sample, numLoops, offsetMs)
  if sample.sample ~= nil and not sample.isPlaying then
    playSample(sample.sample, numLoops, sample.volume, offsetMs)
    if numLoops == 0 then
      sample.isPlaying = true
    end
  end
end
function Utils.stopSample(sample, force)
  if sample.sample ~= nil and (sample.isPlaying or force) then
    stopSample(sample.sample)
    sample.isPlaying = false
  end
end
Utils.sharedI3DFiles = {}
function Utils.loadSharedI3DFile(filename, baseDir, callOnCreate)
  local filename = Utils.getFilename(filename, baseDir)
  local sharedI3D = Utils.sharedI3DFiles[filename]
  if sharedI3D == nil then
    sharedI3D = loadI3DFile(filename, false, false)
    Utils.sharedI3DFiles[filename] = sharedI3D
  end
  if callOnCreate == nil then
    callOnCreate = false
  end
  if sharedI3D == 0 then
    print("Error: failed to load i3d file '" .. filename .. "'")
    printCallstack()
    return 0
  end
  return clone(sharedI3D, false, callOnCreate)
end
function Utils.fillSharedI3DFileCache(filename, baseDir)
  local filename = Utils.getFilename(filename, baseDir)
  local sharedI3D = Utils.sharedI3DFiles[filename]
  if sharedI3D == nil then
    sharedI3D = loadI3DFile(filename, false, false)
    Utils.sharedI3DFiles[filename] = sharedI3D
  end
end
function Utils.deleteSharedI3DFiles()
  for _, node in pairs(Utils.sharedI3DFiles) do
    delete(node)
  end
  Utils.sharedI3DFiles = {}
end
function Utils.getMSAAIndex(msaa)
  local currentMSAAIndex = 1
  if msaa == 2 then
    currentMSAAIndex = 2
  end
  if msaa == 4 then
    currentMSAAIndex = 3
  end
  if msaa == 8 then
    currentMSAAIndex = 4
  end
  return currentMSAAIndex
end
function Utils.getMSAAFromIndex(msaaIndex)
  local currentMSAA = 1
  if msaaIndex == 2 then
    currentMSAA = 2
  end
  if msaaIndex == 3 then
    currentMSAA = 4
  end
  if msaaIndex == 4 then
    currentMSAA = 8
  end
  return currentMSAA
end
function Utils.getAnsioIndex(ansio)
  local currentAnisoIndex = 1
  if ansio == 2 then
    currentAnisoIndex = 2
  end
  if ansio == 4 then
    currentAnisoIndex = 3
  end
  if ansio == 8 then
    currentAnisoIndex = 4
  end
  return currentAnisoIndex
end
function Utils.getAnisoFromIndex(anisoIndex)
  local currentAniso = 1
  if anisoIndex == 2 then
    currentAniso = 2
  end
  if anisoIndex == 3 then
    currentAniso = 4
  end
  if anisoIndex == 4 then
    currentAniso = 8
  end
  return currentAniso
end
function Utils.getProfileClassIndex(profileClass)
  local currentProfileIndex = 1
  if profileClass == "low" then
    currentProfileIndex = 2
  end
  if profileClass == "medium" then
    currentProfileIndex = 3
  end
  if profileClass == "high" then
    currentProfileIndex = 4
  end
  if profileClass == "very high" then
    currentProfileIndex = 5
  end
  return currentProfileIndex
end
function Utils.getProfileClassFromIndex(profileClassIndex)
  local currentProfileClass = "auto"
  if profileClassIndex == 2 then
    currentProfileClass = "low"
  end
  if profileClassIndex == 3 then
    currentProfileClass = "medium"
  end
  if profileClassIndex == 4 then
    currentProfileClass = "high"
  end
  if profileClassIndex == 5 then
    currentProfileClass = "very high"
  end
  return currentProfileClass
end
function Utils.getProfileClassId()
  local index = Utils.getProfileClassIndex(getGPUPerformanceClass():lower())
  if index == 1 then
    index = Utils.getProfileClassIndex(getAutoGPUPerformanceClass():lower())
  end
  return index - 1
end
function Utils.getTimeScaleIndex(timeScale)
  local timeScaleIndex = 1
  if timeScale == 4 then
    timeScaleIndex = 2
  end
  if timeScale == 16 then
    timeScaleIndex = 3
  end
  if timeScale == 32 then
    timeScaleIndex = 4
  end
  if timeScale == 60 then
    timeScaleIndex = 5
  end
  return timeScaleIndex
end
function Utils.getTimeScaleFromIndex(timeScaleIndex)
  local timeScale = 1
  if timeScaleIndex == 2 then
    timeScale = 4
  end
  if timeScaleIndex == 3 then
    timeScale = 16
  end
  if timeScaleIndex == 4 then
    timeScale = 32
  end
  if timeScaleIndex == 5 then
    timeScale = 60
  end
  return timeScale
end
function Utils.getMasterVolumeIndex(masterVolume)
  local masterVolumeIndex = 1
  if 0.2 <= masterVolume then
    masterVolumeIndex = 2
  end
  if 0.4 <= masterVolume then
    masterVolumeIndex = 3
  end
  if 0.6 <= masterVolume then
    masterVolumeIndex = 4
  end
  if 0.8 <= masterVolume then
    masterVolumeIndex = 5
  end
  if masterVolume == 1 then
    masterVolumeIndex = 6
  end
  return masterVolumeIndex
end
function Utils.getMasterVolumeFromIndex(masterVolumeIndex)
  local masterVolume = 1
  if masterVolumeIndex == 1 then
    masterVolume = 0
  end
  if masterVolumeIndex == 2 then
    masterVolume = 0.2
  end
  if masterVolumeIndex == 3 then
    masterVolume = 0.4
  end
  if masterVolumeIndex == 4 then
    masterVolume = 0.6
  end
  if masterVolumeIndex == 5 then
    masterVolume = 0.8
  end
  return masterVolume
end
function Utils.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
  local div = dirX1 * dirZ2 - dirX2 * dirZ1
  if math.abs(div) < 1.0E-5 then
    return false
  end
  local t1 = (dirX2 * (z1 - z2) - dirZ2 * (x1 - x2)) / div
  local t2 = (dirX1 * (z1 - z2) - dirZ1 * (x1 - x2)) / div
  return true, t1, t2
end
function Utils.getCircleCircleIntersection(x1, y1, r1, x2, y2, r2)
  local dx, dy = x2 - x1, y2 - y1
  local dist = Utils.vector2Length(dx, dy)
  if dist == 0 and x1 == x2 and y1 == y2 then
    return nil
  end
  if dist > r1 + r2 then
    return nil
  end
  if dist < math.abs(r1 - r2) then
    return nil
  end
  if dist == r1 + r2 then
    local x = (x1 - x2) / (r1 + r2) * r1 + x2
    local y = (y1 - y2) / (r1 + r2) * r1 + y2
    return x, y
  end
  local a = (r1 * r1 - r2 * r2 + dist * dist) / (2 * dist)
  local v2x = x1 + dx * a / dist
  local v2y = y1 + dy * a / dist
  local h = math.sqrt(r1 * r1 - a * a)
  local rx = -dy * (h / dist)
  local ry = dx * (h / dist)
  return v2x + rx, v2y + ry, v2x - rx, v2y - ry
end
function Utils.hasSphereSphereIntersection(x1, y1, z1, r1, x2, y2, z2, r2)
  local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
  local rsum = r1 + r2
  return dx * dx + dy * dy + dz * dz <= rsum * rsum
end
function Utils.getFilename(filename, baseDir)
  if filename:sub(1, 1) == "$" then
    return filename:sub(2), false
  elseif baseDir == nil or baseDir == "" then
    return filename, false
  elseif filename == "" then
    return filename, true
  end
  return baseDir .. filename, true
end
function Utils.setWorldTranslation(node, x, y, z)
  local parent = getParent(node)
  if parent ~= 0 then
    x, y, z = worldToLocal(parent, x, y, z)
  end
  setTranslation(node, x, y, z)
end
function Utils.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
  local parent = getParent(node)
  if parent ~= 0 then
    dirX, dirY, dirZ = worldDirectionToLocal(parent, dirX, dirY, dirZ)
    upX, upY, upZ = worldDirectionToLocal(parent, upX, upY, upZ)
  end
  setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
end
function Utils.getXMLI18N(xmlFile, baseKey, name, defaultValue, customEnvironment, isDescription)
  return Utils.getXMLI18NValue(xmlFile, baseKey, getXMLString, name, defaultValue, customEnvironment, isDescription)
end
function Utils.getXMLI18NValue(xmlFile, baseKey, func, name, defaultValue, customEnvironment, isDescription)
  local i18n = g_i18n
  if customEnvironment ~= nil then
    i18n = _G[customEnvironment].g_i18n
  end
  if name == nil or name == "" then
    name = ""
  else
    name = "." .. name
  end
  local defaultVal = func(xmlFile, baseKey .. ".en" .. name)
  if defaultVal == nil then
    defaultVal = func(xmlFile, baseKey .. ".de" .. name)
    if defaultVal == nil then
      local s = func(xmlFile, baseKey .. name)
      if s ~= nil then
        if type(s) == "string" and s:sub(1, 6) == "$l10n_" then
          if isDescription then
            defaultVal = i18n:getDescription(s:sub(7))
          else
            defaultVal = i18n:getText(s:sub(7))
          end
        else
          defaultVal = s
        end
      end
      if defaultVal == nil then
        defaultVal = defaultValue
      end
    end
  end
  if defaultVal == nil then
    print("Error: loading xml I18N item, missing 'en' or global value of attribute '" .. baseKey .. name .. "'")
    return nil
  end
  local val = getXMLString(xmlFile, baseKey .. "." .. g_languageShort .. name)
  if val == nil then
    val = defaultVal
  end
  return val
end
function Utils.appendedFunction(oldFunc, newFunc)
  if oldFunc ~= nil then
    return function(...)
      oldFunc(...)
      newFunc(...)
    end
  else
    return newFunc
  end
end
function Utils.prependedFunction(oldFunc, newFunc)
  if oldFunc ~= nil then
    return function(...)
      newFunc(...)
      oldFunc(...)
    end
  else
    return newFunc
  end
end
function Utils.overwrittenFunction(oldFunc, newFunc)
  return function(self, ...)
    return newFunc(self, oldFunc, ...)
  end
end
Utils.encodeEntities = {
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ä = "&auml;",
  à = "&agrave;",
  â = "&acirc;",
  é = "&eacute;",
  è = "&egrave;",
  ê = "&ecirc;",
  ë = "&euml;",
  î = "&icirc;",
  ï = "&iuml;",
  ô = "&ocirc;",
  ö = "&ouml;",
  ù = "&ugrave;",
  û = "&ucirc;",
  ü = "&uuml;",
  ÿ = "&yuml;",
  À = "&Agrave;",
  Â = "&Acirc;",
  É = "&Eacute;",
  È = "&Egrave;",
  Ê = "&Ecirc;",
  Ë = "&Euml;",
  Î = "&Icirc;",
  Ï = "&Iuml;",
  Ô = "&Ocirc;",
  Ö = "&Ouml;",
  Ù = "&Ugrave;",
  Û = "&Ucirc;",
  ç = "&ccedil;",
  Ç = "&Ccedil;",
  ["\159"] = "&Yuml;",
  ["\171"] = "&laquo;",
  ["\187"] = "&raquo;",
  ["\169"] = "&copy;",
  ["\174"] = "&reg;",
  æ = "&aelig;",
  Æ = "&AElig;",
  ["\140"] = "&OElig;",
  ["\156"] = "&oelig;"
}
function Utils.encodeToHTML(str)
  local encodedString = str
  encodedString = string.gsub(encodedString, "&", "&amp;")
  return encodedString
end
Utils.decodeEntities = {
  amp = "&",
  auml = "\228",
  agrave = "\224",
  acirc = "\226",
  eacute = "\233",
  egrave = "\232",
  ecirc = "\234",
  euml = "\235",
  icirc = "\238",
  iuml = "\239",
  ocirc = "\244",
  ouml = "\246",
  ugrave = "\249",
  ucirc = "\251",
  uuml = "\252",
  yuml = "\255",
  Agrave = "\192",
  Acirc = "\194",
  Eacute = "\201",
  Egrave = "\200",
  Ecirc = "\202",
  Euml = "\203",
  Icirc = "\206",
  Iuml = "\207",
  Ocirc = "\212",
  Ouml = "\214",
  Ugrave = "\217",
  Ucirc = "\219",
  ccedil = "\231",
  Ccedil = "\199",
  Yuml = "\159",
  laquo = "\171",
  raquo = "\187",
  copy = "\169",
  reg = "\174",
  aelig = "\230",
  AElig = "\198",
  OElig = "\140",
  oelig = "\156"
}
function Utils.decodeFromHTML(str)
  local ReplaceEntity = function(entity)
    return Utils.decodeEntities[string.sub(entity, 2, -2)] or entity
  end
  return string.gsub(str, "&%a+;", ReplaceEntity)
end
function Utils.removeElementFromList(list, element)
  for i, v in ipairs(list) do
    if v == element then
      table.remove(list, i)
      break
    end
  end
end
function Utils.holdTablesTheSameValues(table1, table2)
  local typeTable1 = type(table1)
  local typeTable2 = type(table2)
  if typeTable1 ~= "table" and typeTable2 ~= "table" then
    return table1 == table2
  elseif typeTable1 ~= "table" or typeTable2 ~= "table" then
    return false
  end
  for i, v in pairs(table1) do
    if not table2[i] then
      return false
    end
    if not Utils.holdTablesSameValues(v, table2[i]) then
      return false
    end
  end
  for i, v in pairs(table2) do
    if not table1[i] then
      return false
    end
    if not Utils.holdTablesSameValues(v, table1[i]) then
      return false
    end
  end
  return true
end
function Utils.areListsEqual(list1, list2)
  local list1MaxIndex = 0
  for i, element1 in ipairs(list1) do
    if list2[i] ~= element1 then
      return false
    end
    list1MaxIndex = i
  end
  return list2[list1MaxIndex + 1] == nil
end
function Utils.listToSet(list)
  local result = {}
  for _, element in ipairs(list) do
    result[element] = true
  end
  return result
end
function Utils.hashToSet(hash)
  local result = {}
  for element, _ in pairs(hash) do
    result[element] = true
  end
  return result
end
function Utils.setToList(set)
  local result = {}
  local resultCount = 0
  for element, _ in pairs(set) do
    resultCount = resultCount + 1
    result[resultCount] = element
  end
  return result
end
function Utils.setToHash(hash)
  local result = {}
  for element, value in pairs(set) do
    result[element] = value
  end
  return result
end
function Utils.areSetsEqual(set1, set2)
  return Utils.isSubset(set1, set2) and Utils.isSubset(set2, set1)
end
function Utils.isSubset(set1, set2)
  for element1, _ in pairs(set1) do
    if not set2[element1] then
      return false
    end
  end
  return true
end
function Utils.isRealSubset(set1, set2)
  return Utils.isSubset(set1, set2) and not Utils.isSubset(set2, set1)
end
function Utils.getSetIntersection(set1, set2)
  local result = {}
  for element1, _ in pairs(set1) do
    for element2, _ in pairs(set2) do
      if element1 == element2 then
        result[element1] = true
        break
      end
    end
  end
  return result
end
function Utils.getSetSubtraction(set, setToSubtract)
  local result = {}
  for element, _ in pairs(set) do
    if not setToSubtract[element] then
      result[element] = true
    end
  end
  return result
end
function Utils.getSetUnion(set1, set2)
  local result = {}
  for element, _ in pairs(set1) do
    result[element] = true
  end
  for element, _ in pairs(set2) do
    result[element] = true
  end
  return result
end
function Utils.packBits(...)
  local args = {
    ...
  }
  local result = 0
  for i = 1, table.getn(args) do
    local currentBit = args[i]
    if currentBit then
      result = result + 2 ^ (i - 1)
    end
  end
  return result
end
local calculateBitVectorArity = function(number)
  assert(0 <= number)
  local n = 1
  local arity = 1
  while number >= n do
    n = 2 * n
    arity = arity + 1
  end
  arity = arity - 1
  return arity
end
function Utils.readBits(number, arity)
  if arity == nil then
    if number == 0 then
      return
    end
    arity = calculateBitVectorArity(number)
  end
  local result = {}
  for i = arity, 1, -1 do
    local value = 2 ^ (i - 1)
    local isBitSet = number >= value
    result[i] = isBitSet
    if isBitSet then
      number = number - value
    end
  end
end
function Utils.readBit(number, bitPosition, arity)
  if arity == nil then
    if number == 0 then
      return
    end
    arity = calculateBitVectorArity(number)
  end
  for i = arity - 1, bitPosition + 1, -1 do
    local value = 2 ^ i
    local isBitSet = number >= value
    if isBitSet then
      number = number - value
    end
  end
  local value = 2 ^ bitPosition
  return number >= value
end
function Utils.writeBit(number, bitPosition, bitValue, arity)
  if arity == nil then
    if number == 0 then
      return
    end
    arity = calculateBitVectorArity(number)
  end
  local isBitSet = Utils.readBit(number, bitPosition, arity)
  local bitNumber = 2 ^ bitPosition
  if isBitSet then
    number = number - bitNumber
  end
  if bitValue then
    number = number + bitNumber
  end
  return number
end
