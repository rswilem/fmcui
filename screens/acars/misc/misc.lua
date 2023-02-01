local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "ACARS-MISC MENU")
    
    self.fmcui:setAction("1LSK", "UNDEL MSGS", self.noop)
    self.fmcui:setAction("2LSK", "7500 RPT", self.noop)
    self.fmcui:setAction("3LSK", "RAMP SRVC", self.noop)
    self.fmcui:setAction("4LSK", "PASSWORD", self.noop)
    self.fmcui:setAction("1RSK", "LINK STATUS", self.noop)
    self.fmcui:setAction("2RSK", "MISC RPT", self.noop)
    self.fmcui:setAction("3RSK", "RCVD MSGS", self.showMessagesOverview)
    
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)

    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/misc/misc" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:noop()
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("acars/aoc")
end

function Screen:showMessagesOverview()
    self.fmcui:showScreen("acars/messages/messages")
end

return Screen
