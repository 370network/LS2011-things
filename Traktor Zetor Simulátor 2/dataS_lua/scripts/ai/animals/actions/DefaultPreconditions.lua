DefaultPreconditions = {}
DefaultPreconditions.isMyself = BasicPrecondition:new("isMyself", 1)
function DefaultPreconditions.isMyself:checkPerception(agent, entity)
  local result = agent == entity
  return result
end
DefaultPreconditions.isStandingOnGrass = BasicPrecondition:new("isStandingOnGrass", 1)
function DefaultPreconditions.isStandingOnGrass:checkPerception(agent, entity)
  local result = true
  return result
end
DefaultPreconditions.isStandingAtWater = BasicPrecondition:new("isStandingAtWater", 1)
function DefaultPreconditions.isStandingAtWater:checkPerception(agent, entity)
  local result = true
  return result
end
DefaultPreconditions.isMoving = BasicPrecondition:new("isMoving", 1)
function DefaultPreconditions.isMoving:checkPerception(agent, entity)
  local result = entity.speed >= 0.05
  return result
end
DefaultPreconditions.isNotMoving = BasicPrecondition:new("isNotMoving", 1)
function DefaultPreconditions.isNotMoving:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isMoving:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.isHungry = BasicPrecondition:new("isHungry", 1)
function DefaultPreconditions.isHungry:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.HUNGER].value > DefaultAttributeValues.A_BIT
  return result
end
DefaultPreconditions.isNotHungry = BasicPrecondition:new("isNotHungry", 1)
function DefaultPreconditions.isNotHungry:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isHungry:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.isVeryHungry = BasicPrecondition:new("isVeryHungry", 1)
function DefaultPreconditions.isVeryHungry:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.HUNGER].value > DefaultAttributeValues.MUCH
  return result
end
DefaultPreconditions.isNotVeryHungry = BasicPrecondition:new("isNotVeryHungry", 1)
function DefaultPreconditions.isNotVeryHungry:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isVeryHungry:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.isThirsty = BasicPrecondition:new("isThirsty", 1)
function DefaultPreconditions.isThirsty:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.THIRST].value > DefaultAttributeValues.MODERATE
  return result
end
DefaultPreconditions.isNotThirsty = BasicPrecondition:new("isNotThirsty", 1)
function DefaultPreconditions.isNotThirsty:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isThirsty:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.isVeryThirsty = BasicPrecondition:new("isVeryThirsty", 1)
function DefaultPreconditions.isVeryThirsty:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.THIRST].value > DefaultAttributeValues.MUCH
  return result
end
DefaultPreconditions.isNotVeryThirsty = BasicPrecondition:new("isNotVeryThirsty", 1)
function DefaultPreconditions.isNotVeryThirsty:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isVeryThirsty:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.hasMuchMilk = BasicPrecondition:new("hasMuchMilk", 1)
function DefaultPreconditions.hasMuchMilk:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.MILK].value > DefaultAttributeValues.MUCH
  return result
end
DefaultPreconditions.isExhausted = BasicPrecondition:new("isExhausted", 1)
function DefaultPreconditions.isExhausted:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.ENERGY].value < DefaultAttributeValues.SLIGHTLY
  return result
end
DefaultPreconditions.isNotExhausted = BasicPrecondition:new("isNotExhausted", 1)
function DefaultPreconditions.isNotExhausted:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isExhausted:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.isVeryExhausted = BasicPrecondition:new("isVeryExhausted", 1)
function DefaultPreconditions.isVeryExhausted:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.ENERGY].value < DefaultAttributeValues.TINY
  return result
end
DefaultPreconditions.isRested = BasicPrecondition:new("isRested", 1)
function DefaultPreconditions.isRested:checkPerception(agent, entity)
  local result = entity.attributes[AnimalAttributeData.ENERGY].value > DefaultAttributeValues.MODERATE
  return result
end
DefaultPreconditions.isNotRested = BasicPrecondition:new("isNotRested", 1)
function DefaultPreconditions.isNotRested:checkPerception(agent, entity)
  local result = not DefaultPreconditions.isExhausted:checkPerception(agent, entity)
  return result
end
DefaultPreconditions.isInRange = BasicPrecondition:new("isInRange", 2)
function DefaultPreconditions.isInRange:checkPerception(agent, entity, entity2)
  local result = Utils.vector3Length(entity.positionX - entity2.positionX, entity.positionY - entity2.positionY, entity.positionZ - entity2.positionZ) <= agent.farDistance
  return result and entity
end
DefaultPreconditions.isOutOfRange = BasicPrecondition:new("isOutOfRange", 2)
function DefaultPreconditions.isOutOfRange:checkPerception(agent, entity, entity2)
  local result = not DefaultPreconditions.isInRange:checkPerception(agent, entity, entity2)
  return result and entity
end
DefaultPreconditions.isNear = BasicPrecondition:new("isNear", 2)
function DefaultPreconditions.isNear:checkPerception(agent, entity)
  local result = Utils.vector3Length(entity.positionX - agent.positionX, entity.positionY - agent.positionY, entity.positionZ - agent.positionZ) <= agent.nearDistance
  return result and entity
end
DefaultPreconditions.isNotNear = NegatePrecondition:new("isNotNear", DefaultPreconditions.isNear)
DefaultPreconditions.isClose = BasicPrecondition:new("isClose", 2)
function DefaultPreconditions.isClose:checkPerception(agent, entity)
  local result = Utils.vector3Length(entity.positionX - agent.positionX, entity.positionY - agent.positionY, entity.positionZ - agent.positionZ) <= agent.closeDistance
  return result and entity
end
DefaultPreconditions.isNotClose = NegatePrecondition:new("isNotClose", DefaultPreconditions.isClose)
DefaultPreconditions.isWithinMediumDistance = BasicPrecondition:new("isWithinMediumDistance", 2)
function DefaultPreconditions.isWithinMediumDistance:checkPerception(agent, entity)
  local result = Utils.vector3Length(entity.positionX - agent.positionX, entity.positionY - agent.positionY, entity.positionZ - agent.positionZ) <= agent.mediumDistance
  return result and entity
end
DefaultPreconditions.isAtArrivingDistance = BasicPrecondition:new("isAtArrivingDistance", 2)
function DefaultPreconditions.isAtArrivingDistance:checkPerception(agent, entity)
  local result = Utils.vector3Length(entity.positionX - agent.positionX, entity.positionY - agent.positionY, entity.positionZ - agent.positionZ) <= (agent.closeDistance + agent.mediumDistance) * 0.5
  return result and entity
end
DefaultPreconditions.isAtFeedingPlace = BasicPrecondition:new("isAtFeedingPlace", 2)
function DefaultPreconditions.isAtFeedingPlace:checkPerception(agent, entity)
  local result = Utils.vector3Length(entity.eatingPositionX - agent.positionX, entity.eatingPositionY - agent.positionY, entity.eatingPositionZ - agent.positionZ) <= agent.closeDistance
  return result and entity
end
DefaultPreconditions.isAtWateringPlace = BasicPrecondition:new("isAtWateringPlace", 2)
function DefaultPreconditions.isAtWateringPlace:checkPerception(agent, entity)
  local result = Utils.vector3Length(entity.drinkingPositionX - agent.positionX, entity.drinkingPositionY - agent.positionY, entity.drinkingPositionZ - agent.positionZ) <= agent.closeDistance
  return result and entity
end
DefaultPreconditions.isPastDirectionalPosition = BasicPrecondition:new("isPastDirectionalPosition", 2)
function DefaultPreconditions.isPastDirectionalPosition:checkPerception(agent, entity)
  local connectionX, connectionY, connectionZ = agent.positionX - entity.positionX, agent.positionY - entity.positionY, agent.positionZ - entity.positionZ
  local angleFactor = Utils.dotProduct(entity.directionX, entity.directionY, entity.directionZ, connectionX, connectionY, connectionZ)
  local result = 0 <= angleFactor
  return result and entity
end
DefaultPreconditions.isFrightening = BasicPrecondition:new("isFrightening", 1)
function DefaultPreconditions.isFrightening:checkPerception(agent, entity)
  local result = not not entity.isFrightening
  return result and entity
end
DefaultPreconditions.isInteresting = BasicPrecondition:new("isInteresting", 1)
function DefaultPreconditions.isInteresting:checkPerception(agent, entity)
  local result = not not entity.isInteresting
  return result and entity
end
DefaultPreconditions.quickensInterest = PreconditionCollection:new("quickensInterest", 2, DefaultPreconditions.isInteresting, DefaultPreconditions.isInRange)
DefaultPreconditions.playerQuickensInterest = EntityPreconditionCollection:new("playerQuickensInterest", 2, EntityType.PLAYER, DefaultPreconditions.quickensInterest)
DefaultPreconditions.shouldWalkToPlayer = PreconditionCollection:new("shouldWalkToPlayer", 1, DefaultPreconditions.isNotExhausted, DefaultPreconditions.isHungry, DefaultPreconditions.isNotVeryHungry, DefaultPreconditions.playerQuickensInterest)
DefaultPreconditions.shouldEatGrass = PreconditionCollection:new("shouldEatGrass", 1, DefaultPreconditions.isVeryHungry, DefaultPreconditions.isStandingOnGrass, DefaultPreconditions.isNotMoving)
DefaultPreconditions.isPlayerOutOfRange = EntityPreconditionCollection:new("isPlayerOutOfRange", 2, EntityType.PLAYER, DefaultPreconditions.isOutOfRange)
DefaultPreconditions.isPlayerClose = EntityPreconditionCollection:new("isPlayerClose", 2, EntityType.PLAYER, DefaultPreconditions.isClose)
DefaultPreconditions.fiveMinutesPassed = BasicPrecondition:new("fiveMinutesPassed", 1)
function DefaultPreconditions.fiveMinutesPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 300000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.threeMinutesPassed = BasicPrecondition:new("threeMinutesPassed", 1)
function DefaultPreconditions.threeMinutesPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 180000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.oneMinutePassed = BasicPrecondition:new("oneMinutePassed", 1)
function DefaultPreconditions.oneMinutePassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 60000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.thirtySecondsPassed = BasicPrecondition:new("thirtySecondsPassed", 1)
function DefaultPreconditions.thirtySecondsPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 30000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.twentySecondsPassed = BasicPrecondition:new("twentySecondsPassed", 1)
function DefaultPreconditions.twentySecondsPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 20000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.fifteenSecondsPassed = BasicPrecondition:new("fifteenSecondsPassed", 1)
function DefaultPreconditions.fifteenSecondsPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 15000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.tenSecondsPassed = BasicPrecondition:new("tenSecondsPassed", 1)
function DefaultPreconditions.tenSecondsPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 10000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.fiveSecondsPassed = BasicPrecondition:new("fiveSecondsPassed", 1)
function DefaultPreconditions.fiveSecondsPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 5000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.threeSecondsPassed = BasicPrecondition:new("threeSecondsPassed", 1)
function DefaultPreconditions.threeSecondsPassed:checkPerception(agent, entity)
  local result = entity.stateData.timeEntered + 3000 < AnimalHusbandry.time
  return result and entity
end
DefaultPreconditions.playerIsFrightening = EntityPreconditionCollection:new("playerIsFrightening", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isInRange)
DefaultPreconditions.canStartToLayDownToRest = PreconditionCollection:new("canStartToLayDownToRest", 1, DefaultPreconditions.isExhausted, DefaultPreconditions.isNotMoving, DefaultPreconditions.isStandingOnGrass)
DefaultPreconditions.canStartToStandUp = PreconditionCollection:new("canStartToStandUp", 1, DefaultPreconditions.isRested, DefaultPreconditions.isNotMoving)
DefaultPreconditions.isDrinkable = BasicPrecondition:new("isDrinkable", 1)
function DefaultPreconditions.isDrinkable:checkPerception(agent, entity)
  local result = not not entity.isDrinkable
  return result and entity
end
DefaultPreconditions.isEatable = BasicPrecondition:new("isEatable", 1)
function DefaultPreconditions.isEatable:checkPerception(agent, entity)
  local result = entity.isEatable and entity.isFilled() or false
  return result and entity
end
DefaultPreconditions.isMilkingPlace = BasicPrecondition:new("MilkingPlace", 1)
function DefaultPreconditions.isMilkingPlace:checkPerception(agent, entity)
  local result = not not entity.isMilkingPlace
  return result and entity
end
DefaultPreconditions.targetsEntity = BasicPrecondition:new("targetsEntity", 2)
function DefaultPreconditions.targetsEntity:checkPerception(agent, entity, entity2)
  local result = entity.stateData.target == entity2
  if result then
    return entity, entity2
  else
    return false
  end
end
DefaultPreconditions.isTargetedByEntity = BasicPrecondition:new("isTargetedByEntity", 2)
function DefaultPreconditions.isTargetedByEntity:checkPerception(agent, entity, entity2)
  local result = entity2.stateData.target == entity
  if result then
    return entity, entity2
  else
    return false
  end
end
DefaultPreconditions.isNotTargetedByEntity = NegatePrecondition:new("isNotTargetedByEntity", DefaultPreconditions.isTargetedByEntity)
DefaultPreconditions.isObjectTargetedByOtherAnimal = EntityPreconditionCollection:new("isObjectTargetedByOtherAnimal", 2, EntityType.ANIMAL, NegatePrecondition:new("isNotMyself", DefaultPreconditions.isMyself), DefaultPreconditions.isInRange, DefaultPreconditions.targetsEntity)
DefaultPreconditions.isInFrontOfMyself = BasicPrecondition:new("isInFrontOfMyself", 1)
function DefaultPreconditions.isInFrontOfMyself:checkPerception(agent, entity)
  local connectionX, connectionY, connectionZ = entity.positionX - agent.positionX, entity.positionY - agent.positionY, entity.positionZ - agent.positionZ
  local length = Utils.vector3Length(connectionX, connectionY, connectionZ)
  local directionX, directionY, directionZ
  if 0 < length then
    directionX, directionY, directionZ = connectionX / length, connectionY / length, connectionZ / length
  else
    directionX, directionY, directionZ = -agent.directionX, -agent.directionY, -agent.directionZ
  end
  local result = 0 < Utils.dotProduct(agent.directionX, agent.directionY, agent.directionZ, directionX, directionY, directionZ)
  return result and entity
end
DefaultPreconditions.isCloserToObjectThanMyself = BasicPrecondition:new("isCloserToObjectThanMyself", 1)
function DefaultPreconditions.isCloserToObjectThanMyself:checkPerception(agent, entity, entity2)
  local result = Utils.vector3Length(entity.positionX - entity2.positionX, entity.positionY - entity2.positionY, entity.positionZ - entity2.positionZ) < Utils.vector3Length(agent.positionX - entity2.positionY, agent.positionY - entity2.positionY, agent.positionZ - entity2.positionZ)
  return result and entity
end
DefaultPreconditions.isFeedingPlaceAvailable = EntityPreconditionCollection:new("isFeedingPlaceAvailable", 1, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isInRange)
DefaultPreconditions.isWateringPlaceAvailable = EntityPreconditionCollection:new("isWateringPlaceAvailable", 1, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isInRange)
DefaultPreconditions.canAnimalWalkToFeedingPlace = PreconditionCollection:new("canAnimalWalkToFeedingPlace", 1, DefaultPreconditions.isHungry, DefaultPreconditions.isFeedingPlaceAvailable)
DefaultPreconditions.canAnimalWalkToWateringPlace = PreconditionCollection:new("canAnimalWalkToWateringPlace", 1, DefaultPreconditions.isThirsty, DefaultPreconditions.isWateringPlaceAvailable)
DefaultPreconditions.canEatFromFeedingPlace = EntityPreconditionCollection:new("canEatFromFeedingPlace", 2, EntityType.OBJECT, DefaultPreconditions.isEatable, DefaultPreconditions.isClose)
DefaultPreconditions.canDrinkFromWateringPlace = EntityPreconditionCollection:new("canDrinkFromWateringPlace", 2, EntityType.OBJECT, DefaultPreconditions.isDrinkable, DefaultPreconditions.isClose)
DefaultPreconditions.isInteractionPlaceAvailable = BasicPrecondition:new("isInteractionPlaceAvailable", 1)
function DefaultPreconditions.isInteractionPlaceAvailable:checkPerception(agent, object)
  local objectPerceptionData = agent.perceptionData.perceptionEntitiesHash[object.type][object]
  local result = object.isRoomForAgent and object:isRoomForAgent(agent, objectPerceptionData.distanceToEntity)
  return result, entity
end
DefaultPreconditions.isInteractionPlaceStillAvailable = BasicPrecondition:new("isInteractionPlaceStillAvailable", 1)
function DefaultPreconditions.isInteractionPlaceStillAvailable:checkPerception(agent, object)
  local result = object.isAgentInSlotList and not not object:isAgentInSlotList(agent)
  return result, entity
end
DefaultPreconditions.isInteractionPlaceNotAvailableAnymore = NegatePrecondition:new("isInteractionPlaceNotAvailableAnymore", DefaultPreconditions.isInteractionPlaceStillAvailable)
DefaultPreconditions.isStateChangePracticable = BasicPrecondition:new("isStateChangePracticable", 1)
function DefaultPreconditions.isStateChangePracticable:checkPerception(agent, entity)
  local result = agent.stateData.isStateChangePracticable
  return result and entity
end
DefaultPreconditions.isNight = BasicPrecondition:new("isNight", 1)
function DefaultPreconditions.isNight:checkPerception(agent, entity)
  local animalTime = (ClockWrapper.currentTimeOfDay + agent.stateData.innerClockDifference) % 1
  local result = 0.85 < animalTime or animalTime < 0.35
  return result and entity
end
DefaultPreconditions.isDay = NegatePrecondition:new("isDay", DefaultPreconditions.isNight)
local precondition
precondition = BasicPrecondition:new("gotRefilled", 1)
DefaultPreconditions[precondition.name] = precondition
DefaultPreconditions[precondition.name].checkPerception = function(self, agent, entity)
  local validTime = 10000
  local result = entity.refillTime and entity.refillTime + validTime > AnimalHusbandry.time or false
  return result and entity
end
local precondition
precondition = BasicPrecondition:new("isSlapping", 1)
DefaultPreconditions[precondition.name] = precondition
DefaultPreconditions[precondition.name].checkPerception = function(self, agent, entity)
  local result = not not entity.isSlapping
  return result and entity
end
DefaultPreconditions.playerSlapped = InjectionPrecondition:new("playerSlappedInjected", EntityPreconditionCollection:new("playerSlapped", 2, EntityType.PLAYER, DefaultPreconditions.isSlapping))
