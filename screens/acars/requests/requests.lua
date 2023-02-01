local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "ACARS-REQUESTS")
    
    self.fmcui:setAction("2LSK", "WEATHER REQ", self.showWeatherRequest)
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)
    
    self.fmcui:setLine(6, (self.fmcui:firstUnreadMessageIndex() == 0 and self.params.vhfInProg and "VHF IN PROG" or ""), "center", 1)
    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/requests/requests" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("acars/aoc")
end

function Screen:showWeatherRequest()
    self.fmcui:showScreen("acars/requests/weather")
end

return Screen
