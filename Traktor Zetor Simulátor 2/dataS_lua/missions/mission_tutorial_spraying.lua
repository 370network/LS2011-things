MissionTutorialSpraying = {}
local MissionTutorialSpraying_mt = Class(MissionTutorialSpraying, FieldMission)
function MissionTutorialSpraying:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionTutorialSpraying_mt
  end
  local self = MissionTutorialSpraying:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_INTRO
  self.playerStartX = 89.5
  self.playerStartY = 0.1
  self.playerStartZ = -259
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(-40)
  self:loadMessages("dataS/missions/messages_tutorial_spraying.xml")
  self.showHudEnv = false
  return self
end
function MissionTutorialSpraying:delete()
  MissionTutorialSpraying:superClass().delete(self)
end
function MissionTutorialSpraying:load()
  self.environment = Environment:new("data/sky/sky_lightClouds.i3d", false, 14)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  self.missionMapInfospots = self:loadMap("data/maps/missions/mission_tutorial_spraying/mission_tutorial_spraying.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 9 do
    AnimalHusbandry.addAnimal()
  end
  setLightDiffuseColor(self.environment.sunLightId, 0.803921568627451, 0.803921568627451, 0.8627450980392157)
  setLightSpecularColor(self.environment.sunLightId, 0.7058823529411765, 0.7843137254901961, 0.7843137254901961)
  setAmbientColor(0.37254901960784315, 0.4117647058823529, 0.45098039215686275)
  setFog("exp", 0.0015, 1, 0.39215686274509803, 0.39215686274509803, 0.4117647058823529)
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronL720.xml", 94.5, 1, -268, Utils.degToRad(180))
  local sprayer = self:loadVehicle("data/vehicles/tools/triton200.xml", 94.5, 1, -263.5, Utils.degToRad(180))
  sprayer:setFillLevel(400, Fillable.FILLTYPE_FERTILIZER)
  self:addSharedMoney(1000)
  self.densityId = self.terrainDetailId
  local maizeId = g_currentMission.fruits[FruitUtil.FRUITTYPE_MAIZE].id
  setDensityMaskedParallelogram(maizeId, 49, -335, 46.5, 0, 0, 63.5, 0, 1, self.densityId, 2, 1, 1)
  setDensityMaskedParallelogram(maizeId, 49, -335, 46.5, 0, 0, 63.5, 1, 1, self.densityId, 2, 1, 1)
  setEnableGrowth(maizeId, false)
  self.densityChannel = 3
  self.targetDensity = 10800
  self:addDensityRegion(49, -335, 46.5, 63.5, true)
  MissionTutorialSpraying:superClass().load(self)
end
function MissionTutorialSpraying:loadFinished()
  MissionTutorialSpraying:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionTutorialSpraying:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialSpraying:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialSpraying:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialSpraying:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialSpraying:update(dt)
  MissionTutorialSpraying:superClass().update(self, dt)
end
function MissionTutorialSpraying:draw()
  MissionTutorialSpraying:superClass().draw(self)
end
