CombinePipeParticleActivatedEvent = {}
CombinePipeParticleActivatedEvent_mt = Class(CombinePipeParticleActivatedEvent, Event)
InitStaticEventClass(CombinePipeParticleActivatedEvent, "CombinePipeParticleActivatedEvent", EventIds.EVENT_COMBINE_PIPE_PARTICLE_ACTIVATED)
function CombinePipeParticleActivatedEvent:emptyNew()
  local self = Event:new(CombinePipeParticleActivatedEvent_mt)
  self.className = "CombinePipeParticleActivatedEvent"
  self.eventId = EventIds.EVENT_COMBINE_PIPE_PARTICLE_ACTIVATED
  return self
end
function CombinePipeParticleActivatedEvent:new(object, pipeParticleActived, pipeIsUnloading)
  local self = CombinePipeParticleActivatedEvent:emptyNew()
  self.object = object
  self.pipeParticleActived = pipeParticleActived
  self.pipeIsUnloading = pipeIsUnloading
  return self
end
function CombinePipeParticleActivatedEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.pipeIsUnloading = streamReadBool(streamId)
  self.pipeParticleActived = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function CombinePipeParticleActivatedEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.pipeIsUnloading)
  streamWriteBool(streamId, self.pipeParticleActived)
end
function CombinePipeParticleActivatedEvent:run(connection)
  self.object.pipeParticleActivated = self.pipeParticleActived
  self.object.pipeIsUnloading = self.pipeIsUnloading
end
