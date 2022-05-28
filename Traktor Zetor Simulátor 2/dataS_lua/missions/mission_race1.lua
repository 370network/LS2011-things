MissionRace1 = {}
local MissionRace1_mt = Class(MissionRace1, RaceMission)
function MissionRace1:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionRace1_mt
  end
  local self = MissionRace1:superClass():new(baseDirectory, mt)
  self.playerStartX = -650
  self.playerStartY = 0.2
  self.playerStartZ = 92.5
  self.playerRotX = 0
  self.playerRotY = Utils.degToRad(120)
  self.numTriggers = 39
  self.triggerShapeCount = 1
  self.triggerSoundPlayed = {}
  self.triggerPrefix = "mission_race1_trigger"
  self.showHudEnv = true
  self.renderTime = false
  self.showWeatherForecast = false
  return self
end
function MissionRace1:delete()
  if self.triggerSound ~= nil then
    delete(self.triggerSound)
  end
  MissionRace1:superClass().delete(self)
end
function MissionRace1:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 9)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self.missionMap = self:loadMap("data/maps/missions/mission_race1/raceTrack.i3d")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 9 do
    AnimalHusbandry.addAnimal()
  end
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgroplus77.xml", -659.5, 1, 96, Utils.degToRad(0))
  self.triggerSound = createSample("triggerSound")
  loadSample(self.triggerSound, "data/maps/sounds/checkpointSound.wav", false)
  setLightDiffuseColor(self.environment.sunLightId, 0.8627450980392157, 0.8235294117647058, 0.7254901960784313)
  setLightSpecularColor(self.environment.sunLightId, 0.7843137254901961, 0.7843137254901961, 0.7058823529411765)
  setAmbientColor(0.45098039215686275, 0.37254901960784315, 0.4117647058823529)
  setFog("exp", 0.0015, 1, 0.39215686274509803, 0.39215686274509803, 0.45098039215686275)
  setVolumeFog("exp", 0.05, 0, -3, 0.15, 0.2, 0.8)
  g_currentMission.missionPDA.showPDA = false
  MissionRace1:superClass().load(self)
end
function MissionRace1:loadFinished()
  MissionRace1:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionRace1:mouseEvent(posX, posY, isDown, isUp, button)
  MissionRace1:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionRace1:keyEvent(unicode, sym, modifier, isDown)
  MissionRace1:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionRace1:update(dt)
  MissionRace1:superClass().update(self, dt)
end
function MissionRace1:draw()
  MissionRace1:superClass().draw(self)
end
