SowingMachineAreaEvent = {}
SowingMachineAreaEvent_mt = Class(SowingMachineAreaEvent, Event)
InitStaticEventClass(SowingMachineAreaEvent, "SowingMachineAreaEvent", EventIds.EVENT_SOWING_MACHINE_AREA)
function SowingMachineAreaEvent:emptyNew()
  local self = Event:new(SowingMachineAreaEvent_mt)
  self.className = "SowingMachineAreaEvent"
  return self
end
function SowingMachineAreaEvent:new(cuttingAreas, seed)
  local self = SowingMachineAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  self.seed = seed
  return self
end
function SowingMachineAreaEvent:readStream(streamId, connection)
  local numAreas = streamReadUIntN(streamId, 4)
  local seed = streamReadUIntN(streamId, FruitUtil.sendNumBits)
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
    Utils.updateSowingArea(seed, x, z, x1, z1, x2, z2)
  end
end
function SowingMachineAreaEvent:writeStream(streamId, connection)
  local numAreas = table.getn(self.cuttingAreas)
  streamWriteUIntN(streamId, numAreas, 4)
  streamWriteUIntN(streamId, self.seed, FruitUtil.sendNumBits)
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
function SowingMachineAreaEvent:run(connection)
  print("Error: do not run SowingMachineAreaEvent locally")
end
function SowingMachineAreaEvent.runLocally(cuttingAreas, seed)
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
  local area = 0
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    area = area + Utils.updateSowingArea(seed, x, z, x1, z1, x2, z2)
  end
  return area
end
