MissionRockSlide = {}
local MissionRockSlide_mt = Class(MissionRockSlide, FSBaseMission)
function MissionRockSlide:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionRockSlide_mt
  end
  local self = MissionRockSlide:superClass():new(baseDirectory, mt)
  self.playerStartX = -120
  self.playerStartY = 0.1
  self.playerStartZ = -187
  self.playerRotX = Utils.degToRad(5)
  self.playerRotY = Utils.degToRad(185)
  self.rockCount = 0
  self.rockHotspots = {}
  self.missionTriggers = {}
  self.frameCount = 0
  self.state = BaseMission.STATE_RUNNING
  return self
end
function MissionRockSlide:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionRockSlide:superClass().delete(self)
end
function MissionRockSlide:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 9 do
    AnimalHusbandry.addAnimal()
  end
  setFog("exp", 0.0015, 1, 0.43137254901960786, 0.49019607843137253, 0.5490196078431373)
  self.missionMap = self:loadMap("data/maps/missions/mission_rockSlide/mission_rockSlide.i3d")
  local triggerParentId = getChild(self.missionMap, "mission_rockSlide_triggers")
  if triggerParentId ~= 0 then
    local numChildren = getNumOfChildren(triggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(triggerParentId, i)
      addTrigger(id, "triggerCallback", self)
      table.insert(self.missionTriggers, id)
    end
  end
  self.rocks = {}
  local rocksParentId = getChild(self.missionMap, "rocks")
  if rocksParentId ~= 0 then
    local numChildren = getNumOfChildren(rocksParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(rocksParentId, i)
      if g_currentMission ~= nil then
        local x, y, z = getTranslation(id)
        g_currentMission.missionPDA:createMapHotspot(tostring(id), "dataS2/missions/hud_pda_spot_rock.png", x + 1024, z + 1024, g_currentMission.missionPDA.pdaMapArrowSize * 0.4, g_currentMission.missionPDA.pdaMapArrowSize * 0.4 * 1.3333333333333333, false, false, id)
      end
      self.rocks[id] = {}
      self.rocks[id].inTriggerCount = 0
    end
  end
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrofarmFrontloader.xml", -119, 1, -181, Utils.degToRad(-50))
  self:loadVehicle("data/vehicles/steerable/deutz/deutzFrontloaderShovel.xml", -123, 1, -178, Utils.degToRad(-50))
  MissionRockSlide:superClass().load(self)
  g_currentMission.missionPDA.showPDA = false
  self.showHudMissionBase = true
end
function MissionRockSlide:loadFinished()
  MissionRockSlide:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionRockSlide:mouseEvent(posX, posY, isDown, isUp, button)
  MissionRockSlide:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionRockSlide:keyEvent(unicode, sym, modifier, isDown)
  MissionRockSlide:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionRockSlide:update(dt)
  MissionRockSlide:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.frameCount = 0
        self.rockCount = 0
        for k, v in pairs(self.rocks) do
          if 0 < v.inTriggerCount then
            self.rockCount = self.rockCount + 1
          end
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.rockCount == 0 then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionRockSlide:superClass().finishMission(self, self.endTime)
        end
        if self.state ~= BaseMission.STATE_FAILED and self.missionTime > self.minTime * 1000 then
          self.state = BaseMission.STATE_FAILED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
        end
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionRockSlide:draw()
  MissionRockSlide:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    local time = self.minTime * 1000 - self.missionTime
    if time < 60000 then
      setTextColor(1, 0, 0, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionRockSlide:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth / 2 - 0.005, 0.915, 0.032, g_i18n:getText("rockSlideMissionGoal") .. string.format(" %d", self.rockCount))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionRockSlide:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionRockSlide:superClass().drawMissionFailed(self)
    end
  end
end
function MissionRockSlide:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.rocks[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inTriggerCount = obj.inTriggerCount + 1
    elseif onLeave then
      obj.inTriggerCount = obj.inTriggerCount - 1
    end
  end
end
