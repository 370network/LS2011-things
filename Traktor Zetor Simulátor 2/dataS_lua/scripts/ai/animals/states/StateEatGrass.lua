StateEatGrass = {}
local StateEatGrass_mt = Class(StateEatGrass, State)
StateRepository:addState(StateEatGrass)
function StateEatGrass:initialize()
  local name = "EatGrass"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateIdle, PreconditionCollection:new("shouldWalkToFeedingPlaceBecauseItGotRefilled", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isHungry, EntityPreconditionCollection:new("isEatableGotRefilledAndAvailable", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.gotRefilled, DefaultPreconditions.isInteractionPlaceAvailable))),
    ChangeStateAction:new():initialize(StateWander, PreconditionCollection:new("finishedEatingGrass", 1, DefaultPreconditions.thirtySecondsPassed), DefaultEffects.lowerHungerABit)
  }
  StateEatGrass:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateEatGrass:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(-5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-1.0E-4 * (dt / 1000))
end
