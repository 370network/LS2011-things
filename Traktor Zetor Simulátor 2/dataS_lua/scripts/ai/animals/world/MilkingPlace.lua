MilkingPlace = {
  name = "MilkingPlace",
  type = EntityType.OBJECT
}
local MilkingPlace_mt = Class(MilkingPlace, InteractionPlace)
function MilkingPlace:onCreate(milkingPlaceObjectId)
  assert(milkingPlaceObjectId)
  local directionObjectId = getChild(milkingPlaceObjectId, "direction")
  assert(directionObjectId, "You didn't specify the direction object for the feeding place, please check the model and add a child with the name \"direction\" in the direction the animal should face when eating")
  local milkRobotId = getChild(milkingPlaceObjectId, "milkrobot")
  local animationCharacterSet = getAnimCharacterSet(milkRobotId)
  local positionObjectId = getChild(milkingPlaceObjectId, "position")
  local positionX, positionY, positionZ = getWorldTranslation(positionObjectId)
  local tempX, tempY, tempZ = getWorldTranslation(directionObjectId)
  local connectionX, connectionY, connectionZ = tempX - positionX, tempY - positionY, tempZ - positionZ
  local connectionLength = Utils.vector3Length(connectionX, connectionY, connectionZ)
  assert(0 < connectionLength, "distance between position and direction object is not allowed to be 0")
  local directionX, directionY, directionZ = connectionX / connectionLength, connectionY / connectionLength, connectionZ / connectionLength
  delete(positionObjectId)
  delete(directionObjectId)
  local entranceObjectId = getChild(milkingPlaceObjectId, "entrance")
  local entrancePositionX, entrancePositionY, entrancePositionZ = getWorldTranslation(entranceObjectId)
  delete(entranceObjectId)
  local exitObjectId = getChild(milkingPlaceObjectId, "exit")
  local exitPositionX, exitPositionY, exitPositionZ = getWorldTranslation(exitObjectId)
  delete(exitObjectId)
  local farExitObjectId = getChild(milkingPlaceObjectId, "farExit")
  local farExitPositionX, farExitPositionY, farExitPositionZ
  if farExitObjectId and 0 < farExitObjectId then
    farExitPositionX, farExitPositionY, farExitPositionZ = getWorldTranslation(farExitObjectId)
    delete(farExitObjectId)
  else
    farExitPositionX, farExitPositionY, farExitPositionZ = exitPositionX, exitPositionY, exitPositionZ
  end
  local entranceGateObjectId = getChild(milkingPlaceObjectId, "entranceGate")
  local exitGateObjectId = getChild(milkingPlaceObjectId, "exitGate")
  local playerTriggerObjectId = getChild(milkingPlaceObjectId, "playerTrigger")
  MilkingPlace:new(milkingPlaceObjectId, animationCharacterSet, positionX, positionY, positionZ, directionX, directionY, directionZ, entrancePositionX, entrancePositionY, entrancePositionZ, exitPositionX, exitPositionY, exitPositionZ, farExitPositionX, farExitPositionY, farExitPositionZ, entranceGateObjectId, exitGateObjectId, playerTriggerObjectId)
end
function MilkingPlace:new(objectId, animationCharacterSet, positionX, positionY, positionZ, viewingDirectionX, viewingDirectionY, viewingDirectionZ, entrancePositionX, entrancePositionY, entrancePositionZ, exitPositionX, exitPositionY, exitPositionZ, farExitPositionX, farExitPositionY, farExitPositionZ, entranceGateObjectId, exitGateObjectId, playerTriggerObjectId)
  if self == MilkingPlace then
    self = {}
    setmetatable(self, MilkingPlace_mt)
  end
  MilkingPlace:superClass().new(self)
  local presets_hash = {}
  presets_hash.name = MilkingPlace.name
  presets_hash.type = MilkingPlace.type
  presets_hash.positionX, presets_hash.positionY, presets_hash.positionZ = positionX, positionY, positionZ
  presets_hash.approachingPositionX, presets_hash.approachingPositionY, presets_hash.approachingPositionZ = entrancePositionX, entrancePositionY, entrancePositionZ
  MilkingPlace:superClass().initialize(self, presets_hash, 1)
  self.objectId = objectId
  self.isMilkingPlace = true
  self.isAlwaysPerceivable = true
  self.directionX, self.directionY, self.directionZ = viewingDirectionX or 0, viewingDirectionY or 0, viewingDirectionZ or 1
  self.entrancePositionX, self.entrancePositionY, self.entrancePositionZ = entrancePositionX, entrancePositionY, entrancePositionZ
  self.exitPositionX, self.exitPositionY, self.exitPositionZ = exitPositionX, exitPositionY, exitPositionZ
  self.farExitPositionX, self.farExitPositionY, self.farExitPositionZ = farExitPositionX, farExitPositionY, farExitPositionZ
  self.tempPositionX, self.tempPositionY, self.tempPositionZ = self.positionX, self.positionY, self.positionZ
  local entranceConnectionX, entranceConnectionY, entranceConnectionZ = self.positionX - self.entrancePositionX, self.positionY - self.entrancePositionY, self.positionZ - self.entrancePositionZ
  local entranceLength = Utils.vector3Length(entranceConnectionX, entranceConnectionY, entranceConnectionZ)
  assert(0 < entranceLength, "distance between position and entrance object is not allowed to be 0")
  self.entranceDirectionX, self.entranceDirectionY, self.entranceDirectionZ = entranceConnectionX / entranceLength, entranceConnectionY / entranceLength, entranceConnectionZ / entranceLength
  local exitConnectionX, exitConnectionY, exitConnectionZ = self.exitPositionX - self.positionX, self.exitPositionY - self.positionY, self.exitPositionZ - self.positionZ
  local exitLength = Utils.vector3Length(exitConnectionX, exitConnectionY, exitConnectionZ)
  assert(0 < exitLength, "distance between position and exit object is not allowed to be 0")
  self.exitDirectionX, self.exitDirectionY, self.exitDirectionZ = exitConnectionX / exitLength, exitConnectionY / exitLength, exitConnectionZ / exitLength
  self.animationCharacterSet = animationCharacterSet
  self.animationOpenFrontGateClipId = getAnimClipIndex(self.animationCharacterSet, "openFrontGate")
  self.animationCloseFrontGateClipId = getAnimClipIndex(self.animationCharacterSet, "closeFrontGate")
  self.animationOpenBackGateClipId = getAnimClipIndex(self.animationCharacterSet, "openBackGate")
  self.animationCloseBackGateClipId = getAnimClipIndex(self.animationCharacterSet, "closeBackGate")
  self.animationCloseBackOpenFrontGateClipId = getAnimClipIndex(self.animationCharacterSet, "openFrontCloseBackGate")
  assignAnimTrackClip(self.animationCharacterSet, 0, self.animationCloseBackOpenFrontGateClipId)
  enableAnimTrack(self.animationCharacterSet, 0)
  setAnimTrackBlendWeight(self.animationCharacterSet, 0, 1)
  setAnimTrackLoopState(self.animationCharacterSet, 0, false)
  setAnimTrackSpeedScale(self.animationCharacterSet, 0, 1)
  setAnimTrackTime(self.animationCharacterSet, 0, 1)
  self.passiveSound = {}
  self.activeSound = {}
  self.entranceGateSound = {}
  self.exitGateSound = {}
  self.centerSoundOuterRadius = 10
  self.centerSoundInnerRadius = 5
  self.gateSoundOuterRadius = 7
  self.gateSoundInnerRadius = 2
  self.centerObjectId = createTransformGroup("center")
  self.entranceGateObjectId = entranceGateObjectId
  self.exitGateObjectId = exitGateObjectId
  link(self.objectId, self.centerObjectId)
  setTranslation(self.centerObjectId, 0, 0, 0)
  self.passiveSound.audioSource = createAudioSource("passiveSound", "dataS2/character/cow/milkRobotPassive.wav", self.centerSoundOuterRadius, self.centerSoundInnerRadius, 0.6, 0)
  link(self.centerObjectId, self.passiveSound.audioSource)
  self.activeSound.audioSource = createAudioSource("activeSound", "dataS2/character/cow/milkRobotActive.wav", self.centerSoundOuterRadius, self.centerSoundInnerRadius, 1, 0)
  link(self.centerObjectId, self.activeSound.audioSource)
  setVisibility(self.activeSound.audioSource, false)
  self.entranceGateSound.audioSource = createAudioSource("entranceGateSound", "dataS2/character/cow/milkRobotGate.wav", self.gateSoundOuterRadius, self.gateSoundInnerRadius, 1, 1)
  link(self.entranceGateObjectId, self.entranceGateSound.audioSource)
  setVisibility(self.entranceGateSound.audioSource, false)
  self.exitGateSound.audioSource = createAudioSource("exitGateSound", "dataS2/character/cow/milkRobotGate.wav", self.gateSoundOuterRadius, self.gateSoundInnerRadius, 1, 1)
  link(self.exitGateObjectId, self.exitGateSound.audioSource)
  setVisibility(self.exitGateSound.audioSource, false)
  self.stateId = 0
  return self
end
function MilkingPlace:dispose()
  removeContactReport(self.playerTriggerObject)
  disableAnimTrack(self.animationCharacterSet, 0)
  delete(self.animationCharacterSet)
  delete(self.entranceGateSound.audioSource)
  delete(self.exitGateSound.audioSource)
  delete(self.activeSound.audioSource)
  delete(self.passiveSound.audioSource)
  delete(self.objectId)
end
function MilkingPlace:enter(agent)
  self.stateId = 1
  if g_server ~= nil then
    g_server:broadcastEvent(MilkRobotEvent:new(self.stateId))
  end
end
function MilkingPlace:startInteraction(agent)
  assignAnimTrackClip(self.animationCharacterSet, 0, self.animationCloseFrontGateClipId)
  setAnimTrackTime(self.animationCharacterSet, 0, 0)
  self:playEntranceGateSound()
  setVisibility(self.activeSound.audioSource, true)
  self.stateId = 2
  if g_server ~= nil then
    g_server:broadcastEvent(MilkRobotEvent:new(self.stateId))
  end
end
function MilkingPlace:endInteraction(agent)
  assignAnimTrackClip(self.animationCharacterSet, 0, self.animationOpenBackGateClipId)
  setAnimTrackTime(self.animationCharacterSet, 0, 0)
  setVisibility(self.activeSound.audioSource, false)
  self:playExitGateSound()
  self.stateId = 3
  if g_server ~= nil then
    g_currentMission:onCowUsedMilkingPlace()
    g_server:broadcastEvent(MilkRobotEvent:new(self.stateId))
  end
end
function MilkingPlace:leave(agent)
  assignAnimTrackClip(self.animationCharacterSet, 0, self.animationCloseBackOpenFrontGateClipId)
  setAnimTrackTime(self.animationCharacterSet, 0, 0)
  self:playEntranceGateSound()
  self:playExitGateSound()
  self.stateId = 0
  if g_server ~= nil then
    g_server:broadcastEvent(MilkRobotEvent:new(self.stateId))
  end
end
function MilkingPlace:playEntranceGateSound()
  if self.entranceGateSound.audioSource then
    delete(self.entranceGateSound.audioSource)
  end
  self.entranceGateSound.audioSource = createAudioSource("entranceGateSound", "dataS2/character/cow/milkRobotGate.wav", self.gateSoundOuterRadius, self.gateSoundInnerRadius, 1, 1)
  link(self.entranceGateObjectId, self.entranceGateSound.audioSource)
  local sample = getAudioSourceSample(self.entranceGateSound.audioSource)
  setSamplePitch(sample, math.random() + 0.5)
end
function MilkingPlace:playExitGateSound()
  if self.exitGateSound.audioSource then
    delete(self.exitGateSound.audioSource)
  end
  self.exitGateSound.audioSource = createAudioSource("exitGateSound", "dataS2/character/cow/milkRobotGate.wav", self.gateSoundOuterRadius, self.gateSoundInnerRadius, 1, 1)
  link(self.exitGateObjectId, self.exitGateSound.audioSource)
  local sample = getAudioSourceSample(self.exitGateSound.audioSource)
  setSamplePitch(sample, math.random() + 0.5)
end
function MilkingPlace:changeState(newStateId)
  if newStateId == 0 then
    self:leave()
  elseif newStateId == 1 then
    self:enter()
  elseif newStateId == 2 then
    self:startInteraction()
  elseif newStateId == 3 then
    self:endInteraction()
  end
end
function MilkingPlace.getInstance()
end
