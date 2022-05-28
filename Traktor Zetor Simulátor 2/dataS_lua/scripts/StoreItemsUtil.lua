StoreItemsUtil = {}
StoreItemsUtil.storeItems = {}
function StoreItemsUtil.addStoreItem(name, description, specs, imageActive, price, xmlFilename, species, rotation, section, achievementsNeeded)
  local item = {}
  item.id = table.getn(StoreItemsUtil.storeItems) + 1
  item.name = name
  item.description = description
  item.specs = specs
  item.imageActive = imageActive
  item.price = price
  item.xmlFilename = xmlFilename
  item.species = species
  item.rotation = rotation
  item.section = section
  item.achievementsNeeded = achievementsNeeded
  table.insert(StoreItemsUtil.storeItems, item)
end
function StoreItemsUtil.loadStoreItems()
  local xmlFile = loadXMLFile("storeItemsXML", "dataS/storeItems.xml")
  local eof = false
  local i = 0
  repeat
    local baseXMLName = string.format("storeItems.storeItem(%d)", i)
    if not StoreItemsUtil.loadStoreItem(xmlFile, baseXMLName, "", nil, false) then
      eof = true
    end
    i = i + 1
  until eof
  delete(xmlFile)
end
function StoreItemsUtil.loadStoreItem(xmlFile, baseXMLName, baseDir, customEnvironment, isMod)
  if not hasXMLProperty(xmlFile, baseXMLName) then
    return false
  end
  local name = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "name", nil, customEnvironment, true)
  local desc = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "description", nil, customEnvironment, true)
  local specs = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "specs", "", customEnvironment, true)
  local imageActive = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "image#active", nil, customEnvironment, true)
  local price = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLFloat, "price", nil, customEnvironment, true)
  local xmlFilename = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "xmlFilename", nil, customEnvironment, true)
  local species = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "species", "", customEnvironment, true)
  local rotation = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLFloat, "rotation", 0, customEnvironment, true)
  local section = "section_misc"
  if isMod then
    section = "section_mods"
  else
    section = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "section", "", customEnvironment, true)
    if section == "" then
      section = "section_misc"
    end
  end
  local achievementsNeeded = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLInt, "achievementsNeeded", 0, customEnvironment, true)
  if name ~= nil and desc ~= nil and imageActive ~= nil and price ~= nil and xmlFilename ~= nil then
    StoreItemsUtil.addStoreItem(name, desc, specs, baseDir .. imageActive, price, baseDir .. xmlFilename, species, rotation, section, achievementsNeeded)
    return true
  end
  return false
end
