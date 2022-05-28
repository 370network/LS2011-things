HotspotTrigger = {}
local HotspotTrigger_mt = Class(HotspotTrigger)
function HotspotTrigger:onCreate(id)
  g_currentMission:addUpdateable(HotspotTrigger:new(id))
end
function HotspotTrigger:new(name)
  local instance = {}
  setmetatable(instance, HotspotTrigger_mt)
  instance.triggerId = name
  addTrigger(name, "triggerCallback", instance)
  instance.hotspotSymbol = getChildAt(name, 0)
  local x, y, z = getTranslation(name)
  instance.mapHotspot = g_currentMission.missionPDA:createMapHotspot(tostring(name), "dataS2/missions/hud_pda_spot_yellow.png", x + 1024, z + 1024, g_currentMission.missionPDA.pdaMapArrowSize / 3, g_currentMission.missionPDA.pdaMapArrowSize * 1.3333333333333333 / 3, false, true, 0)
  instance.distanceToPlayer = 0
  instance.isEnabled = true
  return instance
end
function HotspotTrigger:delete()
  removeTrigger(self.triggerId)
end
function HotspotTrigger:update(dt)
  rotate(self.hotspotSymbol, 0, 0.005 * dt, 0)
end
function HotspotTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and g_currentMission.controlledVehicle ~= nil and otherId == g_currentMission.controlledVehicle.components[1].node then
    if g_currentMission.hotspotSound ~= nil then
      playSample(g_currentMission.hotspotSound, 1, 1, 0)
    end
    g_currentMission:hotspotTouched(triggerId)
    self.mapHotspot.visible = false
    self.mapHotspot.enabled = false
    self.isEnabled = false
    setVisibility(self.triggerId, false)
  end
end
