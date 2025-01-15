local spaces = require("hs.spaces")

-- Hotkey to toggle Show Desktop
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "R", function()
    hs.spaces.toggleShowDesktop()
    hs.alert.show("Toggled Show Desktop")
end)
