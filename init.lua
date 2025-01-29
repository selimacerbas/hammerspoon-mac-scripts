hs.loadSpoon("Apps")
hs.loadSpoon("Vifari")
hs.loadSpoon("Displays")
hs.loadSpoon("MissionControl")


-- Vifari
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "D", function()
    hs.alert.show("Vifari Started")
    spoon.Vifari:start()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
    hs.alert.show("Vifari Stopped")
    spoon.Vifari:stop()
end)

-- Apps
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "/", function()
    spoon.Apps:bringAppToFront()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "K", function()
    spoon.Apps:cycleAppsForwards()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "J", function()
    spoon.Apps:cycleAppsBackwards()
end)

-- Displays
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "L", function()
    spoon.Displays:cycleDisplaysForwards()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "H", function()
    spoon.Displays:cycleDisplaysBackwards()
end)


-- MissionControl
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "F", function()
    spoon.MissionControl:createSpaceUnderCursor()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "X", function()
    spoon.MissionControl:removeCurrentSpace()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, ",", function()
    spoon.MissionControl:moveToNextSpace()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "M", function()
    spoon.MissionControl:moveToPreviousSpace()
end)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", function()
    spoon.MissionControl:toggleShowDesktop()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "E", function()
    spoon.MissionControl:toggleMissionControl()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "T", function()
    spoon.MissionControl:moveAppToNextSpace()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "Z", function()
    spoon.MissionControl:moveAppToPreviousSpace()
end)
