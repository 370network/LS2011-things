FoldableSetFoldDirectionEvent = {}
FoldableSetFoldDirectionEvent_mt = Class(FoldableSetFoldDirectionEvent, Event)
InitStaticEventClass(FoldableSetFoldDirectionEvent, "FoldableSetFoldDirectionEvent", EventIds.EVENT_FOLDABLE_SET_FOLD_DIRECTION)
function FoldableSetFoldDirectionEvent:emptyNew()
  local self = Event:new(FoldableSetFoldDirectionEvent_mt)
  self.className = "FoldableSetFoldDirectionEvent"
  return self
end
function FoldableSetFoldDirectionEvent:new(object, direction)
  local self = FoldableSetFoldDirectionEvent:emptyNew(direction)
  self.object = object
  self.direction = Utils.sign(direction)
  return self
end
function FoldableSetFoldDirectionEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.direction = streamReadInt8(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function FoldableSetFoldDirectionEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt8(streamId, self.direction)
end
function FoldableSetFoldDirectionEvent:run(connection)
  self.object:setFoldDirection(self.direction, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(FoldableSetFoldDirectionEvent:new(self.object, self.direction), nil, connection, self.object)
  end
end
