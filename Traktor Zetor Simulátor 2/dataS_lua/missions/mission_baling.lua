MissionBaling = {}
local MissionBaling_mt = Class(MissionBaling, FSBaseMission)
function MissionBaling:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionBaling_mt
  end
  local self = MissionBaling:superClass():new(baseDirectory, mt)
  self.playerStartX = 197.8
  self.playerStartY = 0.1
  self.playerStartZ = -591.3
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(130)
  self.missionPercent = 0
  self.baleCount = 0
  self.neededBales = 12
  self.state = BaseMission.STATE_WAITING
  return self
end
function MissionBaling:delete()
  MissionBaling:superClass().delete(self)
end
function MissionBaling:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  setFog("exp", 0.0015, 1, 0.43137254901960786, 0.49019607843137253, 0.5490196078431373)
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 3 do
    AnimalHusbandry.addAnimal()
  end
  local tractor = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronM620.xml", 192, 1, -582, Utils.degToRad(0))
  local baler = self:loadVehicle("data/vehicles/balers/kroneComprimaV180.xml", 192, 1, -588, Utils.degToRad(0))
  baler.fillScale = 1
  baler.capacity = 6000
  tractor:attachImplement(baler, 4)
  local cutBarleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].cutShortId
  setDensityMaskedParallelogram(cutBarleyId, 103, -579, 96.5, 0, 0, 130, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  for i = 0, 12 do
    Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_BARLEY, 108 + i * 7, -449, 108 + i * 7 + 2, -449, 108 + i * 7, -579, 3, true)
  end
  MissionBaling:superClass().load(self)
  g_currentMission.missionPDA.showPDA = false
  self.showHudEnv = false
  self.showHudMissionBase = true
  self.state = BaseMission.STATE_RUNNING
end
function MissionBaling:loadFinished()
  MissionBaling:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionBaling:mouseEvent(posX, posY, isDown, isUp, button)
  MissionBaling:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionBaling:keyEvent(unicode, sym, modifier, isDown)
  MissionBaling:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionBaling:update(dt)
  MissionBaling:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.missionTime > self.minTime * 1000 then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.time
        self.endTimeStamp = self.time + self.endDelayTime
      end
      if self.state ~= BaseMission.STATE_FINISHED and self.baleCount >= self.neededBales then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
        MissionBaling:superClass().finishMission(self, self.endTime)
        MissionBaling:superClass().drawMissionCompleted(self)
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionBaling:draw()
  MissionBaling:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth / 2 - 0.005, 0.915, 0.032, g_i18n:getText("balingMissionGoal") .. string.format(" %d", self.baleCount))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionBaling:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionBaling:superClass().drawMissionFailed(self)
    end
  end
end
