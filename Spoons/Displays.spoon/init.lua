local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Apps"
obj.version = "1.0"
obj.author = "Selim Acerbas <selimacerbas@gmail.com>"
obj.license = "MIT"

-- Helper function: Display focus information
local function displayFocusInfo(screen, appName)
    local screenName = screen:name()
    local message = "Focused on " .. screenName .. "\nCurrent window: " .. (appName or "No app")
    hs.alert.show(message)
end

-- Helper function: Get the frontmost window on a given screen
local function getFrontmostWindowOnScreen(targetScreen)
    local windows = hs.window.orderedWindows()
    for _, win in ipairs(windows) do
        if win:screen() == targetScreen then
            return win
        end
    end
    return nil
end

-- Method: Move to the next screen
function obj:cycleDisplaysForwards()
    local currentScreen = hs.mouse.getCurrentScreen()
    local nextScreen = currentScreen:next()
    if not nextScreen then return end -- Safeguard in case there's no next screen

    local nextScreenCenter = hs.geometry.rectMidPoint(nextScreen:frame())
    hs.mouse.setAbsolutePosition(nextScreenCenter)

    local focusedWindow = getFrontmostWindowOnScreen(nextScreen)
    if focusedWindow then
        focusedWindow:focus()
        displayFocusInfo(nextScreen, focusedWindow:application():name())
    else
        displayFocusInfo(nextScreen, nil)
    end
end

-- Method: Move to the previous screen
function obj:cycleDisplaysBackwards()
    local currentScreen = hs.mouse.getCurrentScreen()
    local previousScreen = currentScreen:previous()
    if not previousScreen then return end -- Safeguard in case there's no previous screen

    local previousScreenCenter = hs.geometry.rectMidPoint(previousScreen:frame())
    hs.mouse.setAbsolutePosition(previousScreenCenter)

    local focusedWindow = getFrontmostWindowOnScreen(previousScreen)
    if focusedWindow then
        focusedWindow:focus()
        displayFocusInfo(previousScreen, focusedWindow:application():name())
    else
        displayFocusInfo(previousScreen, nil)
    end
end

return obj
