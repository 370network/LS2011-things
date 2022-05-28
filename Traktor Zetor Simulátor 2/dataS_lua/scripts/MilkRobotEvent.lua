MilkRobotEvent = {}
MilkRobotEvent_mt = Class(MilkRobotEvent, Event)
InitStaticEventClass(MilkRobotEvent, "MilkRobotEvent", EventIds.EVENT_MILKROBOT_CHANGED_STATE)
function MilkRobotEvent:emptyNew()
  local self = Event:new(MilkRobotEvent_mt)
  self.className = "MilkRobotEvent"
  return self
end
function MilkRobotEvent:new(milkRobotStateId)
  local self = MilkRobotEvent:emptyNew()
  self.milkRobotStateId = milkRobotStateId
  return self
end
function MilkRobotEvent:readStream(streamId, connection)
  if connection:getIsServer() then
    self.milkRobotStateId = streamReadUIntN(streamId, 2)
  end
  self:run(connection)
end
function MilkRobotEvent:writeStream(streamId, connection)
  if not connection:getIsServer() then
    streamWriteUIntN(streamId, self.milkRobotStateId, 2)
  end
end
function MilkRobotEvent:run(connection)
  if not connection:getIsServer() then
  elseif g_server == nil then
    AnimalHusbandry.setMilkRobotState(self.milkRobotStateId)
  end
end
