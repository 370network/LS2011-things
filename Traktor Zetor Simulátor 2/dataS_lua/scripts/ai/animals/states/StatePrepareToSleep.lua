StatePrepareToSleep = {}
Class(StatePrepareToSleep, State)
StateRepository:addState(StatePrepareToSleep)
function StatePrepareToSleep:initialize()
  local name = "PrepareToSleep"
  local changeStateActionsList = {
    DefaultChangeStateActions.startToStandUpToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateSleep, DefaultPreconditions.threeSecondsPassed)
  }
  StatePrepareToSleep:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
