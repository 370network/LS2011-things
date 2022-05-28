StateStand = {}
Class(StateStand, State)
function StateStand:initialize(name, changeStateActionsAdditionalsList, speedLimitToUse, accelerationLimitToUse)
  assert(name)
  assert(changeStateActionsAdditionalsList)
  local changeStateActionsList = {}
  for _, changeStateAction in ipairs(changeStateActionsAdditionalsList) do
    table.insert(changeStateActionsList, changeStateAction)
  end
  StateStand:superClass().initialize(self, name, changeStateActionsList, speedLimitToUse or AnimalMotionData.SPEED_WANDER, accelerationLimitToUse or AnimalMotionData.ACCELERATION_WANDER)
end
function StateStand:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(5.0E-4 * (dt / 1000))
end
