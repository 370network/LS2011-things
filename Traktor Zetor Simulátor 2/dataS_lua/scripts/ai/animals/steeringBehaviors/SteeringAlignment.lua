SteeringAlignment = SteeringBehavior:new("ForceAlignment", 100)
function SteeringAlignment:calculateForce(animal, basicWeight, targetX, targetY, targetZ)
  local forceX, forceY, forceZ = animal.herd.velocityX / 100, 0, animal.herd.velocityZ / 100
  return forceX, forceY, forceZ
end
function SteeringAlignment:calculateForce_Complex(animal, basicWeight, targetX, targetY, targetZ)
  return SteeringAlignment:calculateForce(animal, basicWeight, targetX, targetY, targetZ)
end
