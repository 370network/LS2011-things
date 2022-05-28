TedderAreaEvent = {}
TedderAreaEvent_mt = Class(TedderAreaEvent, Event)
InitStaticEventClass(TedderAreaEvent, "TedderAreaEvent", EventIds.EVENT_TEDDER_AREA)
function TedderAreaEvent:emptyNew()
  local self = Event:new(TedderAreaEvent_mt)
  self.className = "TedderAreaEvent"
  return self
end
function TedderAreaEvent:new(cuttingAreas, bitType)
  local self = TedderAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  self.bitType = bitType
  assert(self.bitType >= 0 and self.bitType <= 3)
  assert(0 < table.getn(self.cuttingAreas) and table.getn(self.cuttingAreas) < 16)
  return self
end
function TedderAreaEvent:readStream(streamId, connection)
  local numAreas = streamReadUIntN(streamId, 4)
  local v = {}
  for i = 1, numAreas do
    v[i] = streamReadUIntN(streamId, 3)
  end
  local refX = streamReadFloat32(streamId)
  local refY = streamReadFloat32(streamId)
  local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAreas * 6 - 1, 0.01, true)
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 6 + 1].x
    local z = values[vi * 6 + 1].y
    local x1 = values[vi * 6 + 2].x
    local z1 = values[vi * 6 + 2].y
    local x2 = values[vi * 6 + 3].x
    local z2 = values[vi * 6 + 3].y
    local dx = values[vi * 6 + 4].x
    local dz = values[vi * 6 + 4].y
    local dx1 = values[vi * 6 + 5].x
    local dz1 = values[vi * 6 + 5].y
    local dx2 = values[vi * 6 + 6].x
    local dz2 = values[vi * 6 + 6].y
    Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, x, z, x1, z1, x2, z2, 0)
    Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 0)
    Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS, x, z, x1, z1, x2, z2, 0)
    Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 0)
    Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 1)
    if 1 <= v[i] then
      Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2)
      Utils.destroyOtherFruit(FruitUtil.FRUITTYPE_GRASS, dx, dz, dx1, dz1, dx2, dz2)
      Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2, v[i], true, false)
    end
  end
end
function TedderAreaEvent:writeStream(streamId, connection)
  local numAreas = table.getn(self.cuttingAreas)
  streamWriteUIntN(streamId, numAreas, 4)
  for i = 1, numAreas do
    streamWriteUIntN(streamId, self.cuttingAreas[i][13], 3)
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
    table.insert(values, {
      x = d[7],
      y = d[8]
    })
    table.insert(values, {
      x = d[9],
      y = d[10]
    })
    table.insert(values, {
      x = d[11],
      y = d[12]
    })
  end
  assert(table.getn(values) == numAreas * 6 - 1)
  Utils.writeCompressed2DVectors(streamId, refX, refY, values, 0.01, self.bitType)
end
function TedderAreaEvent:run(connection)
  print("Error: Do not run TedderAreaEvent locally")
end
function TedderAreaEvent.runLocally(cuttingAreas, limitToField)
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
    table.insert(values, {
      x = d[7],
      y = d[8]
    })
    table.insert(values, {
      x = d[9],
      y = d[10]
    })
    table.insert(values, {
      x = d[11],
      y = d[12]
    })
  end
  assert(table.getn(values) == numAreas * 6 - 1)
  local values, bitType = Utils.simWriteCompressed2DVectors(refX, refY, values, 0.01, true)
  local retCuttingAreas = {}
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 6 + 1].x
    local z = values[vi * 6 + 1].y
    local x1 = values[vi * 6 + 2].x
    local z1 = values[vi * 6 + 2].y
    local x2 = values[vi * 6 + 3].x
    local z2 = values[vi * 6 + 3].y
    local dx = values[vi * 6 + 4].x
    local dz = values[vi * 6 + 4].y
    local dx1 = values[vi * 6 + 5].x
    local dz1 = values[vi * 6 + 5].y
    local dx2 = values[vi * 6 + 6].x
    local dz2 = values[vi * 6 + 6].y
    local ratio = g_currentMission.windrowCutLongRatio
    local area = 0
    area = area + Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, x, z, x1, z1, x2, z2, 0)
    area = area + Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 0)
    area = area + Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS, x, z, x1, z1, x2, z2, 0)
    area = area + Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 0)
    if 0 < area then
      Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 1)
      local old, total = Utils.getFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2)
      area = area + old
      local value = area / total
      if value < 1 and 0.1 < value then
        value = 1
      else
        value = math.floor(value + 0.6)
      end
      value = math.min(value, g_currentMission.maxCutLongValue)
      if 1 <= value then
        Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2)
        Utils.destroyOtherFruit(FruitUtil.FRUITTYPE_GRASS, dx, dz, dx1, dz1, dx2, dz2)
        Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2, value, true, false)
      end
      cuttingAreas[i][13] = value
      table.insert(retCuttingAreas, cuttingAreas[i])
    end
  end
  return retCuttingAreas, bitType
end
