UserEvent = {}
UserEvent_mt = Class(UserEvent, Event)
InitStaticEventClass(UserEvent, "UserEvent", EventIds.EVENT_USER)
function UserEvent:emptyNew()
  local self = Event:new(UserEvent_mt)
  self.className = "UserEvent"
  return self
end
function UserEvent:new(users, capacity)
  local self = UserEvent:emptyNew()
  self.users = users
  self.capacity = capacity
  return self
end
function UserEvent:readStream(streamId, connection)
  local userId = streamReadInt32(streamId)
  g_currentMission.playerUserId = userId
  self.capacity = streamReadInt8(streamId)
  local numUsers = streamReadInt8(streamId)
  self.users = {}
  for i = 1, numUsers do
    self.users[i] = {}
    self.users[i].nickname = streamReadString(streamId)
    self.users[i].userId = streamReadInt32(streamId)
    self.users[i].language = streamReadUInt8(streamId)
    local playtime = streamReadInt32(streamId)
    self.users[i].connectedTime = g_currentMission.time - playtime
  end
  self:run(connection)
end
function UserEvent:writeStream(streamId, connection)
  local userId = g_currentMission:findUserIdByConnection(connection)
  streamWriteInt32(streamId, userId)
  streamWriteInt8(streamId, self.capacity)
  local numUsers = table.getn(self.users)
  streamWriteInt8(streamId, numUsers)
  for i = 1, numUsers do
    streamWriteString(streamId, self.users[i].nickname)
    streamWriteInt32(streamId, self.users[i].userId)
    streamWriteUInt8(streamId, self.users[i].language)
    streamWriteInt32(streamId, g_currentMission.time - self.users[i].connectedTime)
  end
end
function UserEvent:run(connection)
  g_currentMission.users = self.users
  g_currentMission.missionDynamicInfo.capacity = self.capacity
  g_currentMission:updateMaxNumHirables()
end
