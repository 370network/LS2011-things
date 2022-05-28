MissionRace2 = {}
local MissionRace2_mt = Class(MissionRace2, RaceMission)
function MissionRace2:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionRace2_mt
  end
  local self = MissionRace2:superClass():new(baseDirectory, mt)
  self.playerStartX = 544
  self.playerStartY = 0.1
  self.playerStartZ = 392.7
  self.playerRotX = 0
  self.playerRotY = Utils.degToRad(-45)
  self.numTriggers = 32
  self.triggerShapeCount = 2
  self.triggerSoundPlayed = {}
  self.triggerPrefix = "mission_race2_trigger"
  return self
end
function MissionRace2:delete()
  if self.triggerSound ~= nil then
    delete(self.triggerSound)
  end
  MissionRace2:superClass().delete(self)
end
function MissionRace2:load()
  self.environment = Environment:new("data/sky/sky_lightClouds.i3d", false, 9)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self.missionMap = self:loadMap("data/maps/missions/mission_race2/raceTrack.i3d")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 9 do
    AnimalHusbandry.addAnimal()
  end
  setLightDiffuseColor(self.environment.sunLightId, 0.803921568627451, 0.803921568627451, 0.8627450980392157)
  setLightSpecularColor(self.environment.sunLightId, 0.7058823529411765, 0.7843137254901961, 0.7843137254901961)
  setAmbientColor(0.37254901960784315, 0.4117647058823529, 0.45098039215686275)
  setFog("exp", 0.0015, 1, 0.39215686274509803, 0.39215686274509803, 0.4117647058823529)
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronK420.xml", 552, 1, 387, Utils.degToRad(90))
  self:loadVehicle("data/vehicles/trailers/smallTipper.xml", 545, 1, 387, Utils.degToRad(90))
  self.triggerSound = createSample("triggerSound")
  loadSample(self.triggerSound, "data/maps/sounds/checkpointSound.wav", false)
  g_currentMission.missionPDA.showPDA = false
  MissionRace2:superClass().load(self)
end
function MissionRace2:loadFinished()
  MissionRace2:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionRace2:mouseEvent(posX, posY, isDown, isUp, button)
  MissionRace2:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionRace2:keyEvent(unicode, sym, modifier, isDown)
  MissionRace2:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionRace2:update(dt)
  MissionRace2:superClass().update(self, dt)
end
function MissionRace2:draw()
  MissionRace2:superClass().draw(self)
end
