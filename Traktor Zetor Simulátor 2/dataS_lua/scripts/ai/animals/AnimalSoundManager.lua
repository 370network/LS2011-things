AnimalSoundManager = {
  DEFAULT_FADEOUT_TIME = 500,
  activatingTags = {},
  deactivatingTags = {},
  triggeredSounds = {},
  triggeredSoundsToFadeOut = {},
  AMBIENTSOUNDS_START_ANIMAL_COUNT = 2
}
function AnimalSoundManager.init()
  AnimalSoundManager.ambientSoundMixer = AmbientSoundMixer:new(true)
end
function AnimalSoundManager.delete()
  AnimalSoundManager.ambientSoundMixer:delete()
  AnimalSoundManager.ambientSoundMixer = nil
  AnimalSoundManager.triggeredSounds = {}
  AnimalSoundManager.activatingTags = {}
  AnimalSoundManager.deactivatingTags = {}
end
function AnimalSoundManager.loadFromXML(xmlFile, herd)
  local basicNode = "xml.soundData"
  local ambientSoundNode = AnimalSoundManager.loadAmbientSounds(xmlFile, basicNode, herd)
  AnimalSoundManager.loadTriggeredSounds(xmlFile, basicNode, herd)
  return ambientSoundNode
end
function AnimalSoundManager.loadAmbientSounds(xmlFile, basicNode)
  local ambientSoundNode = createTransformGroup("AnimalsAmbientSoundNode")
  local ambientBasicNode = basicNode .. ".ambientSamples"
  local ambientSoundBasicVolume = getXMLFloat(xmlFile, ambientBasicNode .. "#basicVolume")
  local innerRadius = Utils.getNoNil(getXMLFloat(xmlFile, ambientBasicNode .. "#rangeInnerRadius"), 50)
  local outerRadius = Utils.getNoNil(getXMLFloat(xmlFile, ambientBasicNode .. "#rangeOuterRadius"), 100)
  AnimalSoundManager.ambientSoundMixer:load(ambientSoundBasicVolume)
  if hasXMLProperty(xmlFile, ambientBasicNode .. ".backgroundSamples") then
    local i = 0
    local backgroundSamples = {}
    while true do
      local key = string.format(ambientBasicNode .. ".backgroundSamples.sample(%d)", i)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local sample = {}
      AnimalSoundManager.loadSample(xmlFile, sample, key, nil, "", true, outerRadius, innerRadius)
      link(ambientSoundNode, sample.audioSource)
      table.insert(backgroundSamples, sample)
      i = i + 1
    end
    AnimalSoundManager.ambientSoundMixer:loadBackgroundSounds(backgroundSamples)
  end
  if hasXMLProperty(xmlFile, ambientBasicNode .. ".continuingSamples") then
    local i = 0
    local continuingSamples = {}
    local numOfSimultaneousSamples = getXMLInt(xmlFile, ambientBasicNode .. ".continuingSamples#numOfSimultaneousSamples")
    local minimumSamplePlayTime = getXMLInt(xmlFile, ambientBasicNode .. ".continuingSamples#minimumSamplePlayTime")
    minimumSamplePlayTime = minimumSamplePlayTime ~= 0 and minimumSamplePlayTime or nil
    local maximumSamplePlayTime = getXMLInt(xmlFile, ambientBasicNode .. ".continuingSamples#maximumSamplePlayTime")
    maximumSamplePlayTime = maximumSamplePlayTime ~= 0 and maximumSamplePlayTime or nil
    while true do
      local key = string.format(ambientBasicNode .. ".continuingSamples.sample(%d)", i)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local sample = {}
      AnimalSoundManager.loadSample(xmlFile, sample, key, nil, "", true, outerRadius, innerRadius)
      link(ambientSoundNode, sample.audioSource)
      sample.minimumPlayTime = getXMLInt(xmlFile, key .. "#minimumSamplePlayTime")
      sample.minimumPlayTime = sample.minimumPlayTime ~= 0 and sample.minimumPlayTime or nil
      sample.maximumPlayTime = getXMLInt(xmlFile, key .. "#maximumSamplePlayTime")
      sample.maximumPlayTime = sample.maximumPlayTime ~= 0 and sample.maximumPlayTime or nil
      sample.maximumPauseTime = getXMLInt(xmlFile, key .. "#maxPause")
      sample.maximumPauseTime = sample.maximumPauseTime ~= 0 and sample.maximumPauseTime or nil
      sample.minimumPauseTime = getXMLInt(xmlFile, key .. "#minPause")
      sample.minimumPauseTime = sample.minimumPauseTime ~= 0 and sample.minimumPauseTime or nil
      table.insert(continuingSamples, sample)
      i = i + 1
    end
    AnimalSoundManager.ambientSoundMixer:loadContinuingSounds(continuingSamples, numOfSimultaneousSamples, minimumSamplePlayTime, maximumSamplePlayTime)
  end
  if hasXMLProperty(xmlFile, ambientBasicNode .. ".intermittentSamples") then
    local i = 0
    local intermittentSamples = {}
    local numOfSimultaneousSamples = getXMLInt(xmlFile, ambientBasicNode .. ".intermittentSamples#numOfSimultaneousSamples")
    local minimumSamplePlayTime = getXMLInt(xmlFile, ambientBasicNode .. ".intermittentSamples#minimumSamplePlayTime")
    minimumSamplePlayTime = minimumSamplePlayTime ~= 0 and minimumSamplePlayTime or nil
    local maximumSamplePlayTime = getXMLInt(xmlFile, ambientBasicNode .. ".intermittentSamples#maximumSamplePlayTime")
    maximumSamplePlayTime = maximumSamplePlayTime ~= 0 and maximumSamplePlayTime or nil
    while true do
      local key = string.format(ambientBasicNode .. ".intermittentSamples.sample(%d)", i)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local sample = {}
      AnimalSoundManager.loadSample(xmlFile, sample, key, nil, "", true, outerRadius, innerRadius)
      link(ambientSoundNode, sample.audioSource)
      sample.minimumPlayTime = getXMLInt(xmlFile, key .. "#minimumSamplePlayTime")
      sample.minimumPlayTime = sample.minimumPlayTime ~= 0 and sample.minimumPlayTime or nil
      sample.maximumPlayTime = getXMLInt(xmlFile, key .. "#maximumSamplePlayTime")
      sample.maximumPlayTime = sample.maximumPlayTime ~= 0 and sample.maximumPlayTime or nil
      sample.maximumPauseTime = getXMLInt(xmlFile, key .. "#maxPause")
      sample.maximumPauseTime = sample.maximumPauseTime ~= 0 and sample.maximumPauseTime or nil
      sample.minimumPauseTime = getXMLInt(xmlFile, key .. "#minPause")
      sample.minimumPauseTime = sample.minimumPauseTime ~= 0 and sample.minimumPauseTime or nil
      table.insert(intermittentSamples, sample)
      i = i + 1
    end
    AnimalSoundManager.ambientSoundMixer:loadIntermittentSounds(intermittentSamples, numOfSimultaneousSamples, minimumSamplePlayTime, maximumSamplePlayTime)
  end
  return ambientSoundNode
end
function AnimalSoundManager.loadSample(xmlFile, sample, baseString, defaultSampleFile, baseDir, is3DSound, outerRadius, innerRadius)
  local sampleFilename = getXMLString(xmlFile, baseString .. "#file")
  if sampleFilename == nil then
    sampleFilename = defaultSampleFile
  end
  if sampleFilename ~= nil then
    sampleFilename = Utils.getFilename(sampleFilename, baseDir)
    if is3DSound then
      sample.audioSource = createAudioSource(sampleFilename, sampleFilename, outerRadius, innerRadius, 0, 0)
      sample.sample = getAudioSourceSample(sample.audioSource)
    else
      sample.sample = createSample(sampleFilename)
      loadSample(sample.sample, sampleFilename, false)
    end
    sample.pitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, baseString .. "#pitchOffset"), 1)
    sample.pitchVariation = Utils.getNoNil(getXMLFloat(xmlFile, baseString .. "#pitchVariation"), 0)
    sample.volume = Utils.getNoNil(getXMLFloat(xmlFile, baseString .. "#volume"), 1)
    sample.isPlaying = false
  end
end
function AnimalSoundManager.loadTriggeredSounds(xmlFile, basicNode, herd)
  local triggeredSoundsBasicNode = basicNode .. ".triggeredSamples"
  if hasXMLProperty(xmlFile, triggeredSoundsBasicNode) then
    local i = 0
    while true do
      local key = string.format(triggeredSoundsBasicNode .. ".triggeredSample(%d)", i)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local triggeredSound = {
        innerRadius = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#rangeInnerRadius"), 5),
        outerRadius = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#rangeOuterRadius"), 15),
        activatingTag = getXMLString(xmlFile, key .. "#activatingTag"),
        deactivatingTag = getXMLString(xmlFile, key .. "#deactivatingTag"),
        sampleFilename = getXMLString(xmlFile, key .. "#file"),
        pitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#pitchOffset"), 1),
        pitchVariation = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#pitchVariation"), 0),
        volume = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#volume"), 1),
        minimumPlayTime = getXMLFloat(xmlFile, key .. "#minimumPlayTime"),
        maximumPlayTime = getXMLFloat(xmlFile, key .. "#maximumPlayTime")
      }
      if not triggeredSound.sampleFilename then
        print(string.format("error loading triggered sound: no sample filename specified"))
        break
      end
      if not triggeredSound.activatingTag then
        print(string.format("error loading triggered sound: no activating tag specified"))
        break
      end
      table.insert(AnimalSoundManager.triggeredSounds, triggeredSound)
      AnimalSoundManager._insertTag(AnimalSoundManager.activatingTags, triggeredSound.activatingTag, triggeredSound)
      if triggeredSound.deactivatingTag then
        AnimalSoundManager._insertTag(AnimalSoundManager.deactivatingTags, triggeredSound.deactivatingTag, triggeredSound)
      end
      i = i + 1
    end
  end
end
function AnimalSoundManager._insertTag(tagSet, tagToInsert, resultOfTag)
  local resultList = tagSet[tagToInsert]
  if not resultList then
    resultList = {}
    tagSet[tagToInsert] = resultList
  end
  table.insert(resultList, resultOfTag)
end
function AnimalSoundManager.retrieveNeededTags()
  return Utils.getSetUnion(AnimalSoundManager.activatingTags, AnimalSoundManager.deactivatingTags)
end
function AnimalSoundManager.prepareForAgent(agent)
  local agentSoundData = {}
  agent.soundData = agentSoundData
  agentSoundData.triggeredSounds = {}
  for _, triggeredSound in ipairs(AnimalSoundManager.triggeredSounds) do
    local sampleData = {}
    agentSoundData.triggeredSounds[triggeredSound] = sampleData
    sampleData.audioSource = createAudioSource(triggeredSound.sampleFilename, triggeredSound.sampleFilename, triggeredSound.outerRadius, triggeredSound.innerRadius, triggeredSound.volume, 1)
    sampleData.sample = getAudioSourceSample(sampleData.audioSource)
    sampleData.soundData = triggeredSound
    link(agent.bonesId, sampleData.audioSource)
    setVisibility(sampleData.audioSource, false)
  end
end
function AnimalSoundManager.releaseFromAgent(agent)
  local agentSoundData = agent.soundData
  for sampleData, _ in pairs(AnimalSoundManager.triggeredSoundsToFadeOut) do
    AnimalSoundManager.stopTriggeredSoundFadeout(agent, agentSoundData, sampleData)
  end
  for _, triggeredSound in ipairs(agentSoundData.triggeredSounds) do
    delete(triggeredSound.audioSource)
  end
end
function AnimalSoundManager:reactOnTag(agent, triggeredTag)
  local activatedSoundList = AnimalSoundManager.activatingTags[triggeredTag]
  if activatedSoundList then
    for _, activatedSound in ipairs(activatedSoundList) do
      AnimalSoundManager.playTriggeredSound(agent, activatedSound)
    end
  end
  local deactivatedSoundList = AnimalSoundManager.deactivatingTags[triggeredTag]
  if deactivatedSoundList then
    for _, deactivatedSound in ipairs(deactivatedSoundList) do
      AnimalSoundManager.stopTriggeredSound(agent, deactivatedSound, true)
    end
  end
end
function AnimalSoundManager.playTriggeredSound(agent, activatedSound)
  local agentSoundData = agent.soundData
  local sampleData = agentSoundData.triggeredSounds[activatedSound]
  if AnimalSoundManager.triggeredSoundsToFadeOut[sampleData] then
    AnimalSoundManager.stopTriggeredSoundFadeout(agent, agentSoundData, sampleData)
  end
  setVisibility(sampleData.audioSource, false)
  setVisibility(sampleData.audioSource, true)
  local soundData = sampleData.soundData
  delete(sampleData.audioSource)
  sampleData.audioSource = createAudioSource(activatedSound.sampleFilename, activatedSound.sampleFilename, activatedSound.outerRadius, activatedSound.innerRadius, activatedSound.volume, 1)
  sampleData.sample = getAudioSourceSample(sampleData.audioSource)
  setSamplePitch(sampleData.sample, soundData.pitchOffset + (math.random() - 1) * soundData.pitchVariation)
  link(agent.bonesId, sampleData.audioSource)
end
function AnimalSoundManager.stopTriggeredSound(agent, deactivatedSound, doFadeout, fadeoutTime)
  local agentSoundData = agent.soundData
  local sampleData = agentSoundData.triggeredSounds[deactivatedSound]
  if doFadeout then
    fadeoutTime = fadeoutTime or AnimalSoundManager.DEFAULT_FADEOUT_TIME
    AnimalSoundManager.triggeredSoundsToFadeOut[sampleData] = agent
    sampleData.timeLeft = fadeoutTime
    sampleData.fadeOutTime = fadeoutTime
  else
    setVisibility(sampleData.audioSource, false)
  end
end
function AnimalSoundManager.updateTriggeredSounds(dt)
  for sampleData, agent in pairs(AnimalSoundManager.triggeredSoundsToFadeOut) do
    sampleData.timeLeft = sampleData.timeLeft - dt
    local fadeFactor = sampleData.timeLeft / sampleData.fadeOutTime
    if fadeFactor < 0 then
      local agentSoundData = agent.soundData
      AnimalSoundManager.stopTriggeredSoundFadeout(agent, agentSoundData, sampleData)
    else
      setSampleVolume(sampleData.sample, sampleData.soundData.volume * fadeFactor)
    end
  end
end
function AnimalSoundManager.stopTriggeredSoundFadeout(agent, agentSoundData, sampleData)
  AnimalSoundManager.triggeredSoundsToFadeOut[sampleData] = nil
  sampleData.timeLeft = nil
  setSampleVolume(sampleData.sample, sampleData.soundData.volume)
  setVisibility(sampleData.audioSource, false)
end
function AnimalSoundManager.pauseAmbientSounds()
  AnimalSoundManager.ambientSoundMixer:pause()
end
function AnimalSoundManager.resumeAmbientSounds()
  AnimalSoundManager.ambientSoundMixer:resume()
end
function AnimalSoundManager.start()
  AnimalSoundManager.ambientSoundMixer:start()
end
function AnimalSoundManager.update(dt)
  AnimalSoundManager.ambientSoundMixer:update(dt)
  AnimalSoundManager.updateTriggeredSounds(dt)
end
