MissionTutorialCultivating = {}
local MissionTutorialCultivating_mt = Class(MissionTutorialCultivating, FieldMission)
function MissionTutorialCultivating:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionTutorialCultivating_mt
  end
  local self = MissionTutorialCultivating:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_INTRO
  self.playerStartX = 89.5
  self.playerStartY = 0.1
  self.playerStartZ = -259
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(-40)
  self.showHudEnv = false
  return self
end
function MissionTutorialCultivating:delete()
  MissionTutorialCultivating:superClass().delete(self)
end
function MissionTutorialCultivating:load()
  self.environment = Environment:new("data/sky/sky_mission_dusk1.i3d", false, 12)
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
  setRotation(self.environment.sunLightId, Utils.degToRad(-33), Utils.degToRad(-62.5), Utils.degToRad(0))
  setLightDiffuseColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  setLightSpecularColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronL720.xml", 94.5, 1, -268, Utils.degToRad(180))
  self:loadVehicle("data/vehicles/tools/poettinger/synkro2600.xml", 94.5, 1, -263.5, Utils.degToRad(180))
  self.densityId = self.terrainDetailId
  local cutMaizeId = g_currentMission.fruits[FruitUtil.FRUITTYPE_MAIZE].cutShortId
  setDensityMaskedParallelogram(cutMaizeId, 49, -335, 46.5, 0, 0, 63.5, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  self.densityChannel = self.cultivatorChannel
  self.targetDensity = 10800
  self:addDensityRegion(49, -335, 46.5, 63.5, true)
  MissionTutorialCultivating:superClass().load(self)
end
function MissionTutorialCultivating:loadFinished()
  MissionTutorialCultivating:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionTutorialCultivating:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialCultivating:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialCultivating:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialCultivating:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialCultivating:update(dt)
  MissionTutorialCultivating:superClass().update(self, dt)
end
function MissionTutorialCultivating:draw()
  MissionTutorialCultivating:superClass().draw(self)
end
