MissionShelter = {}
local MissionShelter_mt = Class(MissionShelter, FSBaseMission)
function MissionShelter:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionShelter_mt
  end
  local self = MissionShelter:superClass():new(baseDirectory, mt)
  self.state = BaseMission.STATE_RUNNING
  self.playerStartX = 794.5
  self.playerStartY = 0.2
  self.playerStartZ = -615.5
  self.playerRotX = 0
  self.playerRotY = Utils.degToRad(55)
  self.vehicleCount = 11
  self.vehiclesNotInShelter = self.vehicleCount
  self.frameCount = 0
  self.missionTriggers = {}
  return self
end
function MissionShelter:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionShelter:superClass().delete(self)
end
function MissionShelter:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.vehicleList[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inShelter = true
    elseif onLeave then
      obj.inShelter = false
    end
  end
end
function MissionShelter:load()
  self.environment = Environment:new("data/sky/sky_day_night.i3d", true, 7, true, false)
  self.environment.timeScale = 30
  local rainStartTime = self.environment.timeScale * self.minTime * 1000 / 60000 - self.environment.rainFadeDuration * 0.9
  self.environment:startRain(36000000, Environment.RAINTYPE_RAIN, rainStartTime)
  self:loadMap("data/maps/map01.i3d")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 5 do
    AnimalHusbandry.addAnimal()
  end
  self.missionMap = self:loadMap("data/maps/missions/mission_shelter/shelterTriggers.i3d")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local triggerParentId = getChild(self.missionMap, "shelterTriggers")
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
  vehicleId = self:loadVehicle("data/vehicles/steerable/krone/kroneBigX1000.xml", 785, 1, -626, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/krone/kroneEasyCollect1053.xml", 785, 1, -620, Utils.degToRad(180)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronM620.xml", -95, 1, -543, Utils.degToRad(270)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/tools/sowingMachine01.xml", -91, 1, -543, Utils.degToRad(270)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/tools/poettinger/synkro4003k.xml", -118, 1, -530, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutz5465H.xml", -585, 1, 690, Utils.degToRad(180)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/cutters/deutz/deutzCutter5465H.xml", -585, 1, 680, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgroplus77.xml", 594, 1, 114, Utils.degToRad(-45)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  vehicleId = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronX720.xml", -597, 1, 150, Utils.degToRad(0)).rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  local trailer = self:loadVehicle("data/vehicles/trailers/smallTipper.xml", -597, 1, 140, Utils.degToRad(0))
  trailer:setFillLevel(5000, Fillable.FILLTYPE_MAIZE)
  vehicleId = trailer.rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  trailer = self:loadVehicle("data/vehicles/trailers/mediumTipper.xml", -601, 1, 180, Utils.degToRad(0))
  trailer:setFillLevel(16000, Fillable.FILLTYPE_MAIZE)
  vehicleId = trailer.rootNode
  self.vehicleList[vehicleId] = {}
  self.vehicleList[vehicleId].inShelter = false
  MissionShelter:superClass().load(self)
  g_currentMission.missionPDA.showPDA = false
  self.showHudMissionBase = true
end
function MissionShelter:loadFinished()
  MissionShelter:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionShelter:mouseEvent(posX, posY, isDown, isUp, button)
  MissionShelter:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionShelter:keyEvent(unicode, sym, modifier, isDown)
  MissionShelter:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionShelter:update(dt)
  MissionShelter:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.vehiclesNotInShelter = self.vehicleCount
        for k, v in pairs(self.vehicleList) do
          if v.inShelter then
            self.vehiclesNotInShelter = self.vehiclesNotInShelter - 1
          end
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.vehiclesNotInShelter == 0 then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionShelter:superClass().finishMission(self, self.endTime)
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
function MissionShelter:draw()
  MissionShelter:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    local time = self.minTime * 1000 - self.missionTime
    if time < 60000 then
      setTextColor(1, 0, 0, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionShelter:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth / 2 - 0.005, 0.915, 0.032, g_i18n:getText("shelterMissionGoal") .. string.format(" %d", self.vehiclesNotInShelter))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionShelter:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionShelter:superClass().drawMissionFailed(self)
    end
  end
end
