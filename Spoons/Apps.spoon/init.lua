local obj = {}
obj.__index = obj

--------------------------------------------------------------------------------
--- metadata
--------------------------------------------------------------------------------
obj.name = "Apps"
obj.version = "1.0"
obj.author = "Selim Acerbas <selimacerbas@gmail.com>"
obj.license = "MIT"

--------------------------------------------------------------------------------
--- logic
--------------------------------------------------------------------------------

-- Function to bring the frontmost application to focus
function obj:bringAppToFront()
    local frontmostApp = hs.application.frontmostApplication()

    if frontmostApp then
        -- Attempt to unhide the application if it's hidden
        frontmostApp:unhide()

        -- Bring the application to the front and activate it
        frontmostApp:activate(true)

        -- Check all windows of the application and bring them to focus
        local allWindows = frontmostApp:allWindows()

        if #allWindows > 0 then
            for _, win in ipairs(allWindows) do
                if win:isMinimized() then
                    win:unminimize() -- Unminimize any minimized windows
                end
                win:focus()          -- Focus each window, ensuring they’re brought to the front
            end
        else
            hs.alert.show("No windows available to focus for " .. frontmostApp:name())
        end
    else
        hs.alert.show("No application detected in the foreground!")
    end
end

-- Method: Cycle through visible windows on the same display
function obj:cycleAppsForwards()
    local currentScreen = hs.mouse.getCurrentScreen()
    local focusedWindow = hs.window.focusedWindow()

    -- Handle minimized focused window by shifting focus to any visible window
    if focusedWindow and focusedWindow:isMinimized() then
        hs.alert.show("Focused window is minimized. Switching to the first visible window.")
        focusedWindow = nil
    end

    -- Check if the focused app is Finder
    if focusedWindow and focusedWindow:application():title() == "Finder" then
        hs.alert.show("Focused app is Finder. Cycling to the next app.")
        local allApps = hs.application.runningApplications()
        for _, app in ipairs(allApps) do
            if app:title() ~= "Finder" and app:mainWindow() then
                app:mainWindow():focus()
                hs.alert.show("Switched to app: " .. app:title())
                return
            end
        end
        hs.alert.show("No other apps available to switch to.")
        return
    end

    -- Gather all non-minimized, visible windows on the current screen, excluding Finder
    local allWindows = hs.window.visibleWindows()
    local screenWindows = {}

    for _, win in ipairs(allWindows) do
        if win:screen() == currentScreen and win:application():title() ~= "Finder" then
            table.insert(screenWindows, win)
        end
    end

    -- Check if we found any windows
    if #screenWindows > 0 then
        hs.alert.show("Number of windows found: " .. #screenWindows)
    else
        hs.alert.show("No windows found on the current screen")
        return
    end

    -- Sort windows by their positions (left-to-right, top-to-bottom)
    table.sort(screenWindows, function(a, b)
        return a:frame().x < b:frame().x or (a:frame().x == b:frame().x and a:frame().y < b:frame().y)
    end)

    -- Set focus to the first window if there was a minimized focus window
    if not focusedWindow then
        focusedWindow = screenWindows[1]
        focusedWindow:focus()
    end

    -- Find the index of the currently focused window
    local currentIndex = nil
    for i, win in ipairs(screenWindows) do
        if win == focusedWindow then
            currentIndex = i
            break
        end
    end

    -- Cycle to the next window in the sorted list
    if currentIndex then
        local nextIndex = (currentIndex % #screenWindows) + 1
        screenWindows[nextIndex]:focus()
        hs.alert.show("Focusing window: " .. screenWindows[nextIndex]:title())
    else
        hs.alert.show("Current window not found in list")
    end
end

-- Method: Cycle through visible windows on the same display forwards
function obj:cycleAppsBackwards()
    local currentScreen = hs.mouse.getCurrentScreen()
    local focusedWindow = hs.window.focusedWindow()

    -- Handle minimized focused window by shifting focus to any visible window
    if focusedWindow and focusedWindow:isMinimized() then
        hs.alert.show("Focused window is minimized. Switching to the first visible window.")
        focusedWindow = nil
    end

    -- Check if the focused app is Finder
    if focusedWindow and focusedWindow:application():title() == "Finder" then
        hs.alert.show("Focused app is Finder. Cycling to the next app.")
        -- Cycle to the next app (excluding Finder)
        local allApps = hs.application.runningApplications()
        for _, app in ipairs(allApps) do
            if app:title() ~= "Finder" and app:mainWindow() then
                app:mainWindow():focus()
                hs.alert.show("Switched to app: " .. app:title())
                return
            end
        end
        hs.alert.show("No other apps available to switch to.")
        return
    end

    -- Gather all non-minimized, visible windows on the current screen, excluding Finder
    local allWindows = hs.window.visibleWindows() -- Only visible windows
    local screenWindows = {}

    for _, win in ipairs(allWindows) do
        if win:screen() == currentScreen and win:application():title() ~= "Finder" then
            table.insert(screenWindows, win)
        end
    end

    -- Check if we found any windows
    if #screenWindows > 0 then
        hs.alert.show("Number of windows found: " .. #screenWindows)
    else
        hs.alert.show("No windows found on the current screen")
        return
    end

    -- Sort windows by their positions (left-to-right, top-to-bottom)
    table.sort(screenWindows, function(a, b)
        return a:frame().x < b:frame().x or (a:frame().x == b:frame().x and a:frame().y < b:frame().y)
    end)

    -- Set focus to the first window if there was a minimized focus window
    if not focusedWindow then
        focusedWindow = screenWindows[1]
        focusedWindow:focus()
    end

    -- Find the index of the currently focused window
    local currentIndex = nil
    for i, win in ipairs(screenWindows) do
        if win == focusedWindow then
            currentIndex = i
            break
        end
    end

    -- Cycle to the previous window in the sorted list
    if currentIndex then
        local prevIndex = (currentIndex - 2) % #screenWindows + 1
        screenWindows[prevIndex]:focus()
        hs.alert.show("Focusing window: " .. screenWindows[prevIndex]:title())
    else
        hs.alert.show("Current window not found in list")
    end
end

-- Hotkey binding to trigger the function
function obj:bindHotkeys(mapping)
    local def = {
        bringAppToFront = { { "cmd", "alt", "ctrl" }, "/", function() self:bringAppToFront() end },
        cycleAppsForwards = { { "ctrl", "alt", "cmd" }, "K", function() self:cycleAppsForwards() end },
        cycleAppsBackwards = { { "ctrl", "alt", "cmd" }, "J", function() self:cycleAppsBackwards() end },
    }

    -- Debugging: Print all keys being bound
    for key, value in pairs(mapping or def) do
        print("Binding hotkey for: " .. key)
        if not def[key] then
            error("Invalid key in mapping: " .. key)
        end
    end

    -- Bind hotkeys
    hs.spoons.bindHotkeysToSpec(def, mapping or def)
end

return obj
