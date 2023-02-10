# FMCUI

This is the FMCUI repository, the library to ease development for the **Zibo B737-800X (ZIBO mod)** in X-Plane.
FMCUI aims to ease the development by providing high level functions to write information and gather actions by the user.



## Concept

FMCUI uses the concept of Screens, a single .lua file that contains information for the specific screen. This way, all code is seperated nicely and will not interfere with other screens.
Since I think Zibo did a superb job on the FMC already, I did not want to remove any functionality. I have hijacked the _menu_ screen (main screen on startup) and rewrote the <DLNK menu's.

![Screenshot 2023-01-29 at 10 56 31](https://user-images.githubusercontent.com/18720368/218189676-d0da9912-4156-41da-85fb-ab7cf8f6f418.png)

## Roadmap

- [x] Basic screen drawing for all six lines
- [x] Screen drawing with all variants for all six lines
- [x] Support for buttons / softkeys / next, prev
- [x] Reading and writing the scratchpad
- [x] First officer display support
- [x] Implement Zibo's current screens in DLNK
- [x] Implement weather request for X-Plane 12 (Fixes "NO METAR DATA")
- [ ] Implement weather request for X-Plane 11 (metar.rwx)
- [ ] Implement more ACARS screens
- [ ] Add networking to talk to OPS (via GPT api?)

## Installation

1. Go to the `.../X-Plane 12/Aircraft/B737-800X/plugins/xlua/scripts/B738.a_fms/` directory and create a folder named `fmcui` there.
2. Place all the FMCUI files (download repository as zip, and unextract) in the `.../X-Plane 12/Aircraft/B737-800X/plugins/xlua/scripts/B738.a_fms/fmcui` directory
3. Alter the `B738.a_fms.lua` file (that should've been there by default), scroll to the bottom where it says "SUB-MODULE PROCESSING".
4. Add the following line: `dofile("fmcui/main.lua") -- Load FMCUI extension`
5. Make sure the line is **not commented out**. The line should **not** start with two dashes `--`, it should start with `dofile` instead.

## Creating a screen

To add a new screen, simply add a file to the `screens/` directory. Grouping screens in subdirectories is supported. You can then call the screen using the `FMCUI:showScreen("yourSubdirectory/yourScreen")` function. See usage below for more information.

## Usage

### General

Your screen will need to define (at least) one main method that is called when the screen is initialized, and about to be shown.

```lua
function Screen:initialize(fmcui, params)
```

`fmcui` will contain the fmcui handle. `params` will contain any parameters that have been passed.

This means that a basic lua file may look as follows:

```lua
local Screen = {}
Screen.__index = Screen

function Screen:initialize(fmcui, params)
  self.fmcui = fmcui or {}
  self.params = params or {}
  setmetatable(self, Screen)

  -- Do your initialization here

  return  self
end

return Screen
```

There are a few more optional methods that can be defined in your screen file:

```lua
function Screen:destroy()
```

This method is called when you navigate away from this screen, but may be called by the system at any time.
You have a chance to clean up any leftovers, or reset them to their default values.

```lua
function Screen:input(keyIdentifier, phase, duration)
```

This method is called when any button is pressed on the FMC.  
`phase` is the phase of the button. (0=started pressing, 1=pressing, 2=released)  
`duration` is the duration of the press in seconds.  
`keyIdentifier` can be one of:  

---

| keyIdentifier | Description      |
| ------------- | ---------------- |
| 1LSK          | Softkey 1, left  |
| 2LSK          | Softkey 2, left  |
| 3LSK          | Softkey 3, left  |
| 4LSK          | Softkey 4, left  |
| 5LSK          | Softkey 5, left  |
| 6LSK          | Softkey 6, left  |
| 1RSK          | Softkey 1, right |
| 2RSK          | Softkey 2, right |
| 3RSK          | Softkey 3, right |
| 4RSK          | Softkey 4, right |
| 5RSK          | Softkey 5, right |
| 6RSK          | Softkey 6, right |
| PREV          | PREV page button |
| NEXT          | NEXT page button |
| EXEC          | EXEC button      |
| INITREF       | Init/ref button  |
| MENU          | MENU button      |
| N1LIM         | N1/LIM button    |
| RTE           | ROUTE button     |
| LEGS          | LEGS button      |
| FIX           | NAV/FIX button   |
| CLB           | CLB button       |
| CRZ           | CRZ button       |
| DES           | DES button       |
| DEPAPP        | DEP/APP button   |
| HOLD          | HOLD button      |
| PROG          | PROG button      |

---

```lua
function Screen:update()
```

This method is called every tick (every time the screen is updated).

### Available methods

Call a function using the `fmcui` handle that is passed to your screen upon initialization, e.g.

```lua
function Screen:initialize(fmcui, params)
  self.fmcui = fmcui or {}
  self.params = params or {}
  setmetatable(self, Screen)

  -- Do your initialization here
  self.fmcui:setLine(0, "MY FIRST SCREEN")
  self.fmcui:setAction("6LSK", "RETURN", self.showPreviousScreen)
end
```

Make sure to always use the colon operator, so the proper fmcui handle is passed back to the library. The handle contains information about the display (pilot / first officer), which is needed by the library.

#### showScreen

```lua
function FMCUI.showScreen(fmcui, screenIdentifier, params, direct)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`screenIdentifier` The filename of the screen to show  
`params` OPTIONAL: Parameters for the screen.  
`direct` OPTIONAL: Force the screen to be visible, without input lag, even if the input lag setting is ON.  

Show a screen on the FMC.
This function invalidates the current screen and shows a screen on the FMC.
The screen will be '`require`'d in lua, so make sure to pass the filename in the screens/ directory.

#### showWarning

```lua
function FMCUI.showWarning(fmcui, message, isError)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`message` The message to show.  
`isError` OPTIONAL: Mark the message as an error. If omitted or false, the message will be handled as a normal warning.  

Show a warning message on the FMC.
Shows a message on the FMC, followed by a 'ding' sound.

#### addMessage

```lua
function  FMCUI.addMessage(fmcui, message, delay, showNotice)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`message` The text of the message.  
`delay` OPTIONAL: The delay in seconds from now; when to show the message.  
`showNotice` OPTIONAL: Default false, shows a notice on the FMC "NEW MESSAGE"  

Add an incoming message to the FMC. (ACARS)
Shows a message on the FMC, followed by a 'ding' sound.

#### getMessage

```lua
function  FMCUI.getMessage(fmcui, index, markAsRead)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`index` The index of the message  
`markAsRead` Mark the message as read  

Get message at index. (ACARS)
Returns the message at index in the following format: {text = 'Lorem ipsum', time = '11:22', unread = true}
Use `FMCUI.getMessagesCount()` to get the number of messages.

#### firstUnreadMessageIndex

```lua
function  FMCUI.firstUnreadMessageIndex(fmcui)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  

Returns the index for the first unread message. Indices start at 1. (ACARS)
Returns 0 if there is no unread message.

#### messagesCount

```lua
function  FMCUI.messagesCount(fmcui)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  

Get all messages count. (ACARS)
Returns total number of messages.

#### setAction

```lua
function  FMCUI.setAction(fmcui, keyIdentifier, text, handler, variant)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`keyIdentifier` The name of the key (1-6LSK, 1-6RSK), for example '2LSK'  
`handler` The handler (function) that will be called when the soft key is pressed  
`text` OPTIONAL: The text of the action (e.g. 'MENU' or 'PERF INIT'). Will display a text based on the keyIdentifier, e.g. < MENU  
`variant` OPTIONAL: The variant (text color) of the action line.  

Add an action to one of the SK buttons (1-6LSK, 1-6RSK) on the FMC.
This action registers one of the soft keys on the FMC to the handler provided.

#### clearAction

```lua
function  FMCUI.clearAction(fmcui, keyIdentifier)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`keyIdentifier` The name of the key (1-6LSK, 1-6RSK), for example '2LSK'  

Clear an action bound to a key.
Clears the action bound to the passed key identifier.

#### clearActions

```lua
function  FMCUI.clearActions(fmcui)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  

Clear all actions bound to the SK
Clears all actouns bound to the softkeys. Good practice is to call this function when your screen is 'destroy()'ed.

#### setExecLight

```lua
function  FMCUI.setExecLight(fmcui, enabled)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`enabled` Whether the exec light should be enabled  

Set exec light
Set exec light enabled/disabled

#### setScratchpad

```lua
function  FMCUI.setScratchpad(fmcui, input)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`input` Scratchpad input  

Set scratchpad
Sets the buffer / scratchpad / user input

#### getScratchpad

```lua
function  FMCUI.getScratchpad(fmcui)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  

Get scratchpad
Gets the buffer / scratchpad / user input

#### setInput

```lua
function  FMCUI.setInput(fmcui, keyIdentifier, placeholder, handler, inputLength)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`keyIdentifier` The name of the key (1-6LSK, 1-6RSK), for example '2LSK'  
`handler` The handler (function) that will be called when the soft key is pressed. Passed arguments: #0: Input, #1: keyIdentifier  
`inputLength` OPTIONAL: The length of the input. Will initially show this much empty 'blocks'.  

Add an input to one of the SK buttons (1-6LSK, 1-6RSK) on the FMC.
This input shows **[][]** blocks, and captures the scratchpad when the user clicks on the soft key. Also, the handler is invoked.

#### setLine

```lua
function  FMCUI.setLine(fmcui, index, text, alignment, variant)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`index` The line index to show the text on. Range 0-6, top to bottom  
`text` The text  
`alignment` OPTIONAL: Alignment of the text. Can be one of ("left", "center", "right"), default is "left"  
`variant` OPTIONAL: Variant of the text. Range 0-8. Check availableVariants on the top of this file. Default is 0.  

Set a line on the FMC.
This sets a line of text on the FMC, with an optional variant.

#### setMultiline

```lua
function  FMCUI.setMultiline(fmcui, startIndex, text, alignment, variant)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`startIndex` The start index of the line  
`text` The text value (may contain line breaks)  
`alignment` The alignment (see FMCUI.setLine)  
`variant` The variant (see FMCUI.setLine) or set "compact mode" with -1, startIndex will behave differently (0 is 0, 1 is actually the line between 0 and 1, 2 is 1).  

Set multiline text on the FMC.
Sets a multiline text on the FMC. Will break words.

#### replaceLine

```lua
function  FMCUI.replaceLine(fmcui, index, text, variant, offset)
```

Replaces a part of the line on the FMC
Used to replace a part of the text on the FMC, e.g. to add text, like `<ACT>` or `<SEL>` on the menu page.

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`index` The target line  
`text` The text to insert  
`variant` The variant to replace the text on  
`offset` The offset in the line, e.g. 2 to replace text starting from the 2nd character.  

#### clearLines

```lua
function  FMCUI.clearLines(fmcui)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  

Clear lines on the FMC
This clears all six lines on the FMC, use this to reset the screen to black.

#### set

```lua
function  FMCUI.set(fmcui, variableName, value, atIndex)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`variableName` The name of the variable to change  
`value` The new value  
`atIndex` When specified, handles the variable name as a table, and gets the value at index  

Set a global variable.
Use with caution. This function can be used to set a global variable of the B738.a_fms.lua script.

#### get

```lua
function  FMCUI.get(fmcui, variableName, atIndex)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`variableName` The name of the variable  
`atIndex` When specified, handles the variable name as a table, and gets the value at index  

Get a global variable.
This function can be used to get a global variable of the B738.a_fms.lua script.

#### command

```lua
function  FMCUI.command(fmcui, commandName)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  
`commandName` The name of the command, e.g. 'laminar/B738/toggle_switch/no_smoking_dn'  

Execute a global command.

#### reset

```lua
function  FMCUI.reset(fmcui)
```

`fmcui` The FMCUI instance. Invoke function with colon - e.g. fmcui:showScreen(...)  

Reset FMCUI.
This resets FMCUI and destroys the active screen.
