BalerAreaEvent = {}
BalerAreaEvent_mt = Class(BalerAreaEvent, Event)
InitStaticEventClass(BalerAreaEvent, "BalerAreaEvent", EventIds.EVENT_BALER_AREA)
function BalerAreaEvent:emptyNew()
  local self = Event:new(BalerAreaEvent_mt)
  self.className = "BalerAreaEvent"
  return self
end
function BalerAreaEvent:new(cuttingAreas, fruitTypes)
  local self = BalerAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  self.fruitTypes = fruitTypes
  assert(table.getn(self.cuttingAreas) > 0 and table.getn(self.cuttingAreas) <= 16)
  assert(table.getn(self.fruitTypes) > 0 and table.getn(self.fruitTypes) <= 16)
  return self
end
function BalerAreaEvent:readStream(streamId, connection)
  local numAreas = streamReadUIntN(streamId, 4) + 1
  local numFruitTypes = streamReadUIntN(streamId, 4) + 1
  local fruitTypes = {}
  for i = 1, numFruitTypes do
    local fruitType = streamReadUIntN(streamId, FruitUtil.sendNumBits) + 1
    table.insert(fruitTypes, fruitType)
  end
  local refX = streamReadFloat32(streamId)
  local refY = streamReadFloat32(streamId)
  local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAreas * 3 - 1, 0.01, true)
  for i = 1, numAreas do
    for _, fruitType in ipairs(fruitTypes) do
      local desc = FruitUtil.fruitIndexToDesc[fruitType]
      local vi = i - 1
      local x = values[vi * 3 + 1].x
      local z = values[vi * 3 + 1].y
      local x1 = values[vi * 3 + 2].x
      local z1 = values[vi * 3 + 2].y
      local x2 = values[vi * 3 + 3].x
      local z2 = values[vi * 3 + 3].y
      Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0)
      Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0)
      if fruitType == FruitUtil.FRUITTYPE_DRYGRASS then
        Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 1)
      end
    end
  end
end
function BalerAreaEvent:writeStream(streamId, connection)
  local numAreas = table.getn(self.cuttingAreas)
  local numFruitTypes = table.getn(self.fruitTypes)
  streamWriteUIntN(streamId, numAreas - 1, 4)
  streamWriteUIntN(streamId, numFruitTypes - 1, 4)
  for i = 1, numFruitTypes do
    streamWriteUIntN(streamId, self.fruitTypes[i] - 1, FruitUtil.sendNumBits)
  end
  local refX, refY
  local values = {}
  for i = 1, numAreas do
    local d = self.cuttingAreas[i]
    if i == 1 then
      refX = d[1]
      refY = d[2]
      streamWriteFloat32(streamId, d[1])
      streamWriteFloat32(streamId, d[2])
    else
      table.insert(values, {
        x = d[1],
        y = d[2]
      })
    end
    table.insert(values, {
      x = d[3],
      y = d[4]
    })
    table.insert(values, {
      x = d[5],
      y = d[6]
    })
  end
  assert(table.getn(values) == numAreas * 3 - 1)
  Utils.writeCompressed2DVectors(streamId, refX, refY, values, 0.01)
end
function BalerAreaEvent:run(connection)
end
function BalerAreaEvent.runLocally(cuttingAreas, fruitTypes)
  local totalArea = 0
  local usedFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  local numAreas = table.getn(cuttingAreas)
  local refX, refY
  local values = {}
  for i = 1, numAreas do
    local d = cuttingAreas[i]
    if i == 1 then
      refX = d[1]
      refY = d[2]
    else
      table.insert(values, {
        x = d[1],
        y = d[2]
      })
    end
    table.insert(values, {
      x = d[3],
      y = d[4]
    })
    table.insert(values, {
      x = d[5],
      y = d[6]
    })
  end
  assert(table.getn(values) == numAreas * 3 - 1)
  local values = Utils.simWriteCompressed2DVectors(refX, refY, values, 0.01, true)
  for i = 1, numAreas do
    for _, fruitType in ipairs(fruitTypes) do
      local desc = FruitUtil.fruitIndexToDesc[fruitType]
      local vi = i - 1
      local x = values[vi * 3 + 1].x
      local z = values[vi * 3 + 1].y
      local x1 = values[vi * 3 + 2].x
      local z1 = values[vi * 3 + 2].y
      local x2 = values[vi * 3 + 3].x
      local z2 = values[vi * 3 + 3].y
      local area = Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0) * g_currentMission.windrowCutLongRatio
      area = area + Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0)
      if 0 < area then
        if fruitType == FruitUtil.FRUITTYPE_DRYGRASS then
          Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 1)
        end
        totalArea = totalArea + area
        usedFruitType = fruitType
      end
    end
  end
  return totalArea, usedFruitType
end
