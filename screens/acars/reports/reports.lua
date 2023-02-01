local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "ACARS-REPORTS")
    
    self.fmcui:setAction("1LSK", "POSITION", self.noop)
    self.fmcui:setAction("2LSK", "ENGINE", self.noop)
    self.fmcui:setAction("3LSK", "DELAY", self.noop)
    self.fmcui:setAction("4LSK", "DIVERSION", self.noop)
    self.fmcui:setAction("5LSK", "SNAG", self.noop)
    self.fmcui:setAction("1RSK", "OPS", self.showOps)
    self.fmcui:setAction("2RSK", "MAINT", self.noop)
    self.fmcui:setAction("3RSK", "OTHER RPT", self.noop)
    self.fmcui:setAction("4RSK", "IN RANGE", self.noop)
    self.fmcui:setAction("5RSK", "ETA", self.noop)
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)

    self.fmcui:setLine(6, (self.fmcui:firstUnreadMessageIndex() == 0 and self.params.vhfInProg and "VHF IN PROG" or ""), "center", 1)
    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/reports/reports" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end


function Screen:noop()
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("acars/aoc")
end

function Screen:showOps()
    self.fmcui:showScreen("acars/reports/ops")
end

return Screen
