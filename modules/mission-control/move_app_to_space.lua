--  This is currently not working but there is a good progress. This script should normallz work but due to Hammerspoon API, it does not.
local spaces = require("hs.spaces")
local window = require("hs.window")

-- Helper function to move a window to a target space
local function moveWindowToSpace(win, targetSpaceID)
    print("Attempting to move window ID:", win:id(), "to space ID:", targetSpaceID)

    -- Check if the window is already in the target space
    local currentSpaces = spaces.windowSpaces(win)
    if currentSpaces and hs.fnutils.contains(currentSpaces, targetSpaceID) then
        hs.alert.show("Window is already in the target space")
        print("Window ID:", win:id(), "is already in space ID:", targetSpaceID)
        return false
    end

    -- Check if the target space is a user space
    local spaceType = spaces.spaceType(targetSpaceID)
    if spaceType ~= "user" then
        hs.alert.show("Target space is not a user space")
        print("Target Space ID:", targetSpaceID, "is not a user space (type:", spaceType, ")")
        return false
    end

    -- Check if the window is compatible (not full-screen or tiled)
    local isStandard = win:isStandard()
    local isFullScreen = win:isFullScreen()
    if not isStandard or isFullScreen then
        hs.alert.show("Window is not compatible for movement (not standard or is full-screen)")
        print("Window ID:", win:id(), "isStandard:", isStandard, "isFullScreen:", isFullScreen)
        return false
    end

    -- Attempt to move the window
    local success, err = spaces.moveWindowToSpace(win, targetSpaceID)
    if not success then
        hs.alert.show("Failed to move window: " .. (err or "Unknown error"))
        print("Error moving window ID:", win:id(), "to space ID:", targetSpaceID, "Error:", err)
        return false
    end

    -- Verify the window was moved
    local targetWindows = spaces.windowsForSpace(targetSpaceID)
    if not hs.fnutils.contains(targetWindows, win:id()) then
        hs.alert.show("Window move verification failed")
        print("Window ID:", win:id(), "not found in target space ID:", targetSpaceID)
        return false
    end

    print("Window ID:", win:id(), "successfully moved to space ID:", targetSpaceID)
    return true
end


-- Move the focused app to the next space
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "T", function()
    local win = window.focusedWindow()
    if not win then
        hs.alert.show("No focused window found")
        return
    end

    local currentSpace = spaces.windowSpaces(win:id())
    if not currentSpace or #currentSpace == 0 then
        hs.alert.show("Unable to determine the current space for the focused window")
        print("Window ID:", win:id(), "has no associated spaces")
        return
    end

    local currentSpaceID = currentSpace[1]
    print("Current Space ID:", currentSpaceID)

    local currentScreen = win:screen()
    if not currentScreen then
        hs.alert.show("Unable to determine the screen for the focused window")
        return
    end

    local screenUUID = currentScreen:getUUID()
    print("Current Screen UUID:", screenUUID)

    local spaceIDs = spaces.spacesForScreen(screenUUID)
    if not spaceIDs or #spaceIDs == 0 then
        hs.alert.show("No spaces found for the current screen")
        print("Screen UUID:", screenUUID, "has no spaces")
        return
    end

    print("Space IDs for screen:", hs.inspect(spaceIDs))

    local currentIndex = hs.fnutils.indexOf(spaceIDs, currentSpaceID)
    if not currentIndex then
        hs.alert.show("Current space not found in space list")
        print("Current space ID:", currentSpaceID, "not found in space list")
        return
    end

    local nextIndex = (currentIndex % #spaceIDs) + 1
    local nextSpaceID = spaceIDs[nextIndex]
    print("Next Space ID:", nextSpaceID)

    -- Move the window to the next space
    if moveWindowToSpace(win, nextSpaceID) then
        spaces.gotoSpace(nextSpaceID)
        hs.timer.doAfter(0.5, function()
            win:focus()
        end)
        hs.alert.show("Moved app to next space")
    end
end)

-- Move the focused app to the previous space
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "Z", function()
    local win = window.focusedWindow()
    if not win then
        hs.alert.show("No focused window found")
        return
    end

    local currentSpace = spaces.windowSpaces(win:id())
    if not currentSpace or #currentSpace == 0 then
        hs.alert.show("Unable to determine the current space for the focused window")
        print("Window ID:", win:id(), "has no associated spaces")
        return
    end

    local currentSpaceID = currentSpace[1]
    print("Current Space ID:", currentSpaceID)

    local currentScreen = win:screen()
    if not currentScreen then
        hs.alert.show("Unable to determine the screen for the focused window")
        return
    end

    local screenUUID = currentScreen:getUUID()
    print("Current Screen UUID:", screenUUID)

    local spaceIDs = spaces.spacesForScreen(screenUUID)
    if not spaceIDs or #spaceIDs == 0 then
        hs.alert.show("No spaces found for the current screen")
        print("Screen UUID:", screenUUID, "has no spaces")
        return
    end

    print("Space IDs for screen:", hs.inspect(spaceIDs))

    local currentIndex = hs.fnutils.indexOf(spaceIDs, currentSpaceID)
    if not currentIndex then
        hs.alert.show("Current space not found in space list")
        print("Current space ID:", currentSpaceID, "not found in space list")
        return
    end

    local prevIndex = (currentIndex - 2 + #spaceIDs) % #spaceIDs + 1
    local prevSpaceID = spaceIDs[prevIndex]
    print("Previous Space ID:", prevSpaceID)

    -- Move the window to the previous space
    if moveWindowToSpace(win, prevSpaceID) then
        spaces.gotoSpace(prevSpaceID)
        hs.timer.doAfter(0.5, function()
            win:focus()
        end)
        hs.alert.show("Moved app to previous space")
    end
end)
