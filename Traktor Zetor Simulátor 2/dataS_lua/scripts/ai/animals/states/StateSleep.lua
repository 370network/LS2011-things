StateSleep = {}
Class(StateSleep, State)
StateRepository:addState(StateSleep)
function StateSleep:initialize()
  local name = "Sleep"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateWakeFromSleep, EntityPreconditionCollection:new("playerWakesCowFromNap", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateWakeFromSleep, PreconditionCollection:new("wakeUpBecauseItsTime", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.oneMinutePassed, DefaultPreconditions.isDay))
  }
  StateSleep:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateSleep:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.002 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(0.002 * (dt / 1000))
end
