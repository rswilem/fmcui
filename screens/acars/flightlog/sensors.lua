local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.keys = {
        [1] = {
            title = "PARK BRAKE",
            valueKeys = { [1] = 'B738DR_parking_brake_pos' },
            displayValues = {[0] = 'RELEASED', [1] = 'SET'}
        },

        [2] = {
            title = "AIR/GND",
            valueKeys = { [1] = 'B738DR_air_ground_sensor' },
            displayValues = {[0] = 'AIRBORNE', [1] = 'GROUND'}
        },

        [3] = {
            title = "FWD DOOR",
            valueKeys = { [1] = 'door_ratio_fwd_L' },
            displayValues = {[0] = 'CLOSED', [1] = 'OPEN'}
        },

        [4] = {
            title = "AFT DOOR",
            valueKeys = { [1] = 'door_ratio_aft_L' },
            displayValues = {[0] = 'CLOSED', [1] = 'OPEN'}
        },

        [5] = {
            title = "CARGO/EE DOORS",
            valueKeys = { [1] = 'door_ratio_fwd_cargo', [2] = 'door_ratio_aft_cargo' },
            displayValues = {[0] = 'CLOSED', [1] = 'OPEN'}
        },

        [6] = {
            title = "SERVICE DOORS",
            valueKeys = { [1] = 'door_ratio_fwd_R', [2] = 'door_ratio_aft_R' },
            displayValues = {[0] = 'CLOSED', [1] = 'OPEN'}
        },

        [7] = {
            title = "FOB",
            valueKeys = { [1] = 'fuel_weight' },
            displayValues = {}
        },
    }

    self.fmcui:setLine(0, "ACARS-SENSORS")
    self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)

    return self
end

function Screen:update()
    local zuluHours = self.fmcui:get('simDR_zulu_hours')
    local zuluMinutes = self.fmcui:get('simDR_zulu_minutes')

    self.fmcui:replaceLine(6, string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes), 2, 10)

    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "acars/flightlog/sensors" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end

    self:drawSensors()
end

function Screen:drawSensors()
    local columnValueLength = 8

    for i = 1, #self.keys do
        local line = math.ceil(i / 2)
        local lineVariant = i % 2 == 1 and 1 or 2
        self.fmcui:setLine(line, self.keys[i].title, "left", lineVariant)
        local valueKeys = self.keys[i].valueKeys

        local lastValue = nil
        local isDifferingValue = false
        for j = 0, #valueKeys do
            local value = self.fmcui:get(valueKeys[j])
            if lastValue and value ~= lastValue then
                isDifferingValue = true
                break
            end

            lastValue = value
        end

        if isDifferingValue then
            self.fmcui:replaceLine(line, "DIFFER", lineVariant, 24 - columnValueLength)
        else
            self.fmcui:replaceLine(line, self.keys[i].displayValues[lastValue] or (lastValue or "-"), lineVariant, 24 - columnValueLength)
        end
    end
end

function Screen:showPreviousScreen()
    self.fmcui:showScreen("acars/flightlog/flightlog")
end

return Screen
