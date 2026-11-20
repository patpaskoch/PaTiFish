# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
### Added
- New addon PaTiFish (owner wish 2026-11-20): a simple fishing helper. One click = one action, nothing automatic.
- Minimap button (drag it anywhere with the right mouse button, or Shift + left button, held): one click puts the fishing pole on (the weapons in your hands are remembered), the next one puts
  those weapons back on. Bar button "Weapons" does the same back.
- Bar (bottom centre, movable, shown while the pole is in your hands): fishing skill, lure time left, a cast bar,
  buttons Cast, Lure (your best lure onto the pole), Catches and Weapons. Key bindings for Cast, Lure and the
  minimap button (Key Bindings > PaTiFish).
- Catch list left of the bar: everything you fished so far with its count (kept per character).
- Louder splash while fishing: effects 100 %, music and ambience off; your volumes come back 15 s after the last cast
  (and on the next login if the game closed while fishing).
- The frame flashes in the last 3 seconds of a cast. Hint for WoW's "Interact with Target" key; setting for "Soft
  interact" so that key finds the bobber.
- `/pfish diagnose`: lists the events of one cast, to find out whether this client reports the bite.
### Fixed
- A fishing pole in the bags was not found (owner 2026-11-20): known poles are recognised by item ID too, and the bags
  are read again when the mouse is over the button.
### Known Issues
- WoW sends no event when a fish bites (as far as known): no flash on the bite itself; catching stays your click.
