MissionVehicles = {}
local MissionVehicles_mt = Class(MissionVehicles, FSBaseMission)
function MissionVehicles:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionVehicles_mt
  end
  local self = MissionVehicles:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_RUNNING
  self.playerStartX = -656
  self.playerStartY = 0.2
  self.playerStartZ = -785
  self.playerRotX = 0
  self.playerRotY = Utils.degToRad(220)
  self.vehicleCount = 8
  self.vehiclesNotParked = self.vehicleCount
  self.frameCount = 0
  self.missionTriggers = {}
  return self
end
function MissionVehicles:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionVehicles:superClass().delete(self)
end
function MissionVehicles:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.vehicleList[otherId]
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName)))
  if obj ~= nil then
    if onEnter then
      if obj.number == triggerNumber then
        obj.parked = true
      end
    elseif onLeave then
      obj.parked = false
    end
  end
end
function MissionVehicles:load()
  self.environment = Environment:new("data/sky/sky_day_night.i3d", true, 16, true, false)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 5 do
    AnimalHusbandry.addAnimal()
  end
  self.missionMap = self:loadMap("data/maps/missions/mission_vehicles/vehicleTriggers.i3d")
  setFog("exp", 0.0015, 1, 0.43137254901960786, 0.49019607843137253, 0.5490196078431373)
  local triggerParentId = getChild(self.missionMap, "vehicleTriggers")
  if triggerParentId ~= 0 then
    local numChildren = getNumOfChildren(triggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(triggerParentId, i)
      addTrigger(id, "triggerCallback", self)
      table.insert(self.missionTriggers, id)
    end
  end
  self.vehicleList = {}
  local vehicleId = 0
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronL720.xml", -638.5, 1, -753, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 2
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutz7545RTS.xml", -585, 1, -763, Utils.degToRad(-90)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 8
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronX720.xml", -611.75, 1, -755, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 7
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrovector.xml", -603, 1, -763, Utils.degToRad(-90)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 5
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutz5465H.xml", -642, 1, -763, Utils.degToRad(90)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 1
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutz5695HTS.xml", -590, 1, -753, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 4
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronM620.xml", -627, 1, -763, Utils.degToRad(90)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 6
  self.vehicleList[vehicleId].parked = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgroplus77.xml", -618, 1, -754.5, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].number = 3
  self.vehicleList[vehicleId].parked = false
  MissionVehicles:superClass().load(self)
  g_currentMission.missionPDA.showPDA = false
  self.showHudMissionBase = true
end
function MissionVehicles:loadFinished()
  MissionVehicles:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionVehicles:mouseEvent(posX, posY, isDown, isUp, button)
  MissionVehicles:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionVehicles:keyEvent(unicode, sym, modifier, isDown)
  MissionVehicles:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionVehicles:update(dt)
  MissionVehicles:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.vehiclesNotParked = self.vehicleCount
        for k, v in pairs(self.vehicleList) do
          if v.parked then
            self.vehiclesNotParked = self.vehiclesNotParked - 1
          end
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.vehiclesNotParked == 0 then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionVehicles:superClass().finishMission(self, self.endTime)
        end
        if self.state ~= BaseMission.STATE_FAILED and self.missionTime > self.minTime * 1000 then
          self.state = BaseMission.STATE_FAILED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
        end
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionVehicles:draw()
  MissionVehicles:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    local time = self.minTime * 1000 - self.missionTime
    if time < 60000 then
      setTextColor(1, 0, 0, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionVehicles:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth / 2 - 0.005, 0.915, 0.032, g_i18n:getText("shelterMissionGoal") .. string.format(" %d", self.vehiclesNotParked))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionVehicles:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionVehicles:superClass().drawMissionFailed(self)
    end
  end
end
