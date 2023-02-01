local Screen = {}
Screen.__index = Screen

local LINE_LENGTH = 24

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)
    
    self.fmcui:setLine(0, "ACARS")
    
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)
    
    if self.fmcui:messagesCount() == 0 then
      self.fmcui:setLine(3, "NO MSG", "center")
      return
    end

    local unreadIndex = self.fmcui:firstUnreadMessageIndex()
    self.currentIndex = unreadIndex > 0 and unreadIndex or 1

    self:drawMessage()

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)
end

function Screen:input(keyIdentifier, phase, duration)
    if phase ~= 2 then return end

    if keyIdentifier == "PREV" then
        self.currentIndex = math.max(1, self.currentIndex - 1)
    elseif keyIdentifier == "NEXT" then
        self.currentIndex = math.min(self.fmcui:messagesCount(), self.currentIndex + 1)
    end
  
    self:drawMessage()
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen(self.params.returnScreen or "acars/messages/messages")
end

function Screen:drawMessage()
    local message = self.fmcui:getMessage(self.currentIndex, true)
    if not message then return end
    
    local page = self.currentIndex .. "/" .. self.fmcui:messagesCount()
    self.fmcui:replaceLine(0, page, 2, LINE_LENGTH - #page)
    
    self.fmcui:replaceLine(0, "-" .. message.text:sub(0, 12), 0, 5)
    self.fmcui:setLine(1, " " .. message.time .. "   " .. (message.unread and "new" or "viewed"), "left", 1)
    self.fmcui:setMultiline(4, message.text, "left", -1)
end

return Screen
