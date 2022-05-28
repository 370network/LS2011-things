CareerMap01 = {}
local CareerMap01_mt = Class(CareerMap01, Mission00)
function CareerMap01:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = CareerMap01_mt
  end
  local self = CareerMap01:superClass():new(baseDirectory, mt)
  return self
end
function CareerMap01:delete()
  CareerMap01:superClass().delete(self)
end
function CareerMap01:load()
  self.environment = Environment:new("data/sky/sky_day_night.i3d", true, 8, true, true)
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  local iconSize = self.missionPDA.pdaMapWidth / 10
  local shopSize = self.missionPDA.pdaMapWidth / 5
  local floraSize = self.missionPDA.pdaMapWidth / 10
  local lighthouseSize = self.missionPDA.pdaMapWidth / 28
  local bellSize = self.missionPDA.pdaMapWidth / 12
  local mallSize = self.missionPDA.pdaMapWidth / 11
  local millSize = self.missionPDA.pdaMapWidth / 10
  local vistaSize = self.missionPDA.pdaMapWidth / 20
  self.missionPDA:createMapHotspot("Twin Cannons Inn", "dataS2/missions/hud_pda_spot_brewery.png", 949, 1771, iconSize, iconSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Watermill", "dataS2/missions/hud_pda_spot_watermill.png", 1507, 1273, iconSize, iconSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Farming Shop", "dataS2/missions/hud_pda_spot_shop.png", 779, 699, shopSize, shopSize * 1.3333333333333333 / 2, false, false, 0)
  self.missionPDA:createMapHotspot("Lighthouse1", "dataS2/missions/hud_pda_spot_lighthouse.png", 106, 1925, lighthouseSize, lighthouseSize * 1.3333333333333333 * 4, false, false, 0)
  self.missionPDA:createMapHotspot("Bell1", "dataS2/missions/hud_pda_spot_bell.png", 449, 714, bellSize, bellSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Bell2", "dataS2/missions/hud_pda_spot_bell.png", 510, 144, bellSize, bellSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Lakeshore Shopping", "dataS2/missions/hud_pda_spot_mall.png", 519, 682, mallSize, mallSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Mill", "dataS2/missions/hud_pda_spot_mill.png", 297, 780, millSize, millSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Vista Point", "dataS2/missions/hud_pda_spot_vista.png", 1037, 1201, iconSize, iconSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Dairy", "dataS2/missions/hud_pda_spot_dairy.png", 1429, 989, iconSize * 1.25, iconSize * 1.3333333333333333 * 1.25, false, false, 0)
  self.missionPDA:createMapHotspot("Ruin", "dataS2/missions/hud_pda_spot_ruin.png", 735, 999, iconSize, iconSize * 1.3333333333333333, false, false, 0)
  self.missionPDA:createMapHotspot("Cows", "dataS2/missions/hud_pda_spot_cow.png", 1189, 229, iconSize, iconSize * 1.3333333333333333, false, false, 0)
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  CareerMap01:superClass().load(self)
  self:loadGlassContainers("data/maps/missions/glassContainers.i3d")
  if not self.missionDynamicInfo.isMultiplayer then
    self:loadCollectableBottles("data/maps/missions/collectableBottles.i3d")
    self:loadInfoTriggers("data/maps/missions/careerInfoTriggers.i3d")
    g_achievementManager.achievementPlates = self:loadMap("data/maps/map01/achievements/achievements.i3d")
    g_achievementManager:updatePlates()
  end
end
function CareerMap01:loadFinished()
  CareerMap01:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function CareerMap01:mouseEvent(posX, posY, isDown, isUp, button)
  CareerMap01:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function CareerMap01:keyEvent(unicode, sym, modifier, isDown)
  CareerMap01:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function CareerMap01:update(dt)
  CareerMap01:superClass().update(self, dt)
end
function CareerMap01:draw()
  CareerMap01:superClass().draw(self)
end
