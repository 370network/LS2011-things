MissionAutoStacking = {}
local MissionAutoStacking_mt = Class(MissionAutoStacking, FSBaseMission)
function MissionAutoStacking:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = MissionAutoStacking_mt
  end
  local self = MissionAutoStacking:superClass():new(baseDirectory, mt)
  self.playerStartX = 645.2
  self.playerStartY = 0.1
  self.playerStartZ = -782.9
  self.playerRotX = Utils.degToRad(0)
  self.playerRotY = Utils.degToRad(225)
  self.missionPercent = 0
  self.baleCount = 0
  self.neededBales = 24
  self.missionTriggers = {}
  self.missionBales = {}
  self.missionBalesCount = 0
  self.frameCount = 0
  self.state = BaseMission.STATE_WAITING
  return self
end
function MissionAutoStacking:delete()
  for _, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionAutoStacking:superClass().delete(self)
end
function MissionAutoStacking:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.missionBales[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inTriggerCount = obj.inTriggerCount + 1
    elseif onLeave then
      obj.inTriggerCount = obj.inTriggerCount - 1
    end
  end
end
function MissionAutoStacking:load()
  self.environment = Environment:new("data/sky/sky_lightClouds.i3d", false, 14)
  self.environment.timeScale = 1
  self:loadMap("data/maps/map01.i3d")
  self.missionPDA:loadMap("data/maps/map01/pda_map.png")
  self:loadMap("data/maps/map01/paths/trafficPaths.i3d")
  self:loadMap("data/maps/map01/paths/pedestrianPaths.i3d")
  self.missionMap = self:loadMap("data/maps/missions/mission_autoStacking/mission_autoStacking.i3d")
  setLightDiffuseColor(self.environment.sunLightId, 0.803921568627451, 0.803921568627451, 0.8627450980392157)
  setLightSpecularColor(self.environment.sunLightId, 0.7058823529411765, 0.7843137254901961, 0.7843137254901961)
  setAmbientColor(0.37254901960784315, 0.4117647058823529, 0.45098039215686275)
  setFog("exp", 0.0015, 1, 0.39215686274509803, 0.39215686274509803, 0.4117647058823529)
  AnimalHusbandry.initialize()
  self:loadMap("data/maps/missions/CattleMeadow.i3d")
  for i = 1, 3 do
    AnimalHusbandry.addAnimal()
  end
  local tractor = self:loadVehicle("data/vehicles/steerable/deutz/deutzAgrotronL720.xml", 651, 1, -768.25, Utils.degToRad(0))
  local autoStacker = self:loadVehicle("data/vehicles/trailers/baleLoader.xml", 651, 1, -776, Utils.degToRad(0))
  local cutBarleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].cutShortId
  setDensityMaskedParallelogram(cutBarleyId, 645, -765, 120, 0, 0, 160, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  local triggerParentId = getChild(self.missionMap, "triggers")
  if triggerParentId ~= 0 then
    local numChildren = getNumOfChildren(triggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(triggerParentId, i)
      addTrigger(id, "triggerCallback", self)
      table.insert(self.missionTriggers, id)
    end
  end
  local transformGroupId = getChild(self.missionMap, "strawBales")
  if transformGroupId ~= 0 then
    local numChildren = getNumOfChildren(transformGroupId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(transformGroupId, i)
      local x, y, z = getTranslation(id)
      local xr, yr, zr = getRotation(id)
      local baleObject = Bale:new(self:getIsServer(), self:getIsClient())
      baleObject:load("data/maps/models/objects/strawbale/strawbaleBaler.i3d", x, y, z, xr, yr, zr)
      baleObject:register()
      self.missionBales[baleObject.nodeId] = {}
      self.missionBales[baleObject.nodeId].inTriggerCount = 0
    end
  end
  MissionAutoStacking:superClass().load(self)
  self.missionPDA:createMapHotspot("Farm", "dataS2/missions/hud_pda_spot_yellow.png", 996, 720, self.missionPDA.pdaMapArrowSize / 3, self.missionPDA.pdaMapArrowSize * 1.3333333333333333 / 3, false, true, 0)
  self.missionPDA.showPDA = false
  self.showHudEnv = false
  self.showHudMissionBase = true
  self.state = BaseMission.STATE_RUNNING
end
function MissionAutoStacking:loadFinished()
  MissionAutoStacking:superClass().loadFinished(self)
  AnimalHusbandry.finalize()
end
function MissionAutoStacking:mouseEvent(posX, posY, isDown, isUp, button)
  MissionAutoStacking:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionAutoStacking:keyEvent(unicode, sym, modifier, isDown)
  MissionAutoStacking:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionAutoStacking:update(dt)
  MissionAutoStacking:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.missionBalesCount = 0
        for k, v in pairs(self.missionBales) do
          if 0 < v.inTriggerCount then
            self.missionBalesCount = self.missionBalesCount + 1
          end
        end
        if self.missionTime > self.minTime * 1000 then
          self.state = BaseMission.STATE_FAILED
          self.endTime = self.time
          self.endTimeStamp = self.time + self.endDelayTime
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.missionBalesCount >= self.neededBales then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionAutoStacking:superClass().finishMission(self, self.endTime)
          MissionAutoStacking:superClass().drawMissionCompleted(self)
        end
        self.frameCount = 0
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionAutoStacking:draw()
  MissionAutoStacking:superClass().draw(self)
  if self.isRunning and g_gui.currentGui == nil and self.showHudMissionBase then
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth / 2 - 0.005, 0.915, 0.032, g_i18n:getText("autoStackingMissionGoal") .. string.format(" %d", self.missionBalesCount))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionAutoStacking:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionAutoStacking:superClass().drawMissionFailed(self)
    end
  end
end
