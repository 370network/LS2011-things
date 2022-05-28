CombineAreaEvent = {}
CombineAreaEvent_mt = Class(CombineAreaEvent, Event)
InitStaticEventClass(CombineAreaEvent, "CombineAreaEvent", EventIds.EVENT_COMBINE_AREA)
function CombineAreaEvent:emptyNew()
  local self = Event:new(CombineAreaEvent_mt)
  self.className = "CombineAreaEvent"
  return self
end
function CombineAreaEvent:new(cuttingAreas, fruitType)
  local self = CombineAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  self.fruitType = fruitType
  assert(g_currentMission.maxWindrowValue <= 3)
  return self
end
function CombineAreaEvent:readStream(streamId, connection)
  local fruitType = streamReadInt8(streamId)
  local numAreas = streamReadUIntN(streamId, 4)
  local v = {}
  for i = 1, numAreas do
    v[i] = streamReadUIntN(streamId, 2)
  end
  local refX = streamReadFloat32(streamId)
  local refY = streamReadFloat32(streamId)
  local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAreas * 3 - 1, 0.01, true)
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, v[i], true)
  end
end
function CombineAreaEvent:writeStream(streamId, connection)
  streamWriteInt8(streamId, self.fruitType)
  local numAreas = table.getn(self.cuttingAreas)
  streamWriteUIntN(streamId, numAreas, 4)
  for i = 1, numAreas do
    assert(self.cuttingAreas[i][7] <= 3)
    streamWriteUIntN(streamId, self.cuttingAreas[i][7], 2)
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
function CombineAreaEvent:run(connection)
  print("Error: Do not run CombineAreaEvent locally")
end
function CombineAreaEvent.runLocally(cuttingAreas, fruitType)
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
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, cuttingAreas[i][7], true)
  end
end
