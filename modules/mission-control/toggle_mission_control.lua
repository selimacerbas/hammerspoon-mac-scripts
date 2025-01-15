-- Hotkey to toggle Mission Control
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "E", function()
    hs.spaces.toggleMissionControl()
    hs.alert.show("Toggled Mission Control")
end)
