StateTakeANap = {}
Class(StateTakeANap, State)
StateRepository:addState(StateTakeANap)
function StateTakeANap:initialize()
  local name = "TakeANap"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateWakeFromNap, EntityPreconditionCollection:new("playerWakesCowFromNap", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateWakeFromNap, PreconditionCollection:new("wakeUpBecauseRested", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isRested)),
    ChangeStateAction:new():initialize(StateWakeFromNap, PreconditionCollection:new("wakeUpBecauseVeryHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryHungry)),
    ChangeStateAction:new():initialize(StateWakeFromNap, PreconditionCollection:new("wakeUpBecauseVeryThirsty", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryThirsty)),
    ChangeStateAction:new():initialize(StateWakeFromNap, PreconditionCollection:new("wakeUpBecauseItsTime", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.oneMinutePassed))
  }
  StateTakeANap:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateTakeANap:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(0.0015 * (dt / 1000))
end
