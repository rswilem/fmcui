--[[
This is the dev tool / debugger. Usage:
`lua __devtool.lua`
or
`nodemon --exec lua __devtool.lua`

To start at a specific screen, use `lua __devtool.lua screen-name`

Very dirty file, but hey, gets the job done.

--]]

-- Internal variables
page_menu = 1
B738DR_fmc_input_lag = 0
simDR_zulu_hours = os.date("%H")
simDR_zulu_minutes = os.date("%M")
simDR_zulu_seconds = os.date("%S")
line0_l = ""
line0_s = ""
line0_m = ""
line0_c = ""
line0_g = ""
line1_x = ""
line1_l = ""
line1_s = ""
line1_m = ""
line1_g = ""
line2_x = ""
line2_l = ""
line2_s = ""
line2_m = ""
line2_g = ""
line3_x = ""
line3_l = ""
line3_s = ""
line3_m = ""
line3_g = ""
line4_x = ""
line4_l = ""
line4_s = ""
line4_m = ""
line4_g = ""
line5_x = ""
line5_l = ""
line5_s = ""
line5_m = ""
line5_g = ""
line6_x = ""
line6_l = ""
line6_s = ""
line6_m = ""
line6_g = ""
line0_inv = ""
line1_inv = ""
line2_inv = ""
line3_inv = ""
line4_inv = ""
line5_inv = ""
line6_inv = ""
line4_si = ""
line1_lx = ""
line6_lx = ""

tmpEnv = _G

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

oldPrint = print
function print(x)
    oldPrint(x)
    os.exit(1)
end
oldOpen = io.open
io.open = (function(name)
    local rootName = "../../../../../../../" .. name
    return oldOpen(rootName)
end)
function getfenv() return tmpEnv end
function setfenv(f, env) end
function run_after_time(handler) handler() end
function add_fmc_msg(message)
    io.write("\27[2J") -- clear screen
    io.write("\27[H") -- Move cursor to 0,0
    io.flush()
    print("FMC Message: " .. message)
    os.exit(1)
end
function reset_fmc_pages() page_menu = 0 end
function null_fmc_disp()
    line0_l = ""
    line0_s = ""
    line0_m = ""
    line0_c = ""
    line0_g = ""
    line1_x = ""
    line1_l = ""
    line1_s = ""
    line1_m = ""
    line1_g = ""
    line2_x = ""
    line2_l = ""
    line2_s = ""
    line2_m = ""
    line2_g = ""
    line3_x = ""
    line3_l = ""
    line3_s = ""
    line3_m = ""
    line3_g = ""
    line4_x = ""
    line4_l = ""
    line4_s = ""
    line4_m = ""
    line4_g = ""
    line5_x = ""
    line5_l = ""
    line5_s = ""
    line5_m = ""
    line5_g = ""
    line6_x = ""
    line6_l = ""
    line6_s = ""
    line6_m = ""
    line6_g = ""
    line0_inv = ""
    line1_inv = ""
    line2_inv = ""
    line3_inv = ""
    line4_inv = ""
    line5_inv = ""
    line6_inv = ""
    line4_si = ""
    line1_lx = ""
    line6_lx = ""
end
function wrap_command() end

function B738_fmc_disp_capt()
    draw()
end

function B738_fmc_disp_fo()
    draw()
end

local req = require('main')
FMCUI = req.FMCUI -- captain
FMCUI = req.FMCUISecondary -- first officer

function main()
    if FMCUI.isPrimaryDisplay then
        B738_fmc_disp_capt()
    else
        B738_fmc_disp_fo()
    end

    handleCommand()
end

function draw()
    io.write("\27[2J") -- clear screen
    io.write("\27[H") -- Move cursor to 0,0
    io.flush()

    for j = 0, #availableVariants do
        io.write("\27[0m") -- Text style
        io.write("\27[H") -- Move cursor to 0,0
        local offset = j * 28
        io.write("\27[" .. offset .. "C") -- Move right
        io.write("----------[" .. availableVariants[j] .. "]----------")
        io.write("\27[E") -- Move cursor down
        
        for i = 0, 6 do
            io.write("\27[" .. offset - 1 .. "C") -- Move right
            local text = _G["line" .. i .. availableVariants[j]]
            if text and string.len(text) > 0 then
                io.write("|" .. text .. "|")
            else
                io.write("|                        |")
            end
            io.write("\27[E") -- Move cursor down
        end

        io.write("\27[" .. offset .. "C") -- Move right
        io.write("----------[" .. availableVariants[j] .. "]----------")

        io.write("\27[0m")
    end
    io.write("\27[E") -- Move cursor down

    io.flush()
end

function handleCommand()
    io.write("\n\nType 'r' to redraw. Type 's' to navigate to a screen. Type '1LSK' to command the first left software button.\nCommand: ")
    io.flush()

    local cmd = io.read()
    
    local softKeyEnding = "SK"
    local isSoftKey = cmd:upper():sub(-#softKeyEnding) == softKeyEnding
    
    if cmd == "r" then
        -- fallthrough, we call main() at the bottom.
    elseif cmd == "s" then
        io.write("Screen name: ")
        io.flush()
        local screenName = io.read()
        FMCUI:showScreen(screenName);
    elseif isSoftKey then
        FMCUI_HandleKey(FMCUI, cmd:upper(), 2, 0)
    end

    main()
end

-- Start at a specific screen
if arg[1] ~= nil and string.len(arg[1]) > 0 then
    B738_fmc_disp_capt()
    FMCUI:showScreen(arg[1])
end

main()
