MissionExploration1 = {}
local MissionExploration1_mt = Class(MissionExploration1, HotspotMission)
function MissionExploration1:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionExploration1_mt
  end
  local self = MissionExploration1:superClass():new(baseDirectory, mt)
  self.playerStartX = -28
  self.playerStartY = 0.1
  self.playerStartZ = -304
  self.playerRotX = 0
  self.playerRotY = Utils.degToRad(-30)
  self.numTriggers = 12
  self.triggerShapeCount = 1
  self.triggerPrefix = "mission_exploration1_trigger"
  self:loadMessages("dataS/missions/messages_exploration1.xml")
  return self
end
function MissionExploration1:delete()
  if self.hotspotSound ~= nil then
    delete(self.hotspotSound)
  end
  MissionExploration1:superClass().delete(self)
end
function MissionExploration1:load()
  self.environment = Environment:new("data/sky/sky_lightClouds.i3d", false, 14)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self.missionMap = self:loadMap("data/maps/missions/mission_exploration1/mission_exploration1.i3d")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 9 do
    AnimalHusbandry.addAnimal()
  end
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronK420.xml", -24, 1, -310, Utils.degToRad(180))
  self.hotspotSound = createSample("hotspotSound")
  loadSample(self.hotspotSound, "data/maps/sounds/hotspotSound.wav", false)
  setLightDiffuseColor(self.environment.sunLightId, 0.803921568627451, 0.803921568627451, 0.8627450980392157)
  setLightSpecularColor(self.environment.sunLightId, 0.7058823529411765, 0.7843137254901961, 0.7843137254901961)
  setAmbientColor(0.37254901960784315, 0.4117647058823529, 0.45098039215686275)
  setFog("exp", 0.0015, 1, 0.39215686274509803, 0.39215686274509803, 0.4117647058823529)
  g_currentMission.missionPDA.showPDA = false
  MissionExploration1:superClass().load(self)
end
function MissionExploration1:loadFinished()
  MissionExploration1:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionExploration1:mouseEvent(posX, posY, isDown, isUp, button)
  MissionExploration1:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionExploration1:keyEvent(unicode, sym, modifier, isDown)
  MissionExploration1:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionExploration1:update(dt)
  MissionExploration1:superClass().update(self, dt)
end
function MissionExploration1:draw()
  MissionExploration1:superClass().draw(self)
end
function MissionExploration1:showMessage(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end
