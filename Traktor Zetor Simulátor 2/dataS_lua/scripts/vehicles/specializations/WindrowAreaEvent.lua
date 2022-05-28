WindrowAreaEvent = {}
WindrowAreaEvent_mt = Class(WindrowAreaEvent, Event)
InitStaticEventClass(WindrowAreaEvent, "WindrowAreaEvent", EventIds.EVENT_WINDROW_AREA)
function WindrowAreaEvent:emptyNew()
  local self = Event:new(WindrowAreaEvent_mt)
  self.className = "WindrowAreaEvent"
  return self
end
function WindrowAreaEvent:new(cuttingAreas, dropAreas, fruitType, bitType)
  local self = WindrowAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  self.dropAreas = dropAreas
  self.fruitType = fruitType
  self.bitType = bitType
  assert(table.getn(self.cuttingAreas) > 0 and table.getn(self.cuttingAreas) < 16)
  assert(table.getn(self.dropAreas) < 16)
  assert(self.bitType >= 0 and self.bitType <= 3)
  return self
end
function WindrowAreaEvent:readStream(streamId, connection)
  local numCutAreas = streamReadUIntN(streamId, 4)
  local numDropAreas = streamReadUIntN(streamId, 4)
  local fruitType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
  local v = {}
  for i = 1, numDropAreas do
    v[i] = streamReadUIntN(streamId, 3) + 1
  end
  local refX = streamReadFloat32(streamId)
  local refY = streamReadFloat32(streamId)
  local values = Utils.readCompressed2DVectors(streamId, refX, refY, (numCutAreas + numDropAreas) * 3 - 1, 0.01, true)
  for i = 1, numCutAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0)
    Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0)
    Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 1)
  end
  for i = 1, numDropAreas do
    local vi = numCutAreas + i - 1
    local dx = values[vi * 3 + 1].x
    local dz = values[vi * 3 + 1].y
    local dx1 = values[vi * 3 + 2].x
    local dz1 = values[vi * 3 + 2].y
    local dx2 = values[vi * 3 + 3].x
    local dz2 = values[vi * 3 + 3].y
    Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2)
    Utils.destroyOtherFruit(FruitUtil.FRUITTYPE_GRASS, dx, dz, dx1, dz1, dx2, dz2)
    if v[i] > g_currentMission.maxCutLongValue then
      Utils.updateFruitWindrowArea(fruitType, dx, dz, dx1, dz1, dx2, dz2, v[i] - g_currentMission.maxCutLongValue, true, false)
    else
      Utils.updateFruitCutLongArea(fruitType, dx, dz, dx1, dz1, dx2, dz2, v[i], true, false)
    end
  end
end
function WindrowAreaEvent:writeStream(streamId, connection)
  local numCuttingAreas = table.getn(self.cuttingAreas)
  local numDropAreas = table.getn(self.dropAreas)
  streamWriteUIntN(streamId, numCuttingAreas, 4)
  streamWriteUIntN(streamId, numDropAreas, 4)
  streamWriteUIntN(streamId, self.fruitType, FruitUtil.sendNumBits)
  for i = 1, numDropAreas do
    streamWriteUIntN(streamId, self.dropAreas[i][7] - 1, 3)
  end
  local refX, refY
  local values = {}
  for i = 1, numCuttingAreas do
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
  for i = 1, numDropAreas do
    local d = self.dropAreas[i]
    table.insert(values, {
      x = d[1],
      y = d[2]
    })
    table.insert(values, {
      x = d[3],
      y = d[4]
    })
    table.insert(values, {
      x = d[5],
      y = d[6]
    })
  end
  assert(table.getn(values) == (numCuttingAreas + numDropAreas) * 3 - 1)
  Utils.writeCompressed2DVectors(streamId, refX, refY, values, 0.01, self.bitType)
end
function WindrowAreaEvent:run(connection)
  print("Error: Do not run WindrowAreaEvent locally")
end
function WindrowAreaEvent.runLocally(cuttingAreas, dropAreas, accumulatedCuttingAreaValues)
  local numAreas = table.getn(cuttingAreas)
  local numDropAreas = table.getn(dropAreas)
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
  for i = 1, numDropAreas do
    local d = dropAreas[i]
    table.insert(values, {
      x = d[1],
      y = d[2]
    })
    table.insert(values, {
      x = d[3],
      y = d[4]
    })
    table.insert(values, {
      x = d[5],
      y = d[6]
    })
  end
  local values, bitType = Utils.simWriteCompressed2DVectors(refX, refY, values, 0.01, true)
  local sum = 0
  local fruitType = FruitUtil.FRUITTYPE_GRASS
  local fruitTypeFix = false
  local ratio = g_currentMission.windrowCutLongRatio
  local cuttingAreasSend = {}
  local dropAreasSend = {}
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    if not fruitTypeFix then
      fruitType = FruitUtil.FRUITTYPE_DRYGRASS
    end
    local area = Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0)
    area = area + Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0) * ratio
    if area == 0 and not fruitTypeFix then
      fruitType = FruitUtil.FRUITTYPE_GRASS
      area = Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0)
      area = area + Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0) * ratio
    end
    if 0 < area then
      fruitTypeFix = true
      Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 1)
      table.insert(cuttingAreasSend, {
        x,
        z,
        x1,
        z1,
        x2,
        z2
      })
    end
    area = area + accumulatedCuttingAreaValues[i]
    accumulatedCuttingAreaValues[i] = 0
    if numAreas <= numDropAreas then
      if 0 < area then
        local dvi = i + numAreas - 1
        local dx = values[dvi * 3 + 1].x
        local dz = values[dvi * 3 + 1].y
        local dx1 = values[dvi * 3 + 2].x
        local dz1 = values[dvi * 3 + 2].y
        local dx2 = values[dvi * 3 + 3].x
        local dz2 = values[dvi * 3 + 3].y
        local old, total = Utils.getFruitCutLongArea(fruitType, dx, dz, dx1, dz1, dx2, dz2)
        old = old + Utils.getFruitWindrowArea(fruitType, dx, dz, dx1, dz1, dx2, dz2) * ratio
        local useWindrows = false
        local valueRatio = 1
        local value = (area + old) / total
        if value > g_currentMission.maxCutLongValue then
          useWindrows = true
          value = value / ratio
          valueRatio = ratio
        end
        value = math.floor(value)
        if 1 <= value then
          accumulatedCuttingAreaValues[i] = math.min(math.max(area + old - value * total * valueRatio, 0), g_currentMission.maxWindrowValue * ratio)
          if useWindrows then
            value = math.min(value, g_currentMission.maxWindrowValue)
          end
          Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2)
          Utils.destroyOtherFruit(FruitUtil.FRUITTYPE_GRASS, dx, dz, dx1, dz1, dx2, dz2)
          if useWindrows then
            Utils.updateFruitWindrowArea(fruitType, dx, dz, dx1, dz1, dx2, dz2, value, true, false)
            table.insert(dropAreasSend, {
              dx,
              dz,
              dx1,
              dz1,
              dx2,
              dz2,
              value + g_currentMission.maxCutLongValue
            })
          else
            Utils.updateFruitCutLongArea(fruitType, dx, dz, dx1, dz1, dx2, dz2, value, true, false)
            table.insert(dropAreasSend, {
              dx,
              dz,
              dx1,
              dz1,
              dx2,
              dz2,
              value
            })
          end
        else
          accumulatedCuttingAreaValues[i] = area
        end
      end
    else
      sum = sum + area
    end
  end
  if 0 < sum and 0 < numDropAreas then
    local dvi = numAreas
    local dx = values[dvi * 3 + 1].x
    local dz = values[dvi * 3 + 1].y
    local dx1 = values[dvi * 3 + 2].x
    local dz1 = values[dvi * 3 + 2].y
    local dx2 = values[dvi * 3 + 3].x
    local dz2 = values[dvi * 3 + 3].y
    local old, total = Utils.getFruitCutLongArea(fruitType, dx, dz, dx1, dz1, dx2, dz2)
    old = old + Utils.getFruitWindrowArea(fruitType, dx, dz, dx1, dz1, dx2, dz2) * ratio
    local useWindrows = false
    local valueRatio = 1
    local value = (sum + old) / total
    if value > g_currentMission.maxCutLongValue then
      useWindrows = true
      value = value / ratio
      valueRatio = ratio
    end
    if 1 <= value then
      accumulatedCuttingAreaValues[1] = math.min(math.max(sum + old - value * total * valueRatio, 0), g_currentMission.maxWindrowValue * ratio)
      if useWindrows then
        value = math.min(value, g_currentMission.maxWindrowValue)
      end
      Utils.switchFruitTypeArea(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_DRYGRASS, dx, dz, dx1, dz1, dx2, dz2)
      Utils.destroyOtherFruit(FruitUtil.FRUITTYPE_GRASS, dx, dz, dx1, dz1, dx2, dz2)
      if useWindrows then
        Utils.updateFruitWindrowArea(fruitType, dx, dz, dx1, dz1, dx2, dz2, value, true, false)
        table.insert(dropAreasSend, {
          dx,
          dz,
          dx1,
          dz1,
          dx2,
          dz2,
          value + g_currentMission.maxCutLongValue
        })
      else
        Utils.updateFruitCutLongArea(fruitType, dx, dz, dx1, dz1, dx2, dz2, value, true, false)
        table.insert(dropAreasSend, {
          dx,
          dz,
          dx1,
          dz1,
          dx2,
          dz2,
          value
        })
      end
    else
      accumulatedCuttingAreaValues[1] = sum
    end
  end
  return cuttingAreasSend, dropAreasSend, fruitType, bitType
end
