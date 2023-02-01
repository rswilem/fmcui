local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "ACARS-AOC MENU")
    
    self.fmcui:setAction("1LSK", "PREFLIGHT", self.noop)
    self.fmcui:setAction("2LSK", "ENROUTE", self.noop)
    self.fmcui:setAction("3LSK", "POSTFLIGHT", self.noop)
    self.fmcui:setAction("4LSK", "CLOCK SET", self.noop)
    self.fmcui:setAction("5LSK", "TECH MENU", self.noop)
    self.fmcui:setAction("1RSK", "FLT LOG", self.showFlightLog)
    self.fmcui:setAction("2RSK", "ATS LOG", self.noop)
    self.fmcui:setAction("3RSK", "REPORTS", self.showReports)
    self.fmcui:setAction("4RSK", "REQUESTS", self.showRequests)
    self.fmcui:setAction("5RSK", "MISC MENU", self.showMisc)
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)

    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/aoc" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:noop()
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("dlnk-application-menu")
end

function Screen:showFlightLog()
    self.fmcui:showScreen("acars/flightlog/flightlog")
end

function Screen:showReports()
    self.fmcui:showScreen("acars/reports/reports")
end

function Screen:showRequests()
    self.fmcui:showScreen("acars/requests/requests")
end

function Screen:showMisc()
    self.fmcui:showScreen("acars/misc/misc")
end

return Screen
