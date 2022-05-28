MissionChaff = {}
local MissionChaff_mt = Class(MissionChaff, FSBaseMission)
function MissionChaff:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionChaff_mt
  end
  local self = MissionChaff:superClass():new(baseDirectory, mt)
  self.playerStartX = 393.6
  self.playerStartY = 0.1
  self.playerStartZ = 828.3
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(50)
  self.missionScore = 0
  self.missionGoal = 18000
  self.state = BaseMission.STATE_RUNNING
  return self
end
function MissionChaff:delete()
  MissionChaff:superClass().delete(self)
end
function MissionChaff:load()
  self.environment = Environment:new("data/sky/sky_lightClouds.i3d", false, 14)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 10 do
    AnimalHusbandry.addAnimal()
  end
  setLightDiffuseColor(self.environment.sunLightId, 0.803921568627451, 0.803921568627451, 0.8627450980392157)
  setLightSpecularColor(self.environment.sunLightId, 0.7058823529411765, 0.7843137254901961, 0.7843137254901961)
  setAmbientColor(0.37254901960784315, 0.4117647058823529, 0.45098039215686275)
  setFog("exp", 0.001, 1, 0.39215686274509803, 0.39215686274509803, 0.4117647058823529)
  self:loadVehicle("data/vehicles/steerable/krone/kroneBigX1000.xml", 381.5, 1, 818, Utils.degToRad(180))
  self:loadVehicle("data/vehicles/steerable/krone/kroneEasyCollect1053.xml", 381.5, 1, 812.5, Utils.degToRad(0))
  self.missionTrailer = self:loadVehicle("data/vehicles/trailers/mediumTipper.xml", 381.5, 1, 831, Utils.degToRad(180))
  MissionChaff:superClass().load(self)
  self.missionPDA:createMapHotspot("CowZone", "dataS2/missions/hud_pda_spot_yellow.png", 1210, 259, self.missionPDA.pdaMapArrowSize / 3, self.missionPDA.pdaMapArrowSize * 1.3333333333333333 / 3, false, true, 0)
  self.missionPDA.showPDA = false
  self.showHudEnv = false
  self.showHudMissionBase = true
end
function MissionChaff:loadFinished()
  MissionChaff:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionChaff:mouseEvent(posX, posY, isDown, isUp, button)
  MissionChaff:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionChaff:keyEvent(unicode, sym, modifier, isDown)
  MissionChaff:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionChaff:update(dt)
  MissionChaff:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.missionScore = math.max(0, math.floor(self.missionGoal - self.missionStats.farmSiloAmounts[Fillable.FILLTYPE_CHAFF]))
      if self.state ~= BaseMission.STATE_FINISHED and self.missionScore == 0 then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
        MissionChaff:superClass().finishMission(self, self.endTime)
      end
      if self.state ~= BaseMission.STATE_FAILED and self.missionTime > self.minTime * 1000 then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionChaff:draw()
  MissionChaff:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.025, 0.93, 0.032, g_i18n:getText("chaffMissionGoal"))
    renderText(self.hudMissionBasePosX + 0.23, 0.91, 0.032, tostring(self.missionScore))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionChaff:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionChaff:superClass().drawMissionFailed(self)
    end
  end
end
