source("dataS/scripts/shared/input.lua")
source("dataS/scripts/shared/scenegraph.lua")
source("dataS/scripts/shared/audio.lua")
source("dataS/scripts/shared/class.lua")
source("dataS/scripts/shared/graph.lua")
source("dataS/scripts/network/EventIds.lua")
source("dataS/scripts/network/ObjectIds.lua")
source("dataS/scripts/network/Object.lua")
source("dataS/scripts/network/NetworkNode.lua")
source("dataS/scripts/network/Client.lua")
source("dataS/scripts/network/Server.lua")
source("dataS/scripts/network/Connection.lua")
source("dataS/scripts/network/Event.lua")
source("dataS/scripts/network/MessageIds.lua")
source("dataS/scripts/network/ConnectionManager.lua")
source("dataS/scripts/I18N.lua")
source("dataS/scripts/gui/Mouse.lua")
source("dataS/scripts/gui/base_gui.lua")
source("dataS/scripts/gui/MouseControlsHelp.lua")
source("dataS/scripts/InputBinding.lua")
source("dataS/scripts/InputHelper.lua")
source("dataS/scripts/MissionStats.lua")
source("dataS/scripts/MissionPDA.lua")
source("dataS/scripts/BaseMission.lua")
source("dataS/scripts/FSBaseMission.lua")
source("dataS/missions/mission00.lua")
source("dataS/scripts/RaceMission.lua")
source("dataS/scripts/HotspotMission.lua")
source("dataS/scripts/StationFillMission.lua")
source("dataS/scripts/FieldMission.lua")
source("dataS/scripts/AmbientSoundMixer.lua")
source("dataS/scripts/RestartManager.lua")
source("dataS/scripts/Files.lua")
source("dataS/scripts/SpecializationUtil.lua")
source("dataS/scripts/VehicleTypeUtil.lua")
source("dataS/scripts/RoadUtil.lua")
source("dataS/scripts/TrafficVehicleUtil.lua")
source("dataS/scripts/FruitUtil.lua")
source("dataS/scripts/StoreItemsUtil.lua")
source("dataS/scripts/ModsUtil.lua")
source("dataS/scripts/MapsUtil.lua")
source("dataS/scripts/PlacementUtil.lua")
source("dataS/scripts/MasterServerMessageIds.lua")
source("dataS/scripts/MasterServerConnection.lua")
source("dataS/scripts/gui/InGameMessage.lua")
source("dataS/scripts/gui/InGameIcon.lua")
source("dataS/scripts/gui/Gui.lua")
initGuiLibrary("dataS/scripts/gui")
source("dataS/scripts/gui/FocusManager.lua")
source("dataS/scripts/gui/MainScreen.lua")
source("dataS/scripts/gui/SettingsScreen.lua")
source("dataS/scripts/gui/CareerScreen.lua")
source("dataS/scripts/gui/ControlsScreen.lua")
source("dataS/scripts/gui/AdvancedControlsScreen.lua")
source("dataS/scripts/gui/DifficultyScreen.lua")
source("dataS/scripts/gui/DenyAcceptDialog.lua")
source("dataS/scripts/gui/YesNoDialog.lua")
source("dataS/scripts/gui/MissionScreen.lua")
source("dataS/scripts/gui/InGameMenu.lua")
source("dataS/scripts/gui/MultiplayerScreen.lua")
source("dataS/scripts/gui/CreateGameScreen.lua")
source("dataS/scripts/gui/JoinGameScreen.lua")
source("dataS/scripts/gui/MPLoadingScreen.lua")
source("dataS/scripts/gui/ChatDialog.lua")
source("dataS/scripts/gui/PasswordDialog.lua")
source("dataS/scripts/gui/ConnectionRequestAnswerDialog.lua")
source("dataS/scripts/gui/ShutdownDialog.lua")
source("dataS/scripts/gui/ConnectionLostDialog.lua")
source("dataS/scripts/gui/ShopScreen.lua")
source("dataS/scripts/gui/AdminGameScreen.lua")
source("dataS/scripts/gui/AdminUsersScreen.lua")
source("dataS/scripts/gui/ConnectionFailedDialog.lua")
source("dataS/scripts/gui/InvalidKeyDialog.lua")
source("dataS/scripts/gui/ModSelectionScreen.lua")
source("dataS/scripts/gui/ModManagementScreen.lua")
source("dataS/scripts/gui/MoneyScreen.lua")
source("dataS/scripts/gui/MapSelectionScreen.lua")
source("dataS/scripts/gui/WrongGameVersionDialog.lua")
source("dataS/scripts/gui/ConnectToMasterServerScreen.lua")
source("dataS/scripts/gui/SelectMasterServerScreen.lua")
source("dataS/scripts/gui/CreditsScreen.lua")
source("dataS/scripts/gui/PortDialog.lua")
source("dataS/scripts/gui/ServerDetailDialog.lua")
source("dataS/scripts/gui/ModScreen.lua")
source("dataS/scripts/gui/FilterGameScreen.lua")
source("dataS/scripts/gui/AchievementsScreen.lua")
source("dataS/scripts/gui/StartupScreen.lua")
source("dataS/scripts/gui/DemoEndScreen.lua")
source("dataS/scripts/MissionInfo.lua")
source("dataS/scripts/FSMissionInfo.lua")
source("dataS/scripts/FSCareerMissionInfo.lua")
source("dataS/scripts/FSMissionMissionInfo.lua")
source("dataS/scripts/environment/Environment.lua")
source("dataS/scripts/Player.lua")
source("dataS/scripts/Utils.lua")
source("dataS/scripts/AnimCurve.lua")
source("dataS/scripts/events.lua")
source("dataS/scripts/AchievementManager.lua")
source("dataS/scripts/player/PlayerEnterEvent.lua")
source("dataS/scripts/player/PlayerLeaveEvent.lua")
source("dataS/scripts/player/PlayerTeleportEvent.lua")
source("dataS/scripts/objects/StartleAnimalEvent.lua")
source("dataS/scripts/ChatEvent.lua")
source("dataS/scripts/ShutdownEvent.lua")
source("dataS/scripts/objects/SiloAmountMover.lua")
source("dataS/scripts/objects/Windmill.lua")
source("dataS/scripts/objects/BuildingSign.lua")
source("dataS/scripts/objects/Ship.lua")
source("dataS/scripts/objects/Nightlight.lua")
source("dataS/scripts/objects/Nightlight2.lua")
source("dataS/scripts/objects/HouseLight.lua")
source("dataS/scripts/objects/LighthouseBeam.lua")
source("dataS/scripts/objects/ChurchClock.lua")
source("dataS/scripts/objects/Fountain.lua")
source("dataS/scripts/objects/Saucer.lua")
source("dataS/scripts/objects/ChairLift.lua")
source("dataS/scripts/objects/DualColoredHouse.lua")
source("dataS/scripts/objects/PhysicsObject.lua")
source("dataS/scripts/objects/Bale.lua")
source("dataS/scripts/objects/Watermill.lua")
source("dataS/scripts/objects/ChairLiftWheel.lua")
source("dataS/scripts/objects/PedestrianSpline.lua")
source("dataS/scripts/objects/DistantTrain.lua")
source("dataS/scripts/objects/AnimalsNetworkObject.lua")
source("dataS/scripts/vehicles/AIVehicleUtil.lua")
source("dataS/scripts/vehicles/WheelsUtil.lua")
source("dataS/scripts/vehicles/VehicleMotor.lua")
source("dataS/scripts/vehicles/VehiclePlacementCallback.lua")
source("dataS/scripts/vehicles/VehicleCamera.lua")
source("dataS/scripts/vehicles/VehicleEnterRequestEvent.lua")
source("dataS/scripts/vehicles/VehicleEnterResponseEvent.lua")
source("dataS/scripts/vehicles/VehicleLeaveEvent.lua")
source("dataS/scripts/vehicles/VehicleAttachEvent.lua")
source("dataS/scripts/vehicles/VehicleDetachEvent.lua")
source("dataS/scripts/vehicles/VehicleLowerImplementEvent.lua")
source("dataS/scripts/triggers/MilktruckFillTrigger.lua")
source("dataS/scripts/triggers/MilktruckStartTrigger.lua")
source("dataS/scripts/triggers/SiloTrigger.lua")
source("dataS/scripts/triggers/TipTrigger.lua")
source("dataS/scripts/triggers/GasStationTrigger.lua")
source("dataS/scripts/triggers/BarrierTrigger.lua")
source("dataS/scripts/triggers/VisualPlayerTrigger.lua")
source("dataS/scripts/triggers/HotspotTrigger.lua")
source("dataS/scripts/triggers/InfospotTrigger.lua")
source("dataS/scripts/triggers/SprayerFillTrigger.lua")
source("dataS/scripts/triggers/SowingMachineFillTrigger.lua")
source("dataS/scripts/sounds/RandomSound.lua")
source("dataS/scripts/sounds/DailySound.lua")
source("dataS/scripts/triggers/BarnMoverTrigger.lua")
source("dataS/scripts/triggers/PalletTrigger.lua")
source("dataS/scripts/triggers/ShopTrigger.lua")
source("dataS/scripts/triggers/CoinTelescopeTrigger.lua")
source("dataS/scripts/triggers/ManureShovelTrigger.lua")
source("dataS/scripts/triggers/TeleportTrigger.lua")
source("dataS/scripts/ai/aiSources.lua")
gameMenuSystem = {}
g_networkDebug = false
g_networkDebugPrints = false
g_uniqueDlcNamePrefix = "pdlc_"
g_languageSuffix = "_de"
g_languageShort = "de"
g_isDemo = false
g_isGamesloadDemo = false
g_isTriSynergyDemo = false
g_flightAndNoHUDKeysEnabled = false
g_isDevelopmentVersion = false
g_gameVersion = 6
g_gameVersionDisplay = "1.023 (Patch 2.3)"
g_settingsJoystickEnabled = false
g_settingsJoystickVibrationEnabled = false
g_settingsNickname = getUserName()
g_settingsNickname = Utils.trim(g_settingsNickname)
if g_settingsNickname == nil or g_settingsNickname == "" then
  g_settingsNickname = "Player"
end
g_settingsLanguage = getSystemLanguage()
g_settingsHelpText = true
g_settingsTimeScale = 16
g_settingsMSAA = 0
g_settingsAnsio = 0
g_settingsDisplayResolution = 0
g_settingsDisplayProfile = 0
g_savegameRevision = 7
g_careerSavegameRevision = 1
g_densityMapRevision = 1
g_finishedMissions = {}
g_finishedMissionsRecord = {}
g_achievementManager = nil
g_menuMusic = nil
g_fuelPricePerLiter = 0.7
g_milkPricePerLiter = 1
g_milkLitersPerCowPerDay = 30000
g_milkingPlaceMilkPerCow = 1000
g_liquidManureLitersPerCowPerDay = 10500
g_manureLitersPerCowPerDay = 8400
g_grassPerCowPerDay = 14400
g_chaffPerCowPerDay = 19200
g_seedsPricePerLiter = 0.33
g_strawLitersPerSqm = 2
g_originalMilkPricePerLiter = g_milkPricePerLiter
g_originalMilkLitersPerCowPerDay = g_milkLitersPerCowPerDay
g_originalMilkingPlaceMilkPerCow = g_milkingPlaceMilkPerCow
g_originalLiquidManureLitersPerCowPerDay = g_liquidManureLitersPerCowPerDay
g_originalManureLitersPerCowPerDay = g_manureLitersPerCowPerDay
g_startPrices = {}
g_startPriceSum = 0
g_modEventListeners = {}
g_mouseControlsHelp = {}
g_mouse = {}
g_dlcsDirectories = {}
table.insert(g_dlcsDirectories, {
  path = getUserProfileAppPath() .. "pdlc2.1",
  isLoaded = true
})
table.insert(g_dlcsDirectories, {
  path = getAppBasePath() .. "pdlc2.1",
  isLoaded = true
})
table.insert(g_dlcsDirectories, {path = "pdlc2.1", isLoaded = false})
g_maxUploadRate = 15.36
g_defaultServerPort = 10823
g_drawGuiHelper = false
g_guiHelperSteps = 0.1
g_lastMousePosX = 0
g_lastMousePosY = 0
g_modIsLoaded = {}
g_modNameToDirectory = {}
modOnCreate = {}
function init(args)
  local availableLanguagesString = "Available Languages:"
  local xmlFile = loadXMLFile("LanguageFile", "dataS/languages.xml")
  local defaultShort, defaultSuffix
  local codeFound = false
  local systemLanguageCode = getLanguageCode(getSystemLanguage())
  local i = 0
  while true do
    local key = string.format("languages.language(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local code = getXMLString(xmlFile, key .. "#code")
    local languageShort = getXMLString(xmlFile, key .. "#short")
    local languageSuffix = getXMLString(xmlFile, key .. "#suffix")
    if defaultShort == nil then
      defaultShort = languageShort
      defaultSuffix = languageSuffix
    end
    if code == systemLanguageCode then
      g_languageShort = languageShort
      g_languageSuffix = languageSuffix
      codeFound = true
    end
    availableLanguagesString = availableLanguagesString .. " " .. languageShort
    i = i + 1
  end
  if not codeFound then
    g_languageShort = defaultShort
    g_languageSuffix = defaultSuffix
  end
  delete(xmlFile)
  local RC = ""
  if g_languageShort == "de" then
    RC = "5"
  elseif g_languageShort == "en" then
    RC = "1"
  elseif g_languageShort == "pl" then
    RC = "4"
  elseif g_languageShort == "hu" then
    RC = "2"
  elseif g_languageShort == "fr" then
    RC = "1"
  end
  print("Farming Simulator 2011")
  print("  Version: " .. g_gameVersionDisplay .. " RC" .. RC)
  print("  " .. availableLanguagesString)
  print("  Language: " .. g_languageShort)
  local screenshotsDir = getUserProfileAppPath() .. "screenshots"
  g_screenshotsDirectory = screenshotsDir
  createFolder(screenshotsDir)
  local inputBindingPathTemplate = getAppBasePath() .. "profileTemplate/inputBindingDefault.xml"
  g_inputBindingPath = getUserProfileAppPath() .. "inputBinding.xml"
  copyFile(inputBindingPathTemplate, g_inputBindingPath, false)
  if not InputBinding.checkFormat() or not InputBinding.checkVersion(g_inputBindingPath, inputBindingPathTemplate) then
    copyFile(inputBindingPathTemplate, g_inputBindingPath, true)
  end
  InputBinding.load()
  g_settingsJoystickEnabled = getGamepadEnabled()
  g_settingsJoystickVibrationEnabled = getGamepadVibrationEnabled()
  g_i18n = I18N:new(true)
  local savegamePathTemplate = getAppBasePath() .. "profileTemplate/savegamesTemplate.xml"
  g_savegamePath = getUserProfileAppPath() .. "savegames.xml"
  copyFile(savegamePathTemplate, g_savegamePath, false)
  g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
  local revision = getXMLInt(g_savegameXML, "savegames#revision")
  if revision == nil or revision ~= g_savegameRevision then
    copyFile(savegamePathTemplate, g_savegamePath, true)
    delete(g_savegameXML)
    g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
  end
  g_settingsNickname = Utils.getNoNil(getXMLString(g_savegameXML, "savegames.settings.nickname"), g_settingsNickname)
  g_settingsNickname = Utils.trim(g_settingsNickname)
  if g_settingsNickname == "" then
    g_settingsNickname = "Player"
  end
  local nicknameLength = utf8Strlen(g_settingsNickname)
  if 15 < nicknameLength then
    g_settingsNickname = utf8Substr(g_settingsNickname, 0, 15)
  end
  g_settingsHelpText = Utils.getNoNil(getXMLBool(g_savegameXML, "savegames.settings.autohelp"), g_settingsHelpText)
  local language = getXMLInt(g_savegameXML, "savegames.settings#language")
  if language ~= nil and 0 <= language and language <= getNumOfLanguages() - 1 then
    g_settingsLanguage = language
  end
  g_settingsTimeScale = getXMLFloat(g_savegameXML, "savegames.settings#timescale")
  if g_settingsTimeScale == nil or g_settingsTimeScale == 0 then
    g_settingsTimeScale = 16
  end
  g_foliageViewDistanceCoeff = 1
  local profileId = Utils.getProfileClassId()
  if 4 <= profileId then
    g_foliageViewDistanceCoeff = 1.6
  elseif profileId == 3 then
    g_foliageViewDistanceCoeff = 1.4
  elseif profileId <= 1 then
    g_foliageViewDistanceCoeff = 1
  end
  setFoliageViewDistanceCoeff(g_foliageViewDistanceCoeff)
  math.randomseed(os.time())
  math.random()
  math.random()
  math.random()
  SpecializationUtil.registerSpecialization("motorized", "Motorized", "dataS/scripts/vehicles/specializations/Motorized.lua")
  SpecializationUtil.registerSpecialization("steerable", "Steerable", "dataS/scripts/vehicles/specializations/Steerable.lua")
  SpecializationUtil.registerSpecialization("combine", "Combine", "dataS/scripts/vehicles/specializations/Combine.lua")
  SpecializationUtil.registerSpecialization("attachable", "Attachable", "dataS/scripts/vehicles/specializations/Attachable.lua")
  SpecializationUtil.registerSpecialization("plough", "Plough", "dataS/scripts/vehicles/specializations/Plough.lua")
  SpecializationUtil.registerSpecialization("fillable", "Fillable", "dataS/scripts/vehicles/specializations/Fillable.lua")
  SpecializationUtil.registerSpecialization("trailer", "Trailer", "dataS/scripts/vehicles/specializations/Trailer.lua")
  SpecializationUtil.registerSpecialization("cutter", "Cutter", "dataS/scripts/vehicles/specializations/Cutter.lua")
  SpecializationUtil.registerSpecialization("baler", "Baler", "dataS/scripts/vehicles/specializations/Baler.lua")
  SpecializationUtil.registerSpecialization("forageWagon", "ForageWagon", "dataS/scripts/vehicles/specializations/ForageWagon.lua")
  SpecializationUtil.registerSpecialization("cultivator", "Cultivator", "dataS/scripts/vehicles/specializations/Cultivator.lua")
  SpecializationUtil.registerSpecialization("mower", "Mower", "dataS/scripts/vehicles/specializations/Mower.lua")
  SpecializationUtil.registerSpecialization("sowingMachine", "SowingMachine", "dataS/scripts/vehicles/specializations/SowingMachine.lua")
  SpecializationUtil.registerSpecialization("sprayer", "Sprayer", "dataS/scripts/vehicles/specializations/Sprayer.lua")
  SpecializationUtil.registerSpecialization("manureSpreader", "ManureSpreader", "dataS/scripts/vehicles/specializations/ManureSpreader.lua")
  SpecializationUtil.registerSpecialization("pathVehicle", "PathVehicle", "dataS/scripts/vehicles/specializations/PathVehicle.lua")
  SpecializationUtil.registerSpecialization("trafficVehicle", "TrafficVehicle", "dataS/scripts/vehicles/specializations/TrafficVehicle.lua")
  SpecializationUtil.registerSpecialization("milktruck", "Milktruck", "dataS/scripts/vehicles/specializations/Milktruck.lua")
  SpecializationUtil.registerSpecialization("frontloader", "Frontloader", "dataS/scripts/vehicles/specializations/Frontloader.lua")
  SpecializationUtil.registerSpecialization("foldable", "Foldable", "dataS/scripts/vehicles/specializations/Foldable.lua")
  SpecializationUtil.registerSpecialization("hirable", "Hirable", "dataS/scripts/vehicles/specializations/Hirable.lua")
  SpecializationUtil.registerSpecialization("aiCombine", "AICombine", "dataS/scripts/vehicles/specializations/AICombine.lua")
  SpecializationUtil.registerSpecialization("aiTractor", "AITractor", "dataS/scripts/vehicles/specializations/AITractor.lua")
  SpecializationUtil.registerSpecialization("windrower", "Windrower", "dataS/scripts/vehicles/specializations/Windrower.lua")
  SpecializationUtil.registerSpecialization("tedder", "Tedder", "dataS/scripts/vehicles/specializations/Tedder.lua")
  SpecializationUtil.registerSpecialization("animatedVehicle", "AnimatedVehicle", "dataS/scripts/vehicles/specializations/AnimatedVehicle.lua")
  SpecializationUtil.registerSpecialization("baleLoader", "BaleLoader", "dataS/scripts/vehicles/specializations/BaleLoader.lua")
  SpecializationUtil.registerSpecialization("cylindered", "Cylindered", "dataS/scripts/vehicles/specializations/Cylindered.lua")
  SpecializationUtil.registerSpecialization("mouseControlsVehicle", "MouseControlsVehicle", "dataS/scripts/vehicles/specializations/MouseControlsVehicle.lua")
  SpecializationUtil.registerSpecialization("shovel", "Shovel", "dataS/scripts/vehicles/specializations/Shovel.lua")
  SpecializationUtil.registerSpecialization("honk", "Honk", "dataS/scripts/vehicles/specializations/Honk.lua")
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car2.xml", 14)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car3.xml", 14)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car4.xml", 14)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car5.xml", 14)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car6.xml", 14)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car7.xml", 14)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/car9.xml", 14)
  VehicleTypeUtil.loadVehicleTypes()
  FruitUtil.registerFruitType("wheat", true, true, true, 3, 0.4, 1.2, 0.0275, 0.5, "dataS2/missions/hud_fruit_wheat.png")
  FruitUtil.registerFruitType("barley", true, true, true, 3, 0.4, 1.2, 0.0275, 0.5, "dataS2/missions/hud_fruit_barley.png")
  FruitUtil.registerFruitType("rape", true, true, false, 4, 0.8, 0.6, 0.0275, 0.5, "dataS2/missions/hud_fruit_rape.png")
  FruitUtil.registerFruitType("maize", true, true, false, 4, 0.4, 1.2, 0.0275, 0.5, "dataS2/missions/hud_fruit_maize.png")
  FruitUtil.registerFruitType("grass", false, true, true, 3, 0.4, 1.2, 0.0275, 0.5, "dataS2/missions/hud_fruit_grass.png")
  FruitUtil.registerFruitType("dryGrass", false, false, true, 0, 0.45, 1.2, 0.0275, 0.5, "dataS2/missions/hud_fruit_grass.png")
  FruitUtil.registerFruitType("chaff", false, false, false, 0, 0.4, 3.9, 0.0275, 0.5, "dataS2/missions/hud_fruit_chaff.png")
  FruitUtil.setAutoSeedFruitType(FruitUtil.FRUITTYPE_GRASS, FruitUtil.FRUITTYPE_GRASS)
  FruitUtil.setAutoSeedFruitType(FruitUtil.FRUITTYPE_DRYGRASS, FruitUtil.FRUITTYPE_GRASS)
  Fillable.registerFillType("milk")
  MapsUtil.addMapItem("Map01", "dataS/missions/CareerMap01.lua", "CareerMap01", "dataS2/menu/briefingScreen/careerMap01", "careerMap01", "profileTemplate/careerVehicles_map01.xml", g_i18n:getText("Map01_Title"), g_i18n:getText("Map01_Description"), "data/maps/map01/map_preview.png", "", nil)
  if g_isDevelopmentVersion then
    MapsUtil.addMapItem("FastLoadingMap", "dataS/missions/FastLoadingMap.lua", "FastLoadingMap", "dataS2/menu/briefingScreen/careerMap01", "careerMap01", "profileTemplate/careerVehicles_fastLoadingMap.xml", "Fast Loading Map Dev Map", "Fast Loading Map Dev Map", "data/maps/map01/map_preview.png", "", nil)
  end
  PedestrianSpline.addPedestrianType("dataS2/character/pedestrians/casual02.i3d", "walkSource", 1.2)
  PedestrianSpline.addPedestrianType("dataS2/character/pedestrians/casual03.i3d", "walkSource", 1.35)
  PedestrianSpline.addPedestrianType("dataS2/character/pedestrians/casual07.i3d", "walkSource", 1.35)
  PedestrianSpline.addPedestrianType("dataS2/character/pedestrians/casual15.i3d", "walkSource", 1.5)
  PedestrianSpline.addPedestrianType("dataS2/character/pedestrians/executive03.i3d", "walkSource", 1.35)
  PedestrianSpline.addPedestrianType("dataS2/character/pedestrians/casual08.i3d", "walkSource", 1.4)
  g_achievementManager = AchievementManager:new()
  local modsDir = ""
  if Utils.getNoNil(getXMLBool(g_savegameXML, "savegames.settings.modsDirectoryOverride#active"), false) then
    modsDir = getXMLString(g_savegameXML, "savegames.settings.modsDirectoryOverride#directory")
  end
  if modsDir == nil or modsDir == "" then
    modsDir = getUserProfileAppPath() .. "mods"
  end
  g_modsDirectory = modsDir
  createFolder(modsDir)
  print("Mod directory: ", g_modsDirectory)
  loadDlcs()
  loadMods()
  InputBinding.setBlockingInputForActions()
  StoreItemsUtil.loadStoreItems()
  simulatePhysics(false)
  g_connectionManager = ConnectionManager:new()
  g_masterServerConnection = MasterServerConnection:new()
  g_gui = Gui:new(g_languageSuffix)
  g_gui:loadProfiles("dataS/guiProfiles.xml", GUIProfiles)
  g_mainScreen = MainScreen:new()
  g_settingsScreen = SettingsScreen:new()
  g_controlsScreen = ControlsScreen:new()
  g_advancedControlsScreen = AdvancedControlsScreen:new()
  g_careerScreen = CareerScreen:new()
  g_difficultyScreen = DifficultyScreen:new()
  g_yesNoDialog = YesNoDialog:new()
  g_inGameMenu = InGameMenu:new()
  g_missionScreen = MissionScreen:new()
  g_multiplayerScreen = MultiplayerScreen:new()
  g_createGameScreen = CreateGameScreen:new()
  g_joinGameScreen = JoinGameScreen:new()
  g_mpLoadingScreen = MPLoadingScreen:new(OnLoadingScreen)
  g_chatDialog = ChatDialog:new()
  g_passwordDialog = PasswordDialog:new()
  g_connectionRequestAnswerDialog = ConnectionRequestAnswerDialog:new()
  g_shutdownDialog = ShutdownDialog:new()
  g_connectionLostDialog = ConnectionLostDialog:new()
  g_denyAcceptDialog = DenyAcceptDialog:new()
  g_shopScreen = ShopScreen:new()
  g_adminGameScreen = AdminGameScreen:new()
  g_adminUsersScreen = AdminUsersScreen:new()
  g_invalidKeyDialog = InvalidKeyDialog:new()
  g_connectionFailedDialog = ConnectionFailedDialog:new()
  g_modSelectionScreen = ModSelectionScreen:new()
  g_modManagementScreen = ModManagementScreen:new()
  g_moneyScreen = MoneyScreen:new()
  g_mapSelectionScreen = MapSelectionScreen:new()
  g_wrongGameVersionDialog = WrongGameVersionDialog:new()
  g_connectToMasterServerScreen = ConnectToMasterServerScreen:new()
  g_selectMasterServerScreen = SelectMasterServerScreen:new()
  g_creditsScreen = CreditsScreen:new()
  g_portDialog = PortDialog:new()
  g_serverDetailDialog = ServerDetailDialog:new()
  g_modScreen = ModScreen:new()
  g_filterGameScreen = FilterGameScreen:new()
  g_achievementsScreen = AchievementsScreen:new()
  g_startupScreen = StartupScreen:new()
  if g_isDemo then
    g_demoEndScreen = DemoEndScreen:new()
  end
  g_gui:loadGui("dataS/MainScreen.xml", "MainScreen", g_mainScreen)
  g_gui:loadGui("dataS/SettingsScreen.xml", "SettingsScreen", g_settingsScreen)
  g_gui:loadGui("dataS/ControlsScreen.xml", "ControlsScreen", g_controlsScreen)
  g_gui:loadGui("dataS/AdvancedControlsScreen.xml", "AdvancedControlsScreen", g_advancedControlsScreen)
  g_gui:loadGui("dataS/CareerScreen.xml", "CareerScreen", g_careerScreen)
  g_gui:loadGui("dataS/DifficultyScreen.xml", "DifficultyScreen", g_difficultyScreen)
  g_gui:loadGui("dataS/YesNoDialog.xml", "YesNoDialog", g_yesNoDialog)
  g_gui:loadGui("dataS/MissionScreen.xml", "MissionScreen", g_missionScreen)
  g_gui:loadGui("dataS/InGameMenu.xml", "InGameMenu", g_inGameMenu)
  g_gui:loadGui("dataS/MultiplayerScreen.xml", "MultiplayerScreen", g_multiplayerScreen)
  g_gui:loadGui("dataS/CreateGameScreen.xml", "CreateGameScreen", g_createGameScreen)
  g_gui:loadGui("dataS/JoinGameScreen.xml", "JoinGameScreen", g_joinGameScreen)
  g_gui:loadGui("dataS/MPLoadingScreen.xml", "MPLoadingScreen", g_mpLoadingScreen)
  g_gui:loadGui("dataS/ChatDialog.xml", "ChatDialog", g_chatDialog)
  g_gui:loadGui("dataS/PasswordDialog.xml", "PasswordDialog", g_passwordDialog)
  g_gui:loadGui("dataS/ConnectionRequestAnswerDialog.xml", "ConnectionRequestAnswerDialog", g_connectionRequestAnswerDialog)
  g_gui:loadGui("dataS/ShutdownDialog.xml", "ShutdownDialog", g_shutdownDialog)
  g_gui:loadGui("dataS/ConnectionLostDialog.xml", "ConnectionLostDialog", g_connectionLostDialog)
  g_gui:loadGui("dataS/DenyAcceptDialog.xml", "DenyAcceptDialog", g_denyAcceptDialog)
  g_gui:loadGui("dataS/ShopScreen.xml", "ShopScreen", g_shopScreen)
  g_gui:loadGui("dataS/AdminGameScreen.xml", "AdminGameScreen", g_adminGameScreen)
  g_gui:loadGui("dataS/AdminUsersScreen.xml", "AdminUsersScreen", g_adminUsersScreen)
  g_gui:loadGui("dataS/InvalidKeyDialog.xml", "InvalidKeyDialog", g_invalidKeyDialog)
  g_gui:loadGui("dataS/ConnectionFailedDialog.xml", "ConnectionFailedDialog", g_connectionFailedDialog)
  g_gui:loadGui("dataS/WrongGameVersionDialog.xml", "WrongGameVersionDialog", g_wrongGameVersionDialog)
  g_gui:loadGui("dataS/ModSelectionScreen.xml", "ModSelectionScreen", g_modSelectionScreen)
  g_gui:loadGui("dataS/ModManagementScreen.xml", "ModManagementScreen", g_modManagementScreen)
  g_gui:loadGui("dataS/MoneyScreen.xml", "MoneyScreen", g_moneyScreen)
  g_gui:loadGui("dataS/MapSelectionScreen.xml", "MapSelectionScreen", g_mapSelectionScreen)
  g_gui:loadGui("dataS/ConnectToMasterServerScreen.xml", "ConnectToMasterServerScreen", g_connectToMasterServerScreen)
  g_gui:loadGui("dataS/SelectMasterServerScreen.xml", "SelectMasterServerScreen", g_selectMasterServerScreen)
  g_gui:loadGui("dataS/CreditsScreen.xml", "CreditsScreen", g_creditsScreen)
  g_gui:loadGui("dataS/PortDialog.xml", "PortDialog", g_portDialog)
  g_gui:loadGui("dataS/ServerDetailDialog.xml", "ServerDetailDialog", g_serverDetailDialog)
  g_gui:loadGui("dataS/ModScreen.xml", "ModScreen", g_modScreen)
  g_gui:loadGui("dataS/FilterGameScreen.xml", "FilterGameScreen", g_filterGameScreen)
  g_gui:loadGui("dataS/AchievementsScreen.xml", "AchievementsScreen", g_achievementsScreen)
  g_gui:loadGui("dataS/StartupScreen.xml", "StartupScreen", g_startupScreen)
  if g_isDemo then
    g_gui:loadGui("dataS/DemoEndScreen.xml", "DemoEndScreen", g_demoEndScreen)
  end
  g_gui:showGui("StartupScreen")
  g_mouseControlsHelp = MouseControlsHelp:new()
  g_mouseControlsHelp:init()
  local overlays = {}
  cursorFilenames = {
    [Mouse.NORMAL] = "mouse_cursor_n"
  }
  for state, filename in pairs(cursorFilenames) do
    overlays[state] = Overlay:new(filename, "dataS2/menu/" .. filename .. ".png", 0, 0, 0.03, 0.04)
  end
  g_mouse = Mouse:new(overlays, 100, 100, false)
  InputBinding.setShowMouseCursor(true)
  g_defaultCamera = getCamera()
  g_menuMusic = createStreamedSample("menuMusic")
  loadStreamedSample(g_menuMusic, "dataS2/menu/menu.ogg")
  setStreamedSampleVolume(g_menuMusic, 0.35)
  RestartManager:init(args)
  if RestartManager.restarting then
    playStreamedSample(g_menuMusic, 0)
    g_gui:showGui("MainScreen")
    RestartManager:handleRestart()
  else
  end
  addConsoleCommand("gsDrawGuiHelper", "", "consoleCommandDrawGuiHelper", self)
  addConsoleCommand("gsCleanI3DCache", "", "consoleCommandCleanI3DCache", self)
  return true
end
function mouseEvent(posX, posY, isDown, isUp, button)
  if isDown then
    Input.updateMouseButtonState(button, true)
  elseif isUp then
    Input.updateMouseButtonState(button, false)
  end
  InputBinding.mouseEvent(posX, posY, isDown, isUp, button)
  g_mouse:mouseEvent(posX, posY, isDown, isUp, button)
  g_gui:mouseEvent(posX, posY, isDown, isUp, button)
  if g_mouse.isEnabled and g_currentMission ~= nil and g_currentMission.isLoaded then
    g_currentMission:mouseEvent(posX, posY, isDown, isUp, button)
  end
  g_lastMousePosX = posX
  g_lastMousePosY = posY
end
function keyEvent(unicode, sym, modifier, isDown)
  Input.updateKeyState(sym, isDown)
  InputBinding.keyEvent(unicode, sym, modifier, isDown)
  if g_gui.currentGuiName == "" then
    if g_currentMission ~= nil and g_currentMission.isLoaded then
      g_currentMission:keyEvent(unicode, sym, modifier, isDown)
    end
  else
    g_gui:keyEvent(unicode, sym, modifier, isDown)
  end
end
function update(dt)
  InputBinding.update(dt)
  if g_gui ~= nil then
    g_gui:update(dt)
  end
  if g_currentMission ~= nil and g_currentMission.isLoaded then
    g_currentMission:update(dt)
  end
  if InputBinding.hasEvent(InputBinding.TAKE_SCREENSHOT) then
    local screenshotName = g_screenshotsDirectory .. "/lsScreen_" .. os.date("%Y_%m_%d_%H_%M_%S") .. ".png"
    print("Saving screenshot: " .. screenshotName)
    saveScreenshot(screenshotName)
  end
  g_achievementManager:update(dt)
end
function draw()
  if g_gui ~= nil then
    g_gui:draw()
  end
  if g_currentMission ~= nil and g_currentMission.isLoaded then
    g_currentMission:draw()
    g_mouseControlsHelp:render()
  end
  g_achievementManager:render()
  g_mouse:render()
  if g_drawGuiHelper then
    if g_guiHelperOverlay == nil then
      g_guiHelperOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
    end
    if g_guiHelperOverlay ~= 0 then
      setTextColor(1, 1, 1, 1)
      local width, height = getScreenModeInfo(getScreenMode())
      for i = g_guiHelperSteps, 1, g_guiHelperSteps do
        renderOverlay(g_guiHelperOverlay, i, 0, 1 / width, 1)
        renderOverlay(g_guiHelperOverlay, 0, i, 1, 1 / height)
      end
      for i = 0.05, 1, 0.05 do
        renderText(i, 0.97, 0.02, tostring(i))
        renderText(0.01, i, 0.02, tostring(i))
      end
      setTextAlignment(RenderText.ALIGN_RIGHT)
      setTextColor(0, 0, 0, 0.9)
      renderText(g_lastMousePosX - 0.015, g_lastMousePosY - 0.0125 - 0.002, 0.025, string.format("%1.2f", g_lastMousePosY))
      setTextColor(1, 1, 1, 1)
      renderText(g_lastMousePosX - 0.015, g_lastMousePosY - 0.0125, 0.025, string.format("%1.2f", g_lastMousePosY))
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextColor(0, 0, 0, 0.9)
      renderText(g_lastMousePosX, g_lastMousePosY + 0.015 - 0.002, 0.025, string.format("%1.2f", g_lastMousePosX))
      setTextColor(1, 1, 1, 1)
      renderText(g_lastMousePosX, g_lastMousePosY + 0.015, 0.025, string.format("%1.2f", g_lastMousePosX))
      setTextAlignment(RenderText.ALIGN_LEFT)
      local halfCrosshairWidth = 5 / width
      local halfCrosshairHeight = 5 / width
      renderOverlay(g_guiHelperOverlay, g_lastMousePosX - halfCrosshairWidth, g_lastMousePosY, 2 * halfCrosshairWidth, 1 / height)
      renderOverlay(g_guiHelperOverlay, g_lastMousePosX, g_lastMousePosY - halfCrosshairHeight, 1 / width, 2 * halfCrosshairHeight)
    end
  end
end
function doExit()
  g_createGameScreen:removePortMapping()
  delete(g_savegameXML)
  Utils.deleteSharedI3DFiles()
  requestExit()
end
function registerObjectClassName(object, className)
  g_currentMission.objectsToClassName[object] = className
end
function unregisterObjectClassName(object)
  g_currentMission.objectsToClassName[object] = nil
end
function loadDlcs()
  if g_isDemo then
    return
  end
  local loadedDlcs = {}
  for i = 1, table.getn(g_dlcsDirectories) do
    local dir = g_dlcsDirectories[i]
    if dir.isLoaded then
      loadDlcsFromDirectory(dir.path, loadedDlcs)
    end
  end
end
function loadDlcsFromDirectory(dlcsDir, loadedDlcs)
  createFolder(dlcsDir)
  local files = Files:new(dlcsDir)
  for k, v in pairs(files.files) do
    local dlcFileHash, dlcDir
    if v.isDirectory then
      if g_isDevelopmentVersion then
        dlcDir = v.filename
      end
    else
      local len = v.filename:len()
      if 4 < len then
        local ext = v.filename:sub(len - 3)
        if ext == ".dlc" then
          dlcDir = v.filename:sub(1, len - 4)
          dlcFileHash = getFileMD5(dlcsDir .. "/" .. v.filename, dlcDir)
        end
      end
    end
    if dlcDir ~= nil then
      local absDlcDir = dlcsDir .. "/" .. dlcDir .. "/"
      local dlcFile = absDlcDir .. "dlcDesc.xml"
      if loadedDlcs[dlcDir] == nil then
        loadModDesc(dlcDir, absDlcDir, dlcFile, dlcFileHash, dlcsDir .. "/" .. v.filename, v.isDirectory)
        loadedDlcs[dlcDir] = true
      end
    end
  end
end
function loadMods()
  local loadedMods = {}
  local modsDir = g_modsDirectory
  if g_isDemo then
    return
  end
  local files = Files:new(modsDir)
  for k, v in pairs(files.files) do
    local modFileHash, modDir
    if v.isDirectory then
      modDir = v.filename
    else
      local len = v.filename:len()
      if 4 < len then
        local ext = v.filename:sub(len - 3)
        if ext == ".zip" or ext == ".gar" then
          modDir = v.filename:sub(1, len - 4)
          modFileHash = getFileMD5(modsDir .. "/" .. v.filename, modDir)
        end
      end
    end
    if modDir ~= nil then
      local absModDir = modsDir .. "/" .. modDir .. "/"
      local modFile = absModDir .. "modDesc.xml"
      if loadedMods[modFile] == nil then
        loadModDesc(modDir, absModDir, modFile, modFileHash, modsDir .. "/" .. v.filename, v.isDirectory)
        loadedMods[modFile] = true
      end
    end
  end
end
function loadModDesc(modName, modDir, modFile, modFileHash, absBaseFilename, isDirectory)
  print("Load mod: " .. modName)
  local isDLCFile = false
  if Utils.endsWith(modFile, "dlcDesc.xml") then
    isDLCFile = true
  end
  if not getIsValidModDir(modName) then
    print("Error: Invalid mod name '" .. modName .. "'! Characters allowed: (_, A-Z, a-z, 0-9). The first character must not be a digit")
    return
  end
  if isDLCFile then
    modName = g_uniqueDlcNamePrefix .. modName
  end
  local xmlFile = loadXMLFile("ModFile", modFile)
  local modDescVersion = getXMLInt(xmlFile, "modDesc#descVersion")
  if modDescVersion == nil then
    print("Error: Missing descVersion attribute in mod " .. modName)
    return
  end
  if modDescVersion ~= 4 and modDescVersion ~= 5 and modDescVersion ~= 6 then
    print("Error: Unsupported mod description version in mod " .. modName)
    return
  end
  if _G[modName] ~= nil then
    print("Error: Invalid mod name '" .. modName .. "'")
    return
  end
  local modEnv = {}
  _G[modName] = modEnv
  local modEnv_mt = {__index = _G}
  setmetatable(modEnv, modEnv_mt)
  if not isDLCFile then
    modEnv._G = modEnv
  end
  modEnv.g_i18n = I18N:new(false)
  I18N.initModI18N(modEnv.g_i18n, g_i18n, modName)
  function modEnv.loadstring(str, chunkname)
    str = "setfenv(1," .. modName .. "); " .. str
    return loadstring(str, chunkname)
  end
  function modEnv.source(filename, env)
    if isAbsolutPath(filename) then
      source(filename, modName)
    else
      source(filename)
    end
  end
  function modEnv.InitEventClass(classObject, className)
    InitEventClass(classObject, modName .. "." .. className)
  end
  modEnv.InitStaticEventClass = ""
  modEnv.loadMod = ""
  modEnv.loadModDesc = ""
  modEnv.deleteFile = ""
  modEnv.deleteFolder = ""
  function modEnv.registerObjectClassName(object, className)
    registerObjectClassName(object, modName .. "." .. className)
  end
  local onCreateUtil = {}
  onCreateUtil.onCreateFunctions = {}
  modEnv.g_onCreateUtil = onCreateUtil
  function onCreateUtil.addOnCreateFunction(name, func)
    onCreateUtil.onCreateFunctions[name] = func
  end
  function onCreateUtil.activateOnCreateFunctions()
    for name in pairs(modOnCreate) do
      modOnCreate[name] = nil
    end
    for name, func in pairs(onCreateUtil.onCreateFunctions) do
      modOnCreate[name] = function(self, id)
        func(id)
      end
    end
  end
  function onCreateUtil.deactivateOnCreateFunctions()
    for name in pairs(modOnCreate) do
      modOnCreate[name] = nil
    end
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.l10n.text(%d)", i)
    local name = getXMLString(xmlFile, baseName .. "#name")
    if name == nil then
      break
    end
    local text = getXMLString(xmlFile, baseName .. "." .. g_languageShort)
    if text == nil then
      text = getXMLString(xmlFile, baseName .. ".en")
      if text == nil then
        text = getXMLString(xmlFile, baseName .. ".de")
      end
    end
    if text == nil then
      print("Warning: No l10n text found for entry '" .. name .. "' in mod '" .. modName .. "'")
    elseif modEnv.g_i18n:hasModText(name) then
      print("Warning: Duplicate l10n entry '" .. name .. "' in mod '" .. modName .. "'. Ignoring this defintion.")
    else
      modEnv.g_i18n:setText(name, text)
    end
    i = i + 1
  end
  local title = Utils.getXMLI18N(xmlFile, "modDesc.title", nil, "", modName)
  local desc = Utils.getXMLI18N(xmlFile, "modDesc.description", nil, "", modName)
  local iconFilename = Utils.getXMLI18N(xmlFile, "modDesc.iconFilename", nil, "", modName)
  if title == "" then
    print("Error: Missing title in mod " .. modName)
    return
  end
  if desc == "" then
    print("Error: Missing description in mod " .. modName)
    return
  end
  local isMultiplayerSupported = Utils.getNoNil(getXMLBool(xmlFile, "modDesc.multiplayer#supported"), false)
  if modFileHash == nil then
    if isMultiplayerSupported then
      print("Warning: Only zip mods are supported in multiplayer. You need to zip the mod " .. modName .. " to use it in multiplayer.")
    end
    isMultiplayerSupported = false
  end
  if isMultiplayerSupported and iconFilename == "" then
    print("Error: Missing icon filename in mod " .. modName)
    return
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.inputBindings.input(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    InputBinding.loadInputButtonFromXML(xmlFile, baseName, modName, not isDLCFile)
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.maps.map(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local mapId = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#id"), "")
    local defaultVehiclesXMLFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#defaultVehiclesXMLFilename"), "")
    local mapTitle = Utils.getXMLI18N(xmlFile, baseName .. ".title", nil, "", modName)
    local mapDesc = Utils.getXMLI18N(xmlFile, baseName .. ".description", nil, "", modName)
    local mapClassName = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#className"), "")
    local mapFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#filename"), "")
    local briefingImagePrefix = Utils.getXMLI18N(xmlFile, baseName .. ".briefingImagePrefix", nil, "", modName)
    local briefingTextPrefix = Utils.getXMLI18N(xmlFile, baseName .. ".briefingTextPrefix", nil, "", modName)
    local mapIconFilename = Utils.getXMLI18N(xmlFile, baseName .. ".iconFilename", nil, "", modName)
    if mapId ~= "" and mapTitle ~= "" and mapDesc ~= "" and mapClassName ~= "" and mapFilename ~= "" and defaultVehiclesXMLFilename ~= "" and briefingImagePrefix ~= "" and briefingTextPrefix ~= "" and mapIconFilename ~= "" then
      local customEnvironment
      local useModDirectory = true
      local baseDirectory = modDir
      mapFilename, useModDirectory = Utils.getFilename(mapFilename, baseDirectory)
      if useModDirectory then
        customEnvironment = modName
        mapClassName = modName .. "." .. mapClassName
      end
      mapId = modName .. "." .. mapId
      mapIconFilename = Utils.getFilename(mapIconFilename, baseDirectory)
      briefingImagePrefix = Utils.getFilename(briefingImagePrefix, baseDirectory)
      defaultVehiclesXMLFilename = Utils.getFilename(defaultVehiclesXMLFilename, baseDirectory)
      MapsUtil.addMapItem(mapId, mapFilename, mapClassName, briefingImagePrefix, briefingTextPrefix, defaultVehiclesXMLFilename, mapTitle, mapDesc, mapIconFilename, baseDirectory, customEnvironment)
    end
    i = i + 1
  end
  local version = Utils.getXMLI18N(xmlFile, "modDesc.version", nil, "", modName)
  local author = Utils.getXMLI18N(xmlFile, "modDesc.author", nil, "", modName)
  iconFilename = Utils.getFilename(iconFilename, modDir)
  ModsUtil.addModItem(title, desc, version, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, modFileHash, absBaseFilename, isDirectory)
  delete(xmlFile)
end
function loadMod(modName, modDir, modFile)
  if g_modIsLoaded[modName] then
    return
  end
  g_modIsLoaded[modName] = true
  g_modNameToDirectory[modName] = modDir
  local xmlFile = loadXMLFile("ModFile", modFile)
  local isDLCFile = false
  if Utils.endsWith(modFile, "dlcDesc.xml") then
    isDLCFile = true
  end
  g_currentModDirectory = modDir
  g_currentModName = modName
  local modEnv = _G[modName]
  if modEnv == nil then
    return
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.extraSourceFiles.sourceFile(%d)", i)
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    if filename == nil then
      break
    end
    source(modDir .. filename, modName)
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.specializations.specialization(%d)", i)
    local specName = getXMLString(xmlFile, baseName .. "#name")
    if specName == nil then
      break
    end
    local className = getXMLString(xmlFile, baseName .. "#className")
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    if className ~= nil and filename ~= nil then
      filename = modDir .. filename
      className = modName .. "." .. className
      specName = modName .. "." .. specName
      SpecializationUtil.registerSpecialization(specName, className, filename, modName)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.vehicleTypes.type(%d)", i)
    local typeName = getXMLString(xmlFile, baseName .. "#name")
    if typeName == nil then
      break
    end
    typeName = modName .. "." .. typeName
    local className = getXMLString(xmlFile, baseName .. "#className")
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    if className ~= nil and filename ~= nil then
      local customEnvironment
      local useModDirectory = true
      filename, useModDirectory = Utils.getFilename(filename, modDir)
      if useModDirectory then
        customEnvironment = modName
        className = modName .. "." .. className
      end
      local specializationNames = {}
      local j = 0
      while true do
        local baseSpecName = baseName .. string.format(".specialization(%d)", j)
        local specName = getXMLString(xmlFile, baseSpecName .. "#name")
        if specName == nil then
          break
        end
        local entry = SpecializationUtil.specializations[specName]
        if entry == nil then
          specName = modName .. "." .. specName
        end
        table.insert(specializationNames, specName)
        j = j + 1
      end
      VehicleTypeUtil.registerVehicleType(typeName, className, filename, specializationNames, customEnvironment)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.storeItems.storeItem(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    StoreItemsUtil.loadStoreItem(xmlFile, baseName, modDir, modName, not isDLCFile)
    i = i + 1
  end
  delete(xmlFile)
  g_currentModDirectory = nil
  g_currentModName = nil
end
function getIsValidModDir(modDir)
  if modDir:len() == 0 then
    return false
  end
  if Utils.startsWith(modDir, g_uniqueDlcNamePrefix) then
    return false
  end
  if modDir:find("%d") == 1 then
    return false
  end
  if modDir:find("[^%w_]") ~= nil then
    return false
  end
  return true
end
function getModNameAndBaseDirectory(filename)
  return Utils.getModNameAndBaseDirectory(filename)
end
function addModEventListener(listener)
  table.insert(g_modEventListeners, listener)
end
function consoleCommandDrawGuiHelper(steps)
  local steps = tonumber(steps)
  if steps ~= nil then
    g_guiHelperSteps = math.max(steps, 0.001)
    g_drawGuiHelper = true
  else
    g_guiHelperSteps = 0.1
    g_drawGuiHelper = false
  end
  if g_drawGuiHelper then
    return "DrawGuiHelper = true (step = " .. g_guiHelperSteps .. ")"
  else
    return "DrawGuiHelper = false"
  end
end
function consoleCommandCleanI3DCache()
  Utils.deleteSharedI3DFiles()
  return "I3D cache cleaned"
end
