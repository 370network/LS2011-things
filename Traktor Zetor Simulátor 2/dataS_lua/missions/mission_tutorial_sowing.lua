MissionTutorialSowing = {}
local MissionTutorialSowing_mt = Class(MissionTutorialSowing, FieldMission)
function MissionTutorialSowing:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionTutorialSowing_mt
  end
  local self = MissionTutorialSowing:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_INTRO
  self.playerStartX = 89.5
  self.playerStartY = 0.1
  self.playerStartZ = -259
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(-40)
  self:loadMessages("dataS/missions/messages_tutorial_sowing.xml")
  self.showHudEnv = false
  return self
end
function MissionTutorialSowing:delete()
  MissionTutorialSowing:superClass().delete(self)
end
function MissionTutorialSowing:load()
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
  setFog("exp", 0.0015, 1, 0.43137254901960786, 0.49019607843137253, 0.5490196078431373)
  self.missionMapInfospots = self:loadMap("data/maps/missions/mission_tutorial_sowing/mission_tutorial_sowing.i3d")
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronM620.xml", 94.5, 1, -268, Utils.degToRad(180))
  local sowingMachine = self:loadVehicle("data/vehicles/tools/poettinger/vitasemA301.xml", 94.5, 1, -263.5, Utils.degToRad(180))
  sowingMachine:setSeedFruitType(FruitUtil.FRUITTYPE_MAIZE)
  sowingMachine.allowsSeedChanging = false
  sowingMachine:setFillLevel(500, Fillable.FILLTYPE_SEEDS)
  self.densityId = self.terrainDetailId
  setDensityMaskedParallelogram(self.densityId, 49, -335, 46.5, 0, 0, 63.5, 1, 1, self.densityId, 2, 1, 1)
  setDensityParallelogram(self.densityId, 49, -335, 46.5, 0, 0, 63.5, 2, 1, 0)
  self.densityChannel = 2
  self.targetDensity = 10800
  self:addDensityRegion(49, -335, 46.5, 63.5, true)
  self:addSharedMoney(1000)
  MissionTutorialSowing:superClass().load(self)
end
function MissionTutorialSowing:loadFinished()
  MissionTutorialSowing:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionTutorialSowing:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialSowing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialSowing:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialSowing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialSowing:update(dt)
  MissionTutorialSowing:superClass().update(self, dt)
end
function MissionTutorialSowing:draw()
  MissionTutorialSowing:superClass().draw(self)
end
