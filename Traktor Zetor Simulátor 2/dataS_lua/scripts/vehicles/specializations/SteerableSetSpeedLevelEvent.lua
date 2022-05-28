SteerableSetSpeedLevelEvent = {}
SteerableSetSpeedLevelEvent_mt = Class(SteerableSetSpeedLevelEvent, Event)
InitStaticEventClass(SteerableSetSpeedLevelEvent, "SteerableSetSpeedLevelEvent", EventIds.EVENT_STEERABLE_SPEED_LEVEL)
function SteerableSetSpeedLevelEvent:emptyNew()
  local self = Event:new(SteerableSetSpeedLevelEvent_mt)
  self.className = "SteerableSetSpeedLevelEvent"
  return self
end
function SteerableSetSpeedLevelEvent:new(object, speedLevel)
  local self = SteerableSetSpeedLevelEvent:emptyNew()
  self.speedLevel = speedLevel
  self.object = object
  return self
end
function SteerableSetSpeedLevelEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.speedLevel = streamReadInt8(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function SteerableSetSpeedLevelEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt8(streamId, self.speedLevel)
end
function SteerableSetSpeedLevelEvent:run(connection)
  Steerable.setSpeedLevel(self.object, self.speedLevel)
end
