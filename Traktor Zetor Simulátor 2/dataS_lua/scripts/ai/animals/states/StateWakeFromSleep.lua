StateWakeFromSleep = {}
Class(StateWakeFromSleep, State)
StateRepository:addState(StateWakeFromSleep)
function StateWakeFromSleep:initialize()
  local name = "WakeFromSleep"
  local changeStateActionsList = {
    DefaultChangeStateActions.startToStandUpToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateRest, DefaultPreconditions.threeSecondsPassed)
  }
  StateWakeFromSleep:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
