MissionTutorialThreshing = {}
local MissionTutorialThreshing_mt = Class(MissionTutorialThreshing, FieldMission)
function MissionTutorialThreshing:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionTutorialThreshing_mt
  end
  local self = MissionTutorialThreshing:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_INTRO
  self.playerStartX = 83.85
  self.playerStartY = 0.1
  self.playerStartZ = -254.67
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(-40)
  self.showHudEnv = false
  return self
end
function MissionTutorialThreshing:delete()
  MissionTutorialThreshing:superClass().delete(self)
end
function MissionTutorialThreshing:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
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
  local missionCombine = self:loadVehicle("data/vehicles/steerable/deutz/deutz7545RTS.xml", 92, 0.1, -263, Utils.degToRad(180))
  self:loadVehicle("data/vehicles/cutters/deutz/deutzCornCutter7545RTS.xml", 92, 0.5, -268, 0)
  local trailer = self:loadVehicle("data/vehicles/trailers/smallTipper.xml", 38, 0.1, -277, 0)
  local tractor = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronX720.xml", 38, 0.1, -270, 0)
  tractor:attachImplement(trailer, 3)
  self.densityId = self.terrainDetailId
  local maizeId = g_currentMission.fruits[FruitUtil.FRUITTYPE_MAIZE].id
  local maizeDesc = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_MAIZE]
  maizeDesc.literPerSqm = 5
  setDensityMaskedParallelogram(maizeId, 49, -335, 46.5, 0, 0, 63.5, 0, 1, self.densityId, self.sowingChannel, 1, 1)
  setDensityMaskedParallelogram(maizeId, 49, -335, 46.5, 0, 0, 63.5, 2, 1, self.densityId, self.sowingChannel, 1, 1)
  self.densityId = maizeId
  setEnableGrowth(maizeId, false)
  self.densityChannel = 0
  self.targetDensity = 400
  self.isLowerLimit = true
  self:addDensityRegion(49, -335, 46.5, 63.5, true)
  self.numRegionsPerFrame = 2
  self:updateDensity()
  self.numRegionsPerFrame = 1
  self.startDensity = self.currentDensity
  MissionTutorialThreshing:superClass().load(self)
end
function MissionTutorialThreshing:loadFinished()
  MissionTutorialThreshing:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionTutorialThreshing:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialThreshing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialThreshing:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialThreshing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialThreshing:update(dt)
  MissionTutorialThreshing:superClass().update(self, dt)
end
function MissionTutorialThreshing:draw()
  MissionTutorialThreshing:superClass().draw(self)
end
