CombineSetChopperEnableEvent = {}
CombineSetChopperEnableEvent_mt = Class(CombineSetChopperEnableEvent, Event)
InitStaticEventClass(CombineSetChopperEnableEvent, "CombineSetChopperEnableEvent", EventIds.EVENT_COMBINE_SET_CHOPPER_ENABLE)
function CombineSetChopperEnableEvent:emptyNew()
  local self = Event:new(CombineSetChopperEnableEvent_mt)
  self.className = "CombineSetChopperEnableEvent"
  return self
end
function CombineSetChopperEnableEvent:new(object, enabled, fruitType)
  local self = CombineSetChopperEnableEvent:emptyNew()
  self.object = object
  self.enabled = enabled
  self.fruitType = fruitType
  return self
end
function CombineSetChopperEnableEvent:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.enabled = streamReadBool(streamId)
  self.fruitType = streamReadUIntN(streamId, FruitUtil.sendNumBits)
  self:run(connection)
end
function CombineSetChopperEnableEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.enabled)
  streamWriteUIntN(streamId, self.fruitType, FruitUtil.sendNumBits)
end
function CombineSetChopperEnableEvent:run(connection)
  CombineSetChopperEnableEvent.execute(self.object, self.enabled, self.fruitType)
end
function CombineSetChopperEnableEvent.execute(object, enabled, fruitType)
  if object.currentChopperParticleSystem ~= nil then
    Utils.setEmittingState(object.currentChopperParticleSystem, false)
  end
  object.currentChopperParticleSystem = object.chopperParticleSystems[fruitType]
  if object.currentChopperParticleSystem == nil then
    object.currentChopperParticleSystem = object.defaultChopperParticleSystem
  end
  if enabled then
    Utils.setEmittingState(object.currentChopperParticleSystem, true)
  else
    Utils.setEmittingState(object.currentChopperParticleSystem, false)
  end
end
