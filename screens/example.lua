--[[
This is the example FMC screen. To remove this, remove the reference in menu.lua, and delete this file.

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

local totalStages = 5

function Screen:initialize(fmcui, params)
  self.fmcui = fmcui or {}
  self.params = params or {}
  setmetatable(self, Screen)
  self.stage = 0

  self.fmcui:setLine(0, "Welcome", "center", 8)
  self.fmcui:setMultiline(4, "Welcome to this example.\nAre you interested in a showcase of", "center", -1)
  self.fmcui:setLine(4, "FMCUI", "center", 4)

  self.fmcui:setAction("6RSK", "Certainly", self.nextStage)
  self.fmcui:setAction("6LSK", "Nope", self.showMenu)

  return self
end

function Screen:destroy()
end

function Screen:input(keyIdentifier, phase, duration)
  if self.stage == 3 then
    self.fmcui:setLine(4, "")
    self.fmcui:setLine(4, "", "left", 3)
    self.fmcui:setLine(5, "")
    self.fmcui:setLine(4, keyIdentifier .. " button", "left", 2)
  elseif phase == 2 and keyIdentifier == "PREV" then
    self:previousStage()
  elseif phase == 2 and keyIdentifier == "NEXT" then
    self:nextStage()
  elseif phase == 2 and self.stage == 4 and keyIdentifier == "EXEC" then
    self.fmcui:setExecLight(false)
    self:nextStage()
  end
end

function Screen:showMenu()
  self.fmcui:showScreen('menu')
end

function Screen:nextStage()
  self.fmcui:clearLines()
  self.fmcui:clearActions()
  self.stage = math.min(totalStages, self.stage + 1)

  self:drawStage()
end

function Screen:previousStage()
  self.fmcui:clearLines()
  self.fmcui:clearActions()
  self.stage = math.max(1, self.stage - 1)
  self:drawStage()
end

function Screen:drawStage()
  self.fmcui:setLine(0, self.stage .. "/" .. totalStages, "right", 2)

  if self.stage == 1 then
    self.fmcui:setLine(1, "FMCUI can draw left", "left")
    self.fmcui:setLine(2, "centered", "center")
    self.fmcui:setLine(3, "right", "right")
    self.fmcui:setLine(4, "or even some variants", "left", 2)
    self.fmcui:setLine(5, "With ease", "left", 3)
    self.fmcui:setAction("6RSK", "OK", self.nextStage)
  elseif self.stage == 2 then
    self.fmcui:setMultiline(5, "This is achieved with a simple scripting interface. You should check out the code.", "left", -1)
    self.fmcui:setAction("6RSK", "Understood", self.nextStage)
  elseif self.stage == 3 then
    self.fmcui:setMultiline(4, "Handling button presses is made easy as well. Try pressing", "left", -1)
    self.fmcui:setLine(4, "NEXT, EXEC or PREV", "left", 3)
    self.fmcui:setLine(5, "on your FMC.")
    self.fmcui:setAction("6RSK", "Next", self.nextStage)
  elseif self.stage == 4 then
    self.fmcui:setMultiline(1, "Now for the scratchpad.", "left", 1)
    self.fmcui:setInput("3LSK", "Random ICAO", self.inputChanged, 4)
    self.fmcui:setAction("6RSK", "Fill scratchpad", self.setInput)
  elseif self.stage == 5 then
    self.fmcui:setMultiline(1, "And last but not least, here are some airplane commands.", "left", 1)

    self.fmcui:setAction("5RSK", "No smoking", self.noSmokingToggle)
    self.fmcui:setAction("5LSK", "Lights", self.switchLandingLights)
    self.fmcui:setAction("6RSK", "Finish", self.showMenu)
  end
end

function Screen:noSmokingToggle()
  self.fmcui:command('laminar/B738/toggle_switch/no_smoking_dn')
end

function Screen:switchLandingLights()
  self.fmcui:command('laminar/B738/spring_switch/landing_lights_all')
end

function Screen:setInput(input)
  self.fmcui:setScratchpad("TEST")
end

function Screen:inputChanged(input, keyIdentifier)
  if string.len(input) == 4 then
    self.fmcui:setLine(5, "Press EXEC to continue", "left", 2)
    self.fmcui:setLine(5, "Your input was " .. input, "left", 1, true)
    self.fmcui:setExecLight(true)
    return true
  else
    self.fmcui:showWarning("Not a four char input")
    return false
  end
end

return Screen