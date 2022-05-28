function OnLoadingScreen(missionInfo, missionDynamicInfo, loadingScreen)
  pauseStreamedSample(g_menuMusic)
  g_inGameMenu:setMissionInfo(missionInfo, missionDynamicInfo)
  if missionInfo.useCustomEnvironmentForScript then
    source(missionInfo.scriptFilename, missionInfo.customEnvironment)
  else
    source(missionInfo.scriptFilename)
  end
  loadstring("g_asd_missionClass = " .. missionInfo.scriptClass)()
  local missionClass = g_asd_missionClass
  g_asd_missionClass = nil
  if missionClass ~= nil then
    g_currentMission = missionClass:new(missionInfo.baseDirectory)
    g_currentMission:setLoadingScreen(loadingScreen)
    g_currentMission:setMissionInfo(missionInfo, missionDynamicInfo)
    g_masterServerConnection:setCallbackTarget(g_currentMission)
  else
    print("Error: mission class " .. missionInfo.scriptClass .. " could not be found.")
    OnInGameMenuMenu()
    return
  end
  if missionDynamicInfo.isMultiplayer then
    if missionDynamicInfo.isClient then
      g_client = Client:new()
      g_client:setNetworkListener(g_currentMission)
      g_client:start(missionDynamicInfo.serverAddress, missionDynamicInfo.serverPort)
      g_masterServerConnection:disconnectFromMasterServer()
    else
      g_server:setNetworkListener(g_currentMission)
      g_client:setNetworkListener(g_currentMission)
    end
  else
    g_server = Server:new()
    g_server:setNetworkListener(g_currentMission)
    g_client = Client:new()
    g_client:setNetworkListener(g_currentMission)
    g_server:startLocal()
  end
  if g_server ~= nil then
    g_server:init()
  end
  if not missionDynamicInfo.isMultiplayer or not missionDynamicInfo.isClient then
    g_client:startLocal()
  end
end
function OnCreditsMenuBack()
  gameMenuSystem:mainMenuMode()
end
function OnInGameMenu()
  if g_currentMission.inGameMessage ~= nil then
    g_currentMission.inGameMessage.visible = false
  end
  gameMenuSystem:inGameMenuMode()
  InputBinding.setShowMouseCursor(true)
end
function OnInGameMenuPlay()
  gameMenuSystem:playMode()
  InputBinding.setShowMouseCursor(false)
end
function OnInGameMenuSettings()
end
function OnInGameMenuMenu()
  g_masterServerConnection:disconnectFromMasterServer()
  if g_client ~= nil then
    g_client:stop()
  end
  if g_server ~= nil then
    g_server:stop()
  end
  local isCareer = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
  local isMultiplayer = g_currentMission.missionDynamicInfo.isMultiplayer
  local isMultiplayerClient = g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.missionDynamicInfo.isClient
  g_currentMission:delete()
  g_currentMission = nil
  g_server = nil
  g_client = nil
  g_connectionManager:shutdownAll()
  g_createGameScreen:removePortMapping()
  if isCareer then
    if isMultiplayer then
      if masterServerConnectFront == nil then
        RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
        restartApplication()
        return
      else
        g_gui:showGui("MultiplayerScreen")
      end
    else
      g_gui:showGui("MainScreen")
    end
  else
    g_gui:showGui("MissionScreen")
  end
  InputBinding.setShowMouseCursor(true)
  resumeStreamedSample(g_menuMusic, 0)
end
function OnInGameMenuAreYouSure()
  gameMenuSystem.inGameMenu:exitAreYouSureDialog()
end
function OnBackToInGameMenu()
  gameMenuSystem.inGameMenu:backToInGameMenu()
end
function OnMenuStore()
  gameMenuSystem:storeMode()
  InputBinding.setShowMouseCursor(true)
end
function OnChatMsgSend()
  print("send chat msg")
end
