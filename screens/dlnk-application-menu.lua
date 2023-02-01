local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "DLNK -APPLICATION MENU")
    
    self.fmcui:setAction("2LSK", "CPDLC", self.showCPDLCMenu)
    self.fmcui:setAction("2RSK", "AOC", self.showAOCMenu)
    self.fmcui:setAction("3RSK", "EXAMPLE", self.showExample)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)
    
    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "dlnk-application-menu" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:showCPDLCMenu()
end

function Screen:showAOCMenu()
    self.fmcui:showScreen("acars/aoc")
end

function Screen:showExample()
    self.fmcui:showScreen("example")
end

return Screen
