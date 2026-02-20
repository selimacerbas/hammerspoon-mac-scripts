------------------------------------------------------------
-- 0) Generic git-based spoon installer/updater
------------------------------------------------------------
local HOME = os.getenv("HOME")
local SPOON_DIR = HOME .. "/.hammerspoon/Spoons"

local function exists(p)
	return hs.fs.attributes(p) ~= nil
end

local function sh(cmd)
	local out, ok, _, rc = hs.execute(cmd, true)
	return (ok == true and rc == 0), (out or "")
end

-- ensureSpoonGit(name, url, opts)
-- opts.branch (string): git branch to ensure
-- opts.depth  (int|nil): default 1
-- opts.reset  (bool): default true (hard reset to origin/<branch>)
--
-- If the spoon is already cloned, git updates run in the background
-- so a slow/hanging fetch never blocks Hammerspoon from loading.
-- Fresh clones still run synchronously (files must exist before loadSpoon).
local function ensureSpoonGit(name, url, opts)
	opts = opts or {}
	local branch = opts.branch or "main"
	local depth = opts.depth or 1
	local reset = (opts.reset ~= false)

	local target = string.format("%s/%s.spoon", SPOON_DIR, name)
	hs.fs.mkdir(SPOON_DIR)

	-- Path A: already cloned → update in the background (non-blocking)
	if exists(target) and exists(target .. "/.git") then
		local resetCmd = reset
			and string.format([[/usr/bin/git -C %q reset --hard origin/%s]], target, branch)
			or  string.format([[/usr/bin/git -C %q pull --ff-only origin %s]], target, branch)
		local script = table.concat({
			string.format([[/usr/bin/git -C %q remote set-url origin %q]], target, url),
			string.format([[/usr/bin/git -C %q fetch --prune origin]], target),
			string.format([[/usr/bin/git -C %q checkout %s]], target, branch),
			resetCmd,
		}, " && ")
		hs.task.new("/bin/sh", function(code, _, stderr)
			if code == 0 then
				local _, b = sh(string.format([[/usr/bin/git -C %q rev-parse --abbrev-ref HEAD]], target))
				local _, c = sh(string.format([[/usr/bin/git -C %q log -1 --pretty=%%h]], target))
				b = (b or ""):gsub("%s+$", "")
				c = (c or ""):gsub("%s+$", "")
				hs.printf("%s.spoon => branch=%s commit=%s (bg)", name, b, c)
			else
				hs.printf("%s.spoon: bg update failed (exit %d): %s", name, code, (stderr or ""):gsub("%s+$", ""))
			end
		end, { "-c", script }):start()
		return true
	end

	-- Path B: clone fresh (synchronous — needed for first load)
	local tmp = string.format("%s/._tmp_%s_%d", SPOON_DIR, name, os.time())
	sh(string.format([[rm -rf %q]], tmp))
	local ok = sh(string.format([[/usr/bin/git clone --branch %q --depth %d %q %q]], branch, depth, url, tmp))
	if not ok then
		hs.alert.show("Clone failed for " .. name)
		return false
	end

	-- Find the actual spoon directory within the repo (supports nested layouts)
	local candidate = tmp .. "/" .. name .. ".spoon"
	local src
	if exists(candidate) then
		src = candidate
	else
		local iter, dirObj = hs.fs.dir(tmp)
		if iter then
			for f in iter, dirObj do
				if f and f:match("%.spoon$") then
					src = tmp .. "/" .. f
					break
				end
			end
		end
		src = src or tmp -- fallback: repo itself is the spoon
	end

	sh(string.format([[rm -rf %q]], target))
	sh(string.format([[mkdir -p %q]], SPOON_DIR))
	sh(string.format([[mv %q %q]], src, target))
	sh(string.format([[rm -rf %q]], tmp))

	-- If target is not a spoon root (missing init.lua), do a one-shot unpack
	if not exists(target .. "/init.lua") then
		local tmp2 = string.format("%s/._tmp_fix_%s_%d", SPOON_DIR, name, os.time())
		sh(string.format([[rm -rf %q]], tmp2))
		local ok2 = sh(string.format([[/usr/bin/git clone --branch %q --depth %d %q %q]], branch, depth, url, tmp2))
		if ok2 then
			local candidate2 = tmp2 .. "/" .. name .. ".spoon"
			local src2
			if exists(candidate2) then
				src2 = candidate2
			else
				local iter2, dirObj2 = hs.fs.dir(tmp2)
				if iter2 then
					for f in iter2, dirObj2 do
						if f and f:match("%.spoon$") then
							src2 = tmp2 .. "/" .. f
							break
						end
					end
				end
				src2 = src2 or tmp2
			end
			sh(string.format([[rm -rf %q]], target))
			sh(string.format([[mv %q %q]], src2, target))
		end
		sh(string.format([[rm -rf %q]], tmp2))
	end

	-- Log the exact build
	local _, b = sh(string.format([[ /usr/bin/git -C %q rev-parse --abbrev-ref HEAD ]], target))
	local _, c = sh(string.format([[ /usr/bin/git -C %q log -1 --pretty=%%h ]], target))
	b = (b or ""):gsub("%s+$", "")
	c = (c or ""):gsub("%s+$", "")
	hs.printf("%s.spoon => branch=%s commit=%s", name, b, c)
	return true
end

-- === Soft reload (skip repo updates) ===
local ENSURE_SKIP_KEY = "EnsureSpoons.skip"
local skipEnsures = hs.settings.get(ENSURE_SKIP_KEY) == true
if skipEnsures then
	hs.settings.set(ENSURE_SKIP_KEY, false)
end

-- Hotkey: Ctrl+Alt+Cmd+L → reload without updating any spoons
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "L", function()
	hs.settings.set(ENSURE_SKIP_KEY, true)
	hs.alert.show("Reloading without updating spoons…")
	hs.reload()
end)

------------------------------------------------------------
-- 1) FocusMode
------------------------------------------------------------
if not skipEnsures then
	ensureSpoonGit("FocusMode", "https://github.com/selimacerbas/FocusMode.spoon", { branch = "main" })
end
FocusMode = hs.loadSpoon("FocusMode")

FocusMode.dimAlpha = 0.5
FocusMode.mouseDim = true
FocusMode.windowCornerRadius = 8
FocusMode:bindHotkeys({
	start = { { "ctrl", "alt", "cmd" }, "I" },
	stop = { { "ctrl", "alt", "cmd" }, "O" },
})
FocusMode:start()

------------------------------------------------------------
-- 2) CursorScope
------------------------------------------------------------
if not skipEnsures then
	ensureSpoonGit("CursorScope", "https://github.com/selimacerbas/CursorScope.spoon", { branch = "main" })
end
CursorScope = hs.loadSpoon("CursorScope")
CursorScope:bindHotkeys()

------------------------------------------------------------
-- 3) PaperWM
------------------------------------------------------------
local PAPERWM_BRANCH = "main"
local PAPERWM_REPO = "https://github.com/mogenson/PaperWM.spoon"
local PAPERWM_NAME = "PaperWM"
local PAPERWM_PATH = string.format("%s/%s.spoon", SPOON_DIR, PAPERWM_NAME)

if not skipEnsures then
	ensureSpoonGit(PAPERWM_NAME, PAPERWM_REPO, { branch = PAPERWM_BRANCH, depth = 1, reset = true })
end

PaperWM = hs.loadSpoon("PaperWM")
PaperWM.screen_margin = 16
PaperWM.window_gap = 2
PaperWM.window_filter:setAppFilter("Safari", false)
PaperWM:start()
hs.timer.doAfter(0.05, function()
	if PaperWM.refreshWindows then
		PaperWM:refreshWindows()
	end
end)

hs.printf("PaperWM running from %s (branch=%s)", PAPERWM_PATH, PAPERWM_BRANCH)

local s = PaperWM
s:bindHotkeys(s.default_hotkeys)
s.window_ratios = { 1 / 2 }

local A = s.actions.actions()
local normalized = {}
local function normalizeToHalf(win)
	if not win then
		return
	end
	local id = win:id()
	if not id or normalized[id] then
		return
	end
	if not s.window_filter:isWindowAllowed(win) then
		return
	end
	normalized[id] = true -- Mark immediately to prevent duplicate triggers
	s:refreshWindows()
	hs.timer.doAfter(0.10, function()
		local prev = hs.window.frontmostWindow()
		win:focus()
		A.cycle_width()
		if prev and prev:id() ~= id then
			prev:focus()
		end
	end)
end
s.window_filter:subscribe({ hs.window.filter.windowCreated, hs.window.filter.windowVisible }, function(win)
	hs.timer.doAfter(0.05, function()
		normalizeToHalf(win)
	end)
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", function()
	A.refresh_windows()
end)

local nav = hs.hotkey.modal.new({ "cmd" }, "return")
local tip
function nav:entered()
	tip = hs.alert.show("PaperWM: NAV MODE (Esc to exit)")
end

function nav:exited()
	if tip then
		hs.alert.closeAll()
		tip = nil
	end
end

-- wrapMove: for cross-space moves (async Spaces API needs a beat before retile)
local function wrapMove(fn)
	return function()
		fn()
		hs.timer.doAfter(0.25, A.refresh_windows)
	end
end
-- wrapSwitch: for space switching (Mission Control is async)
local function wrapSwitch(fn)
	return function()
		fn()
		hs.timer.doAfter(0.25, A.refresh_windows)
	end
end

nav:bind({}, "escape", function()
	nav:exit()
end)
nav:bind({ "cmd" }, "return", function()
	nav:exit()
end)
-- Focus/swap: direct calls, no wrapper needed (these don't use Spaces APIs)
nav:bind({}, "h", nil, A.focus_left, nil, A.focus_left)
nav:bind({}, "l", nil, A.focus_right, nil, A.focus_right)
nav:bind({}, "j", nil, A.focus_down, nil, A.focus_down)
nav:bind({}, "k", nil, A.focus_up, nil, A.focus_up)
nav:bind({ "shift" }, "h", nil, A.swap_left, nil, A.swap_left)
nav:bind({ "shift" }, "j", nil, A.swap_down, nil, A.swap_down)
nav:bind({ "shift" }, "k", nil, A.swap_up, nil, A.swap_up)
nav:bind({ "shift" }, "l", nil, A.swap_right, nil, A.swap_right)
nav:bind({}, "c", nil, A.center_window)
nav:bind({}, "f", nil, A.full_width)
nav:bind({}, "r", nil, A.cycle_width)
nav:bind({}, ",", nil, wrapSwitch(A.switch_space_l), wrapSwitch(A.switch_space_l))
nav:bind({}, ".", nil, wrapSwitch(A.switch_space_r), wrapSwitch(A.switch_space_r))
nav:bind({}, "1", nil, wrapSwitch(A.switch_space_1), wrapSwitch(A.switch_space_1))
nav:bind({}, "2", nil, wrapSwitch(A.switch_space_2), wrapSwitch(A.switch_space_2))
nav:bind({}, "3", nil, wrapSwitch(A.switch_space_3), wrapSwitch(A.switch_space_3))
--
-- move focused window into / out of a column
nav:bind({}, "i", nil, wrapMove(A.slurp_in), nil, wrapMove(A.slurp_in))
nav:bind({}, "o", nil, wrapMove(A.barf_out), nil, wrapMove(A.barf_out))

nav:bind({ "shift" }, "1", nil, wrapMove(A.move_window_1), nil, wrapMove(A.move_window_1))
nav:bind({ "shift" }, "2", nil, wrapMove(A.move_window_2), nil, wrapMove(A.move_window_2))
nav:bind({ "shift" }, "3", nil, wrapMove(A.move_window_3), nil, wrapMove(A.move_window_3))

------------------------------------------------------------
-- 4) ActiveSpace & WarpMouse
------------------------------------------------------------
if not skipEnsures then
	ensureSpoonGit("ActiveSpace", "https://github.com/mogenson/ActiveSpace.spoon", { branch = "main" })
end
ActiveSpace = hs.loadSpoon("ActiveSpace")
ActiveSpace:start()

if not skipEnsures then
	ensureSpoonGit("WarpMouse", "https://github.com/mogenson/WarpMouse.spoon", { branch = "main" })
end
WarpMouse = hs.loadSpoon("WarpMouse")
WarpMouse:start()

------------------------------------------------------------
-- 5) KeyCaster
------------------------------------------------------------
if not skipEnsures then
	ensureSpoonGit("KeyCaster", "https://github.com/selimacerbas/KeyCaster.spoon", { branch = "main" })
end
KeyCaster = hs.loadSpoon("KeyCaster")
KeyCaster:bindHotkeys(KeyCaster.defaultHotkeys)

------------------------------------------------------------
-- 6) StayActive
------------------------------------------------------------
if not skipEnsures then
	ensureSpoonGit("StayActive", "https://github.com/selimacerbas/StayActive.spoon", { branch = "main" })
end
StayActive = hs.loadSpoon("StayActive")
StayActive:bindHotkeys(StayActive.defaultHotkeys)

------------------------------------------------------------
-- 7) Vifari
------------------------------------------------------------
if not skipEnsures then
	ensureSpoonGit("Vifari", "https://github.com/dzirtusss/vifari", { branch = "main" })
end
Vifari = hs.loadSpoon("Vifari")
Vifari:start()

------------------------------------------------------------
-- Tips: Mission Control settings
-- - Uncheck: “Automatically rearrange Spaces based on most recent use”
-- - Check:   “Displays have separate Spaces”
------------------------------------------------------------
