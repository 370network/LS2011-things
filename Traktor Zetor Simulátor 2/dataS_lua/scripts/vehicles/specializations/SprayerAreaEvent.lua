SprayerAreaEvent = {}
SprayerAreaEvent_mt = Class(SprayerAreaEvent, Event)
InitStaticEventClass(SprayerAreaEvent, "SprayerAreaEvent", EventIds.EVENT_SPRAYER_AREA)
function SprayerAreaEvent:emptyNew()
  local self = Event:new(SprayerAreaEvent_mt)
  self.className = "SprayerAreaEvent"
  return self
end
function SprayerAreaEvent:new(cuttingAreas)
  local self = SprayerAreaEvent:emptyNew()
  self.cuttingAreas = cuttingAreas
  return self
end
function SprayerAreaEvent:readStream(streamId, connection)
  local numAreas = streamReadUIntN(streamId, 4)
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
    Utils.updateSprayArea(x, z, x1, z1, x2, z2)
  end
end
function SprayerAreaEvent:writeStream(streamId, connection)
  local numAreas = table.getn(self.cuttingAreas)
  streamWriteUIntN(streamId, numAreas, 4)
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
function SprayerAreaEvent:run(connection)
  print("Error: Do not run SprayerAreaEvent locally")
end
function SprayerAreaEvent.runLocally(cuttingAreas)
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
    Utils.updateSprayArea(x, z, x1, z1, x2, z2)
  end
end
