EventIds = {}
EventIds.eventClasses = {}
EventIds.eventIdNext = 0
EventIds.eventIdsUsed = {}
EventIds.eventIdToClass = {}
function InitEventClass(classObject, className)
  if g_currentMission ~= nil then
    print("Error: Event initialization only allowed at compile time")
    printCallstack()
    return
  end
  if EventIds.eventClasses[className] ~= nil then
    print("Error: Same class name used multiple times " .. className)
    printCallstack()
    return
  end
  EventIds.eventClasses[className] = classObject
end
function InitStaticEventClass(classObject, className, id)
  if g_server ~= nil or g_client ~= nil then
    print("Error: Event initialization only allowed at compile time")
    printCallstack()
    return
  end
  EventIds.assignEventObjectId(classObject, className, id)
end
function EventIds.getEventClassByName(className)
  return EventIds.eventClasses[className]
end
function EventIds.getEventClassById(id)
  return EventIds.eventIdToClass[id]
end
function EventIds.assignEventIds()
  for className, classObject in pairs(EventIds.eventClasses) do
    EventIds.assignEventObjectId(classObject, className, EventIds.eventIdNext)
  end
end
function EventIds.assignEventId(className, id)
  local classObject = EventIds.eventClasses[className]
  if classObject ~= nil then
    EventIds.assignEventObjectId(classObject, className, id)
  end
end
function EventIds.assignEventObjectId(classObject, className, id)
  if id == nil then
    print("Error: Invalid event id, it is nil")
    printCallstack()
    return
  end
  if classObject.eventId == nil then
    if EventIds.eventIdsUsed[id] ~= nil then
      print("Error: Same event id used multiple times " .. id)
      printCallstack()
      return
    end
    EventIds.eventIdsUsed[id] = true
    EventIds.eventIdNext = math.max(EventIds.eventIdNext, id + 1)
    classObject.eventId = id
    EventIds.eventIdToClass[id] = classObject
  end
end
EventIds.EVENT_BALECREATE = 1
EventIds.EVENT_FINISHED_LOADING = 2
EventIds.EVENT_READY_EVENT = 3
EventIds.EVENT_SET_FRUIT_AMOUNT = 4
EventIds.EVENT_CHAT = 5
EventIds.EVENT_CONNECTION_REQUEST_ANSWER = 6
EventIds.EVENT_CONNECTION_REQUEST = 7
EventIds.EVENT_ENVIRONMENT_PRICE = 8
EventIds.EVENT_ENVIRONMENT_TIME = 9
EventIds.EVENT_ENVIRONMENT_TMP = 10
EventIds.EVENT_ENVIRONMENT_WEATHER = 11
EventIds.EVENT_CLIENT_POSITION = 12
EventIds.EVENT_PLAYER_ENTER = 13
EventIds.EVENT_PLAYER_LEAVE = 14
EventIds.EVENT_SET_DENSITY_MAP = 15
EventIds.EVENT_SHUTDOWN = 16
EventIds.EVENT_ON_CREATE_LOADED_OBJECT = 19
EventIds.EVENT_AICOMBINE_SET_STARTED = 20
EventIds.EVENT_AITRACTOR_LOWER_IMPLEMENT = 21
EventIds.EVENT_AITRACTOR_RAISE_IMPLEMENT = 22
EventIds.EVENT_AITRACTOR_ROTATE_LEFT = 23
EventIds.EVENT_AITRACTOR_ROTATE_RIGHT = 24
EventIds.EVENT_AITRACTOR_SET_STARTED = 25
EventIds.EVENT_ANIMATED_VEHICLE_START = 26
EventIds.EVENT_ANIMATED_VEHICLE_STOP = 27
EventIds.EVENT_BALER_AREA = 28
EventIds.EVENT_BALER_CREATE_BALE = 29
EventIds.EVENT_BALER_DELETE_BALE = 30
EventIds.EVENT_BALER_SET_BALE_TIME = 31
EventIds.EVENT_COMBINE_AREA = 32
EventIds.EVENT_COMBINE_PIPE_PARTICLE_ACTIVATED = 34
EventIds.EVENT_COMBINE_SET_CHOPPER_ENABLE = 35
EventIds.EVENT_COMBINE_SET_PIPE_STATE = 36
EventIds.EVENT_COMBINE_SET_STRAW_ENABLE = 37
EventIds.EVENT_COMBINE_SET_TRESHING_ENABLED = 38
EventIds.EVENT_CULTIVATOR_AREA = 39
EventIds.EVENT_CUTTER_AREA = 40
EventIds.EVENT_FOLDABLE_SET_FOLD_DIRECTION = 41
EventIds.EVENT_FORAGE_WAGON_AREA = 42
EventIds.EVENT_MOWER_AREA = 44
EventIds.EVENT_PLOUGH_AREA = 45
EventIds.EVENT_PLOUGH_ROTATION = 46
EventIds.EVENT_SET_MOTOR_TURNED_ON = 47
EventIds.EVENT_SET_TURNED_ON = 48
EventIds.EVENT_SOWING_MACHINE_AREA = 49
EventIds.EVENT_SPRAYER_AREA = 50
EventIds.EVENT_STEERABLE_SPEED_LEVEL = 51
EventIds.EVENT_STEERABLE_TOGGLE_LIGHT = 52
EventIds.EVENT_STEERABLE_TOGGLE_REFUEL = 53
EventIds.EVENT_TEDDER_AREA = 54
EventIds.EVENT_TEDDER_SET_ANIM_TIME = 55
EventIds.EVENT_TRAILER_TOGGLE_TIP = 58
EventIds.EVENT_WINDROW_AREA = 59
EventIds.EVENT_WINDROWER_SET_ANIM_TIME = 60
EventIds.EVENT_VEHICLE_ATTACH = 61
EventIds.EVENT_VEHICLE_DETACH = 62
EventIds.EVENT_VEHICLE_ENTER_REQUEST = 63
EventIds.EVENT_VEHICLE_ENTER_RESPONSE = 64
EventIds.EVENT_VEHICLE_LEAVE = 65
EventIds.EVENT_VEHICLE_LOWER_IMPLEMENT = 66
EventIds.EVENT_VEHICLE_REMOVE = 67
EventIds.EVENT_USER = 68
EventIds.EVENT_MONEY = 69
EventIds.EVENT_GAME_PAUSE = 71
EventIds.EVENT_BALE_LOADER_STATE = 72
EventIds.EVENT_SELL_COW = 73
EventIds.EVENT_SELL_VEHICLE = 74
EventIds.EVENT_BUY_COW = 75
EventIds.EVENT_BUY_VEHICLE = 76
EventIds.EVENT_SEND_MONEY = 77
EventIds.EVENT_SPRAYER_SET_IS_FILLING = 78
EventIds.EVENT_STARTLE_ANIMAL = 79
EventIds.EVENT_CREATE_COWS = 80
EventIds.EVENT_SOWING_MACHINE_SET_IS_FILLING = 81
EventIds.EVENT_BALER_SET_IS_UNLOADING_BALE = 82
EventIds.EVENT_PLAYER_TELEPORT = 83
EventIds.EVENT_HONK = 84
EventIds.EVENT_MILKROBOT_CHANGED_STATE = 85
EventIds.EVENT_VEHICLE_SET_BEACON_LIGHT = 86
EventIds.EVENT_SOWING_MACHINE_SET_SEED_INDEX = 87
