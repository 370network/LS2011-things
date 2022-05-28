Milktruck = {}
Milktruck.STATE_WAIT_TO_START = 0
Milktruck.STATE_WAIT_TO_FILL = 1
Milktruck.STATE_DRIVING = 2
function Milktruck.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(TrafficVehicle, specializations)
end
function Milktruck:load(xmlFile)
  self.onEnteredMilktruckStartTrigger = Milktruck.onEnteredMilktruckStartTrigger
  self.onEnteredMilktruckFillTrigger = Milktruck.onEnteredMilktruckFillTrigger
  self.finallySetVehicleToDeleted = Utils.prependedFunction(self.finallySetVehicleToDeleted, Milktruck.finallySetVehicleToDeleted)
  self.milktruckState = Milktruck.STATE_DRIVING
  self.milktruckStartTime1 = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.milktruck#startTime1"), 7) * 1000 * 60 * 60
  self.milktruckStartTime2 = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.milktruck#startTime2"), 18) * 1000 * 60 * 60
  self.milktruckFilledTime = 0
  self.milktruckFillDuration = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.milktruck#fillDuration"), 6) * 1000
  self.milktruckStopNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.milktruck#stopNode"))
  if self.milktruckStopNode == nil then
    self.milktruckStopNode = self.components[1].node
  end
  g_currentMission:addNodeObject(self.milktruckStopNode, self)
end
function Milktruck:delete()
  g_currentMission:removeNodeObject(self.milktruckStopNode)
end
function Milktruck:mouseEvent(posX, posY, isDown, isUp, button)
end
function Milktruck:keyEvent(unicode, sym, modifier, isDown)
end
function Milktruck:update(dt)
  if self.milktruckState == Milktruck.STATE_WAIT_TO_START then
    local dayTime = g_currentMission.environment.dayTime
    if math.abs(dayTime - self.milktruckStartTime1) < 2000 or 2000 > math.abs(dayTime - self.milktruckStartTime2) then
      self.milktruckState = Milktruck.STATE_DRIVING
      self.forceStopMovement = false
    end
  elseif self.milktruckState == Milktruck.STATE_WAIT_TO_FILL and self.time > self.milktruckFilledTime then
    g_currentMission:onPickupMilk()
    self.milktruckState = Milktruck.STATE_DRIVING
    self.forceStopMovement = false
  end
end
function Milktruck:draw()
end
function Milktruck:finallySetVehicleToDeleted()
  if g_currentMission.loadMilktruck ~= nil then
    g_currentMission:loadMilktruck()
  end
end
function Milktruck:onEnteredMilktruckStartTrigger(trigger)
  if self.milktruckState == Milktruck.STATE_DRIVING then
    self.milktruckState = Milktruck.STATE_WAIT_TO_START
    self.forceStopMovement = true
  end
end
function Milktruck:onEnteredMilktruckFillTrigger(trigger)
  if self.milktruckState == Milktruck.STATE_DRIVING then
    self.milktruckState = Milktruck.STATE_WAIT_TO_FILL
    self.forceStopMovement = true
    self.milktruckFilledTime = self.time + self.milktruckFillDuration
  end
end
