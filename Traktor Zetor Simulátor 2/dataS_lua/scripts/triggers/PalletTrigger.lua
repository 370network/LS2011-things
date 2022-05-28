PalletTrigger = {}
local PalletTrigger_mt = Class(PalletTrigger, Object)
InitStaticObjectClass(PalletTrigger, "PalletTrigger", ObjectIds.OBJECT_PALLET_TRIGGER)
function PalletTrigger:onCreate(id)
  local trigger = PalletTrigger:new(g_server ~= nil, g_client ~= nil)
  local index = g_currentMission:addOnCreateLoadedObject(trigger)
  trigger:load(id)
  trigger:register(true)
end
function PalletTrigger:new(isServer, isClient)
  local self = Object:new(isServer, isClient, PalletTrigger_mt)
  self.className = "PalletTrigger"
  self.triggerId = 0
  self.deletePalletTimerId = 0
  return self
end
function PalletTrigger:load(id)
  self.triggerId = id
  addTrigger(self.triggerId, "triggerCallback", self)
  if self.isClient then
    self.palletTriggerSound = createSample("palletTriggerSound")
    loadSample(self.palletTriggerSound, "data/maps/sounds/cashRegistry.wav", false)
  end
  self.currentPallet = 0
  self.deletePalletTimerId = 0
  return self
end
function PalletTrigger:update()
end
function PalletTrigger:delete()
  removeTrigger(self.triggerId)
  if self.deletePalletTimerId ~= 0 then
    removeTimer(self.deletePalletTimerId)
  end
  if self.isClient then
    delete(self.palletTriggerSound)
  end
  PalletTrigger:superClass().delete(self)
end
function PalletTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if otherId ~= 0 then
    if onLeave then
      local isPallet = getUserAttribute(otherId, "isPallet")
      if isPallet ~= nil and isPallet then
        self.currentPallet = 0
      end
    end
    if onEnter then
      local isPallet = getUserAttribute(otherId, "isPallet")
      if isPallet ~= nil and isPallet then
        self.currentPallet = otherId
      end
    end
    if onLeave and self.isServer and self.deletePalletTimerId == 0 and self.currentPallet ~= 0 then
      local isPalletFork = getUserAttribute(otherId, "isPalletFork")
      if isPalletFork ~= nil and isPalletFork then
        self.deletePalletTimerId = addTimer(2000, "palletTriggerTimerCallback", self)
      end
    end
  end
end
function PalletTrigger:palletTriggerTimerCallback()
  if self.currentPallet ~= 0 then
    delete(self.currentPallet)
    self.currentPallet = 0
    local difficultyMultiplier = 2 ^ (3 - g_currentMission.missionStats.difficulty)
    local money = 400 * difficultyMultiplier
    g_currentMission:addSharedMoney(money)
    g_currentMission:increaseReputation(1)
    if self.palletTriggerSound ~= nil then
      playSample(self.palletTriggerSound, 1, 1, 0)
    end
  end
  self.deletePalletTimerId = 0
  return false
end
