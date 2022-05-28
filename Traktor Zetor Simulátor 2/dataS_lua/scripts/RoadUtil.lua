RoadUtil = {}
RoadUtil.roads = {}
RoadUtil.splineIdsToRoad = {}
RoadUtil.junctions = {}
RoadUtil.DIRECTION_FORWARD = 1
RoadUtil.DIRECTION_BACKWARD = 2
RoadUtil.minCrossroadsDistance = 5
RoadUtil.maxNumVehiclesInSeries = 3
RoadUtil.randomSequenceNumber = 1
function RoadUtil.debugPrint(...)
end
function RoadUtil.init()
  if not g_currentMission:getIsServer() then
    return
  end
  local matchLimit = 3
  local testStepDistance = 0.5
  local switchMinDistance = 1
  for k1, road in pairs(RoadUtil.roads) do
    local minStartDistances = {}
    local minEndDistances = {}
    local step = testStepDistance / road.splineLength
    for i = 0, 1, step do
      local x, y, z = getSplinePosition(road.spline, i)
      for k2, road2 in pairs(RoadUtil.roads) do
        if road2 ~= road then
          local dist = Utils.vector2Length(x - road2.startPoint[1], z - road2.startPoint[3])
          if matchLimit > dist and (minStartDistances[road2] == nil or dist < minStartDistances[road2][1]) then
            minStartDistances[road2] = {dist, i}
          end
          local dist = Utils.vector2Length(x - road2.endPoint[1], z - road2.endPoint[3])
          if matchLimit > dist and (minEndDistances[road2] == nil or dist < minEndDistances[road2][1]) then
            minEndDistances[road2] = {dist, i}
          end
        end
      end
    end
    local switchLimitStart = switchMinDistance / road.splineLength
    local switchLimitEnd = 1 - switchMinDistance / road.splineLength
    for road2, crossInfo in pairs(minStartDistances) do
      RoadUtil.addCrossroads(road, crossInfo[2], road2, 0, RoadUtil.DIRECTION_FORWARD)
      if not road2.isOneWay then
        if switchLimitEnd > crossInfo[2] then
          RoadUtil.addCrossroads(road2, 0, road, crossInfo[2], RoadUtil.DIRECTION_FORWARD)
        end
        if not road.isOneWay and switchLimitStart < crossInfo[2] then
          RoadUtil.addCrossroads(road2, 0, road, crossInfo[2], RoadUtil.DIRECTION_BACKWARD)
        end
      end
    end
    for road2, crossInfo in pairs(minEndDistances) do
      if not road2.isOneWay then
        RoadUtil.addCrossroads(road, crossInfo[2], road2, 1, RoadUtil.DIRECTION_BACKWARD)
      end
      if switchLimitEnd > crossInfo[2] then
        RoadUtil.addCrossroads(road2, 1, road, crossInfo[2], RoadUtil.DIRECTION_FORWARD)
      end
      if not road.isOneWay and switchLimitStart < crossInfo[2] then
        RoadUtil.addCrossroads(road2, 1, road, crossInfo[2], RoadUtil.DIRECTION_BACKWARD)
      end
    end
  end
  RoadUtil.debugPrint("roads:")
  for i = 1, table.getn(RoadUtil.roads) do
    RoadUtil.debugPrint(" -num crossroads: ", table.getn(RoadUtil.roads[i].crossroads))
  end
end
function RoadUtil.delete()
  RoadUtil.roads = {}
  RoadUtil.splineIdsToRoad = {}
  for k, v in pairs(RoadUtil.junctions) do
    removeTrigger(getChildAt(v.node, 0))
    removeTrigger(v.node)
  end
  RoadUtil.junctions = {}
end
function RoadUtil.getRandomRoadSequence(roadTypeAttribute, sequenceIndicesAttribute, sequenceDirectionsAttribute)
  RoadUtil.debugPrint("start path:")
  RoadUtil.randomSequenceNumber = RoadUtil.randomSequenceNumber + 1
  RoadUtil.nextSequenceNumber = 0
  local sequence = {}
  local loopIndex = 0
  local numRoads = table.getn(RoadUtil.roads)
  if numRoads == 0 then
    return nil
  end
  local possibleStarts = {}
  for _, road in pairs(RoadUtil.roads) do
    if RoadUtil.isRoadOk(road, roadTypeAttribute) then
      local numStarts = 1
      if not road.isOneWay then
        numStarts = 2
      end
      for i = 1, numStarts do
        local crossroads = road.crossroads[i]
        if RoadUtil.isSequenceIndexOk(road, crossroads.directionOnRoad2, sequenceIndicesAttribute, sequenceDirectionsAttribute) then
          table.insert(possibleStarts, crossroads)
        end
      end
    end
  end
  local numPossibleStarts = table.getn(possibleStarts)
  if numPossibleStarts == 0 then
    RoadUtil.debugPrint("No possible starts found")
    return nil
  end
  local currentCrossroads = possibleStarts[math.random(1, numPossibleStarts)]
  table.insert(sequence, currentCrossroads)
  RoadUtil.nextSequenceNumber = RoadUtil.nextSequenceNumber + 1
  RoadUtil.debugPrint("add: " .. getName(currentCrossroads.road2.spline) .. " ", currentCrossroads.timePos2, " ", RoadUtil.directionToString(currentCrossroads.directionOnRoad2))
  local finished = false
  while not finished do
    local curRoad = currentCrossroads.road2
    local curTimePos = currentCrossroads.timePos2
    local curDirection = currentCrossroads.directionOnRoad2
    local numStarts = 1
    if not curRoad.isOneWay then
      numStarts = 2
    end
    local numCrossroads = table.getn(curRoad.crossroads)
    if numCrossroads > numStarts * 2 then
      local num = math.random(1, numCrossroads)
      local i = 1 + numStarts * 2
      local j = 1
      local found = false
      while true do
        local crossroads = curRoad.crossroads[i]
        if RoadUtil.isCrossroadsOk(curRoad, curTimePos, curDirection, crossroads, roadTypeAttribute, sequenceIndicesAttribute, sequenceDirectionsAttribute) then
          found = true
          if j == num then
            local road2Name = "end"
            if crossroads.road2 ~= nil then
              road2Name = getName(crossroads.road2.spline)
            end
            RoadUtil.debugPrint("add: " .. getName(crossroads.road1.spline) .. "->" .. road2Name .. " ", crossroads.timePos2, " angle ", math.deg(math.acos(crossroads.cosAngle)))
            table.insert(sequence, crossroads)
            RoadUtil.nextSequenceNumber = RoadUtil.nextSequenceNumber + 1
            currentCrossroads = crossroads
            crossroads.randomSequenceNumber = RoadUtil.randomSequenceNumber
            break
          end
          j = j + 1
        end
        i = i + 1
        if numCrossroads < i then
          if not found then
            finished = true
            break
          end
          found = false
          i = 1 + numStarts * 2
        end
      end
    else
      finished = true
    end
    if finished then
      RoadUtil.randomSequenceNumber = RoadUtil.randomSequenceNumber + 1
      if sequenceIndicesAttribute ~= nil then
        RoadUtil.nextSequenceNumber = 0
        local numCrossroads = table.getn(curRoad.crossroads)
        if numCrossroads > numStarts * 2 then
          for i = numStarts * 2 + 1, numCrossroads do
            local crossroads = curRoad.crossroads[i]
            if RoadUtil.isCrossroadsOk(curRoad, curTimePos, curDirection, crossroads, roadTypeAttribute, sequenceIndicesAttribute, sequenceDirectionsAttribute) then
              loopIndex = 1
              RoadUtil.debugPrint("sequence using loop")
              table.insert(sequence, crossroads)
              break
            end
          end
        end
      else
        local numCrossroads = table.getn(curRoad.crossroads)
        if numCrossroads > numStarts * 2 then
          RoadUtil.debugPrint("searching for loop")
          for i = numStarts * 2 + 1, numCrossroads do
            local crossroads = curRoad.crossroads[i]
            if RoadUtil.isCrossroadsOk(curRoad, curTimePos, curDirection, crossroads, roadTypeAttribute, sequenceIndicesAttribute, sequenceDirectionsAttribute) then
              RoadUtil.debugPrint("found crossroads: " .. getName(crossroads.road1.spline) .. "->" .. getName(crossroads.road2.spline))
              for k = 2, table.getn(sequence) do
                if sequence[k].road1.spline == crossroads.road2.spline then
                  RoadUtil.debugPrint("found sequence ", k)
                  if RoadUtil.isCrossroadsOk(crossroads.road2, crossroads.timePos2, crossroads.directionOnRoad2, sequence[k], roadTypeAttribute, sequenceIndicesAttribute, sequenceDirectionsAttribute) then
                    local length = 0
                    local lastCrossroads = crossroads
                    for a = k, table.getn(sequence) do
                      length = length + math.abs(lastCrossroads.timePos2 - sequence[a].timePos) * lastCrossroads.road2.splineLength
                      lastCrossroads = sequence[a]
                    end
                    RoadUtil.debugPrint("length: ", length)
                    if 1000 < length then
                      loopIndex = k
                      RoadUtil.debugPrint("using loop")
                      table.insert(sequence, crossroads)
                      break
                    end
                  end
                else
                  RoadUtil.debugPrint("not equal: " .. getName(sequence[k].road1.spline) .. " " .. getName(crossroads.road2.spline))
                end
              end
              if loopIndex ~= 0 then
                break
              end
            end
          end
        end
      end
      if loopIndex == 0 then
        local endIndex = numStarts + math.random(1, numStarts)
        table.insert(sequence, curRoad.crossroads[endIndex])
        RoadUtil.debugPrint("add final: " .. getName(curRoad.crossroads[endIndex].road1.spline) .. "->end ", curRoad.crossroads[endIndex].timePos)
      end
    end
  end
  return sequence, loopIndex
end
function RoadUtil.isCrossroadsOk(curRoad, curTimePos, curDirection, crossroads, roadTypeAttribute, sequenceIndicesAttribute, sequenceDirectionsAttribute)
  local sequenceOk = RoadUtil.isSequenceIndexOk(crossroads.road2, crossroads.directionOnRoad2, sequenceIndicesAttribute, sequenceDirectionsAttribute)
  if sequenceOk then
    if sequenceIndicesAttribute ~= nil then
      return true
    end
  else
    return false
  end
  if crossroads.randomSequenceNumber == RoadUtil.randomSequenceNumber then
    return false
  end
  if crossroads.road1 == 0 then
    return false
  end
  if curDirection == RoadUtil.DIRECTION_FORWARD then
    if crossroads.cosAngle < -0.64 then
      RoadUtil.debugPrint("ignore: " .. getName(curRoad.spline) .. " " .. RoadUtil.directionToString(curDirection) .. "->" .. getName(crossroads.road2.spline) .. " " .. RoadUtil.directionToString(crossroads.directionOnRoad2) .. " cos angle: ", crossroads.cosAngle)
      return false
    end
  elseif curDirection == RoadUtil.DIRECTION_BACKWARD and crossroads.cosAngle > 0.64 then
    RoadUtil.debugPrint("ignore: " .. getName(curRoad.spline) .. " " .. RoadUtil.directionToString(curDirection) .. "->" .. getName(crossroads.road2.spline) .. " " .. RoadUtil.directionToString(crossroads.directionOnRoad2) .. " cos angle: ", crossroads.cosAngle)
    return false
  end
  if not RoadUtil.isRoadOk(crossroads.road2, roadTypeAttribute) then
    return false
  end
  if curDirection == RoadUtil.DIRECTION_FORWARD then
    return crossroads.timePos > curTimePos + RoadUtil.minCrossroadsDistance / curRoad.splineLength
  elseif curDirection == RoadUtil.DIRECTION_BACKWARD then
    return crossroads.timePos < curTimePos - RoadUtil.minCrossroadsDistance / curRoad.splineLength
  end
  return false
end
function RoadUtil.isSequenceIndexOk(road, direction, sequenceIndicesAttribute, sequenceDirectionsAttribute)
  if sequenceIndicesAttribute == nil then
    return true
  end
  local indicesAttr = getUserAttribute(road.spline, sequenceIndicesAttribute)
  if indicesAttr == nil then
    return false
  end
  local indices = Utils.splitString(" ", tostring(indicesAttr))
  if table.getn(indices) == 0 then
    return false
  end
  local directions = {}
  if sequenceDirectionsAttribute ~= nil and direction ~= nil then
    local directionsAttr = getUserAttribute(road.spline, sequenceDirectionsAttribute)
    if directionsAttr ~= nil then
      directions = Utils.splitString(" ", tostring(directionsAttr))
    end
  end
  for i = 1, table.getn(indices) do
    local sequenceDirection = tonumber(directions[i])
    if tonumber(indices[i]) == RoadUtil.nextSequenceNumber and (direction == nil or sequenceDirection == nil or sequenceDirection == direction) then
      return true
    end
  end
  return false
end
function RoadUtil.isRoadOk(road, roadTypeAttribute)
  if roadTypeAttribute ~= nil then
    local userAttr = getUserAttribute(road.spline, roadTypeAttribute)
    if roadTypeAttribute == "trafficRoad" then
      if userAttr ~= nil and not userAttr then
        return false
      end
    elseif userAttr == nil or not userAttr then
      return false
    end
  end
  return true
end
function RoadUtil.addRoad(spline)
  if RoadUtil.splineIdsToRoad[spline] == nil then
    local road = {}
    road.spline = spline
    road.splineLength = getSplineLength(spline)
    road.crossroads = {}
    road.roadsToCrossroads = {}
    road.startPoint = {
      getSplineCV(spline, 0)
    }
    road.endPoint = {
      getSplineCV(spline, getSplineNumOfCV(spline) - 1)
    }
    road.isOneWay = Utils.getNoNil(getUserAttribute(spline, "isOneWay"), false)
    if not road.isOneWay then
      road.trackDistance = Utils.getNoNil(getUserAttribute(spline, "trackDistance"), 4)
    end
    table.insert(RoadUtil.roads, road)
    RoadUtil.splineIdsToRoad[spline] = road
    return road
  end
  return nil
end
function RoadUtil.addCrossroads(road1, timePos, road2, timePos2, directionOnRoad2)
  local crossroadsRef = road1.roadsToCrossroads[road2]
  if crossroadsRef == nil or crossroadsRef[directionOnRoad2] == nil then
    local dx1, dy1, dz1 = getSplineDirection(road1.spline, timePos)
    local dx2, dy2, dz2 = getSplineDirection(road2.spline, timePos2)
    local cosAngle = dx1 * dx2 + dy1 * dy2 + dz1 * dz2
    if directionOnRoad2 == RoadUtil.DIRECTION_BACKWARD then
      cosAngle = -cosAngle
    end
    RoadUtil.debugPrint("angle " .. getName(road1.spline) .. "->" .. getName(road2.spline) .. ": " .. math.deg(math.acos(cosAngle)) .. " directionOnRoad2: " .. RoadUtil.directionToString(directionOnRoad2))
    local crossroads = {
      timePos = timePos,
      road1 = road1,
      road2 = road2,
      timePos2 = timePos2,
      directionOnRoad2 = directionOnRoad2,
      cosAngle = cosAngle
    }
    table.insert(road1.crossroads, crossroads)
    if crossroadsRef == nil then
      crossroadsRef = {}
      road1.roadsToCrossroads[road2] = crossroadsRef
    end
    crossroadsRef[directionOnRoad2] = crossroads
  end
end
function RoadUtil.addStartCrossroads(road)
  local crossroads = {
    timePos = 0,
    road1 = nil,
    road2 = road,
    timePos2 = 0,
    directionOnRoad2 = RoadUtil.DIRECTION_FORWARD,
    cosAngle = 0
  }
  table.insert(road.crossroads, crossroads)
  if not road.isOneWay then
    local crossroads = {
      timePos = 0,
      road1 = nil,
      road2 = road,
      timePos2 = 1,
      directionOnRoad2 = RoadUtil.DIRECTION_BACKWARD,
      cosAngle = 0
    }
    table.insert(road.crossroads, crossroads)
  end
end
function RoadUtil.addEndCrossroads(road)
  local crossroads = {
    timePos = 1,
    road1 = road,
    road2 = nil,
    timePos2 = 0,
    directionOnRoad2 = RoadUtil.DIRECTION_FORWARD,
    cosAngle = 0
  }
  table.insert(road.crossroads, crossroads)
  if not road.isOneWay then
    local crossroads = {
      timePos = 0,
      road1 = road,
      road2 = nil,
      timePos2 = 0,
      directionOnRoad2 = RoadUtil.DIRECTION_BACKWARD,
      cosAngle = 0
    }
    table.insert(road.crossroads, crossroads)
  end
end
function RoadUtil.update(dt)
  for k, junction in pairs(RoadUtil.junctions) do
    local numWaiting = table.getn(junction.waitingVehicles)
    if 0 < numWaiting then
      if junction.numLocks > RoadUtil.maxNumVehiclesInSeries then
        junction.allowSeries = false
      end
      if junction.numLocks == 0 then
        local waitingVehicle = junction.waitingVehicles[1]
        local vehicle = waitingVehicle.vehicle
        junction.locks[vehicle] = true
        junction.numLocks = 1
        junction.lockRoad1 = waitingVehicle.road1
        junction.lockRoad2 = waitingVehicle.road2
        junction.allowSeries = true
        vehicle.waitingForJunction = false
        table.remove(junction.waitingVehicles, 1)
      elseif junction.allowSeries or numWaiting == 1 then
        for i = 1, numWaiting do
          local waitingVehicle = junction.waitingVehicles[i]
          local isOk = false
          if junction.lockRoad1 == waitingVehicle.road1 then
            if junction.lockRoad2 == waitingVehicle.road2 then
              isOk = true
            elseif junction.lockRoad2 == nil and waitingVehicle.road2 == waitingVehicle.road1 then
              isOk = true
            end
          elseif junction.lockRoad2 == waitingVehicle.road1 and junction.lockRoad1 == waitingVehicle.road2 then
            isOk = true
          end
          if isOk then
            local vehicle = waitingVehicle.vehicle
            junction.locks[vehicle] = true
            junction.numLocks = junction.numLocks + 1
            vehicle.waitingForJunction = false
            table.remove(junction.waitingVehicles, i)
            break
          end
        end
      end
    end
  end
end
function RoadUtil.onJunctionTriggerEnter(junction, triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter then
    local vehicle = g_currentMission.nodeToVehicle[otherId]
    if vehicle ~= nil and vehicle.isPathVehicle and junction.locks[vehicle] == nil then
      junction.locks[vehicle] = false
      local road1 = vehicle.currentRoad
      local endTime
      if vehicle.nextCrossroads ~= nil then
        endTime = vehicle.nextCrossroads.timePos
      elseif vehicle.currentDirection == RoadUtil.DIRECTION_FORWARD then
        endTime = 1
      else
        endTime = 0
      end
      local distanceToEnd = math.abs(vehicle.lastSplineTime - endTime) * vehicle.splineLength
      local road2
      if 20 < distanceToEnd then
        road2 = road1
      elseif vehicle.nextCrossroads ~= nil then
        road2 = vehicle.nextCrossroads.road2
      else
        road2 = nil
      end
      if vehicle.forceJunctionTime ~= nil and vehicle.forceJunctionTime > g_currentMission.time then
        for k, v in pairs(junction.locks) do
          if v == true then
            junction.locks[k] = false
            k.waitingForJunction = true
            table.insert(junction.waitingVehicles, 1, {
              vehicle = k,
              road1 = junction.lockRoad1,
              road2 = junction.lockRoad2
            })
          end
        end
        junction.lockRoad1 = road1
        junction.lockRoad2 = road2
        junction.locks[vehicle] = true
        junction.numLocks = 1
        vehicle.waitingForJunction = false
      else
        vehicle.waitingForJunction = true
        table.insert(junction.waitingVehicles, {
          vehicle = vehicle,
          road1 = road1,
          road2 = road2
        })
      end
      vehicle.forceJunctionTime = nil
    end
  end
end
function RoadUtil.onJunctionTriggerLeave(junction, triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onLeave then
    local vehicle = g_currentMission.nodeToVehicle[otherId]
    if vehicle ~= nil and vehicle.isPathVehicle then
      RoadUtil.removeVehicleFromJunction(junction, vehicle)
    end
  end
end
function RoadUtil.removeVehicleFromJunction(junction, vehicle)
  if junction.locks[vehicle] ~= nil and junction.locks[vehicle] == true then
    junction.locks[vehicle] = nil
    junction.numLocks = junction.numLocks - 1
  else
    for i = 1, table.getn(junction.waitingVehicles) do
      if junction.waitingVehicles[i].vehicle == vehicle then
        table.remove(junction.waitingVehicles, i)
        break
      end
    end
  end
end
function RoadUtil.onTrafficVehicleDeleted(vehicle)
  for k, junction in pairs(RoadUtil.junctions) do
    RoadUtil.removeVehicleFromJunction(junction, vehicle)
  end
end
function RoadUtil:onCreateJunction(id)
  setVisibility(id, false)
  if g_currentMission:getIsServer() then
    local junction = {}
    junction.node = id
    junction.locks = {}
    junction.numLocks = 0
    junction.waitingVehicles = {}
    junction.lockRoad1 = nil
    junction.lockRoad2 = nil
    junction.allowSeries = true
    junction.onJunctionTriggerEnter = RoadUtil.onJunctionTriggerEnter
    junction.onJunctionTriggerLeave = RoadUtil.onJunctionTriggerLeave
    addTrigger(id, "onJunctionTriggerEnter", junction)
    addTrigger(getChildAt(id, 0), "onJunctionTriggerLeave", junction)
    table.insert(RoadUtil.junctions, junction)
  end
end
function RoadUtil:onCreateRoad(id)
  setVisibility(id, false)
  if g_currentMission:getIsServer() then
    local road = RoadUtil.addRoad(id)
    RoadUtil.addStartCrossroads(road)
    RoadUtil.addEndCrossroads(road)
  end
end
function RoadUtil.directionToString(direction)
  if direction == RoadUtil.DIRECTION_FORWARD then
    return "forward"
  elseif direction == RoadUtil.DIRECTION_BACKWARD then
    return "backward"
  end
  return "unknown"
end
