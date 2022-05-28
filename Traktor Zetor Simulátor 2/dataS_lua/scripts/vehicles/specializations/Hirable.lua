Hirable = {}
Hirable.numHirablesHired = 0
function Hirable.prerequisitesPresent(specializations)
  return true
end
function Hirable:load(xmlFile)
  self.hire = SpecializationUtil.callSpecializationsFunction("hire")
  self.dismiss = SpecializationUtil.callSpecializationsFunction("dismiss")
  self.pricePerMS = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pricePerHour"), 2000) / 60 / 60 / 1000
  self.isHired = false
end
function Hirable:delete()
end
function Hirable:mouseEvent(posX, posY, isDown, isUp, button)
end
function Hirable:keyEvent(unicode, sym, modifier, isDown)
end
function Hirable:update(dt)
  if self.isHired then
    self.forceIsActive = true
    self.stopMotorOnLeave = false
    self.steeringEnabled = false
    self.deactivateOnLeave = false
    if self.isServer then
      local difficultyMultiplier = Utils.lerp(0.6, 1, (g_currentMission.missionStats.difficulty - 1) / 2)
      g_currentMission:addSharedMoney(-dt * difficultyMultiplier * self.pricePerMS)
    end
  end
end
function Hirable:draw()
end
function Hirable:hire()
  if not self.isHired then
    Hirable.numHirablesHired = Hirable.numHirablesHired + 1
  end
  self.isHired = true
  self.forceIsActive = true
  self.stopMotorOnLeave = false
  self.steeringEnabled = false
  self.deactivateOnLeave = false
  self.disableCharacterOnLeave = false
end
function Hirable:dismiss()
  if self.isHired then
    Hirable.numHirablesHired = math.max(Hirable.numHirablesHired - 1, 0)
  end
  self.isHired = false
  self.forceIsActive = false
  self.stopMotorOnLeave = true
  self.steeringEnabled = true
  self.deactivateOnLeave = true
  self.disableCharacterOnLeave = true
  if not self.isEntered and not self.isControlled and self.characterNode ~= nil then
    setVisibility(self.characterNode, false)
  end
end
