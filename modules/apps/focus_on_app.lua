-- Keybinding to forcefully bring the frontmost application to focus, handling various window states
-- Used to bring minimized windows forward, or activate non-reactive screen
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "/", function()
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
end)


