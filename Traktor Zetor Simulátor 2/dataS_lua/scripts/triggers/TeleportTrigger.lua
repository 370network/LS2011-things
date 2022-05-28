TeleportTrigger = {}
local TeleportTrigger_mt = Class(TeleportTrigger)
function TeleportTrigger:onCreate(id)
  g_currentMission:addUpdateable(TeleportTrigger:new(id))
end
function TeleportTrigger:new(name)
  local instance = {}
  setmetatable(instance, TeleportTrigger_mt)
  instance.triggerId = name
  if g_currentMission:getIsClient() then
    addTrigger(name, "triggerCallback", instance)
  end
  instance.triggerSymbol = getChildAt(name, 0)
  instance.triggerPlayerSpawn = getChildAt(name, 1)
  local x, y, z = getTranslation(instance.triggerSymbol)
  instance.posY = y
  instance.jump = 0.05
  instance.isEnabled = true
  return instance
end
function TeleportTrigger:delete()
  if g_currentMission:getIsClient() then
    removeTrigger(self.triggerId)
  end
end
function TeleportTrigger:update(dt)
  if self.isEnabled then
    rotate(self.triggerSymbol, 0, 0.001 * dt, 0)
    self.jump = self.jump - 1.5E-4 * dt
    local x, y, z = getTranslation(self.triggerSymbol)
    setTranslation(self.triggerSymbol, x, y + self.jump, z)
    if y + self.jump <= self.posY then
      self.jump = 0.05
    end
  end
end
function TeleportTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and g_currentMission.controlPlayer and otherId == g_currentMission.player.rootNode then
    local x, y, z = getWorldTranslation(self.triggerPlayerSpawn)
    local dx, dy, dz = localDirectionToWorld(self.triggerPlayerSpawn, 0, 0, 1)
    g_currentMission.player:moveToAbsolute(x, y, z)
    g_client:getServerConnection():sendEvent(PlayerTeleportEvent:new(x, y, z))
    g_currentMission.player.rotY = Utils.getYRotationFromDirection(dx, dz) + math.pi
  end
end
