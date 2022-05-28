ModsUtil = {}
ModsUtil.modList = {}
ModsUtil.modHashToMod = {}
ModsUtil.modNameToMod = {}
ModsUtil.nextModId = 1
function ModsUtil.addModItem(title, description, version, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, fileHash, absBaseFilename, isDirectory)
  if fileHash ~= nil and ModsUtil.modHashToMod[fileHash] ~= nil then
    print("Error: Adding mod with same file hash twice. Title is " .. title .. " filehash: " .. fileHash)
    return
  end
  local item = {}
  item.id = ModsUtil.nextModId
  ModsUtil.nextModId = ModsUtil.nextModId + 1
  item.title = title
  item.description = description
  item.version = version
  item.author = author
  item.iconFilename = iconFilename
  item.fileHash = fileHash
  item.modName = modName
  item.modDir = modDir
  item.modFile = modFile
  item.absBaseFilename = absBaseFilename
  item.isDirectory = isDirectory
  item.isMultiplayerSupported = isMultiplayerSupported
  table.insert(ModsUtil.modList, item)
  ModsUtil.modNameToMod[modName] = item
  if fileHash ~= nil then
    ModsUtil.modHashToMod[fileHash] = item
  end
end
function ModsUtil.removeModItem(item)
  ModsUtil.modNameToMod[item.modName] = nil
  if item.fileHash ~= nil then
    ModsUtil.modHashToMod[item.fileHash] = nil
  end
  for index, modItem in ipairs(ModsUtil.modList) do
    if modItem == item then
      table.remove(ModsUtil.modList, index)
      break
    end
  end
end
function ModsUtil.findModItemByFileHash(fileHash)
  return ModsUtil.modHashToMod[fileHash]
end
function ModsUtil.findModItemByModName(modName)
  return ModsUtil.modNameToMod[modName]
end
function ModsUtil.getAreAllModsAvailable(modHashs)
  for _, modHash in pairs(modHashs) do
    if not ModsUtil.getIsModAvailable(modHash) then
      return false
    end
  end
  return true
end
function ModsUtil.getIsModAvailable(modHash)
  local modItem = ModsUtil.modHashToMod[modHash]
  if modItem == nil or not modItem.isMultiplayerSupported then
    return false
  end
  return true
end
