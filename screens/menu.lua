--[[
This is the main menu FMC screen.

There are is only one main method that needs to be defined:
- Screen:initialize(fmcui, params)
  | This method will be called when the screen is initialized, and about to be shown.
  | `fmcui` will contain the fmcui handle. `params` will contain any parameters that have been passed.
  | The first few lines of the function will always be as below, in order to properly instantiate the screen:
  | self.fmcui = fmcui or {}
  | self.params = params or {}
  | setmetatable(self, Screen)


- OPTIONAL: Screen:destroy()
  | This method is called when you navigate away from this screen, but may be called by the system at any time.
  | You have a chance to clean up any leftovers, or reset them to their default values.

- OPTIONAL: Screen:input(keyIdentifier, phase, duration)
  | This method is called when any button is pressed.

- Screen:update()
| This method is called every tick (every time the screen is updated).

--]]

local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
    self.fmcui = fmcui or {}
    self.params = params or {}
    setmetatable(self, Screen)

    self.fmcui:setLine(0, "MENU", "center")
    
    self.fmcui:setAction("1LSK", "FMC", self.resumeNormalOperation)
    self.fmcui:replaceLine(1, "<ACT>", 0, 8)
    self.fmcui:setAction("2LSK", "DLNK", self.showDlnkApplicationMenu)

    return self
end

function Screen:update()
    if self.fmcui:firstUnreadMessageIndex() > 0 then
        self.fmcui:setAction("6RSK", "+MESSAGE", (function() self.fmcui:showScreen("acars/messages/detail", { returnScreen = "menu" }) end), 3)
    else
        self.fmcui:replaceLine(6, "        ", 3, 24 - 8)
    end
end

function Screen:resumeNormalOperation()
    self.fmcui:reset()
    if self.fmcui.isPrimaryDisplay then
        self.fmcui:set("page_menu", 0)
        self.fmcui:set("page_ident", 1)
    else
        self.fmcui:set("page_menu2", 0)
        self.fmcui:set("page_ident2", 1)
    end
end

function Screen:showDlnkApplicationMenu()
    if self.fmcui:get('B738DR_fmc_input_lag') == 1 then
        self.fmcui:replaceLine(1, "     ", 0, 8)
        run_after_time((function() self.fmcui:replaceLine(2, "<SEL>", 0, 8) end), 0.05)
        run_after_time((function() self.fmcui:replaceLine(2, "<ACT>", 0, 8) end), 0.8)
        run_after_time((function() self.fmcui:showScreen("dlnk-application-menu") end), 1)
    else
        self.fmcui:showScreen("dlnk-application-menu")
    end
end

return Screen