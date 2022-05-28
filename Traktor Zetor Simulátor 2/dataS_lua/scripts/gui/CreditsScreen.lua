CreditsScreen = {}
local CreditsScreen_mt = Class(CreditsScreen)
function CreditsScreen:new(backgroundOverlay)
  local instance = {}
  setmetatable(instance, CreditsScreen_mt)
  instance.creditsLines = {}
  instance.creditsTexts = {}
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Developed by")
  table.insert(instance.creditsTexts, "GIANTS Software GmbH")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Executive Producer")
  table.insert(instance.creditsTexts, "Christian Ammann")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Programmer")
  table.insert(instance.creditsTexts, "Stefan Geiger")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Artist")
  table.insert(instance.creditsTexts, "Thomas Frey")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Designer")
  table.insert(instance.creditsTexts, "Renzo Th\195\182nen")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Animator")
  table.insert(instance.creditsTexts, "Mikael Persson")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Programmers")
  table.insert(instance.creditsTexts, "Melanie Imhof")
  table.insert(instance.creditsTexts, "Matthias Kollmer")
  table.insert(instance.creditsTexts, "Thomas Brunner")
  table.insert(instance.creditsTexts, "Jonathan Sieber")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Artists")
  table.insert(instance.creditsTexts, "Guido Lein")
  table.insert(instance.creditsTexts, "Thomas Flachs")
  table.insert(instance.creditsTexts, "Jozef Rolincin")
  table.insert(instance.creditsTexts, "Roger Gerzner")
  table.insert(instance.creditsTexts, "Branislav Florian")
  table.insert(instance.creditsTexts, "Andrej Svoboda")
  table.insert(instance.creditsTexts, "Erin McClellan")
  table.insert(instance.creditsTexts, "Dody Saputra")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Sound Designer")
  table.insert(instance.creditsTexts, "Tobias Reuber")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Music Composer")
  table.insert(instance.creditsTexts, "Cary Jed Masters")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "QA Lead")
  table.insert(instance.creditsTexts, "Chris Wachter")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "QA Testers")
  table.insert(instance.creditsTexts, "Manuel Leithner")
  table.insert(instance.creditsTexts, "Stefan Seidel")
  table.insert(instance.creditsTexts, "Matthias Kollmer")
  table.insert(instance.creditsTexts, "Hans-Peter Imboden")
  table.insert(instance.creditsTexts, "Tobias Reuber")
  table.insert(instance.creditsTexts, "Thomas Brunner")
  table.insert(instance.creditsTexts, "Jens Karwehl-Behrens")
  table.insert(instance.creditsTexts, "Norman G\195\182rk")
  table.insert(instance.creditsTexts, "Michael Schmelter")
  table.insert(instance.creditsTexts, "Christoph Schmitt")
  table.insert(instance.creditsTexts, "Rene Monsees")
  table.insert(instance.creditsTexts, "Christian Zoltan")
  table.insert(instance.creditsTexts, "Manuel Adams")
  table.insert(instance.creditsTexts, "Russell Peterson")
  table.insert(instance.creditsTexts, "Benjamin Gerisch")
  table.insert(instance.creditsTexts, "Luca Braun")
  table.insert(instance.creditsTexts, "Ralf Schmidt")
  table.insert(instance.creditsTexts, "Niklas Meyer")
  table.insert(instance.creditsTexts, "Marcus Grimm")
  table.insert(instance.creditsTexts, "Marius Hofmann")
  table.insert(instance.creditsTexts, "Michael Kirschig")
  table.insert(instance.creditsTexts, "Stefan Robrecht")
  table.insert(instance.creditsTexts, "Stephan Bongartz")
  table.insert(instance.creditsTexts, "Detlef B\195\182vers")
  table.insert(instance.creditsTexts, "Dominik Oppel")
  table.insert(instance.creditsTexts, "Jan Geiger")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Localization")
  table.insert(instance.creditsTexts, "Erin McClellan")
  table.insert(instance.creditsTexts, "Ruth Koch")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses PhysX by NVIDIA")
  table.insert(instance.creditsTexts, "Copyright (C) 2009, NVIDIA Corporation")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses LUA")
  table.insert(instance.creditsTexts, "Copyright (C) 1994-2008 Lua.org, PUC-Rio")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses Ogg Vorbis")
  table.insert(instance.creditsTexts, "Copyright (C) 1994-2007 Xiph.Org Foundation")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses Zlib")
  table.insert(instance.creditsTexts, "Copyright (C) 1995-2004 Jean-loup Gailly")
  table.insert(instance.creditsTexts, "and Mark Adler")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "this software is based in part on")
  table.insert(instance.creditsTexts, "the work of the Independent JPEG Group")
  table.insert(instance.creditsTexts, "Copyright (C) 1991-1998 Independent JPEG Group")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Published by")
  table.insert(instance.creditsTexts, "astragon Software GmbH")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "CEO")
  table.insert(instance.creditsTexts, "Dirk Walner")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Senior Product Manager")
  table.insert(instance.creditsTexts, "Dirk Ohler")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Head of Public Relations")
  table.insert(instance.creditsTexts, "Felix Buschbaum")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Product Manager")
  table.insert(instance.creditsTexts, "Jens Brauckhoff")
  table.insert(instance.creditsTexts, "Susanne Sch\195\188bel")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Thanks for playing!")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "You can stop reading now.")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Seriously, that's all.")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  instance.currentTopLine = 1
  instance.creditsStartY = 0.1
  instance.creditsFontSize = 0.05
  instance.time = 0
  instance.creditsLinesFrequency = 750
  return instance
end
function CreditsScreen:onCreditsScreenCreated(element)
end
function CreditsScreen:onClickBack()
  self:reset()
  g_gui:showGui("MainScreen")
end
function CreditsScreen:delete()
end
function CreditsScreen:addItem(item)
  table.insert(self.items, item)
end
function CreditsScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function CreditsScreen:keyEvent(unicode, sym, modifier, isDown)
end
function CreditsScreen:update(dt)
  self.time = self.time + dt
  if self.time >= self.creditsLinesFrequency then
    self.time = 0
    self.currentTopLine = self.currentTopLine + 1
    if self.currentTopLine > table.getn(self.creditsTexts) then
      self.currentTopLine = 1
    end
    table.insert(self.creditsLines, CreditsLine:new(self.creditsTexts[self.currentTopLine], self.creditsFontSize, self.creditsStartY))
  end
  for i = 1, table.getn(self.creditsLines) do
    self.creditsLines[i]:update(dt)
  end
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onClickBack()
  end
end
function CreditsScreen:draw()
  for i = 1, table.getn(self.creditsLines) do
    self.creditsLines[i]:render()
  end
end
function CreditsScreen:reset()
  self.creditsLines = {}
  table.insert(self.creditsLines, CreditsLine:new(self.creditsTexts[1], self.creditsFontSize, self.creditsStartY))
  self.currentTopLine = 1
  self.time = 0
end
CreditsLine = {}
local CreditsLine_mt = Class(CreditsLine)
function CreditsLine:new(textLine, textSize, yPos)
  return setmetatable({
    textLine = textLine,
    textSize = textSize,
    yPos = yPos,
    fadedInPos = yPos + 0.1,
    fadeOutPos = 0.8,
    alpha = 1,
    visible = true
  }, CreditsLine_mt)
end
function CreditsLine:render()
  if self.visible then
    self.alpha = 1
    if self.yPos < self.fadedInPos then
      self.alpha = (0.1 - (self.fadedInPos - self.yPos)) / 0.1
    end
    if self.yPos > self.fadeOutPos then
      self.alpha = (0.1 - (self.yPos - self.fadeOutPos)) / 0.1
    end
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextColor(0.05, 0.05, 0.1, self.alpha)
    renderText(0.5, self.yPos - 0.005, self.textSize, self.textLine)
    setTextColor(1, 1, 1, self.alpha)
    renderText(0.5, self.yPos, self.textSize, self.textLine)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
  end
end
function CreditsLine:update(dt)
  if self.visible then
    self.yPos = self.yPos + 7.0E-5 * dt
    if self.yPos > 0.9 then
      self.visible = false
    end
  end
end
