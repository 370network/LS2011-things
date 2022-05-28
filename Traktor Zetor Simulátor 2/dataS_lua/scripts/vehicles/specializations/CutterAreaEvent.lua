CutterAreaEvent = {}
CutterAreaEvent_mt = Class(CutterAreaEvent, Event)
InitStaticEventClass(CutterAreaEvent, "CutterAreaEvent", EventIds.EVENT_CUTTER_AREA)
function CutterAreaEvent:emptyNew()
  local self = Event:new(CutterAreaEvent_mt)
  self.className = "CutterAreaEvent"
  return self
end
function CutterAreaEvent:new(cuttingAreas, fruitType)
  local self = CutterAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  self.fruitType = fruitType
  return self
end
function CutterAreaEvent:readStream(streamId, connection)
  local numAreas = streamReadUIntN(streamId, 4)
  local fruitType = streamReadInt8(streamId)
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
    Utils.updateFruitCutShortArea(fruitType, x, z, x1, z1, x2, z2, 1)
    Utils.cutFruitArea(fruitType, x, z, x1, z1, x2, z2)
  end
end
function CutterAreaEvent:writeStream(streamId, connection)
  local numAreas = table.getn(self.cuttingAreas)
  streamWriteUIntN(streamId, numAreas, 4)
  streamWriteInt8(streamId, self.fruitType)
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
function CutterAreaEvent:run(connection)
  print("Error: Do not run CutterAreaEvent locally")
end
function CutterAreaEvent.runLocally(cuttingAreas, fruitType)
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
  local lastArea = 0
  local realArea = 0
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    Utils.updateFruitCutShortArea(fruitType, x, z, x1, z1, x2, z2, 1)
    local area = Utils.cutFruitArea(fruitType, x, z, x1, z1, x2, z2)
    if 0 < area then
      local spray = Utils.getDensity(g_currentMission.terrainDetailId, g_currentMission.sprayChannel, x, z, x1, z1, x2, z2)
      local multi = 1
      if 0 < spray then
        multi = 2
      end
      lastArea = lastArea + area * multi
      realArea = realArea + area / g_currentMission.maxFruitValue
    end
  end
  return lastArea, realArea
end
