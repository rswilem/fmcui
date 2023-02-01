local Screen = {}
Screen.__index = Screen

local pageSize = 5

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)
    self.currentPage = 1

    self.fmcui:setLine(0, "ACARS-RCVD MSGS")

    self:drawPage()

    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)

    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/messages/messages" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:input(keyIdentifier, phase, duration)
    if phase ~= 2 then return end

    if keyIdentifier == "PREV" then
        self.currentPage = math.max(1, self.currentPage - 1)
    elseif keyIdentifier == "NEXT" then
        self.currentPage = math.min(math.ceil(self.fmcui:messagesCount() / pageSize), self.currentPage + 1)
    end

    self:drawPage()
end

function Screen:drawPage()
    local start = (self.currentPage - 1) * pageSize
    local totalMessages = self.fmcui:messagesCount()
    self.fmcui:setLine(0, (totalMessages > 0 and self.currentPage or 0) .. "/" .. math.ceil(totalMessages / pageSize), "right", 2)
    
    for i = 1, pageSize do
        local message = self.fmcui:getMessage(start + i, false)
        if message then
            self.fmcui:setAction(i .. "LSK", message.text:sub(0, 18), (function () self:showMessageDetails(start + i) end))
        else
            self.fmcui:setLine(i, "")
            self.fmcui:clearAction(i .. "LSK")
        end
    end
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("acars/misc/misc")
end

function Screen:showMessageDetails(index)
    self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/messages/messages", index = index })
end

return Screen
