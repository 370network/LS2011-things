AnimationEventManager = {
  tagListeners = {}
}
function AnimationEventManager.loadClipEventData(xmlFile, usedAnimationsHash)
  local clipEventData = {}
  local clipNameToAnimationHash = {}
  for _, animationData in pairs(usedAnimationsHash) do
    clipNameToAnimationHash[animationData.clipName] = animationData
    clipEventData[animationData.clipName] = {
      timeEvents = {}
    }
  end
  local baseName = "xml.clipEventData"
  if not hasXMLProperty(xmlFile, baseName) then
    return clipEventData
  end
  local tagFilterString = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#neededTagsFilter"), "")
  local tagFilterSet = Utils.listToSet(Utils.splitString(" ", tagFilterString))
  tagFilterSet = Utils.getSetUnion(tagFilterSet, AnimationEventManager.collectNeededTags())
  local tagReplacementSet = {}
  local tagReplacementsPath = baseName .. ".tagReplacementData"
  local tagReplacementPath = tagReplacementsPath .. ".tagReplacement(0)"
  local tagReplacementsCount = 0
  while hasXMLProperty(xmlFile, tagReplacementPath) do
    local tagToReplaceName = getXMLString(xmlFile, tagReplacementPath .. "#tagToReplace")
    local replaceWithTagName = getXMLString(xmlFile, tagReplacementPath .. "#replaceWithTag")
    local displacementTime = Utils.getNoNil(getXMLString(xmlFile, tagReplacementPath .. "#displacementTime"), 0)
    local removeOldTag = Utils.getNoNil(getXMLString(xmlFile, tagReplacementPath .. "#removeOldTag"), false)
    if not tagToReplaceName or tagToReplaceName == "" then
      print("error loadAnimationEventData: tag replacement used but tag to replace not specified")
    end
    if not replaceWithTagName or replaceWithTagName == "" then
      print("error loadAnimationEventData: tag replacement used but tag to replace with not specified")
    end
    if tagFilterSet[replaceWithTagName] then
      local tagReplacement = {
        tagToReplaceName = tagToReplaceName,
        replaceWithTagName = replaceWithTagName,
        displacementTime = displacementTime,
        removeOldTag = removeOldTag
      }
      tagReplacementSet[tagReplacement.tagToReplaceName] = tagReplacement
    end
    tagReplacementsCount = tagReplacementsCount + 1
    tagReplacementPath = string.format(tagReplacementsPath .. ".tagReplacement(%d)", tagReplacementsCount)
  end
  local clipId = 0
  while true do
    local clipBaseName = string.format(baseName .. ".eventData(%d)", clipId)
    if not hasXMLProperty(xmlFile, clipBaseName) then
      break
    end
    local clipName = getXMLString(xmlFile, clipBaseName .. "#clipName")
    if not clipName then
      print("error loadAnimationEventData: clip name not specified")
      break
    end
    if not clipNameToAnimationHash[clipName] then
      break
    end
    local clipEventsTimeSorted = {}
    local singleEventId = 0
    while true do
      local eventBaseName = string.format(clipBaseName .. ".singleEvent(%d)", singleEventId)
      if not hasXMLProperty(xmlFile, eventBaseName) then
        break
      end
      local eventTimeString = getXMLString(xmlFile, eventBaseName .. "#time")
      if not eventTimeString then
        print("error loadAnimationEventData: event time not specified")
        break
      end
      local eventTagsString = getXMLString(xmlFile, eventBaseName .. "#tags")
      if not eventTagsString or eventTagsString == "" then
        print("error loadAnimationEventData: event tag(s) not specified")
        break
      end
      local eventTime = tonumber(eventTimeString)
      if not eventTime then
        print(string.format("error loadAnimationEventData: could not convert time to number (%s)", eventTimeString))
        break
      end
      local eventTagsSet = Utils.listToSet(Utils.splitString(" ", eventTagsString))
      for tagName, _ in pairs(eventTagsSet) do
        for tagToReplaceName, replacementData in pairs(tagReplacementSet) do
          if tagName == tagToReplaceName then
            local replacementEventTime = eventTime + replacementData.displacementTime
            local replacementTagSet = {}
            replacementTagSet[replacementData.replaceWithTagName] = true
            AnimationEventManager._insertAndSortNewEventTagSet(replacementTagSet, replacementEventTime, clipEventsTimeSorted)
            if replacementData.removeOldTag then
              eventTagsSet[tagName] = nil
            end
          end
        end
      end
      local filteredEventTagSet = Utils.getSetIntersection(tagFilterSet, eventTagsSet)
      if next(filteredEventTagSet) then
        AnimationEventManager._insertAndSortNewEventTagSet(filteredEventTagSet, eventTime, clipEventsTimeSorted)
      else
      end
      singleEventId = singleEventId + 1
    end
    if 0 < table.getn(clipEventsTimeSorted) then
      clipEventData[clipName].timeEvents = clipEventsTimeSorted
    end
    local clipStartEvents = {}
    local startEventBaseName = clipBaseName .. ".startEvent"
    if hasXMLProperty(xmlFile, startEventBaseName) then
      local eventTagsString = getXMLString(xmlFile, startEventBaseName .. "#tags")
      if not eventTagsString or eventTagsString == "" then
        print("error loadAnimationEventData: event tag(s) not specified")
        break
      end
      local eventTagsSet = Utils.listToSet(Utils.splitString(" ", eventTagsString))
      local filteredEventTagSet = Utils.getSetIntersection(tagFilterSet, eventTagsSet)
      if next(filteredEventTagSet) then
        local startEvent = {tags = filteredEventTagSet}
        clipEventData[clipName].startEvent = startEvent
      else
      end
    end
    local clipStopEvents = {}
    local stopEventBaseName = clipBaseName .. ".stopEvent"
    if hasXMLProperty(xmlFile, stopEventBaseName) then
      local eventTagsString = getXMLString(xmlFile, stopEventBaseName .. "#tags")
      if not eventTagsString or eventTagsString == "" then
        print("error loadAnimationEventData: event tag(s) not specified")
        break
      end
      local eventTagsSet = Utils.listToSet(Utils.splitString(" ", eventTagsString))
      local filteredEventTagSet = Utils.getSetIntersection(tagFilterSet, eventTagsSet)
      if next(filteredEventTagSet) then
        local stopEvent = {tags = filteredEventTagSet}
        clipEventData[clipName].stopEvent = stopEvent
      else
      end
    end
    clipId = clipId + 1
  end
  return clipEventData
end
function AnimationEventManager._insertAndSortNewEventTagSet(tagSetToInsert, eventTime, timeSortedClipEvents)
  local newEvent = {time = eventTime, tags = tagSetToInsert}
  local inserted = false
  for index, eventData in ipairs(timeSortedClipEvents) do
    if newEvent.time < eventData.time then
      table.insert(timeSortedClipEvents, index, newEvent)
      inserted = true
      break
    elseif newEvent.time == eventData.time then
      eventData.tags = Utils.getSetUnion(eventData.tags, newEvent.tags)
      inserted = true
      break
    end
  end
  if not inserted then
    table.insert(timeSortedClipEvents, newEvent)
  end
end
function AnimationEventManager.collectNeededTags()
  local neededTags = {}
  local soundTagSet = AnimalSoundManager.retrieveNeededTags()
  for tag, _ in pairs(soundTagSet) do
    AnimationEventManager.addTagListener(tag, AnimalSoundManager)
  end
  neededTags = Utils.getSetUnion(neededTags, soundTagSet)
  return neededTags
end
function AnimationEventManager.addTagListener(tag, listener)
  local listenerList = AnimationEventManager.tagListeners[tag]
  if not listenerList then
    listenerList = {}
    AnimationEventManager.tagListeners[tag] = listenerList
  end
  table.insert(listenerList, listener)
end
function AnimationEventManager.prepareAgent(agent, agentAnimationData)
  local agentEventData = {}
  agentAnimationData.eventData = agentEventData
end
function AnimationEventManager.startListeningForEvents(agent, agentAnimationData, animationInstance)
  AnimationEventManager.stopListeningForEvents(agent, agentAnimationData)
  local agentEventData = agentAnimationData.eventData
  agentEventData.isActive = AnimationEventManager.checkIfActive(agent)
  agentEventData.isInactive = not agentEventData.isActive
  if agentEventData.isInactive then
    return
  end
  local currentClipName = animationInstance.animation.clipName
  local clipEventData = AnimationControl.clipEventData[currentClipName]
  if clipEventData.startEvent then
    for tag, _ in pairs(clipEventData.startEvent.tags) do
      AnimationEventManager.dispatchEventTag(agent, tag)
    end
  end
  agentEventData.eventList = clipEventData.timeEvents
  agentEventData.animationInstance = animationInstance
  agentEventData.lastIndex = 1
  for i, event in ipairs(agentEventData.eventList) do
    if animationInstance.clipTime >= event.time then
    else
      agentEventData.lastIndex = i
      break
    end
  end
  agentEventData.stopEvent = clipEventData.stopEvent
end
function AnimationEventManager.stopListeningForEvents(agent, agentAnimationData)
  local agentEventData = agentAnimationData.eventData
  if agentEventData.isInactive then
    return
  end
  if agentEventData.stopEvent then
    for tag, _ in pairs(agentEventData.stopEvent.tags) do
      AnimationEventManager.dispatchEventTag(agent, tag)
    end
  end
  agentEventData.eventList = nil
  agentEventData.stopEvent = nil
  agentEventData.animationInstance = nil
  agentEventData.lastIndex = 0
end
function AnimationEventManager.checkForEvent(agent, agentAnimationData)
  local agentEventData = agentAnimationData.eventData
  if agentEventData.isInactive then
    return
  end
  local currentClipTime = agentEventData.animationInstance.clipTime
  if agentEventData.lastIndex <= table.getn(agentEventData.eventList) then
    for i = agentEventData.lastIndex, table.getn(agentEventData.eventList) do
      local event = agentEventData.eventList[i]
      if currentClipTime >= event.time then
        for tag, _ in pairs(event.tags) do
          AnimationEventManager.dispatchEventTag(agent, tag)
        end
        agentEventData.lastIndex = i + 1
      else
        break
      end
    end
  end
  local currentAnimationTime
end
function AnimationEventManager.dispatchEventTag(agent, tagToDispatch)
  local listenerList = AnimationEventManager.tagListeners[tagToDispatch]
  if listenerList then
    for _, listener in ipairs(listenerList) do
      listener:reactOnTag(agent, tagToDispatch)
    end
  end
end
function AnimationEventManager.checkIfActive(agent)
  local activeDistance = 25
  local minDistance = activeDistance + 1
  for _, playerWrapper in pairs(AnimalHusbandry.playerWrappers) do
    local distance = Utils.vector3Length(playerWrapper.positionX - agent.positionX, playerWrapper.positionY - agent.positionY, playerWrapper.positionZ - agent.positionZ)
    minDistance = math.min(minDistance, distance)
  end
  return activeDistance >= minDistance
end
