local spaces = require("hs.spaces")
local mouse = require("hs.mouse")
local window = require("hs.window")

-- Move to the next space
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, ",", function()
    local function getCursorScreenUUID()
        local screen = mouse.getCurrentScreen() or hs.screen.mainScreen()
        return screen and screen:getUUID() or nil
    end

    local function findActiveSpaceIndex(spaceIDs, activeSpace)
        for i, spaceID in ipairs(spaceIDs) do
            if spaceID == activeSpace then
                return i
            end
        end
        return nil
    end

    local function focusFrontmostWindowOnScreen(screen)
        local windows = window.orderedWindows()
        for _, win in ipairs(windows) do
            if win:screen() == screen then
                win:focus()
                return
            end
        end
        hs.alert.show("No frontmost window found on the target screen")
    end

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
end)

-- Move to the previous space
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "M", function()
    local function getCursorScreenUUID()
        local screen = mouse.getCurrentScreen() or hs.screen.mainScreen()
        return screen and screen:getUUID() or nil
    end

    local function findActiveSpaceIndex(spaceIDs, activeSpace)
        for i, spaceID in ipairs(spaceIDs) do
            if spaceID == activeSpace then
                return i
            end
        end
        return nil
    end

    local function focusFrontmostWindowOnScreen(screen)
        local windows = window.orderedWindows()
        for _, win in ipairs(windows) do
            if win:screen() == screen then
                win:focus()
                return
            end
        end
        hs.alert.show("No frontmost window found on the target screen")
    end

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
end)
