-- Update the Lua package path to include the modules directory
package.path = package.path .. ';' .. hs.configdir .. '/modules/?.lua;' .. hs.configdir .. '/modules/?/init.lua'

-- Load modules
local apps_focus_on_app = require("apps.focus_on_app")
local apps_move_between_apps = require("apps.move_between_apps")

local displays_move_between_displays = require("displays.move_between_displays")

local mission_control_create_space = require("mission-control.create_space")
local mission_control_toggle_desktop = require("mission-control.toggle_desktop")
local mission_control_move_app_to_space = require("mission-control.move_app_to_space")
local mission_control_move_between_spaces = require("mission-control.move_between_spaces")
local mission_control_toggle_mission_control = require("mission-control.toggle_mission_control")
