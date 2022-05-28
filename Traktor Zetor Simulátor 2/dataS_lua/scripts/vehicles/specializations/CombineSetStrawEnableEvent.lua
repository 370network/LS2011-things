CombineSetStrawEnableEvent = {}
CombineSetStrawEnableEvent_mt = Class(CombineSetStrawEnableEvent, Event)
InitStaticEventClass(CombineSetStrawEnableEvent, "CombineSetStrawEnableEvent", EventIds.EVENT_COMBINE_SET_STRAW_ENABLE)
function CombineSetStrawEnableEvent:emptyNew()
  local self = Event:new(CombineSetStrawEnableEvent_mt)
  self.className = "CombineSetStrawEnableEvent"
  return self
end
function CombineSetStrawEnableEvent:new(object, enabled, fruitType)
  local self = CombineSetStrawEnableEvent:emptyNew()
  self.object = object
  self.enabled = enabled
  self.fruitType = fruitType
  return self
end
function CombineSetStrawEnableEvent:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.enabled = streamReadBool(streamId)
  self.fruitType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
  self:run(connection)
end
function CombineSetStrawEnableEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.enabled)
  streamWriteUIntN(streamId, self.fruitType, FruitUtil.sendNumBits)
end
function CombineSetStrawEnableEvent:run(connection)
  CombineSetStrawEnableEvent.execute(self.object, self.enabled, self.fruitType)
end
function CombineSetStrawEnableEvent.execute(object, enabled, fruitType)
  if object.currentStrawParticleSystem ~= nil then
    Utils.setEmittingState(object.currentStrawParticleSystem, false)
  end
  object.currentStrawParticleSystem = object.strawParticleSystems[fruitType]
  if object.currentStrawParticleSystem == nil then
    object.currentStrawParticleSystem = object.defaultStrawParticleSystem
  end
  if enabled then
    Utils.setEmittingState(object.currentStrawParticleSystem, true)
  else
    Utils.setEmittingState(object.currentStrawParticleSystem, false)
  end
end
