CreateCowsEvent = {}
CreateCowsEvent_mt = Class(CreateCowsEvent, Event)
InitStaticEventClass(CreateCowsEvent, "CreateCowsEvent", EventIds.EVENT_CREATE_COWS)
function CreateCowsEvent:emptyNew()
  local self = Event:new(CreateCowsEvent_mt)
  self.className = "CreateCowsEvent"
  return self
end
function CreateCowsEvent:new()
  local self = CreateCowsEvent:emptyNew()
  return self
end
function CreateCowsEvent:readStream(streamId, connection)
  if connection:getIsServer() then
    local numAnimals = streamReadInt16(streamId)
    for i = 1, numAnimals do
      local animalName = streamReadString(streamId)
      local animalIsVisible = streamReadBool(streamId)
      local animalPositionX, animalPositionY, animalPositionZ, animalDirectionX, animalDirectionY, animalDirectionZ, appearanceId
      if animalIsVisible then
        animalPositionX = streamReadFloat32(streamId)
        animalPositionY = streamReadFloat32(streamId)
        animalPositionZ = streamReadFloat32(streamId)
        animalDirectionX = streamReadFloat32(streamId)
        animalDirectionY = streamReadFloat32(streamId)
        animalDirectionZ = streamReadFloat32(streamId)
        appearanceId = streamReadUIntN(streamId, 3)
      end
      AnimalHusbandry.addAnimal(animalName, animalPositionX, animalPositionY, animalPositionZ, animalDirectionX, animalDirectionY, animalDirectionZ, appearanceId, animalIsVisible)
    end
  end
end
function CreateCowsEvent:writeStream(streamId, connection)
  if not connection:getIsServer() then
    local animals = AnimalHusbandry.herd.animals
    local numAnimals = table.getn(animals)
    streamWriteInt16(streamId, numAnimals)
    for i = 1, numAnimals do
      local animalName = animals[i].name
      local animal, animalIsVisible = AnimalHusbandry.herd:getAnimalByName(animalName)
      local posX, posY, posZ, dirX, dirY, dirZ, appearanceId
      if animalIsVisible then
        posX, posY, posZ = animal:getPosition()
        dirX, dirY, dirZ = animal:getDirection()
        appearanceId = animal.appearanceId
      end
      streamWriteString(streamId, animalName)
      streamWriteBool(streamId, animalIsVisible)
      if animalIsVisible then
        streamWriteFloat32(streamId, posX)
        streamWriteFloat32(streamId, posY)
        streamWriteFloat32(streamId, posZ)
        streamWriteFloat32(streamId, dirX)
        streamWriteFloat32(streamId, dirY)
        streamWriteFloat32(streamId, dirZ)
        streamWriteUIntN(streamId, appearanceId, 3)
      end
    end
  end
end
function CreateCowsEvent:run(connection)
end
