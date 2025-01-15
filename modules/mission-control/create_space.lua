local spaces = require("hs.spaces")
local mouse = require("hs.mouse")

-- Hotkey to create a space under the cursor
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "F", function()
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
end)
