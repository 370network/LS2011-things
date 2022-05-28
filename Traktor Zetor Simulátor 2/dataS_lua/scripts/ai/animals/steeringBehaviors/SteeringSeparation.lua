SteeringSeparation = SteeringBehavior:new("Separation", 800)
function SteeringSeparation:applyToAgent(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  SteeringBehavior.applyToAgent(self, agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  if not agent.perceptionData.entityPerceptionLists[EntityType.ANIMAL] then
    agent.perceptionData.entityPerceptionLists[EntityType.ANIMAL] = {}
  end
  if not agent.perceptionData.entityPerceptionLists[EntityType.PLAYER] then
    agent.perceptionData.entityPerceptionLists[EntityType.PLAYER] = {}
  end
end
function SteeringSeparation:calculateForce(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local finalForceX, finalForceY, finalForceZ = 0, 0, 0
  local finalImportance = 0
  local maximumImportance = 0
  local compoundImportance = 0
  local forceX, forceY, forceZ = 0, 0, 0
  local maximumDistance = agent.mediumDistance
  for _, animalData in ipairs(agent.perceptionData.entityPerceptionLists[EntityType.ANIMAL]) do
    local animal = animalData.entity
    if maximumDistance <= animalData.distanceToEntity then
      break
    end
    if animalData.distanceToEntity > 1.0E-4 then
      local distanceModification = animal:getBodyDimensionAtAngle(animalData.angleFromEntity) + agent:getBodyDimensionAtAngle(animalData.angleToEntity)
      local exactDistanceToAnimal = animalData.distanceToEntity - distanceModification
      local exactMaximumDistance = maximumDistance - distanceModification
      exactDistanceToAnimal = math.min(exactDistanceToAnimal, exactMaximumDistance)
      local distanceFactor = exactDistanceToAnimal / exactMaximumDistance
      local angleFactor = (animalData.angleToEntity + 1) / 2
      local importance
      if 0 < distanceFactor then
        importance = 1 / distanceFactor - 1
        importance = importance * angleFactor
      else
        importance = 1
      end
      local newImportance = 1 - distanceFactor
      newImportance = newImportance * angleFactor
      local multiplier = -1 * newImportance
      forceX, forceY, forceZ = forceX + animalData.directionToEntityX * multiplier, forceY + animalData.directionToEntityY * multiplier, forceZ + animalData.directionToEntityZ * multiplier
      maximumImportance = math.max(newImportance, maximumImportance)
      compoundImportance = compoundImportance + newImportance
    end
  end
  for _, animalData in ipairs(agent.perceptionData.entityPerceptionLists[EntityType.PLAYER]) do
    local animal = animalData.entity
    if maximumDistance <= animalData.distanceToEntity then
      break
    end
    if animalData.distanceToEntity > 1.0E-4 then
      local distanceModification = 1 + agent:getBodyDimensionAtAngle(animalData.angleToEntity)
      local exactDistanceToAnimal = animalData.distanceToEntity - distanceModification
      local exactMaximumDistance = maximumDistance - distanceModification
      exactDistanceToAnimal = math.min(exactDistanceToAnimal, exactMaximumDistance)
      local distanceFactor = exactDistanceToAnimal / exactMaximumDistance
      local angleFactor = (animalData.angleToEntity + 1) / 2
      local importance
      if 0 < distanceFactor then
        importance = 1 / distanceFactor - 1
        importance = importance * angleFactor
      else
        importance = 1
      end
      local newImportance = 1 - distanceFactor
      newImportance = newImportance * angleFactor
      local multiplier = -1 * newImportance
      forceX, forceY, forceZ = forceX + animalData.directionToEntityX * multiplier, forceY + animalData.directionToEntityY * multiplier, forceZ + animalData.directionToEntityZ * multiplier
      maximumImportance = math.max(newImportance, maximumImportance)
      compoundImportance = compoundImportance + newImportance
    end
  end
  local forceLength = Utils.vector3Length(forceX, forceY, forceZ)
  if 0 < forceLength then
    local finalDirectionX, finalDirectionY, finalDirectionZ = forceX / forceLength, forceY / forceLength, forceZ / forceLength
    finalForceX, finalForceY, finalForceZ = finalDirectionX, finalDirectionY, finalDirectionZ
    finalImportance = maximumImportance
  else
    finalForceX, finalForceY, finalForceZ, finalImportance = 0, 0, 0, 0
  end
  local finalComplexity = maximumImportance
  return finalForceX, finalForceY, finalForceZ, finalImportance, finalComplexity
end
function SteeringSeparation:calculateForce_Complex(agent, basicWeight, targetPositionX, targetPositionY, targetPositionZ)
  local compoundForce = 0
  local compoundDirectionX, compoundDirectionY, compoundDirectionZ = 0, 0, 0
  local compoundRotationX, compoundRotationY, compoundRotationZ = 0, 0, 0
  local compoundImportance = 0
  local maximumImportance = 0
  for animal, animalData in pairs(agent.perceptionData.perceptionEntitiesHash[EntityType.ANIMAL]) do
    local maximumDistance = animal.nearDistance
    if animalData.distanceToEntity > 0.001 and maximumDistance > animalData.distanceToEntity then
      local distanceModification = 0 - animal:getBodyDimensionInDirection(animalData.directionToEntityX * -1, animalData.directionToEntityY * -1, animalData.directionToEntityZ * -1) - agent:getBodyDimensionInDirection(animalData.directionToEntityX, animalData.directionToEntityY, animalData.directionToEntityZ)
      local exactDistanceToAnimal = animalData.distanceToEntity + distanceModification
      local exactMaximumDistance = (maximumDistance + distanceModification) * basicWeight
      exactDistanceToAnimal = math.min(exactDistanceToAnimal, exactMaximumDistance)
      exactDistanceToAnimal = math.max(exactDistanceToAnimal, 0.001)
      local force = self.basicForce
      local directionX, directionY, directionZ = animalData.directionToEntityX * -1, animalData.directionToEntityY * -1, animalData.directionToEntityZ * -1
      local rotationX, rotationY, rotationZ = MotionControl:convertDirectionToRotation(agent, directionX, directionY, directionZ)
      local importance = basicWeight
      local isFacingEachOther = 0 < animalData.angleToEntityDirection and animalData.angleToEntity > 0.5
      local isInFront = animalData.angleToEntity > 0.5
      local isFaster = agent.speed > animal.speed
      local isClose = animalData.distanceToEntity < agent.closeDistance
      local isMovingForward = 0 < agent.speed
      if isClose then
        if isFacingEachOther then
          force = force * -1
        elseif isInFront and isMovingForward then
          force = force * -1
        end
      else
        force = 0
      end
      importance = 1 / exactDistanceToAnimal - 1 / exactMaximumDistance
      maximumImportance = math.max(importance, maximumImportance)
      compoundForce = compoundForce + force
      compoundDirectionX, compoundDirectionY, compoundDirectionZ = compoundDirectionX + directionX, compoundDirectionY + directionY, compoundDirectionZ + directionZ
      compoundRotationX, compoundRotationY, compoundRotationZ = compoundRotationX + rotationX, compoundRotationY + rotationY, compoundRotationZ + rotationZ
      compoundImportance = compoundImportance + importance
    end
  end
  if 0 < maximumImportance then
    local length = Utils.vector3Length(compoundDirectionX, compoundDirectionY, compoundDirectionZ)
    compoundDirectionX, compoundDirectionY, compoundDirectionZ = compoundDirectionX / length, compoundDirectionY / length, compoundDirectionZ / length
  end
  compoundImportance = maximumImportance
  return compoundForce, compoundDirectionX, compoundDirectionY, compoundDirectionZ, compoundRotationX, compoundRotationY, compoundRotationZ, compoundImportance
end
