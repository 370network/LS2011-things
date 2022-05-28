RaceMission = {}
local RaceMission_mt = Class(RaceMission, FSBaseMission)
function RaceMission:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = RaceMission_mt
  end
  local self = RaceMission:superClass():new(baseDirectory, mt)
  self.missionTriggers = {}
  self.triggerPassed = {}
  self.triggerNames = {}
  self.timeAttack = true
  self.doContactReport = false
  self.contactReportIds = {}
  self.contactMap = {}
  self.contacts = 0
  self.contactForceThreshold = 30
  self.hitSound = nil
  self.loopRace = false
  return self
end
function RaceMission:delete()
  if self.doContactReport then
    local contactTransformGroupId = getChild(self.missionMap, self.contactTransformGroupName)
    local numChildren = getNumOfChildren(contactTransformGroupId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(contactTransformGroupId, i)
      removeContactReport(id)
    end
  end
  for _, triggerId in pairs(self.missionTriggers) do
    removeTrigger(triggerId)
  end
  RaceMission:superClass().delete(self)
end
function RaceMission:pathTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter then
    self.triggerPassed[triggerId] = self.triggerPassed[triggerId] + 1
    if self.triggerPassed[triggerId] >= self.triggerShapeCount and not self.triggerSoundPlayed[triggerId] then
      self.triggerSoundPlayed[triggerId] = true
      if self.triggerSound ~= nil then
        playSample(self.triggerSound, 1, 1, 0)
      end
    end
  end
end
function RaceMission:createTrigger(parent, index)
  local name = self.triggerPrefix .. "0" .. index
  if 9 < index then
    name = self.triggerPrefix .. index
  end
  local triggerId = getChild(parent, name)
  if triggerId ~= 0 then
    addTrigger(triggerId, "pathTriggerCallback", self)
    self.triggerPassed[triggerId] = 0
    self.triggerNames[triggerId] = name
    table.insert(self.missionTriggers, triggerId)
  else
  end
end
function RaceMission:contactReportCallback(objectId, otherObjectId, isStart, normalForce, tangentialForce)
  if normalForce > self.contactForceThreshold then
    for i = 1, table.getn(self.contactReportIds) do
      if otherObjectId == self.contactReportIds[i] then
        if self.contactMap[objectId] == nil then
          self.contacts = self.contacts + 1
          self.contactMap[objectId] = 1
          if self.hitSound ~= nil then
            playSample(self.hitSound, 1, 1, 0)
          end
        end
        break
      end
    end
  end
end
function RaceMission:load()
  RaceMission:superClass().load(self)
  local triggerGroup = getChild(getChild(self.missionMap, "raceTrack"), "triggers")
  for i = 1, self.numTriggers do
    self:createTrigger(triggerGroup, i)
  end
  if self.doContactReport then
    local contactTransformGroupId = getChild(triggerGroup, self.contactTransformGroupName)
    local numChildren = getNumOfChildren(contactTransformGroupId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(contactTransformGroupId, i)
      addContactReport(id, "contactReportCallback", 1.0E-4, self)
    end
    self.showHudMissionBase = true
  end
  self.finishEndTriggerIndex = self.numTriggers
  self.state = RaceMission.STATE_INTRO
end
function RaceMission:mouseEvent(posX, posY, isDown, isUp, button)
  RaceMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function RaceMission:keyEvent(unicode, sym, modifier, isDown)
  local controlPlayer = not self.controlPlayer
  RaceMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function RaceMission:update(dt)
  RaceMission:superClass().update(self, dt)
  for i = 1, table.getn(self.missionTriggers) do
    rotate(getChildAt(self.missionTriggers[i], 0), 0, 0.005 * dt, 0)
  end
  if self.state == BaseMission.STATE_INTRO and 0 < self.triggerPassed[self.missionTriggers[1]] then
    for i = 2, table.getn(self.missionTriggers) do
      self.triggerPassed[self.missionTriggers[i]] = 0
    end
    self.state = BaseMission.STATE_RUNNING
  end
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.sunk or self.missionTime > self.minTime * 1000 or self.doContactReport and self.contacts >= self.maxContacts then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
      else
        local count = 0
        for i = 1, table.getn(self.missionTriggers) do
          if self.triggerPassed[self.missionTriggers[i]] >= self.triggerShapeCount then
            setVisibility(getChildAt(self.missionTriggers[i], 0), false)
            count = count + 1
          end
        end
        if self.loopRace and count == 2 then
          self.triggerPassed[self.missionTriggers[self.finishEndTriggerIndex]] = 0
        end
        if count == table.getn(self.missionTriggers) then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          RaceMission:superClass().finishMission(self, self.endTime)
        end
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function RaceMission:draw()
  RaceMission:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudEnv then
    if self.timeAttack then
      local time = self.minTime * 1000 - self.missionTime
      if time < 10000 then
        setTextColor(1, 0, 0, 1)
        if time < 0 then
          time = 0
        end
      end
      RaceMission:superClass().drawTime(self, true, time / 60000)
      setTextColor(1, 1, 1, 1)
    end
    if self.doContactReport and self.state ~= RaceMission.STATE_FAILED then
      if self.contacts >= self.maxContacts - 1 then
        setTextColor(1, 0, 0, 1)
      end
      setTextBold(true)
      renderText(0.08700000000000002, 0.916, 0.06, g_i18n:getText("mission02Goal") .. string.format(" %d", self.maxContacts - self.contacts))
      setTextBold(false)
      setTextColor(1, 1, 1, 1)
      RaceMission:superClass().drawTime(self, true, self.missionTime / 60000)
    end
    if self.state == BaseMission.STATE_FINISHED then
      self:drawMissionCompleted()
    end
    if self.state == BaseMission.STATE_FAILED then
      self:drawMissionFailed()
    end
  end
end
