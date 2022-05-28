FastLoadingMap = {}
local FastLoadingMap_mt = Class(FastLoadingMap, Mission00)
function FastLoadingMap:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = FastLoadingMap_mt
  end
  local self = FastLoadingMap:superClass():new(baseDirectory, mt)
  return self
end
function FastLoadingMap:delete()
  FastLoadingMap:superClass().delete(self)
end
function FastLoadingMap:load()
  self.environment = Environment:new("data/sky/sky_day_night.i3d", true, 8, true, true)
  self:loadMap("data/maps/fastLoadingMap.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  FastLoadingMap:superClass().load(self)
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
end
function FastLoadingMap:loadFinished()
  FastLoadingMap:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function FastLoadingMap:mouseEvent(posX, posY, isDown, isUp, button)
  FastLoadingMap:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function FastLoadingMap:keyEvent(unicode, sym, modifier, isDown)
  FastLoadingMap:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function FastLoadingMap:update(dt)
  FastLoadingMap:superClass().update(self, dt)
end
function FastLoadingMap:draw()
  FastLoadingMap:superClass().draw(self)
end
