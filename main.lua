--[[
Welcome to the FMCUI library. This addon enables for easy FMC screen programming and manipulation.
Because all screens are contained in their own file in the screens/ directory, all code will be nicely separated.
All usable functions below are provided with some comments describing their functionality. Enjoy!

Installation / Usage:
To inject this script, open B738.a_fms.lua, scroll to the bottom where it says SUB-MODULE PROCESSING.
Add the following line:

dofile("fmcui/main.lua") -- Load FMCUI extension

--]]
package.path = 'Aircraft/B737-800X/plugins/xlua/scripts/B738.a_fms/fmcui/?.lua;' .. package.path

math.randomseed(os.time())
MAX_LINES = 6
LINE_LENGTH = 24
availableVariants = {
    [0] = "_l", -- Plain
    [1] = "_x", -- Header
    [2] = "_s", -- Smaller font
    [3] = "_m", -- Magenta
    [4] = "_g", -- Green
    [5] = "_inv", -- Text w/ background
    [6] = "_si", -- Text w/ background (only line #4)
    [7] = "_lx", -- Header (only line #1 and #6)
    [8] = "_c" -- Blue header (only line #0)
}

local acarsMessages = {}
local FMCUI = {
    isPrimaryDisplay = true,
    activeScreen = nil,
    activeScreenName = nil,
    actions = {},
    lines = {}
}

-- 
-- START OF PUBLIC API
-- 

--- Show a screen on the FMC
-- This function invalidates the current screen and shows a screen on the FMC.
-- The screen will be 'require'd in lua, so make sure to pass the filename in the screens/ directory.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param screenIdentifier The filename of the screen to show
-- @param params OPTIONAL: Parameters for the screen.
-- @param direct OPTIONAL: Force the screen to be visible, without input lag
function FMCUI.showScreen(fmcui, screenIdentifier, params, direct)
    fmcui:reset()

    if B738DR_fmc_input_lag > 0 and not direct then
        run_after_time((function() fmcui:showScreen(screenIdentifier, params, true) end), math.random())
        return
    end

    fmcui.activeScreenName = 'screens.' .. screenIdentifier

    local Screen = require(fmcui.activeScreenName)
    if Screen then
        fmcui.activeScreen = Screen.initialize({}, fmcui, params)
    end
end

--- Show a warning message on the FMC.
-- Shows a message on the FMC, followed by a 'ding' sound.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param message The message to show.
-- @param isError OPTIONAL: Mark the message as an error. If omitted or false, the message will be handled as a normal warning.
function FMCUI.showWarning(fmcui, message, isError)
    if message and string.len(message) > 0 then
        add_fmc_msg(message, (isError and 1 or 2))
    end
end

--- Add an incoming message to the FMC. (ACARS)
-- Shows a message on the FMC, followed by a 'ding' sound.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param message The text of the message.
-- @param delay OPTIONAL: The delay in seconds from now; when to show the message.
-- @param showNotice OPTIONAL: Default false, shows a notice on the FMC "NEW MESSAGE"
function FMCUI.addMessage(fmcui, message, delay, showNotice)
    if delay and delay > 0 then
        run_after_time((function () fmcui:addMessage(message, 0, showNotice) end), delay)
        return
    end

    local zuluHours = fmcui:get('simDR_zulu_hours')
    local zuluMinutes = fmcui:get('simDR_zulu_minutes')
    table.insert(acarsMessages, {
        text = message,
        time = string.format("%02d", zuluHours) .. ":" .. string.format("%02d", zuluMinutes),
        unread = true
    })

    if showNotice then
        fmcui:showWarning("ACARS MESSAGE")
    end
end

--- Get message at index. (ACARS)
-- Returns the message at index in the following format: {text = 'Lorem ipsum', time = '11:22', unread = true}
-- Use FMCUI.getMessagesCount() to get the number of messages.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param index The index of the message
-- @param markAsRead Mark the message as read
function FMCUI.getMessage(fmcui, index, markAsRead)
    local message = acarsMessages[index]

    if markAsRead then
        acarsMessages[index].unread = false
    end

    return message
end

--- Returns the index for the first unread message. Indices start at 1. (ACARS)
-- Returns 0 if there is no unread message.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
function FMCUI.firstUnreadMessageIndex(fmcui)
    for i = 1, #acarsMessages do
        if acarsMessages[i].unread then
            return i
        end
    end

    return 0
end

--- Get all messages count. (ACARS)
-- Returns total number of messages.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
function FMCUI.messagesCount(fmcui)
    return #acarsMessages;
end

--- Add an action to one of the SK buttons (1-6LSK, 1-6RSK) on the FMC.
-- This action registers one of the soft keys on the FMC to the handler provided.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param keyIdentifier The name of the key (1-6LSK, 1-6RSK), for example '2LSK'
-- @param handler The handler (function) that will be called when the soft key is pressed
-- @param text OPTIONAL: The text of the action (e.g. 'MENU' or 'PERF INIT'). Will display a text based on the keyIdentifier, e.g. < MENU
-- @param variant OPTIONAL: The variant (text color) of the action line.
function FMCUI.setAction(fmcui, keyIdentifier, text, handler, variant)
    variant = variant or 0
    local softKeyEnding = "SK"
    local isSoftKey = keyIdentifier:sub(-#softKeyEnding) == softKeyEnding
    local index = tonumber(keyIdentifier:sub(1, 1))
    local isLeft = keyIdentifier:sub(2, 2) == "L"
    if not isSoftKey or index > MAX_LINES then
        return false
    end

    fmcui.actions[keyIdentifier] = handler

    if text and string.len(text) > 0 then
        local existingText = FMCUI_GetLineText(fmcui, index, variant)
        local line = (isLeft and (variant == 3 and "" or "<") .. text .. existingText:sub(#text + 2, LINE_LENGTH) or existingText:sub(1, LINE_LENGTH - #text - 1) ..
        text .. (variant == 3 and "" or ">"))
        fmcui:setLine(index, line, (isLeft and "left" or "right"), variant)
    end

    return true
end

--- Clear an action bound to a key.
-- Clears the action bound to the passed key identifier.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param keyIdentifier The name of the key (1-6LSK, 1-6RSK), for example '2LSK'
function FMCUI.clearAction(fmcui, keyIdentifier)
    fmcui.actions[keyIdentifier] = nil
end

--- Clear all actions bound to the SK
-- Clears all actouns bound to the softkeys. Good practice is to call this function when your screen is 'destroy()'ed.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
function FMCUI.clearActions(fmcui)
    fmcui.actions = {}
end

--- Set exec light
-- Set exec light enabled/disabled
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param enabled Whether the exec light should be enabled
function FMCUI.setExecLight(fmcui, enabled)
    if fmcui.isPrimaryDisplay then
        B738DR_fmc_exec_lights = (enabled and 1 or 0)
        B738DR_fmc_exec_lights2 = (enabled and 1 or 0)
    else
        B738DR_fmc_exec_lights_fo = (enabled and 1 or 0)
        B738DR_fmc_exec_lights2_fo = (enabled and 1 or 0)
    end
end

--- Set scratchpad
-- Sets the buffer / scratchpad / user input
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param input Scratchpad input
function FMCUI.setScratchpad(fmcui, input)
    if fmcui.isPrimaryDisplay then
        entry = input and input or ""
    else
        entry2 = input and input or ""
    end
end

--- Get scratchpad
-- Gets the buffer / scratchpad / user input
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
function FMCUI.getScratchpad(fmcui)
    if fmcui.isPrimaryDisplay then
        return entry or ""
    else
        return entry2 or ""
    end
end

--- Add an input to one of the SK buttons (1-6LSK, 1-6RSK) on the FMC.
-- This input shows [][] blocks, and captures the scratchpad when the user clicks on the soft key. Also, the handler is invoked.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param keyIdentifier The name of the key (1-6LSK, 1-6RSK), for example '2LSK'
-- @param handler The handler (function) that will be called when the soft key is pressed. Passed arguments: #0: Input, #1: keyIdentifier
-- @param inputLength OPTIONAL: The length of the input. Will initially show this much empty 'blocks'.
function FMCUI.setInput(fmcui, keyIdentifier, placeholder, handler, inputLength)
    local softKeyEnding = "SK"
    local isSoftKey = keyIdentifier:sub(-#softKeyEnding) == softKeyEnding
    local index = tonumber(keyIdentifier:sub(1, 1))
    local isLeft = keyIdentifier:sub(2, 2) == "L"
    if not isSoftKey or index > MAX_LINES then
        return false
    end

    fmcui.actions[keyIdentifier] = (function(ref)
        local valid = true
        if handler then
            valid = handler(ref, ref.fmcui:getScratchpad(), keyIdentifier)
        end

        if valid then
            ref.fmcui:setLine(index, ref.fmcui:getScratchpad(), (isLeft and "left" or "right"), 0)
        end

        ref.fmcui:setScratchpad("")
    end)

    text = ""
    for i = 1, inputLength do
        text = text .. "*"
    end

    fmcui:setLine(index, text, (isLeft and "left" or "right"), 0)
    fmcui:setLine(index, placeholder, (isLeft and "left" or "right"), 1)

    return true
end

--- Set a line on the FMC
-- This sets a line of text on the FMC.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param index The line index to show the text on. Range 0-6, top to bottom
-- @param text The text
-- @param alignment OPTIONAL: Alignment of the text. Can be one of ("left", "center", "right"), default is "left"
-- @param variant: OPTIONAL: Variant of the text. Range 0-8. Check availableVariants on the top of this file. Default is 0.
function FMCUI.setLine(fmcui, index, text, alignment, variant)
    if index > MAX_LINES then
        return
    end
    
    variant = variant or 0
    text = text or ""

    isLeft = alignment == nil or alignment == "left"
    isCenter = alignment == "center"

    length = #text
    if length > 0 then
        for i = 0, LINE_LENGTH - length - 1 do
            if isCenter then
                isLeft = i % 2 == 1
            end

            text = (isLeft and text .. " " or " " .. text)
        end
    end

    if not fmcui.lines[index] then
        fmcui.lines[index] = {}
    end

    local entry = {
        text = text,
        variant = (availableVariants[variant] or availableVariants[0]),
    }

    for i = 1, #fmcui.lines[index] do
        if fmcui.lines[index][i].variant == entry.variant then
            fmcui.lines[index][i] = entry
            return text
        end
    end

    table.insert(fmcui.lines[index], entry)

    return text
end

--- Set multiline text on the FMC
-- Sets a multiline text on the FMC. Will break words.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param startIndex The start index of the line
-- @param text The text value (may contain line breaks)
-- @param alignment The alignment (see FMCUI.setLine)
-- @param variant The variant (see FMCUI.setLine) or set "compact mode" with -1, startIndex will behave differently (0 is 0, 1 is actually the line between 0 and 1, 2 is 1).
function FMCUI.setMultiline(fmcui, startIndex, text, alignment, variant)
    lines = {}
    for rawStr in text:gmatch("[^\r\n]+") do
        while string.len(rawStr) > LINE_LENGTH do
            table.insert(lines, ((rawStr:sub(1, LINE_LENGTH - 1)):gsub("^%s*(.-)%s*$", "%1")))
            rawStr = rawStr:sub(LINE_LENGTH)
        end
        table.insert(lines, (rawStr:gsub("^%s*(.-)%s*$", "%1")))
    end

    local isCompact = variant and variant < 0
    for i = 1, #lines do
        fmcui:setLine((isCompact and math.floor(startIndex / 2 + i / 2) or startIndex + i) - 1, lines[i], alignment, (isCompact and (i % 2 == startIndex % 2 and 1 or 2) or variant))
    end
end

--- Replaces a part of the line on the FMC
-- Used to replace a part of the text on the FMC, e.g. to add text, like <ACT>.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param index The target line
-- @param text The text to insert
-- @param variant The variant to replace the text on
-- @param offset The offset in the line, e.g. 2 to replace text starting from the 2nd character.
function FMCUI.replaceLine(fmcui, index, text, variant, offset)
    if not text or string.len(text) == 0 or index > MAX_LINES then
        return
    end

    local existingText = FMCUI_GetLineText(fmcui, index, variant)
    if string.len(existingText) == 0 then
        existingText = fmcui:setLine(index, " ", "left", variant)
    end

    text = (existingText:sub(0, offset) .. text .. existingText:sub(offset + #text + 1)):sub(0, LINE_LENGTH)
    fmcui:setLine(index, text, "left", variant)

    return text
end

--- Clear lines on the FMC
-- This clears all six lines on the FMC, use this to reset the screen to black.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
function FMCUI.clearLines(fmcui)
    null_fmc_disp()
    fmcui.lines = {}
end

--- Set a global variable.
-- Use with caution. This function can be used to set a global variable of the B738.a_fms.lua script.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param variableName The name of the variable to change
-- @param value The new value
-- @param atIndex When specified, handles the variable name as a table, and gets the value at index
function FMCUI.set(fmcui, variableName, value, atIndex)
    ctx = getfenv()
    if atIndex ~= nil and ctx[variableName] then
        ctx[variableName][atIndex] = value
    else
        ctx[variableName] = value
    end
end

--- Get a global variable.
-- This function can be used to get a global variable of the B738.a_fms.lua script.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param variableName The name of the variable
-- @param atIndex When specified, handles the variable name as a table, and gets the value at index
function FMCUI.get(fmcui, variableName, atIndex)
    ctx = getfenv()
    if atIndex ~= nil and ctx[variableName] then
        return ctx[variableName][atIndex]
    else
        return ctx[variableName]
    end
end

--- Execute a global command.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
-- @param commandName The name of the command, e.g. 'laminar/B738/toggle_switch/no_smoking_dn'
function FMCUI.command(fmcui, commandName)
    local command = find_command(commandName)
    command:once()
end

--- Reset FMCUI.
-- This resets FMCUI and destroys the active screen.
-- @param fmcui The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)
function FMCUI.reset(fmcui)
    if fmcui.activeScreen then
        if fmcui.activeScreen.destroy then
            fmcui.activeScreen:destroy()
        end
        
        package.loaded[fmcui.activeScreenName] = nil
        fmcui.activeScreen = nil
    end

    fmcui:clearActions()
    fmcui:clearLines()
end

-- 
-- END OF PUBLIC API
-- 

local FMCUISecondary = {}
for k,v in pairs(FMCUI) do
    FMCUISecondary[k] = v
end
FMCUISecondary.isPrimaryDisplay = false
FMCUISecondary.actions = {}

local original_B738_fmc_disp_capt = B738_fmc_disp_capt
function B738_fmc_disp_capt()
    if page_menu == 1 then
        reset_fmc_pages()
        FMCUI:reset()

        if not FMCUI.activeScreen then
            FMCUI:showScreen('menu')
        end
    end

    if FMCUI.activeScreen then
        if FMCUI.activeScreen.update then
            FMCUI.activeScreen:update()
        end

        FMCUI_drawActiveScreen(FMCUI)
    end

    original_B738_fmc_disp_capt()
end

local original_B738_fmc_disp_fo = B738_fmc_disp_fo
function B738_fmc_disp_fo()
    if page_menu2 == 1 then
        reset_fmc_pages_fo()
        FMCUISecondary:reset()
        
        if not FMCUISecondary.activeScreen then
            FMCUISecondary:showScreen('menu')
        end
    end
    
    if FMCUISecondary.activeScreen then
        if FMCUISecondary.activeScreen.update then
            FMCUISecondary.activeScreen:update()
        end
        
        FMCUI_drawActiveScreen(FMCUISecondary)
    end
    
    original_B738_fmc_disp_fo()
end

local original_B738_exec_light = B738_exec_light
function B738_exec_light()
    if not FMCUI.activeScreen then
        original_B738_exec_light()
    end
end

function FMCUI_noop()
end

function FMCUI_drawActiveScreen(fmcui)
    local ctx = getfenv()

    for i = 0, MAX_LINES do
        local variants = fmcui.lines[i]
        if variants then
            for j = 0, #variants do
                local line = variants[j]
                if line then
                    ctx["line" .. i .. line.variant] = line.text
                end
            end
        end
    end
end

function FMCUI_HandleKey(fmcui, keyIdentifier, phase, duration)
    if fmcui.activeScreen and fmcui.activeScreen.input then
        fmcui.activeScreen:input(keyIdentifier, phase, duration)
    end
    
    if phase == 2 and fmcui.actions[keyIdentifier] then
        fmcui.actions[keyIdentifier](fmcui.activeScreen)
    end
end

function FMCUI_HandlePageChange(fmcui, keyIdentifier, phase, duration)
    FMCUI_HandleKey(fmcui, keyIdentifier, phase, duration)

    if phase == 0 then
        -- Since the user switched pages, we destroy ourselves
        fmcui:reset()
    end
end

function FMCUI_GetLineText(fmcui, index, variant)
    local variants = fmcui.lines[index]
    if not variants then return "" end
    
    local variantType = variant and availableVariants[variant] or availableVariants[0]
    for i = 0, #variants do
        local line = variants[i]
        if line and line.variant == variantType then
            return line.text
        end
    end

    return ""
end

setfenv(FMCUI_HandleKey, getfenv())
setfenv(FMCUI_HandlePageChange, getfenv())

for screenIndex = 1, 2 do
    -- Wrap softkeys
    FMCUI_1LSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_1L", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "1LSK", phase, duration) end), FMCUI_noop)
    FMCUI_2LSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_2L", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "2LSK", phase, duration) end), FMCUI_noop)
    FMCUI_3LSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_3L", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "3LSK", phase, duration) end), FMCUI_noop)
    FMCUI_4LSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_4L", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "4LSK", phase, duration) end), FMCUI_noop)
    FMCUI_5LSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_5L", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "5LSK", phase, duration) end), FMCUI_noop)
    FMCUI_6LSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_6L", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "6LSK", phase, duration) end), FMCUI_noop)

    FMCUI_1RSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_1R", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "1RSK", phase, duration) end), FMCUI_noop)
    FMCUI_2RSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_2R", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "2RSK", phase, duration) end), FMCUI_noop)
    FMCUI_3RSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_3R", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "3RSK", phase, duration) end), FMCUI_noop)
    FMCUI_4RSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_4R", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "4RSK", phase, duration) end), FMCUI_noop)
    FMCUI_5RSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_5R", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "5RSK", phase, duration) end), FMCUI_noop)
    FMCUI_6RSK_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_6R", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "6RSK", phase, duration) end), FMCUI_noop)

    FMCUI_NEXT_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_prev_page", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "PREV", phase, duration) end), FMCUI_noop)
    FMCUI_PREV_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_next_page", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "NEXT", phase, duration) end), FMCUI_noop)
    FMCUI_EXEC_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_exec", (function(phase, duration) FMCUI_HandleKey((screenIndex == 1 and FMCUI or FMCUISecondary), "EXEC", phase, duration) end), FMCUI_noop)

    -- Pages
    FMCUI_INITREF_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_init_ref", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "INITREF", phase, duration) end), FMCUI_noop)
    FMCUI_MENU_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_menu", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "MENU", phase, duration) end), FMCUI_noop)
    FMCUI_N1LIM_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_n1_lim", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "N1LIM", phase, duration) end), FMCUI_noop)
    FMCUI_RTE_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_rte", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "RTE", phase, duration) end), FMCUI_noop)
    FMCUI_LEGS_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_legs", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "LEGS", phase, duration) end), FMCUI_noop)
    FMCUI_FIX_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_fix", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "FIX", phase, duration) end), FMCUI_noop)
    FMCUI_CLB_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_clb", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "CLB", phase, duration) end), FMCUI_noop)
    FMCUI_CRZ_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_crz", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "CRZ", phase, duration) end), FMCUI_noop)
    FMCUI_DES_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_des", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "DES", phase, duration) end), FMCUI_noop)
    FMCUI_DEPAPP_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_dep_app", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "DEPAPP", phase, duration) end), FMCUI_noop)
    FMCUI_HOLD_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_hold", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "HOLD", phase, duration) end), FMCUI_noop)
    FMCUI_PROG_REF = wrap_command("laminar/B738/button/fmc" .. screenIndex .. "_prog", (function(phase, duration) FMCUI_HandlePageChange((screenIndex == 1 and FMCUI or FMCUISecondary), "PROG", phase, duration) end), FMCUI_noop)
end 

return {FMCUI = FMCUI, FMCUISecondary = FMCUISecondary}