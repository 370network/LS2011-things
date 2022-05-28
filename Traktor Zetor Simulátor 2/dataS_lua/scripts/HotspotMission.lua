HotspotMission = {}
local HotspotMission_mt = Class(HotspotMission, FSBaseMission)
function HotspotMission:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = HotspotMission_mt
  end
  local self = HotspotMission:superClass():new(baseDirectory, mt)
  self.touchedATrigger = false
  self.timeAttack = true
  self.touchedTriggerCount = 0
  return self
end
function HotspotMission:delete()
  HotspotMission:superClass().delete(self)
end
function HotspotMission:load()
  HotspotMission:superClass().load(self)
  self.finishEndTriggerIndex = self.numTriggers
  self.state = HotspotMission.STATE_INTRO
  self.showHudMissionBase = true
end
function HotspotMission:mouseEvent(posX, posY, isDown, isUp, button)
  HotspotMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function HotspotMission:keyEvent(unicode, sym, modifier, isDown)
  local controlPlayer = not self.controlPlayer
  HotspotMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function HotspotMission:update(dt)
  HotspotMission:superClass().update(self, dt)
  if self.state == BaseMission.STATE_INTRO and self.touchedATrigger then
    self.state = BaseMission.STATE_RUNNING
  end
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.sunk or self.missionTime > self.minTime * 1000 then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
      elseif self.touchedTriggerCount == self.numTriggers and not self.inGameMessage.visible then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
        HotspotMission:superClass().finishMission(self, self.endTime)
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function HotspotMission:draw()
  HotspotMission:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    if self.timeAttack then
      local time = self.minTime * 1000 - self.missionTime
      if time < 10000 then
        setTextColor(1, 0, 0, 1)
        if time < 0 then
          time = 0
        end
      end
      HotspotMission:superClass().drawTime(self, true, time / 60000)
      setTextColor(1, 1, 1, 1)
    end
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth / 2 - 0.005, 0.915, 0.032, g_i18n:getText("hotspotMissionGoal") .. tostring(self.numTriggers - self.touchedTriggerCount))
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    if self.state == BaseMission.STATE_FINISHED then
      self:drawMissionCompleted()
    end
    if self.state == BaseMission.STATE_FAILED then
      self:drawMissionFailed()
    end
  end
end
function HotspotMission:hotspotTouched(triggerId)
  self.touchedATrigger = true
  self:showMessage(triggerId)
  self.touchedTriggerCount = self.touchedTriggerCount + 1
end
