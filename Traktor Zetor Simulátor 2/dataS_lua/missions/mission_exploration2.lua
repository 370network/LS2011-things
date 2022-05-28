MissionExploration2 = {}
local MissionExploration2_mt = Class(MissionExploration2, HotspotMission)
function MissionExploration2:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionExploration2_mt
  end
  local self = MissionExploration2:superClass():new(baseDirectory, mt)
  self.playerStartX = -246.3
  self.playerStartY = 0.1
  self.playerStartZ = -314.8
  self.playerRotX = 0
  self.playerRotY = Utils.degToRad(275)
  self.numTriggers = 12
  self.triggerShapeCount = 1
  self.triggerPrefix = "mission_exploration2_trigger"
  self:loadMessages("dataS/missions/messages_exploration2.xml")
  return self
end
function MissionExploration2:delete()
  if self.hotspotSound ~= nil then
    delete(self.hotspotSound)
  end
  MissionExploration2:superClass().delete(self)
end
function MissionExploration2:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 8)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self.missionMap = self:loadMap("data/maps/missions/mission_exploration2/mission_exploration2.i3d")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 20 do
    AnimalHusbandry.addAnimal()
  end
  self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronL720.xml", -237.5, 1, -318.5, Utils.degToRad(50))
  self.hotspotSound = createSample("hotspotSound")
  loadSample(self.hotspotSound, "data/maps/sounds/hotspotSound.wav", false)
  setLightDiffuseColor(self.environment.sunLightId, 0.8627450980392157, 0.8235294117647058, 0.7254901960784313)
  setLightSpecularColor(self.environment.sunLightId, 0.7843137254901961, 0.7843137254901961, 0.7058823529411765)
  setAmbientColor(0.45098039215686275, 0.37254901960784315, 0.4117647058823529)
  setFog("exp", 0.0015, 1, 0.39215686274509803, 0.39215686274509803, 0.45098039215686275)
  setVolumeFog("exp", 0.05, 0, -3, 0.15, 0.2, 0.8)
  g_currentMission.missionPDA.showPDA = false
  MissionExploration2:superClass().load(self)
end
function MissionExploration2:loadFinished()
  MissionExploration2:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionExploration2:mouseEvent(posX, posY, isDown, isUp, button)
  MissionExploration2:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionExploration2:keyEvent(unicode, sym, modifier, isDown)
  MissionExploration2:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionExploration2:update(dt)
  MissionExploration2:superClass().update(self, dt)
end
function MissionExploration2:draw()
  MissionExploration2:superClass().draw(self)
end
function MissionExploration2:showMessage(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end
