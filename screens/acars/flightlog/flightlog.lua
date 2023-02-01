local Screen = {}
Screen.__index = Screen

KGS_LBS = 2.204622622

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.log = {}
    self:loadLogfile()

    self.currentIndex = 1
    self:drawLogEntry()

    self.fmcui:setAction("6RSK", "SENSORS", self.showSensors)
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')
    local zuluSeconds = self.fmcui:get('simDR_zulu_seconds')

    self.fmcui:replaceLine(5, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes) .. ":" .. string.format("%02d", zuluSeconds), 1, 8)
    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)

    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/flightlog/flightlog" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:input(keyIdentifier, phase, duration)
    if phase ~= 2 then return end

    if keyIdentifier == "PREV" then
        self.currentIndex = math.max(1, self.currentIndex - 1)
    elseif keyIdentifier == "NEXT" then
        self.currentIndex = math.min(#self.log, self.currentIndex + 1)
    end
  
    self:drawLogEntry()
end

function Screen:drawLogEntry()
    self.fmcui:setLine(0, "ACARS-FLT LOG-" .. (self.currentIndex == 1 and "CURR" or "PREV"))
    self.fmcui:setLine(0, self.currentIndex .. "/" .. #self.log, "right", 2)

    local logEntry = self.log[self.currentIndex]
    if not logEntry then return end

    self.fmcui:setLine(1, "FLT NUM-DATE ORIG-DEST", "center", 1)
    self.fmcui:setLine(1, " " .. (string.len(logEntry.flt_no) > 0 and (logEntry.flt_no .. "-") or "") .. string.format("%02d", logEntry.day), "left", 2)
    self.fmcui:replaceLine(1, logEntry.ref .. "-" .. logEntry.dest, 2, 14)
    
    self.fmcui:setLine(2, "         TIME   FOB    ", "left", 1)

    local types = {[1] = "out", [2] = "in", [3] = "on", [4] = "off"}
    local timeLines = ""
    for i = 1, #types do
        local typeEntry = logEntry[types[i]]
        timeLines = timeLines .. types[i] .. " - "
        if typeEntry then
            timeLines = timeLines .. string.format("%02d", typeEntry.hour) .. ":" .. string.format("%02d", typeEntry.minute) .. "  "
            timeLines = timeLines .. string.format("%05.1f", typeEntry.fuel * (self.fmcui:get('units') == 0 and KGS_LBS or 1))
        end
        timeLines = timeLines .. "\n"
    end
    self.fmcui:setMultiline(6, timeLines, "center", -1)
    self.fmcui:setLine(4, "FLIGHT --TIMES-- BLOCK", "center", 2)
    self.fmcui:setLine(5, string.format("%02d", math.floor(logEntry.flightTime / 60)) .. ":" .. string.format("%02d", logEntry.flightTime % 60) .. "  " .. "--:--:--" .. "  " .. string.format("%02d", math.floor(logEntry.blockTime / 60)) .. ":" .. string.format("%02d", logEntry.blockTime % 60), "center", 1)
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("acars/aoc")
end

function Screen:showSensors()
    self.fmcui:showScreen("acars/flightlog/sensors")
end

function Screen:loadLogfile()
    local file_name = "Output/preferences/" .. (self.fmcui:get('FILE_NAME_STATUS') or "b738x_status.dat")
    local file_data = io.open(file_name, "r")
    if not file_data then
        return
    end

    self.log = {}

    -- Insert current flight
    table.insert(self.log, {
        ref = self.fmcui:get('dl_ref') or "",
        dest = self.fmcui:get('dl_des') or "",
        flt_no = self.fmcui:get('dl_flt_num') or "",
        day = self.fmcui:get('simDR_time_day') or 0,
        out = {
            hour = self.fmcui:get('dl_out_hrs') or 0,
            minute = self.fmcui:get('dl_out_min') or 0,
            fuel = self.fmcui:get('dl_out_fuel') or 0,
        },
        ["in"] = {
            hour = self.fmcui:get('dl_in_hrs') or 0,
            minute = self.fmcui:get('dl_in_min') or 0,
            fuel = self.fmcui:get('dl_in_fuel') or 0,
        },
        off = {
            hour = self.fmcui:get('dl_off_hrs') or 0,
            minute = self.fmcui:get('dl_off_min') or 0,
            fuel = self.fmcui:get('dl_off_fuel') or 0,
        },
        on = {
            hour = self.fmcui:get('dl_on_hrs') or 0,
            minute = self.fmcui:get('dl_on_min') or 0,
            fuel = self.fmcui:get('dl_on_fuel') or 0,
        },
        flightTime = 5,
        blockTime = 5
    })

    -- Clean up current flight values
    self.log[1].ref = (self.log[1].ref == "----" and "" or self.log[1].ref)
    self.log[1].dest = (self.log[1].dest == "****" and "" or self.log[1].dest)
    self.log[1].flt_no = (self.log[1].flt_no == "--------" and "" or self.log[1].flt_no)
    
    local dlinkMarker = false
    local importLineHelper = 0
    local logEntry = {}

    local line = file_data:read()
    while line do
        if string.len(line) > 1 and string.byte(line, -1) == 13 then	-- CR
            line = string.sub(line, 1, -2)
        end
        
        if line == "DLINK DATA" then
            dlinkMarker = true
            line = file_data:read()
        end

        if dlinkMarker and #self.log < 5 then
            if importLineHelper == 0 then
                logEntry.ref = line
            elseif importLineHelper == 1 then
                logEntry.dest = line
            elseif importLineHelper == 2 then          
                logEntry.flt_no = line
            elseif importLineHelper == 3 then
                local day = tonumber(line) or 0
                logEntry.day = day
                
                local types = {[1] = "out", [2] = "in", [3] = "on", [4] = "off"}
                for i = 1, #types do
                    local hour = tonumber(file_data:read()) or 0
                    local minute = tonumber(file_data:read()) or 0
                    local fuel = tonumber(file_data:read()) or 0

                    logEntry[types[i]] = {
                        hour = hour,
                        minute = minute,
                        fuel = fuel
                    }
                end
            elseif importLineHelper == 4 then
                logEntry.flightTime = tonumber(line) or 0
            elseif importLineHelper == 5 then
                logEntry.blockTime = tonumber(line) or 0

                table.insert(self.log, logEntry)
                importLineHelper = -1
                logEntry = {}
            end
                
            importLineHelper = importLineHelper + 1
        end

        line = file_data:read()
    end
    
    file_data:close()
end

return Screen
