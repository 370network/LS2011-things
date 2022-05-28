Event = {}
Event_mt = Class(Event)
function Event:new(customMt)
  local self = {}
  local mt = customMt
  if mt == nil then
    mt = Event_mt
  end
  setmetatable(self, mt)
  return self
end
function Event:delete()
end
function Event:readStream(streamId, connection)
end
function Event:writeStream(streamId, connection)
end
