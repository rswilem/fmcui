local Screen = {}
Screen.__index = Screen

local LINE_LENGTH = 24

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.isEditMode = false
    self.editModePage = 1
    self.editMessage = {}
    self.emptyMessage = ""
    for i = 1, 6 do
        self.emptyMessage = self.emptyMessage .. "(                      )\n"
    end
    self.message = ""
    
    self:drawScreen()

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
        self.editModePage = math.max(1, self.editModePage - 1)
    elseif keyIdentifier == "NEXT" then
        self.editModePage = math.min(2, self.editModePage + 1)
    end
  
    self:drawScreen()
end

function Screen:setEditMode()
    self.isEditMode = true
    self.editModePage = 1
    self.editMessage = {}
    for rawStr in self.message:gmatch("[^\r\n]+") do
        while string.len(rawStr) > LINE_LENGTH do
            table.insert(self.editMessage, ((rawStr:sub(1, LINE_LENGTH - 1)):gsub("^%s*(.-)%s*$", "%1")))
            rawStr = rawStr:sub(LINE_LENGTH)
        end
        table.insert(self.editMessage, (rawStr:gsub("^%s*(.-)%s*$", "%1")))
    end

    self:drawScreen()
end

function Screen:setMessageForLine(index)
    local input = self.fmcui:getScratchpad() or ""
    if string.len(input) == 0 then return end

    self.editMessage[index] = input
    self.fmcui:setLine(index, self.editMessage[index % 4], "left", 0)
    self.fmcui:setScratchpad("")
end

function Screen:clearMessage()
    self.message = ""
    self.editMessage = {}
    self:drawScreen()
end

function Screen:saveMessage()
    self.message = ""
    for k,v in pairs(self.editMessage) do
        self.message = self.message .. v .. "\n"
    end
    
    self.message = string.gsub(self.message, "  ", " ")
    self.isEditMode = false
    self:drawScreen()
end

function Screen:drawScreen()
    self.fmcui:clearLines()
    self.fmcui:setLine(0, "ACARS-OPS")
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    if self.isEditMode then
        self.fmcui:setLine(1, "", "left", 2)
        self.fmcui:setLine(0, self.editModePage .. "/" .. 2, "right", 2)
        
        for i = 1, 4 do
            local idx = i + ((self.editModePage - 1) * 4)
            local line = self.editMessage[idx]
            self.fmcui:setLine(i, (line and string.len(line) > 0 and line or "(                      )"), "left", 0)
            self.fmcui:setAction(i .. "RSK", "", (function(self) self:setMessageForLine(idx) end))
            self.fmcui:setAction(i .. "LSK", "", (function(self) self:setMessageForLine(idx) end))
        end
        
        self.fmcui:setAction("5RSK", "ENTER", self.saveMessage)
    else
        self.fmcui:setLine(1, "FREE TEXT", "center", 2)
        self.fmcui:setAction("1RSK", "EDIT", self.setEditMode)

         -- Draw empty first, then overwrite with message
        self.fmcui:setMultiline(5, self.emptyMessage, "left", -1)
        
        if string.len(self.message) > 0 then
            self.fmcui:setMultiline(5, self.message, "left", -1)
            self.fmcui:setAction("5LSK", "CLEAR TEXT", self.clearMessage)
            self.fmcui:setAction("5RSK", "SEND", self.sendMessage)
        end
    end
end

function Screen:showPreviousScreen(didSend)
    if self.isEditMode then
        self.isEditMode = false
        self:drawScreen()
    else
        self.fmcui:showScreen("acars/reports/reports", {vhfInProg = (didSend == true)})
    end
end

function Screen:sendMessage()
    self.message = ""
    local messageDelay = 3 + math.random() * 2

    -- The list below is generated automatically with ChatGPT.. Input was:
    -- "Pretend you are an operator in an office of an airline. A pilot messages you, but you cannot answer his message or cannot comply. Write a few variants of short text messages where you are sorry that you cannot answer."
    -- Imagine if we can link self.message in real time to the OpenAI ChatGPT API. That would be FIRE. We'd get live responses from HQ.

    local responses = {
        "Hi Pilot, hq here. Sorry, unable to assist at the moment. Apologies.",
        "Captain, op. Sorry, unable to respond to your request. My apologies.",
        "Pilot, hq. Regretful, I am unable to comply with your request. Sorry.",
        "Captain, this is op. Sorry, I am unable to assist you at this time. My apologies.",
        "Pilot, hq. Sorry, unable to answer your message. Apologies.",
        "Captain, this is hq. Can't assist you now, sorry. Apologies.",
        "Pilot, op here. Unfortunately, I am unable to help you at this time. My apologies.",
        "Hi Captain, hq. Sorry, I am unable to reply to your message right now. Apologies.",
        "Captain, from op. Sorry, I cannot comply with your request at this time. My apologies.",
        "Pilot, hq. Regretful, I am unable to assist you currently. Sorry."
    }

    local responseIndex = math.random(#responses)
    local airlineResponse = responses[responseIndex]
    self.fmcui:addMessage(airlineResponse, messageDelay)

    self:showPreviousScreen(true)
end

return Screen
