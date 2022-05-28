MissionTutorialPloughing = {}
local MissionTutorialPloughing_mt = Class(MissionTutorialPloughing, FieldMission)
function MissionTutorialPloughing:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionTutorialPloughing_mt
  end
  local self = MissionTutorialPloughing:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_INTRO
  self.playerStartX = 100.6
  self.playerStartY = 0.1
  self.playerStartZ = -260
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(56)
  self.showHudEnv = false
  return self
end
function MissionTutorialPloughing:delete()
  MissionTutorialPloughing:superClass().delete(self)
end
function MissionTutorialPloughing:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 16)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 9 do
    AnimalHusbandry.addAnimal()
  end
  setFog("exp", 0.0015, 1, 0.2549019607843137, 0.27450980392156865, 0.29411764705882354)
  setLightDiffuseColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  setLightSpecularColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronM620.xml", 95, 0.1, -268, Utils.degToRad(180))
  self:loadVehicle("data/vehicles/tools/poettinger/servo35s.xml", 95, 0.1, -262.5, Utils.degToRad(180))
  self.densityId = self.terrainDetailId
  self.densityChannel = 1
  self.targetDensity = 10800
  self:addDensityRegion(49, -335, 46.5, 63.5, true)
  MissionTutorialPloughing:superClass().load(self)
end
function MissionTutorialPloughing:loadFinished()
  MissionTutorialPloughing:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionTutorialPloughing:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialPloughing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialPloughing:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialPloughing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialPloughing:update(dt)
  MissionTutorialPloughing:superClass().update(self, dt)
end
function MissionTutorialPloughing:draw()
  MissionTutorialPloughing:superClass().draw(self)
end
