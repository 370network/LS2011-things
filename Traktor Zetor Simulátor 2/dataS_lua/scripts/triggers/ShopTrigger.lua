ShopTrigger = {}
local ShopTrigger_mt = Class(ShopTrigger)
function ShopTrigger:onCreate(id)
  g_currentMission:addUpdateable(ShopTrigger:new(id))
end
function ShopTrigger:new(name)
  local instance = {}
  setmetatable(instance, ShopTrigger_mt)
  instance.triggerId = name
  if g_currentMission:getIsClient() then
    addTrigger(name, "triggerCallback", instance)
  end
  instance.shopSymbol = getChildAt(name, 0)
  instance.shopPlayerSpawn = getChildAt(name, 1)
  local x, y, z = getTranslation(instance.shopSymbol)
  instance.posY = y
  instance.jump = 0.05
  instance.isEnabled = true
  if g_isDemo then
    setVisibility(instance.shopSymbol, false)
  end
  return instance
end
function ShopTrigger:delete()
  if g_currentMission:getIsClient() then
    removeTrigger(self.triggerId)
  end
end
function ShopTrigger:update(dt)
  if self.isEnabled then
    rotate(self.shopSymbol, 0, 0.001 * dt, 0)
    self.jump = self.jump - 1.5E-4 * dt
    local x, y, z = getTranslation(self.shopSymbol)
    setTranslation(self.shopSymbol, x, y + self.jump, z)
    if y + self.jump <= self.posY then
      self.jump = 0.05
    end
  end
end
function ShopTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and g_currentMission.controlPlayer and otherId == g_currentMission.player.rootNode and not g_isDemo then
    g_gui:showGui("ShopScreen")
    local x, y, z = getWorldTranslation(self.shopPlayerSpawn)
    local dx, dy, dz = localDirectionToWorld(self.shopPlayerSpawn, 0, 0, 1)
    g_currentMission.player:moveToAbsolute(x, y, z)
    g_client:getServerConnection():sendEvent(PlayerTeleportEvent:new(x, y, z))
    g_currentMission.player.rotY = Utils.getYRotationFromDirection(dx, dz) + math.pi
  end
end
