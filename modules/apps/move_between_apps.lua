-- Cycle forward through visible apps on the same display (Ctrl + Alt + Cmd + K)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "K", function()
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

    -- Cycle to the next window in the sorted list
    if currentIndex then
        local nextIndex = (currentIndex % #screenWindows) + 1
        screenWindows[nextIndex]:focus()
        hs.alert.show("Focusing window: " .. screenWindows[nextIndex]:title())
    else
        hs.alert.show("Current window not found in list")
    end
end)






-- Cycle backward through visible apps on the same display (Ctrl + Alt + Cmd + H)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "J", function()
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
end)











