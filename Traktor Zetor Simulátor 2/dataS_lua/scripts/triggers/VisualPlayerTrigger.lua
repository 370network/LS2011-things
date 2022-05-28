VisualPlayerTrigger = {}
local VisualPlayerTrigger_mt = Class(VisualPlayerTrigger)
function VisualPlayerTrigger:onCreate(id)
  g_currentMission:addUpdateable(VisualPlayerTrigger:new(id))
end
function VisualPlayerTrigger:new(name)
  local instance = {}
  setmetatable(instance, VisualPlayerTrigger_mt)
  instance.triggerId = name
  addTrigger(name, "triggerCallback", instance)
  instance.ring1 = getChildAt(name, 0)
  instance.ring2 = getChildAt(name, 1)
  instance.isEnabled = true
  return instance
end
function VisualPlayerTrigger:delete()
  removeTrigger(self.triggerId)
end
function VisualPlayerTrigger:update(dt)
  rotate(self.ring1, 0, 5.0E-4 * dt, 0)
  rotate(self.ring2, 0, 3.0E-4 * dt, 0)
end
function VisualPlayerTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and g_currentMission.controlPlayer and otherId == g_currentMission.player.rootNode then
    g_gui:showGui("ShopScreen")
  end
end
