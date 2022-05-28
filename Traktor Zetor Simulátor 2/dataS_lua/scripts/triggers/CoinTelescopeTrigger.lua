CoinTelescopeTrigger = {}
local CoinTelescopeTrigger_mt = Class(CoinTelescopeTrigger)
function CoinTelescopeTrigger:onCreate(id)
  g_currentMission:addUpdateable(CoinTelescopeTrigger:new(id))
end
function CoinTelescopeTrigger:new(name)
  local instance = {}
  setmetatable(instance, CoinTelescopeTrigger_mt)
  instance.triggerId = name
  addTrigger(name, "triggerCallback", instance)
  instance.coinTelescopeCamera = getChildAt(name, 0)
  instance.time = 0
  instance.isEnabled = true
  return instance
end
function CoinTelescopeTrigger:delete()
  removeTrigger(self.triggerId)
end
function CoinTelescopeTrigger:update(dt)
  if self.isEnabled and self.time > 0 then
    self.time = self.time - dt
    if InputBinding.hasEvent(InputBinding.SKIP_MESSAGE_BOX) then
      self.time = 0
    end
    g_currentMission.telescopeActive = true
    if self.time <= 0 then
      self.time = 0
      setCamera(g_currentMission.player.cameraId)
      g_currentMission.telescopeActive = false
      g_currentMission.player.isFrozen = false
    end
  end
end
function CoinTelescopeTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and g_currentMission.controlPlayer and otherId == g_currentMission.player.rootNode then
    g_currentMission.missionPDA.showPDA = false
    g_currentMission:addSharedMoney(-1)
    g_currentMission.player.isFrozen = true
    setCamera(self.coinTelescopeCamera)
    self.time = 6000
  end
end
