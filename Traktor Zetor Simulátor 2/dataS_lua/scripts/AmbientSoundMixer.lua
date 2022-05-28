AmbientSoundMixer = {
  DEFAULT_BASICVOLUME = 0.5,
  DEFAULT_SOUNDCOUNT = 0,
  CROSSFADE_TIME = 5000,
  POSTPONE_TIME = 5000,
  DEFAULT_SAMPLEDELAY = 200000,
  STATUS_FADEIN = 1,
  STATUS_PLAY = 2,
  STATUS_FADEOUT = 3,
  STATUS_DELAY = 4,
  SOUNDTYPE_BACKGROUND = 1,
  SOUNDTYPE_CONTINUING = 2,
  SOUNDTYPE_INTERMITTENT = 3
}
local AmbientSoundMixer_mt = Class(AmbientSoundMixer)
function AmbientSoundMixer:new(uses3DSounds)
  self = setmetatable({}, AmbientSoundMixer_mt)
  self.backgroundSounds = {}
  self.continuingSounds = {}
  self.intermittentSounds = {}
  self.activeSounds = {}
  self.updatingSounds = {}
  self.updatingSoundsCount = 0
  self.totalTime = 0
  self.uses3DSounds = uses3DSounds
  return self
end
function AmbientSoundMixer:loadBackgroundSounds(backgroundSoundList)
  for _, sound in ipairs(backgroundSoundList) do
    sound.soundType = AmbientSoundMixer.SOUNDTYPE_BACKGROUND
    table.insert(self.backgroundSounds, sound)
  end
end
function AmbientSoundMixer:loadContinuingSounds(continuingSoundList, numberOfSimultaneousSounds, minimumSoundPlayTime, maximumSoundPlayTime)
  for _, sound in ipairs(continuingSoundList) do
    sound.soundType = AmbientSoundMixer.SOUNDTYPE_CONTINUING
    table.insert(self.continuingSounds, sound)
  end
  self.numberOfSimultaneousContinuingSounds = self.numberOfSimultaneousContinuingSounds and numberOfSimultaneousSounds and math.min(self.numberOfSimultaneousContinuingSounds, numberOfSimultaneousSounds) or self.numberOfSimultaneousContinuingSounds or numberOfSimultaneousSounds
  self.minimumContinuingSoundPlayTime = self.minimumContinuingSoundPlayTime and minimumSoundPlayTime and math.min(self.minimumContinuingSoundPlayTime, minimumSoundPlayTime) or self.minimumContinuingSoundPlayTime or minimumSoundPlayTime
  self.maximumContinuingSoundPlayTime = self.maximumContinuingSoundPlayTime and maximumSoundPlayTime and math.min(self.maximumContinuingSoundPlayTime, maximumSoundPlayTime) or self.maximumContinuingSoundPlayTime or maximumSoundPlayTime
end
function AmbientSoundMixer:loadIntermittentSounds(intermittentSoundList, numberOfSimultaneousSounds, minimumSoundPlayTime, maximumSoundPlayTime)
  for _, sound in ipairs(intermittentSoundList) do
    sound.soundType = AmbientSoundMixer.SOUNDTYPE_INTERMITTENT
    sound.minimumPauseTime = sound.minimumPauseTime or 0
    sound.maximumPauseTime = sound.maximumPauseTime or AmbientSoundMixer.DEFAULT_SAMPLEDELAY
    sound.minimumPauseTime = math.min(sound.minimumPauseTime, sound.maximumPauseTime)
    sound.maximumPauseTime = math.max(sound.minimumPauseTime, sound.maximumPauseTime)
    table.insert(self.intermittentSounds, sound)
  end
  self.numberOfSimultaneousIntermittentSounds = self.numberOfSimultaneousIntermittentSounds and numberOfSimultaneousSounds and math.min(self.numberOfSimultaneousIntermittentSounds, numberOfSimultaneousSounds) or self.numberOfSimultaneousIntermittentSounds or numberOfSimultaneousSounds
  self.minimumIntermittentSoundPlayTime = self.minimumIntermittentSoundPlayTime and minimumSoundPlayTime and math.min(self.minimumIntermittentSoundPlayTime, minimumSoundPlayTime) or self.minimumIntermittentSoundPlayTime or minimumSoundPlayTime
  self.maximumIntermittentSoundPlayTime = self.maximumIntermittentSoundPlayTime and maximumSoundPlayTime and math.min(self.maximumIntermittentSoundPlayTime, maximumSoundPlayTime) or self.maximumIntermittentSoundPlayTime or maximumSoundPlayTime
end
function AmbientSoundMixer:load(ambientSoundBasicVolume)
  self.ambientSoundBasicVolume = self.ambientSoundBasicVolume and ambientSoundBasicVolume and math.min(self.ambientSoundBasicVolume, ambientSoundBasicVolume) or self.ambientSoundBasicVolume or ambientSoundBasicVolume
end
function AmbientSoundMixer:start()
  self.ambientSoundBasicVolume = self.ambientSoundBasicVolume or AmbientSoundMixer.DEFAULT_BASICVOLUME
  self.backroundSoundsCount = #self.backgroundSounds
  self.continuingSoundsCount = #self.continuingSounds
  self.intermittentSoundsCount = #self.intermittentSounds
  self.soundsCount = self.backroundSoundsCount + self.continuingSoundsCount + self.intermittentSoundsCount
  self.numberOfSimultaneousContinuingSounds = self.numberOfSimultaneousContinuingSounds or AmbientSoundMixer.DEFAULT_SOUNDCOUNT
  self.numberOfSimultaneousIntermittentSounds = math.min(self.intermittentSoundsCount, self.numberOfSimultaneousIntermittentSounds or AmbientSoundMixer.DEFAULT_SOUNDCOUNT)
  for _, backgroundSound in ipairs(self.backgroundSounds) do
    self:playSound(backgroundSound)
  end
  if self.continuingSoundsCount <= self.numberOfSimultaneousContinuingSounds then
    for _, continuingSound in ipairs(self.continuingSounds) do
      continuingSound.soundType = AmbientSoundMixer.SOUNDTYPE_BACKGROUND
      self:playSound(continuingSound)
    end
  else
    for i = 1, self.numberOfSimultaneousContinuingSounds do
      self:randomlyChooseAndPlayNewSound(AmbientSoundMixer.SOUNDTYPE_CONTINUING)
    end
  end
  for _, intermittentSound in ipairs(self.intermittentSounds) do
    self:playSound(intermittentSound)
    if self.uses3DSounds then
      setVisibility(intermittentSound.audioSource, false)
    else
      stopSample(intermittentSound.sample)
    end
    self.activeSounds[intermittentSound.sample].status = AmbientSoundMixer.STATUS_DELAY
    local nextUpdateTime = self.totalTime + math.random(intermittentSound.minimumPauseTime, intermittentSound.maximumPauseTime) * 0.5
    self.updatingSounds[1].time = nextUpdateTime
  end
  table.sort(self.updatingSounds, function(updateData1, updateData2)
    return updateData1.time < updateData2.time
  end)
  self.update = AmbientSoundMixer.update_NormalOperation
end
function AmbientSoundMixer:pause()
  if self.isPaused then
    return
  end
  self.isPaused = true
  if self.globalFadingIsFadingIn then
    self.globalFadingIsFadingIn = nil
    self.globalFadingRemainingTime = AmbientSoundMixer.CROSSFADE_TIME - self.globalFadingRemainingTime
  else
    self.globalFadingRemainingTime = AmbientSoundMixer.CROSSFADE_TIME
    self.globalFadingSounds = {}
    for sampleId, soundData in pairs(self.activeSounds) do
      self.globalFadingSounds[sampleId] = {}
      self.globalFadingSounds[sampleId].soundData = soundData
      self.globalFadingSounds[sampleId].originalVolume = getSampleVolume(sampleId)
    end
  end
  self.globalFadingIsFadingOut = true
  self.update = AmbientSoundMixer.update_GlobalFadeOut
end
function AmbientSoundMixer:resume()
  if not self.isPaused then
    return
  end
  self.isPaused = nil
  if self.globalFadingIsFadingOut then
    self.globalFadingIsFadingOut = nil
    self.globalFadingRemainingTime = AmbientSoundMixer.CROSSFADE_TIME - self.globalFadingRemainingTime
  else
    self.globalFadingRemainingTime = AmbientSoundMixer.CROSSFADE_TIME
  end
  self.globalFadingIsFadingIn = true
  self.update = AmbientSoundMixer.update_GlobalFadeIn
end
function AmbientSoundMixer:delete()
  self:reset()
end
function AmbientSoundMixer:update_Disabled(dt)
end
function AmbientSoundMixer:update_GlobalFadeOut(dt)
  self.globalFadingRemainingTime = self.globalFadingRemainingTime - dt
  if self.globalFadingRemainingTime < 0 then
    for sampleId, soundData in pairs(self.globalFadingSounds) do
      setSampleVolume(sampleId, 0)
    end
    self.globalFadingIsFadingOut = nil
    self.globalFadingRemainingTime = nil
    self.update = AmbientSoundMixer.update_Disabled
  else
    local fadingFactor = self.globalFadingRemainingTime / AmbientSoundMixer.CROSSFADE_TIME
    for sampleId, soundData in pairs(self.globalFadingSounds) do
      setSampleVolume(sampleId, fadingFactor * soundData.originalVolume)
    end
  end
end
function AmbientSoundMixer:update_GlobalFadeIn(dt)
  self.globalFadingRemainingTime = self.globalFadingRemainingTime - dt
  if self.globalFadingRemainingTime < 0 then
    for sampleId, soundData in pairs(self.globalFadingSounds) do
      setSampleVolume(sampleId, soundData.originalVolume)
    end
    self.globalFadingIsFadingIn = nil
    self.globalFadingRemainingTime = nil
    self.globalFadingSounds = nil
    self.update = AmbientSoundMixer.update_NormalOperation
  else
    local fadingFactor = 1 - self.globalFadingRemainingTime / AmbientSoundMixer.CROSSFADE_TIME
    for sampleId, soundData in pairs(self.globalFadingSounds) do
      setSampleVolume(sampleId, fadingFactor * soundData.originalVolume)
    end
  end
end
function AmbientSoundMixer:update_NormalOperation(dt)
  self.totalTime = self.totalTime + dt
  local currentIndex = 1
  local loopCount = 1
  while loopCount <= self.updatingSoundsCount do
    local updateData = self.updatingSounds[currentIndex]
    local updateTime = updateData.time
    if updateTime > self.totalTime then
      break
    else
      local soundData = updateData.soundData
      local sampleId = soundData.sample
      local nextIndex
      if soundData.status == AmbientSoundMixer.STATUS_FADEIN or soundData.status == AmbientSoundMixer.STATUS_FADEOUT then
        local currentFadeTime = self.totalTime - updateTime
        local currentFadeFactor = currentFadeTime / AmbientSoundMixer.CROSSFADE_TIME
        if soundData.status == AmbientSoundMixer.STATUS_FADEIN then
          if currentFadeFactor < 1 then
            setSampleVolume(sampleId, currentFadeFactor * soundData.sampleMaxVolume)
            nextIndex = currentIndex + 1
          elseif soundData.soundType == AmbientSoundMixer.SOUNDTYPE_BACKGROUND then
            setSampleVolume(sampleId, soundData.sampleMaxVolume)
            soundData.status = AmbientSoundMixer.STATUS_PLAY
            self:removeUpdatingSoundPosition(currentIndex)
            nextIndex = currentIndex
          else
            soundData.status = AmbientSoundMixer.STATUS_PLAY
            setSampleVolume(sampleId, soundData.sampleMaxVolume)
            local nextUpdateTime = self.totalTime + math.max(0, soundData.playbackTime - AmbientSoundMixer.CROSSFADE_TIME)
            self:adjustUpdatingSoundPosition(currentIndex, nextUpdateTime)
            nextIndex = currentIndex
          end
        elseif soundData.status == AmbientSoundMixer.STATUS_FADEOUT then
          if currentFadeFactor < 1 then
            currentFadeFactor = 1 - currentFadeFactor
            setSampleVolume(sampleId, currentFadeFactor * soundData.sampleMaxVolume)
            nextIndex = currentIndex + 1
          elseif soundData.soundType == AmbientSoundMixer.SOUNDTYPE_CONTINUING then
            if self.uses3DSounds then
              setVisibility(soundData.audioSource, false)
            else
              stopSample(sampleId)
            end
            self.activeSounds[sampleId] = nil
            self:removeUpdatingSoundPosition(currentIndex)
            nextIndex = currentIndex
          else
            if self.uses3DSounds then
              setVisibility(soundData.audioSource, false)
            else
              stopSample(sampleId)
            end
            soundData.status = AmbientSoundMixer.STATUS_DELAY
            local nextUpdateTime = self.totalTime + math.random(soundData.minimumPauseTime, soundData.maximumPauseTime)
            self:adjustUpdatingSoundPosition(currentIndex, nextUpdateTime)
            nextIndex = currentIndex
          end
        end
      elseif soundData.status == AmbientSoundMixer.STATUS_PLAY then
        if soundData.soundType == AmbientSoundMixer.SOUNDTYPE_CONTINUING then
          local newSoundPlaying = self:randomlyChooseAndPlayNewSound(AmbientSoundMixer.SOUNDTYPE_CONTINUING)
          if newSoundPlaying then
            soundData.status = AmbientSoundMixer.STATUS_FADEOUT
            local nextUpdateTime = self.totalTime
            self:adjustUpdatingSoundPosition(currentIndex, nextUpdateTime)
            nextIndex = currentIndex + 1
          else
            local nextUpdateTime = self.totalTime + AmbientSoundMixer.POSTPONE_TIME
            self:adjustUpdatingSoundPosition(currentIndex, nextUpdateTime)
            nextIndex = currentIndex
          end
        else
          self:randomlyChooseAndPlayNewSound(AmbientSoundMixer.SOUNDTYPE_INTERMITTENT)
          soundData.status = AmbientSoundMixer.STATUS_FADEOUT
          local nextUpdateTime = self.totalTime
          self:adjustUpdatingSoundPosition(currentIndex, nextUpdateTime)
          nextIndex = currentIndex
        end
      elseif soundData.status == AmbientSoundMixer.STATUS_DELAY then
        if self.uses3DSounds then
          setVisibility(soundData.audioSource, false)
        else
          stopSample(sampleId)
        end
        self.activeSounds[sampleId] = nil
        self:removeUpdatingSoundPosition(currentIndex)
        if self:randomlyChooseAndPlayNewSound(AmbientSoundMixer.SOUNDTYPE_INTERMITTENT) then
          nextIndex = currentIndex + 1
        else
          nextIndex = currentIndex
        end
      end
      currentIndex = nextIndex
      loopCount = loopCount + 1
    end
  end
end
function AmbientSoundMixer:removeUpdatingSoundPosition(indexToRemove)
  for i = indexToRemove, self.updatingSoundsCount do
    self.updatingSounds[i] = self.updatingSounds[i + 1]
  end
  self.updatingSoundsCount = self.updatingSoundsCount - 1
end
function AmbientSoundMixer:adjustUpdatingSoundPosition(indexToAdjust, nextUpdateTime)
  if nextUpdateTime < self.updatingSounds[indexToAdjust].time then
    print("AmbientSoundMixer:adjustUpdatingSoundPosition() error: cannot shift sound update position down")
  end
  self.updatingSounds[indexToAdjust].time = nextUpdateTime
  for i = indexToAdjust, self.updatingSoundsCount - 1 do
    local currentUpdateData = self.updatingSounds[i]
    local nextUpdateData = self.updatingSounds[i + 1]
    if currentUpdateData.time > nextUpdateData.time then
      self.updatingSounds[i] = nextUpdateData
      self.updatingSounds[i + 1] = currentUpdateData
    else
      break
    end
  end
end
function AmbientSoundMixer:randomlyChooseAndPlayNewSound(soundType)
  local soundTable, soundCount
  if soundType == AmbientSoundMixer.SOUNDTYPE_INTERMITTENT then
    soundTable = self.intermittentSounds
    soundCount = self.intermittentSoundsCount
  elseif soundType == AmbientSoundMixer.SOUNDTYPE_CONTINUING then
    soundTable = self.continuingSounds
    soundCount = self.continuingSoundsCount
  elseif soundType == AmbientSoundMixer.SOUNDTYPE_BACKGROUND then
    soundTable = self.backgroundSounds
    soundCount = self.backgroundSoundsCount
  end
  local newSoundSampleId, newSoundIndex
  local tries = 0
  local currentIndex = math.random(1, soundCount)
  while soundCount > tries do
    local currentSampleId = soundTable[currentIndex].sample
    if not self.activeSounds[currentSampleId] then
      newSoundSampleId = currentSampleId
      newSoundIndex = currentIndex
      break
    end
    currentIndex = currentIndex % soundCount + 1
    tries = tries + 1
  end
  if not newSoundSampleId then
    return false
  else
    return self:playSound(soundTable[newSoundIndex])
  end
end
function AmbientSoundMixer:playSound(sound)
  local playbackTime = self:getSamplePlaybackTime(sound)
  local soundSampleId = sound.sample
  local newSoundUpdateData = {}
  newSoundUpdateData.time = self.totalTime
  newSoundUpdateData.soundData = sound
  newSoundUpdateData.soundData.status = AmbientSoundMixer.STATUS_FADEIN
  newSoundUpdateData.soundData.remainingTime = AmbientSoundMixer.CROSSFADE_TIME
  newSoundUpdateData.soundData.playbackTime = playbackTime
  newSoundUpdateData.soundData.sampleMaxVolume = sound.volume * self.ambientSoundBasicVolume
  local inserted = false
  for i = 1, self.updatingSoundsCount do
    local currentUpdateData = self.updatingSounds[i]
    if newSoundUpdateData.time <= currentUpdateData.time then
      for j = self.updatingSoundsCount, i, -1 do
        self.updatingSounds[j + 1] = self.updatingSounds[j]
      end
      self.updatingSounds[i] = newSoundUpdateData
      inserted = true
      break
    end
  end
  self.updatingSoundsCount = self.updatingSoundsCount + 1
  if not inserted then
    self.updatingSounds[self.updatingSoundsCount] = newSoundUpdateData
  end
  self.activeSounds[soundSampleId] = sound
  local randomOffset = math.random(0, playbackTime)
  if self.uses3DSounds then
    setVisibility(sound.audioSource, true)
  else
    playSample(soundSampleId, 0, 0, randomOffset)
  end
  setSampleVolume(soundSampleId, 0)
  return sound
end
function AmbientSoundMixer:stop()
  if self.uses3DSounds then
    for _, soundData in pairs(self.activeSounds) do
      setVisibility(soundData.audioSource, false)
    end
  else
    for _, soundData in pairs(self.activeSounds) do
      stopSample(soundData.sample)
    end
  end
  self.activeSounds = {}
  self.updatingSounds = {}
  self.updatingSoundsCount = 0
  self.update = nil
end
function AmbientSoundMixer:reset()
  self:stop()
  if self.uses3DSounds then
    for _, soundData in pairs(self.backgroundSounds) do
      delete(soundData.audioSource)
    end
    for _, soundData in pairs(self.continuingSounds) do
      delete(soundData.audioSource)
    end
    for _, soundData in pairs(self.intermittentSounds) do
      delete(soundData.audioSource)
    end
  else
    for _, soundData in pairs(self.backgroundSounds) do
      stopSample(soundData.sample)
      delete(soundData.sample)
    end
    for _, soundData in pairs(self.continuingSounds) do
      stopSample(soundData.sample)
      delete(soundData.sample)
    end
    for _, soundData in pairs(self.intermittentSounds) do
      stopSample(soundData.sample)
      delete(soundData.sample)
    end
  end
  self.backgroundSounds = {}
  self.continuingSounds = {}
  self.intermittentSounds = {}
  self.backgroundSoundsCount = 0
  self.continuingSoundsCount = 0
  self.intermittentSoundsCount = 0
  self.soundsCount = 0
  self.totalTime = 0
  self.globalFadingSounds = nil
  self.globalFadingIsFadingIn = nil
  self.ambientSoundBasicVolume = nil
  self.numberOfSimultaneousContinuingSounds = nil
  self.numberOfSimultaneousIntermittentSounds = nil
end
function AmbientSoundMixer:getSamplePlaybackTime(sound)
  local minimumSoundPlayTime, maximumSoundPlayTime
  if soundType == AmbientSoundMixer.SOUNDTYPE_INTERMITTENT then
    minimumSoundPlayTime = self.minimumIntermittentSoundPlayTime
    maximumSoundPlayTime = self.maximumIntermittentSoundPlayTime
  elseif soundType == AmbientSoundMixer.SOUNDTYPE_CONTINUING then
    minimumSoundPlayTime = self.minimumContinuingSoundPlayTime
    maximumSoundPlayTime = self.maximumContinuingSoundPlayTime
  end
  local currentMinimumSoundPlayTime = sound.minimumPlayTime or minimumSoundPlayTime or getSampleDuration(sound.sample)
  local currentMaximumSoundPlayTime = sound.maximumPlayTime or maximumSoundPlayTime or getSampleDuration(sound.sample)
  currentMinimumSoundPlayTime = math.min(currentMinimumSoundPlayTime, currentMaximumSoundPlayTime)
  currentMaximumSoundPlayTime = math.max(currentMinimumSoundPlayTime, currentMaximumSoundPlayTime)
  return math.random(currentMinimumSoundPlayTime, currentMaximumSoundPlayTime)
end
