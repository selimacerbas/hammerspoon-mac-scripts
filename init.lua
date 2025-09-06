hs.loadSpoon("Apps")
hs.loadSpoon("Vifari")
hs.loadSpoon("Displays")
hs.loadSpoon("MissionControl")
hs.loadSpoon("KeyCaster")
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.PaperWM = {
    url = "https://github.com/mogenson/PaperWM.spoon",
    desc = "PaperWM.spoon repository",
    branch = "release",
}

spoon.SpoonInstall:andUse("PaperWM", {
    repo = "PaperWM",
    config = { screen_margin = 16, window_gap = 2 },
    start = true,
    hotkeys = PaperWM and PaperWM.default_hotkeys or nil, -- use defaults
})

-- Optional: For column
spoon.KeyCaster:configure({
    mode = "column",
    fadingDuration = 2.0,
    maxVisible = 5,
    minAlphaWhileVisible = 0.35,
    followInterval = 0.4,
    -- column behavior
    column = {
        maxCharsPerBox = 14,  -- start a new box after 14 glyphs
        newBoxOnPause  = 0.70 -- or after 0.7s idle
    },
    line = {
        box = { w = 420, h = 36, corner = 10 },
        maxSegments = 60,
        gap = 6, -- px between segments
    },
    -- visuals
    box = { w = 260, h = 36, spacing = 8, corner = 10 },
    margin = { right = 20, bottom = 80 },
    font = { name = "Menlo", size = 18 }, -- change to any installed font name
})

-- Bind your requested hotkeys:
spoon.KeyCaster:bindHotkeys(spoon.KeyCaster.defaultHotkeys)

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
