ObjectIds = {}
ObjectIds.objectClasses = {}
ObjectIds.objectIdNext = 0
ObjectIds.objectIdsUsed = {}
ObjectIds.objectIdToClass = {}
function InitObjectClass(classObject, className)
  if g_server ~= nil or g_client ~= nil then
    print("Error: Object initialization only allowed at compile time")
    printCallstack()
    return
  end
  if ObjectIds.objectClasses[className] ~= nil then
    print("Error: Same class name used multiple times " .. className)
    printCallstack()
    return
  end
  ObjectIds.objectClasses[className] = classObject
end
function InitStaticObjectClass(classObject, className, id)
  if g_server ~= nil or g_client ~= nil then
    print("Error: Object initialization only allowed at compile time")
    printCallstack()
    return
  end
  classObject.className = className
  ObjectIds.assignObjectClassObjectId(classObject, className, id)
end
function ObjectIds.getObjectClassByName(className)
  return ObjectIds.objectClasses[className]
end
function ObjectIds.getObjectClassById(id)
  return ObjectIds.objectIdToClass[id]
end
function ObjectIds.assignObjectClassIds()
  for className, classObject in pairs(ObjectIds.objectClasses) do
    ObjectIds.assignObjectClassObjectId(classObject, className, ObjectIds.objectIdNext)
  end
end
function ObjectIds.assignObjectClassId(className, id)
  local classObject = ObjectIds.objectClasses[className]
  if classObject ~= nil then
    ObjectIds.assignObjectClassObjectId(classObject, className, id)
  end
end
function ObjectIds.assignObjectClassObjectId(classObject, className, id)
  if id == nil then
    printCallstack()
  end
  if rawget(classObject, "classId") == nil then
    if ObjectIds.objectIdsUsed[id] ~= nil then
      print("Error: Same object id used multiple times " .. id)
      printCallstack()
      return
    end
    ObjectIds.objectIdsUsed[id] = true
    ObjectIds.objectIdNext = math.max(ObjectIds.objectIdNext, id) + 1
    classObject.classId = id
    ObjectIds.objectIdToClass[id] = classObject
  end
end
ObjectIds.OBJECT_PLAYER = 1
ObjectIds.OBJECT_VEHICLE = 2
ObjectIds.OBJECT_OBJECT = 3
ObjectIds.OBJECT_PHYSIC_OBJECT = 4
ObjectIds.OBJECT_BALE = 5
ObjectIds.OBJECT_TIP_TRIGGER = 6
ObjectIds.OBJECT_SILO_TRIGGER = 7
ObjectIds.OBJECT_PALLET_TRIGGER = 8
ObjectIds.OBJECT_ANIMALS_NETWORK_OBJECT = 9
