local Screen = {}
Screen.__index = Screen

local icaoList = {}
local LINE_LENGTH = 24

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "ACARS-WEATHER REQ")
    
    self.messageType = "METAR"
    self.fmcui:setLine(1, self.messageType, "left", 1)
    self.fmcui:setAction("2LSK", "WX MSG TYPE", self.changeMessageType)
    self.fmcui:setAction("2RSK", "", (function() self:setIcaoForLine(2) end))
    self.fmcui:setAction("3RSK", "", (function() self:setIcaoForLine(3) end))
    self.fmcui:setAction("4RSK", "", (function() self:setIcaoForLine(4) end))
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)
    self.fmcui:setAction("6RSK", "SEND", self.sendRequest)

    self.fmcui:replaceLine(2, "ARPT 1", 1, LINE_LENGTH - 7)
    self.fmcui:replaceLine(2, "(    )", 0, LINE_LENGTH - 6)
    self.fmcui:replaceLine(3, "ARPT 2", 1, LINE_LENGTH - 7)
    self.fmcui:replaceLine(3, "(    )", 0, LINE_LENGTH - 6)
    self.fmcui:replaceLine(4, "ARPT 3", 1, LINE_LENGTH - 7)
    self.fmcui:replaceLine(4, "(    )", 0, LINE_LENGTH - 6)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)
end

function Screen:showPreviousScreen(wasSent)
    self.fmcui:showScreen("acars/requests/requests", { vhfInProg = (wasSent == true) })
end

function Screen:changeMessageType()
    if self.messageType == "METAR" then
        self.messageType = "METAR+TAF"
    else
        self.messageType = "METAR"
    end

    self.fmcui:setLine(1, self.messageType, "left", 1)
end

function Screen:setIcaoForLine(line)
    local icao = self.fmcui:getScratchpad()
    self.fmcui:setScratchpad()
    if not icao or string.len(icao) ~= 4 then
        self.fmcui:showWarning("Invalid ICAO", 1)
        return
    end

    icaoList[line - 1] = icao
    self.fmcui:replaceLine(line, "  " .. icao, 0, LINE_LENGTH - 6)
end

function Screen:sendRequest()
    local messageDelay = 3 + math.random() * 2

    for i = 1, #icaoList do
        local icao = icaoList[i]
        local metar = self:getMetar(icao)
        self.fmcui:addMessage(string.len(metar) > 0 and metar or (icaoList[1] .. " NO METAR DATA"), messageDelay)
    end
    
    self:showPreviousScreen(true)
end

function Screen:getMetar(icao, time)
    if not icao or string.len(icao) ~= 4 then
        return ""
    end
    
    local year = tonumber(self.fmcui:get('B738DR_clock_year'))
    local month = tonumber(self.fmcui:get('simDR_time_month'))
    local day = math.min(tonumber(self.fmcui:get('simDR_time_day')), tonumber(os.date("%d")))
    local zuluHours = tonumber(self.fmcui:get('simDR_zulu_hours'))
    local zuluMinutes = tonumber(self.fmcui:get('simDR_zulu_minutes'))

    local file_name_path = "Output/real weather/"
    timeString = time or string.format("%02d", zuluHours) .. "." .. (zuluMinutes > 30 and "30" or "00")
    local metarFilename = "metar-20" .. string.format("%02d", year) .. "-" .. string.format("%02d", month) .. "-" .. string.format("%02d", day) .. "-" .. timeString .. ".txt"
    local file_name = file_name_path .. metarFilename
    
    local file_data = io.open(file_name, "r")
    if not file_data then
        if not time then
            return self:getMetar(icao, string.format("%02d", zuluHours - 1) .. "." .. ((zuluMinutes + 30) % 60 > 30 and "30" or "00"))
        end
        return ""
    end
    
    local line = file_data:read()
    local metar = ""
    while line do
        if string.len(line) > 4 then
            local foundIcao = string.sub(line, 0, 4)
            if foundIcao == icao then
                metar = line
            end
        end
        
        line = file_data:read()
    end
    
    file_data:close()
    return metar
end

return Screen
