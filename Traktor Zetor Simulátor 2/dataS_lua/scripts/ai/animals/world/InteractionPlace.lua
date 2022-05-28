InteractionPlace = {}
Class(InteractionPlace, Entity)
function InteractionPlace:new()
  assert(self ~= InteractionPlace, "cannot instantiate abstract class InteractionPlace")
  InteractionPlace:superClass().new(self)
end
function InteractionPlace:initialize(presets_hash, availableSlots)
  InteractionPlace:superClass().initialize(self, presets_hash)
  self.slotsList = {}
  self.slotsHash = {}
  self.distancesHash = {}
  self.availableSlots = availableSlots
  self.usedSlots = 0
  self.approachingPositionX, self.approachingPositionY, self.approachingPositionZ = presets_hash.approachingPositionX or self.positionX, presets_hash.approachingPositionY or self.positionY, presets_hash.approachingPositionZ or self.positionZ
  assert(self.availableSlots >= 1)
  return self
end
function InteractionPlace.isRoomForAgent(interactionPlace, agent, distance)
  if interactionPlace.usedSlots < interactionPlace.availableSlots then
    return true
  else
    return distance < interactionPlace.distancesHash[interactionPlace.slotsList[interactionPlace.usedSlots]].distanceToEntity * 0.9
  end
end
function InteractionPlace.addAgent(interactionPlace, agent)
  interactionPlace.usedSlots = interactionPlace.usedSlots + 1
  interactionPlace.slotsList[interactionPlace.usedSlots] = agent
  interactionPlace.slotsHash[agent] = interactionPlace.usedSlots
  interactionPlace.distancesHash[agent] = agent.perceptionData.perceptionEntitiesHash[interactionPlace.type][interactionPlace]
  InteractionPlace.sortSlotsList(interactionPlace, agent)
  while interactionPlace.usedSlots > interactionPlace.availableSlots do
    local agentToRemove = interactionPlace.slotsList[interactionPlace.usedSlots]
    interactionPlace.slotsList[interactionPlace.usedSlots] = nil
    interactionPlace.slotsHash[agentToRemove] = nil
    interactionPlace.distancesHash[agentToRemove] = nil
    interactionPlace.usedSlots = interactionPlace.usedSlots - 1
  end
end
function InteractionPlace.sortSlotsList(interactionPlace)
  if interactionPlace.usedSlots <= 1 then
    return
  end
  local newList = {
    interactionPlace.slotsList[1]
  }
  local agentsAdded = 1
  for i = 2, interactionPlace.usedSlots do
    local agentToAdd = interactionPlace.slotsList[i]
    local isAgentAdded = false
    for j = agentsAdded, 1, -1 do
      if interactionPlace.distancesHash[newList[j]].distanceToEntity < interactionPlace.distancesHash[agentToAdd].distanceToEntity then
        table.insert(newList, j + 1, agentToAdd)
        isAgentAdded = true
        break
      end
    end
    if not isAgentAdded then
      table.insert(newList, 1, agentToAdd)
    end
  end
  interactionPlace.slotsList = {}
  for index, agent in ipairs(newList) do
    interactionPlace.slotsList[index] = agent
    interactionPlace.slotsHash[agent] = index
  end
end
function InteractionPlace.removeAgent(interactionPlace, agent)
  local indexToRemove = interactionPlace.slotsHash[agent]
  if not indexToRemove then
    return
  end
  table.remove(interactionPlace.slotsList, indexToRemove)
  interactionPlace.usedSlots = interactionPlace.usedSlots - 1
  interactionPlace.slotsHash[agent] = nil
  interactionPlace.distancesHash[agent] = nil
  for i = indexToRemove, interactionPlace.usedSlots do
    local currentAgent = interactionPlace.slotsList[i]
    interactionPlace.slotsHash[currentAgent] = i
  end
end
function InteractionPlace.isAgentInSlotList(interactionPlace, agent)
  return interactionPlace.slotsHash[agent]
end
function InteractionPlace.printSlotsList(interactionPlace)
  for _, agent in ipairs(interactionPlace.slotsList) do
    print(tostring(agent) .. " - " .. (interactionPlace.distancesHash[agent] or "unknown"))
  end
end
function InteractionPlace.checkConsistency(interactionPlace)
  if interactionPlace.usedSlots > interactionPlace.availableSlots then
    print("consistency failed (1)")
    return false
  end
  if interactionPlace.usedSlots ~= #interactionPlace.slotsList then
    print("consistency failed (2)")
    return false
  end
  for index, agent in ipairs(interactionPlace.slotsList) do
    if interactionPlace.slotsHash[agent] ~= index then
      print("consistency failed (3)")
      return false
    end
    if not interactionPlace.distancesHash[agent] then
      print("consistency failed (4)")
      return false
    end
  end
  local count = 0
  for agent, index in pairs(interactionPlace.slotsHash) do
    if index > interactionPlace.usedSlots then
      print("consistency failed (5)")
      return false
    end
  end
  for agent, distance in pairs(interactionPlace.distancesHash) do
    if not interactionPlace.slotsHash[agent] then
      print("consistency failed (6)")
      return false
    end
  end
  return true
end
