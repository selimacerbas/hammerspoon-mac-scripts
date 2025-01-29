local spaces = require("hs.spaces")
local mouse = require("hs.mouse")
local window = require("hs.window")

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Apps"
obj.version = "1.0"
obj.author = "Selim Acerbas <selimacerbas@gmail.com>"
obj.license = "MIT"

--- Helper: Get the UUID of the screen under the mouse
local function getCursorScreenUUID()
    local screen = mouse.getCurrentScreen() or hs.screen.mainScreen()
    return screen and screen:getUUID() or nil
end

--- Helper: Find the active space index in a list of space IDs
local function findActiveSpaceIndex(spaceIDs, activeSpace)
    for i, spaceID in ipairs(spaceIDs) do
        if spaceID == activeSpace then
            return i
        end
    end
    return nil
end

--- Helper: Focus the frontmost window on a specific screen
local function focusFrontmostWindowOnScreen(screen)
    local windows = hs.window.orderedWindows()
    for _, win in ipairs(windows) do
        if win:screen() == screen then
            win:focus()
            return
        end
    end
    hs.alert.show("No frontmost window found on the target screen")
end

--- Method: Create a space under the cursor
function obj:createSpaceUnderCursor()
    local currentScreen = mouse.getCurrentScreen()
    if not currentScreen then
        hs.alert.show("Unable to determine the current screen")
        return
    end

    local screenUUID = currentScreen:getUUID()
    local success, err = spaces.addSpaceToScreen(screenUUID)
    if not success then
        hs.alert.show("Failed to create space: " .. (err or "Unknown error"))
    else
        hs.alert.show("Space created on screen: " .. currentScreen:name())
    end
end

-- Method: Delete the current space
function obj:removeCurrentSpace()
    -- Get the current screen based on the mouse position
    local currentScreen = mouse.getCurrentScreen()
    if not currentScreen then
        hs.alert.show("Unable to determine the current screen!")
        return
    end

    -- Get the UUID and spaces for the current screen
    local screenUUID = currentScreen:getUUID()
    local spaceList = spaces.spacesForScreen(screenUUID)

    if not spaceList or #spaceList == 0 then
        hs.alert.show("No spaces found for the current screen!")
        return
    end

    -- Get the focused space
    local currentSpace = spaces.focusedSpace()
    if not currentSpace then
        hs.alert.show("No active space detected!")
        return
    end

    -- Ensure the focused space belongs to the current screen
    if not hs.fnutils.contains(spaceList, currentSpace) then
        hs.alert.show("Active space does not belong to the current screen!")
        return
    end

    -- Get all windows in the current space
    local windowsInSpace = spaces.windowsForSpace(currentSpace)
    local ignoredApps = { ["Finder"] = true, ["MonitorControl"] = true }
    local openApps = {}

    -- Check if any non-ignored apps are open in the current space
    for _, winID in ipairs(windowsInSpace) do
        local win = hs.window.get(winID)
        if win and not ignoredApps[win:application():name()] then
            table.insert(openApps, win:application():name())
        end
    end

    if #openApps > 0 then
        hs.alert.show("Space contains active applications: " .. table.concat(openApps, ", "))
        return
    end

    -- Attempt to switch to another space before removing
    local otherSpace = spaceList[1] -- Get the first space on the screen
    if otherSpace and otherSpace ~= currentSpace then
        spaces.gotoSpace(otherSpace)
        hs.timer.doAfter(1.0, function()
            local success = spaces.removeSpace(currentSpace)
            if success then
                hs.alert.show("Space removed successfully!")
            else
                hs.alert.show("Failed to remove space. It may be locked or in use.")
            end
        end)
    else
        hs.alert.show("No other space available to switch to!")
    end
end

--- Method: Move to the next space
function obj:moveToNextSpace()
    local screenUUID = getCursorScreenUUID()
    if not screenUUID then
        hs.alert.show("Unable to determine the active screen")
        return
    end

    local spaceIDs = spaces.spacesForScreen(screenUUID)
    if not spaceIDs or #spaceIDs == 0 then
        hs.alert.show("No spaces found for the current screen")
        return
    end

    local activeSpace = spaces.focusedSpace()
    local index = findActiveSpaceIndex(spaceIDs, activeSpace)
    if index then
        local nextIndex = (index % #spaceIDs) + 1
        local nextSpace = spaceIDs[nextIndex]
        spaces.gotoSpace(nextSpace)
        hs.timer.doAfter(1.0, function()
            local screen = hs.screen.find(screenUUID)
            if screen then
                focusFrontmostWindowOnScreen(screen)
            end
        end)
    else
        hs.alert.show("Active space not found in space list")
    end
end

--- Method: Move to the previous space
function obj:moveToPreviousSpace()
    local screenUUID = getCursorScreenUUID()
    if not screenUUID then
        hs.alert.show("Unable to determine the active screen")
        return
    end

    local spaceIDs = spaces.spacesForScreen(screenUUID)
    if not spaceIDs or #spaceIDs == 0 then
        hs.alert.show("No spaces found for the current screen")
        return
    end

    local activeSpace = spaces.focusedSpace()
    local index = findActiveSpaceIndex(spaceIDs, activeSpace)
    if index then
        local prevIndex = (index - 2 + #spaceIDs) % #spaceIDs + 1
        local prevSpace = spaceIDs[prevIndex]
        spaces.gotoSpace(prevSpace)
        hs.timer.doAfter(1.0, function()
            local screen = hs.screen.find(screenUUID)
            if screen then
                focusFrontmostWindowOnScreen(screen)
            end
        end)
    else
        hs.alert.show("Active space not found in space list")
    end
end

-- Helper function to move a window to a target space
local function moveWindowToSpace(win, targetSpaceID)
    print("Attempting to move window ID:", win:id(), "to space ID:", targetSpaceID)

    -- Check if the window is already in the target space
    local currentSpaces = spaces.windowSpaces(win)
    if currentSpaces and hs.fnutils.contains(currentSpaces, targetSpaceID) then
        hs.alert.show("Window is already in the target space")
        return false
    end

    -- Check if the target space is a user space
    local spaceType = spaces.spaceType(targetSpaceID)
    if spaceType ~= "user" then
        hs.alert.show("Target space is not a user space")
        return false
    end

    -- Check if the window is compatible (not full-screen or tiled)
    if not win:isStandard() or win:isFullScreen() then
        hs.alert.show("Window is not compatible for movement (not standard or is full-screen)")
        return false
    end

    -- Attempt to move the window
    local success, err = spaces.moveWindowToSpace(win, targetSpaceID)
    if not success then
        hs.alert.show("Failed to move window: " .. (err or "Unknown error"))
        return false
    end

    -- Retry Verification: Ensure the window has moved
    hs.timer.doAfter(0.5, function()
        local targetWindows = spaces.windowsForSpace(targetSpaceID)
        if not hs.fnutils.contains(targetWindows, win:id()) then
            hs.alert.show("Window move verification failed. Retrying...")
            print("Retrying move of Window ID:", win:id(), "to space ID:", targetSpaceID)
            spaces.moveWindowToSpace(win, targetSpaceID) -- Retry the move
        else
            print("Window ID:", win:id(), "successfully moved to space ID:", targetSpaceID)
        end
    end)

    return true
end


--- Method: Move the focused app to the next space
function obj:moveAppToNextSpace()
    local win = window.focusedWindow()
    if not win then
        hs.alert.show("No focused window found")
        return
    end

    local currentSpace = spaces.windowSpaces(win:id())
    if not currentSpace or #currentSpace == 0 then
        hs.alert.show("Unable to determine the current space for the focused window")
        return
    end

    local currentSpaceID = currentSpace[1]
    local currentScreen = win:screen()
    if not currentScreen then
        hs.alert.show("Unable to determine the screen for the focused window")
        return
    end

    local screenUUID = currentScreen:getUUID()
    local spaceIDs = spaces.spacesForScreen(screenUUID)
    if not spaceIDs or #spaceIDs == 0 then
        hs.alert.show("No spaces found for the current screen")
        return
    end

    local currentIndex = hs.fnutils.indexOf(spaceIDs, currentSpaceID)
    if not currentIndex then
        hs.alert.show("Current space not found in space list")
        return
    end

    local nextIndex = (currentIndex % #spaceIDs) + 1
    local nextSpaceID = spaceIDs[nextIndex]

    -- Move the window to the next space
    if moveWindowToSpace(win, nextSpaceID) then
        spaces.gotoSpace(nextSpaceID)
        hs.timer.doAfter(0.5, function()
            win:focus()
        end)
        hs.alert.show("Moved app to next space")
    end
end

--- Method: Move the focused app to the previous space
function obj:moveAppToPreviousSpace()
    local win = window.focusedWindow()
    if not win then
        hs.alert.show("No focused window found")
        return
    end

    local currentSpace = spaces.windowSpaces(win:id())
    if not currentSpace or #currentSpace == 0 then
        hs.alert.show("Unable to determine the current space for the focused window")
        return
    end

    local currentSpaceID = currentSpace[1]
    local currentScreen = win:screen()
    if not currentScreen then
        hs.alert.show("Unable to determine the screen for the focused window")
        return
    end

    local screenUUID = currentScreen:getUUID()
    local spaceIDs = spaces.spacesForScreen(screenUUID)
    if not spaceIDs or #spaceIDs == 0 then
        hs.alert.show("No spaces found for the current screen")
        return
    end

    local currentIndex = hs.fnutils.indexOf(spaceIDs, currentSpaceID)
    if not currentIndex then
        hs.alert.show("Current space not found in space list")
        return
    end

    local prevIndex = (currentIndex - 2 + #spaceIDs) % #spaceIDs + 1
    local prevSpaceID = spaceIDs[prevIndex]

    -- Move the window to the previous space
    if moveWindowToSpace(win, prevSpaceID) then
        spaces.gotoSpace(prevSpaceID)
        hs.timer.doAfter(0.5, function()
            win:focus()
        end)
        hs.alert.show("Moved app to previous space")
    end
end

-- Method: Toggle Show Desktop
function obj:toggleShowDesktop()
    hs.spaces.toggleShowDesktop()
    hs.alert.show("Toggled Show Desktop")
end

-- Method: Toggle Mission Control
function obj:toggleMissionControl()
    hs.spaces.toggleMissionControl()
    hs.alert.show("Toggled Mission Control")
end

return obj
