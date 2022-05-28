Animation = {}
function Animation.loadAnimationsFromXML(characterSet, xmlFile, xmlBaseName, animationsHash, animationStatesHash)
  local i = 0
  while true do
    local baseName = xmlBaseName .. string.format(".animation(%d)", i)
    if not Animation.loadAnimationFromXML(characterSet, xmlFile, baseName, animationsHash, animationStatesHash, Animation) then
      break
    end
    i = i + 1
  end
end
function Animation.loadAnimationFromXML(characterSet, xmlFile, baseName, animationsHash, animationStatesHash)
  local animationName = getXMLString(xmlFile, baseName .. "#name")
  if animationName == nil then
    return false
  end
  if animationName == "" then
    error("error: you have to specifiy an animation name and state")
    return false
  end
  if animationsHash[animationName] then
    error("error: the given animation name \"" .. animationName .. "\" was specified multiple times")
    return false
  end
  local animationType = getXMLString(xmlFile, baseName .. "#type")
  local animationStateName = getXMLString(xmlFile, baseName .. "#state")
  local animationCanLoop = getXMLBool(xmlFile, baseName .. "#loop") or false
  local animationInitialTimeFunction = getXMLString(xmlFile, baseName .. "#initialTime") or "noChange"
  local animationClass
  if animationType == "animation" then
    animationClass = Animation
  elseif animationType == "walkAnimation" then
    animationClass = WalkAnimation
  elseif animationType == "mixAnimation" then
    animationClass = MixAnimation
  elseif animationType == "walkMixAnimation" then
    animationClass = WalkMixAnimation
  else
    error("error: unknown animation type \"" .. animationType .. "\"")
    return false
  end
  if not animationStatesHash[animationStateName] then
    error("error: the given animation state name \"" .. animationStateName .. "\" was not specified before")
    return false
  end
  local animationClipName = getXMLString(xmlFile, baseName .. "#clipName")
  local animationSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#speed"), 1)
  local averageClipSpeed = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#averageClipSpeed"), 1)
  local clipName, clipId, clipDuration
  if animationClipName then
    clipName = animationClipName or animationName
    clipId = getAnimClipIndex(characterSet, clipName)
    if not clipId or clipId == -1 then
      error("error: the specified clip name \"" .. clipName .. "\" is not associated with an animation clip")
      return false
    end
    clipDuration = getAnimClipDuration(characterSet, clipId)
  end
  local animationWalkDistance = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#distance"), 0)
  local animationRotationAngle = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#angle"), 0)
  local animationFinalTranslationX, animationFinalTranslationY, animationFinalTranslationZ = Utils.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, baseName .. "#finalTranslation"), "0.0 0.0 0.0"))
  local animationFinalRotationX, animationFinalRotationY, animationFinalRotationZ = Utils.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, baseName .. "#finalRotation"), "0.0 0.0 0.0"))
  local animationPositionUpdater = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#positionUpdate"), "none")
  local animationSpeedScaleUpdater = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#speedScaleUpdate"), "none")
  local mixingAnimation1Name = getXMLString(xmlFile, baseName .. "#animation1Name")
  local mixingAnimation2Name = getXMLString(xmlFile, baseName .. "#animation2Name")
  local mixingVariableName = getXMLString(xmlFile, baseName .. "#mixingVariable")
  local mixingVariableMinValue = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#minValue"), 0)
  local mixingVariableMaxValue = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#maxValue"), 0)
  local isSecondAnimationDriving = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#isSecondAnimationDriving"), false)
  local animation1
  if mixingAnimation1Name then
    if not mixingAnimation1Name or mixingAnimation1Name == "" or not animationsHash[mixingAnimation1Name] then
      error("error: the given animation name \"" .. mixingAnimation1Name .. "\" was not specified before")
      return false
    end
    animation1 = animationsHash[mixingAnimation1Name]
  end
  local animation2
  if mixingAnimation2Name then
    if not mixingAnimation2Name or mixingAnimation2Name == "" or not animationsHash[mixingAnimation2Name] then
      error("error: the given animation name \"" .. mixingAnimation2Name .. "\" was not specified before")
      return false
    end
    animation2 = animationsHash[mixingAnimation2Name]
  end
  if mixingVariableName then
    if mixingVariableName ~= "distance" and mixingVariableName ~= "angle" and mixingVariableName ~= "forwardSpeed" then
      print("warning: unknown variable name used (" .. mixingVariableName .. ")")
    end
    if mixingVariableName == "angle" then
      mixingVariableMinValue = mixingVariableMinValue / 180 * math.pi
      mixingVariableMaxValue = mixingVariableMaxValue / 180 * math.pi
    end
  end
  if mixingVariableMinValue and mixingVariableMaxValue and mixingVariableMinValue > mixingVariableMaxValue then
    error("error: min value has to be smaller than max value")
    return false
  end
  local animation = animationClass:new({
    name = animationName,
    stateName = animationStateName,
    state = animationStatesHash[animationStateName],
    canLoop = animationCanLoop,
    initialTimeFunction = animationInitialTimeFunction,
    clipName = clipName,
    clipId = clipId,
    duration = clipDuration,
    speedScale = animationSpeedScale,
    averageClipSpeed = averageClipSpeed,
    walkDistance = animationWalkDistance,
    rotationAngle = animationRotationAngle / 180 * math.pi,
    finalTranslationX = animationFinalTranslationX,
    finalTranslationY = animationFinalTranslationY,
    finalTranslationZ = animationFinalTranslationZ,
    finalRotationX = animationFinalRotationX / 180 * math.pi,
    finalRotationY = animationFinalRotationY / 180 * math.pi,
    finalRotationZ = animationFinalRotationZ / 180 * math.pi,
    positionUpdater = animationPositionUpdater,
    speedScaleUpdater = animationSpeedScaleUpdater,
    animation1Name = mixingAnimation1Name,
    animation1 = animation1,
    animation2Name = mixingAnimation2Name,
    animation2 = animation2,
    mixingVariable = mixingVariableName,
    minValue = mixingVariableMinValue,
    maxValue = mixingVariableMaxValue,
    isSecondAnimationDriving = isSecondAnimationDriving
  })
  animationsHash[animation.name] = animation
  return animation
end
local Animation_mt = Class(Animation)
function Animation:new(presetsHash)
  if self == Animation then
    self = setmetatable({}, Animation_mt)
  end
  if not presetsHash.name then
    error("animation name not specified")
  end
  if not presetsHash.stateName then
    error("animation stateName not specified")
  end
  if not presetsHash.state then
    error("animation state not specified")
  end
  if presetsHash.canLoop == nil then
    error("animation canLoop not specified")
  end
  if not presetsHash.clipName then
    error("animation clipName not specified")
  end
  if not presetsHash.clipId then
    error("animation clipId not specified")
  end
  if not presetsHash.duration then
    error("animation duration not specified")
  end
  if not presetsHash.speedScale then
    error("animation speedScale not specified")
  end
  self.name = presetsHash.name
  self.stateName = presetsHash.stateName
  self.state = presetsHash.state
  self.canLoop = presetsHash.canLoop
  self.clipName = presetsHash.clipName
  self.clipId = presetsHash.clipId
  self.duration = presetsHash.duration
  self.speedScale = presetsHash.speedScale
  self.averageClipSpeed = presetsHash.averageClipSpeed
  if self.averageClipSpeed == 0 then
    print("Error: averageClipSpeed is 0")
  end
  if presetsHash.initialTimeFunction == "noChange" then
    function self.initialTimeFunction(initialTime)
      return initialTime
    end
  elseif presetsHash.initialTimeFunction == "zero" then
    function self.initialTimeFunction(initialTime)
      return 0
    end
  elseif type(presetsHash.initialTimeFunction) == "number" then
    do
      local initialTimeValue = presetsHash.initialTimeFunction
      function self.initialTimeFunction(initialTime)
        return initialTimeValue
      end
    end
  else
    error(string.format("unknown time function name \"%s\" (animation name \"%s\")", tostring(presetsHash.initialTimeFunction), self.name))
  end
  if self.speedScale > 0 then
    self.duration = self.duration * (1 / self.speedScale)
  end
  return self
end
function Animation:prepare(agent, agentAnimationData)
  agentAnimationData[self] = {
    instances = {}
  }
end
function Animation:start(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationData = agentAnimationData[self]
  local assignedTrackId = table.remove(agentAnimationData.freeTrackIds)
  if not assignedTrackId then
    print("could not retrieve new free track")
    return nil
  end
  agentAnimationData.usedTrackIds[assignedTrackId] = self
  local animationInstance = tableToUseForInstance or {}
  animationInstance.animation = self
  animationInstance.name = self.name
  function animationInstance.class()
    return nil
  end
  animationInstance.update = Animation.update
  animationInstance.stop = Animation.stop
  animationInstance.startDrivingAnimation = Animation.startDrivingAnimation
  animationInstance.updateDrivingAnimation = Animation.updateDrivingAnimation
  animationInstance.stopDrivingAnimation = Animation.stopDrivingAnimation
  animationInstance.handleNotDrivingAnimationAnymore = Animation.handleNotDrivingAnimationAnymore
  animationInstance.getRemainingTime = Animation.getRemainingTime
  animationInstance.clipTime = initialTime
  animationInstance.averageClipSpeed = self.averageClipSpeed
  animationInstance.getNeededTrackCount = Animation.getNeededTrackCount
  animationInstance.assignedTrackId = assignedTrackId
  animationData.instances[animationInstance] = true
  local characterSet = agentAnimationData.characterSet
  initialTime = self.initialTimeFunction(initialTime)
  assignAnimTrackClip(characterSet, assignedTrackId, self.clipId)
  enableAnimTrack(characterSet, assignedTrackId)
  setAnimTrackBlendWeight(characterSet, assignedTrackId, 1)
  setAnimTrackLoopState(characterSet, assignedTrackId, false)
  setAnimTrackSpeedScale(characterSet, assignedTrackId, self.speedScale)
  setAnimTrackTime(characterSet, assignedTrackId, initialTime)
  BlendTree.animationStarted(agent, agentAnimationData, self)
  return animationInstance
end
function Animation:update(agent, agentAnimationData, blendWeight, dt)
  setAnimTrackBlendWeight(agentAnimationData.characterSet, self.assignedTrackId, blendWeight)
  self.lastUsedBlendWeight = blendWeight
end
function Animation:stop(agent, agentAnimationData)
  local animationData = agentAnimationData[self.animation]
  disableAnimTrack(agentAnimationData.characterSet, self.assignedTrackId)
  table.insert(agentAnimationData.freeTrackIds, self.assignedTrackId)
  agentAnimationData.usedTrackIds[self.assignedTrackId] = nil
  self.assignedTrackId = nil
  BlendTree.animationStopped(agent, agentAnimationData, self.animation)
  animationData.instances[self] = nil
end
function Animation:getNeededTrackCount()
  return 1
end
function Animation:startDrivingAnimation(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationInstance = self:start(agent, agentAnimationData, initialTime, tableToUseForInstance)
  return animationInstance
end
function Animation:updateDrivingAnimation(agent, agentAnimationData, dt)
  self.clipTime = getAnimTrackTime(agentAnimationData.characterSet, self.assignedTrackId)
  return self.animation.duration <= self.clipTime
end
function Animation:handleNotDrivingAnimationAnymore(agent, agentAnimationData)
end
function Animation:stopDrivingAnimation(agent, agentAnimationData)
  local remainingTime = self:getRemainingTime(agent, agentAnimationData)
  remainingTime = remainingTime % self.animation.duration
  self:stop(agent, agentAnimationData)
  return remainingTime
end
function Animation:getRemainingTime(agent, agentAnimationData)
  local remainingTime = getAnimTrackTime(agentAnimationData.characterSet, self.assignedTrackId)
  return remainingTime
end
WalkAnimation = {}
local WalkAnimation_mt = Class(WalkAnimation, Animation)
function WalkAnimation:new(presetsHash)
  if self == WalkAnimation then
    self = setmetatable({}, WalkAnimation_mt)
  end
  if not presetsHash.positionUpdater then
    error("animation positionUpdater not specified")
  end
  if not presetsHash.speedScaleUpdater then
    error("animation speedScaleUpdater not specified")
  end
  Animation.new(self, presetsHash)
  self.positionUpdater = PositionUpdater:load(presetsHash.positionUpdater)
  self.speedScaleUpdater = SpeedScaleUpdater:load(presetsHash.speedScaleUpdater)
  return self
end
function WalkAnimation:start(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationInstance = Animation.start(self, agent, agentAnimationData, initialTime, tableToUseForInstance)
  if not animationInstance then
    return nil
  end
  animationInstance.update = WalkAnimation.update
  animationInstance.stop = WalkAnimation.stop
  animationInstance.startDrivingAnimation = WalkAnimation.startDrivingAnimation
  animationInstance.updateDrivingAnimation = WalkAnimation.updateDrivingAnimation
  animationInstance.stopDrivingAnimation = WalkAnimation.stopDrivingAnimation
  animationInstance.getRemainingTime = WalkAnimation.getRemainingTime
  animationInstance.handleNotDrivingAnimationAnymore = WalkAnimation.handleNotDrivingAnimationAnymore
  animationInstance.getNeededTrackCount = WalkAnimation.getNeededTrackCount
  animationInstance.positionUpdater = self.positionUpdater
  animationInstance.speedScaleUpdater = self.speedScaleUpdater
  animationInstance.speedScaleUpdater:start(agent, agentAnimationData, animationInstance)
  return animationInstance
end
function WalkAnimation:update(agent, agentAnimationData, blendWeight, dt)
  Animation.update(self, agent, agentAnimationData, blendWeight, dt)
  self.speedScaleUpdater:update(agent, agentAnimationData, self, dt)
end
function WalkAnimation:stop(agent, agentAnimationData)
  self.speedScaleUpdater:stop(agent, agentAnimationData, self)
  Animation.stop(self, agent, agentAnimationData)
end
function WalkAnimation:getNeededTrackCount()
  return 1
end
function WalkAnimation:startDrivingAnimation(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationInstance = WalkAnimation.start(self, agent, agentAnimationData, initialTime, tableToUseForInstance)
  self.positionUpdater:start(agent, agentAnimationData)
  return animationInstance
end
function WalkAnimation:updateDrivingAnimation(agent, agentAnimationData, dt)
  local result = Animation.updateDrivingAnimation(self, agent, agentAnimationData, dt)
  self.positionUpdater:update(agent, agentAnimationData, dt)
  return result
end
function WalkAnimation:handleNotDrivingAnimationAnymore(agent, agentAnimationData)
  self.positionUpdater:stop(agent, agentAnimationData)
  Animation.handleNotDrivingAnimationAnymore(self, agent, agentAnimationData)
end
function WalkAnimation:stopDrivingAnimation(agent, agentAnimationData)
  self.positionUpdater:stop(agent, agentAnimationData)
  return Animation.stopDrivingAnimation(self, agent, agentAnimationData)
end
MixAnimation = {}
local MixAnimation_mt = Class(MixAnimation, Animation)
function MixAnimation:new(presetsHash)
  if self == MixAnimation then
    self = setmetatable({}, MixAnimation_mt)
  end
  if not presetsHash.animation1Name then
    error("MixAnimation:new - animation1Name not specified")
  end
  if not presetsHash.animation1 then
    error("MixAnimation:new - animation1 not specified")
  end
  if not presetsHash.animation2Name then
    error("MixAnimation:new - animation2Name not specified")
  end
  if not presetsHash.animation2 then
    error("MixAnimation:new - animation2 not specified")
  end
  if not presetsHash.mixingVariable then
    error("MixAnimation:new - mixingVariable not specified")
  end
  if not presetsHash.minValue then
    error("MixAnimation:new - minValue not specified")
  end
  if not presetsHash.maxValue then
    error("MixAnimation:new - maxValue not specified")
  end
  self.animation1Name = presetsHash.animation1Name
  self.animation1 = presetsHash.animation1
  self.animation2Name = presetsHash.animation2Name
  self.animation2 = presetsHash.animation2
  self.mixingVariable = presetsHash.mixingVariable
  self.minValue = presetsHash.minValue
  self.maxValue = presetsHash.maxValue
  self.valueRange = self.maxValue - self.minValue
  self.isFirstAnimationDriving = not presetsHash.isSecondAnimationDriving
  if valueRange == 0 then
    error("MixAnimation:new - valueRange is 0")
  end
  local baseClassData = {
    name = presetsHash.name,
    stateName = presetsHash.stateName,
    state = presetsHash.state,
    canLoop = presetsHash.animation1.canLoop and presetsHash.animation2.canLoop,
    initialTimeFunction = presetsHash.initialTimeFunction,
    clipName = self.isFirstAnimationDriving and self.animation1.clipName or self.animation2.clipName,
    clipId = self.isFirstAnimationDriving and self.animation1.clipId or self.animation2.clipId,
    duration = self.isFirstAnimationDriving and self.animation1.duration or self.animation2.duration,
    speedScale = self.isFirstAnimationDriving and self.animation1.speedScale or self.animation2.speedScale
  }
  Animation.new(self, baseClassData)
  self.averageClipSpeed = self.isFirstAnimationDriving and self.animation1.averageClipSpeed or self.animation2.averageClipSpeed
  return self
end
function MixAnimation:start(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationData = agentAnimationData[self]
  initialTime = self.initialTimeFunction(initialTime)
  local animation1Instance = self.animation1:start(agent, agentAnimationData, initialTime)
  if not animation1Instance then
    return nil
  end
  local animation2Instance = self.animation2:start(agent, agentAnimationData, initialTime)
  if not animation2Instance then
    animation1Instance:stop(agent, agentAnimationData)
    return nil
  end
  local animationInstance = tableToUseForInstance or {}
  animationInstance.animation = self
  animationInstance.animation1 = self.animation1
  animationInstance.animation2 = self.animation2
  animationInstance.name = self.name
  function animationInstance.class()
    return nil
  end
  animationInstance.update = MixAnimation.update
  animationInstance.stop = MixAnimation.stop
  animationInstance.startDrivingAnimation = MixAnimation.startDrivingAnimation
  animationInstance.updateDrivingAnimation = MixAnimation.updateDrivingAnimation
  animationInstance.stopDrivingAnimation = MixAnimation.stopDrivingAnimation
  animationInstance.handleNotDrivingAnimationAnymore = MixAnimation.handleNotDrivingAnimationAnymore
  animationInstance.getRemainingTime = MixAnimation.getRemainingTime
  animationInstance.getNeededTrackCount = MixAnimation.getNeededTrackCount
  animationData.instances[animationInstance] = true
  animationInstance.assignedTrackId = self.isFirstAnimationDriving and animation1Instance.assignedTrackId or animation2Instance.assignedTrackId
  animationInstance.clipTime = self.isFirstAnimationDriving and animation1Instance.clipTime or animation2Instance.clipTime
  animationInstance.animation1Instance = animation1Instance
  animationInstance.animation2Instance = animation2Instance
  return animationInstance
end
function MixAnimation:update(agent, agentAnimationData, availableBlendWeight, dt)
  local mixingValue = agentAnimationData[self.animation.mixingVariable]
  local mixingRatio = (mixingValue - self.animation.minValue) / self.animation.valueRange
  local animationFinished
  if mixingRatio < 0 then
    mixingRatio = 0
    animationFinished = true
  elseif 1 < mixingRatio then
    mixingRatio = 1
    animationFinished = true
  end
  local averageClipSpeed = self.averageClipSpeed or (1 - mixingRatio) * self.animation1.averageClipSpeed + mixingRatio * self.animation2.averageClipSpeed
  self.animation1Instance.averageClipSpeed = averageClipSpeed
  self.animation2Instance.averageClipSpeed = averageClipSpeed
  self.animation1Instance:update(agent, agentAnimationData, availableBlendWeight * (1 - mixingRatio), dt)
  self.animation2Instance:update(agent, agentAnimationData, availableBlendWeight * mixingRatio, dt)
  self.averageClipSpeed = nil
  self.mixingRatio = mixingRatio
  return animationFinished
end
function MixAnimation:stop(agent, agentAnimationData)
  if self and self.animation and agentAnimationData and agentAnimationData[self.animation] and agentAnimationData[self.animation].instances then
    agentAnimationData[self.animation].instances[self] = nil
  end
  self.animation1Instance:stop(agent, agentAnimationData)
  self.animation2Instance:stop(agent, agentAnimationData)
end
function MixAnimation:getNeededTrackCount()
  return self.animation1:getNeededTrackCount() + self.animation2:getNeededTrackCount()
end
function MixAnimation:updateDrivingAnimation(agent, agentAnimationData, dt)
  self.clipTime = getAnimTrackTime(agentAnimationData.characterSet, self.animation1Instance.assignedTrackId)
  return self.animation.duration <= self.clipTime
end
function MixAnimation:getRemainingTime(agent, agentAnimationData)
  local remainingTime1 = self.animation1Instance:getRemainingTime(agent, agentAnimationData)
  local remainingTime2 = self.animation2Instance:getRemainingTime(agent, agentAnimationData)
  local remainingTime = math.max(remainingTime1, remainingTime2)
  return remainingTime
end
WalkMixAnimation = {}
local WalkMixAnimation_mt = Class(WalkMixAnimation, MixAnimation)
function WalkMixAnimation:new(presetsHash)
  if self == WalkMixAnimation then
    self = setmetatable({}, WalkMixAnimation_mt)
  end
  MixAnimation.new(self, presetsHash)
  if self.animation1.positionUpdater ~= self.animation2.positionUpdater then
    error(string.format("specified animations (%s, %s) use different way of updating the positions", self.animation1.name, self.animation2.name))
  end
  self.positionUpdater = self.animation1.positionUpdater
  return self
end
function WalkMixAnimation:start(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationInstance = MixAnimation.start(self, agent, agentAnimationData, initialTime, tableToUseForInstance)
  if not animationInstance then
    return nil
  end
  animationInstance.updateDrivingAnimation = WalkMixAnimation.updateDrivingAnimation
  animationInstance.stopDrivingAnimation = WalkMixAnimation.stopDrivingAnimation
  animationInstance.handleNotDrivingAnimationAnymore = WalkMixAnimation.handleNotDrivingAnimationAnymore
  animationInstance.positionUpdater = self.positionUpdater
  return animationInstance
end
function WalkMixAnimation:startDrivingAnimation(agent, agentAnimationData, initialTime, tableToUseForInstance)
  local animationInstance = MixAnimation.startDrivingAnimation(self, agent, agentAnimationData, initialTime, tableToUseForInstance)
  if not animationInstance then
    return nil
  end
  animationInstance.updateDrivingAnimation = WalkMixAnimation.updateDrivingAnimation
  animationInstance.stopDrivingAnimation = WalkMixAnimation.stopDrivingAnimation
  animationInstance.handleNotDrivingAnimationAnymore = WalkMixAnimation.handleNotDrivingAnimationAnymore
  self.positionUpdater:start(agent, agentAnimationData)
  return animationInstance
end
function WalkMixAnimation:updateDrivingAnimation(agent, agentAnimationData, dt)
  local result = MixAnimation.updateDrivingAnimation(self, agent, agentAnimationData, dt)
  self.positionUpdater:update(agent, agentAnimationData, dt)
  return result
end
function WalkMixAnimation:handleNotDrivingAnimationAnymore(agent, agentAnimationData)
  self.positionUpdater:stop(agent, agentAnimationData)
  MixAnimation.handleNotDrivingAnimationAnymore(self, agent, agentAnimationData)
end
function WalkMixAnimation:stopDrivingAnimation(agent, agentAnimationData)
  self.positionUpdater:stop(agent, agentAnimationData)
  local result = MixAnimation.stopDrivingAnimation(self, agent, agentAnimationData)
  return result
end
function Animation:getCurrentPosition(agent, agentAnimationData)
  return agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ
end
function WalkAnimation:getCurrentPosition(agent, agentAnimationData)
  local positionDisplacementX, positionDisplacementY, positionDisplacementZ = self.positionUpdater:getCurrentDisplacement(agent, agentAnimationData)
  return agentAnimationData.animationPositionX + positionDisplacementX, agentAnimationData.animationPositionY + positionDisplacementY, agentAnimationData.animationPositionZ + positionDisplacementZ
end
