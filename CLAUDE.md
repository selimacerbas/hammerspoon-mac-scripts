# Hammerspoon Configuration

## Project Structure

- `init.lua` — Main config. Loads all spoons, sets up PaperWM nav mode, configures hotkeys.
- `Spoons/` — Each spoon is a separate git repo cloned into `<Name>.spoon/` directories.

## Spoon Ownership

**My repos** (selimacerbas):
- `FocusMode.spoon` — github.com/selimacerbas/FocusMode.spoon
- `CursorScope.spoon` — github.com/selimacerbas/CursorScope.spoon
- `KeyCaster.spoon` — github.com/selimacerbas/KeyCaster.spoon

**Upstream repos** (mogenson, dzirtusss):
- `PaperWM.spoon` — github.com/mogenson/PaperWM.spoon
- `ActiveSpace.spoon` — github.com/mogenson/ActiveSpace.spoon
- `WarpMouse.spoon` — github.com/mogenson/WarpMouse.spoon
- `Vifari` — github.com/dzirtusss/vifari

## How Spoons Are Managed

`init.lua` has `ensureSpoonGit(name, url, opts)` which auto-clones/updates spoons on reload. Each spoon load is guarded with `if not skipEnsures then` so that `Ctrl+Alt+Cmd+L` does a fast reload without hitting git.

Each spoon under my ownership is its own git repo with its own commits, tags, and releases. The parent `.hammerspoon` repo tracks configuration only (`init.lua`), not the spoon contents.

## Conventions

- Spoons use `obj` pattern (table with `__index`, `:start()`, `:stop()`, `:bindHotkeys()`)
- Settings are `obj.<name>` fields set before `:start()`
- Internal state uses `obj._<name>` prefix
- Version string in `obj.version` matches git tags (`v0.3.0`)
- Commits on my spoons: authored by me (selimacerbas), no Co-Authored-By

## Key Integration: FocusMode + PaperWM

- FocusMode dims everything except focused app, PaperWM tiles windows
- PaperWM fires rapid move/resize events during tiling; FocusMode debounces via `eventSettleDelay`
- `wrapMove()` in init.lua calls `FocusMode:_suspendFor(1.2)` to hide overlays during PaperWM window moves
- Both use separate `hs.window.filter` instances (no conflict)

## Hotkey Map

- `Ctrl+Alt+Cmd+I` — Start FocusMode
- `Ctrl+Alt+Cmd+O` — Stop FocusMode
- `Ctrl+Alt+Cmd+L` — Reload Hammerspoon (skip spoon git updates)
- `Ctrl+Alt+Cmd+R` — Refresh PaperWM windows
- `Cmd+Return` — Enter PaperWM nav mode (h/j/k/l to navigate, Shift to swap, Esc to exit)

## Releasing My Spoons

For spoons I own, use semver tags matching `obj.version`:
1. Bump `obj.version` in `init.lua`
2. Commit, push
3. `git tag v<version>` and push tag
4. `gh release create v<version>` with release notes referencing issue numbers
